# Phase 8: Legacy Workload Migration to Azure

**Depends on**: Phase 7 (Azure VNet and VPN active), Phase 6 (ASR vault configured)  
**Key Result**: HR application VM running in Azure, DNS updated, users accessing the app transparently over the VPN, and on-premises server safely decommissioned

---

## Overview

This phase lifts the on-premises HR application server (HR-APP-01) into Azure using a combination of Azure Site Recovery for the initial replication and a final cutover during a scheduled maintenance window. The application uses IIS to host a web front-end and a local SQL Server instance. After migration, on-premises clients reach the app over the S2S VPN without any client-side changes — only the DNS record changes.

---

## Step 1: Pre-Migration Assessment

Before moving anything, document the current server state so you have an accurate baseline to verify against post-migration.

**Capture a performance baseline from the on-premises server** (run during a typical business hour):

```powershell
# Run on HR-APP-01 directly or via PSRemoting
$server = "HR-APP-01"
Invoke-Command -ComputerName $server -ScriptBlock {
  $cpu = (Get-Counter "\Processor(_Total)\% Processor Time" -SampleInterval 5 -MaxSamples 12).CounterSamples.CookedValue | Measure-Object -Average
  $mem = (Get-Counter "\Memory\Available MBytes" -SampleInterval 5 -MaxSamples 12).CounterSamples.CookedValue | Measure-Object -Average
  [PSCustomObject]@{
    CPU_Avg_Pct   = [math]::Round($cpu.Average, 1)
    MemAvail_MB   = [math]::Round($mem.Average, 0)
    OS            = (Get-WmiObject Win32_OperatingSystem).Caption
    DiskUsed_GB   = [math]::Round((Get-PSDrive C).Used / 1GB, 1)
  }
} | Format-List
```

Record the output. Use the CPU and memory averages to size the Azure VM: if the server is running at 40% CPU on a 4-core host, a `Standard_D4s_v3` (4 vCPU, 16 GB RAM) is a comfortable match. If average CPU is below 20%, a `Standard_D2s_v3` is sufficient.

Also document:
- Current IP address: `192.168.1.50`
- DNS name: `hr-app.nig-e-mart.local`
- Services running: IIS (W3SVC) and SQL Server (MSSQLSERVER)
- SQL database names: run `Get-SqlDatabase -ServerInstance HR-APP-01` and note each database name

---

## Step 2: Enable ASR Replication for HR-APP-01

Azure Site Recovery will continuously replicate the VM's disks to Azure. This minimises down-time during cutover because the replica is kept nearly in sync. If you have not yet set up the ASR infrastructure, complete `07-phase-6-high-availability-redundancy/02-azure-site-recovery.md` first.

Assuming the Recovery Services Vault and Hyper-V site are already configured, add HR-APP-01 to replication:

1. In the Azure portal, go to your Recovery Services Vault → **Site Recovery** → **Replicated items** → **+ Replicate**.
2. Set **Source**: On-Premises | **Source location**: your Hyper-V site name.
3. **Target location**: your Azure region (e.g., Canada East).
4. **Target resource group**: `rg-hybrid-prod`.
5. **Target virtual network**: `vnet-hybrid` | **Subnet**: `subnet-application`.
6. Under **Replication policy**, select `ASRPolicy-default` (15-min copy frequency).
7. Select **HR-APP-01** from the list of VMs and click **OK** to start replication.

Initial replication transfers the full disk contents and can take several hours depending on the disk size. Monitor progress under **Replicated items** — wait until the status shows **Protected** before proceeding to the cutover.

---

## Step 3: Prepare the Azure VM (Pre-Cutover)

While ASR is replicating, configure the target Azure environment so you can act quickly during the maintenance window.

**Create the NIC and confirm the target IP:**

```powershell
Connect-AzAccount
$rg        = "rg-hybrid-prod"
$vnet      = Get-AzVirtualNetwork -ResourceGroupName $rg -Name "vnet-hybrid"
$subnet    = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name "subnet-application"

# Reserve a static private IP for the migrated VM so DNS is predictable
$nicName   = "hr-app-azure-nic"
$privateIP = "10.0.2.50"

$nic = New-AzNetworkInterface `
  -Name $nicName `
  -ResourceGroupName $rg `
  -Location "canadaeast" `
  -SubnetId $subnet.Id `
  -PrivateIpAddress $privateIP
```

Do not assign a public IP. The VM is only accessible from on-premises over the VPN.

**Create a Network Security Group for the application tier:**

```powershell
$nsgName = "nsg-hr-app"
$nsg = New-AzNetworkSecurityGroup -Name $nsgName -ResourceGroupName $rg -Location "canadaeast"

# Allow inbound traffic on IIS port 8080 from on-prem subnet only
Add-AzNetworkSecurityRuleConfig -NetworkSecurityGroup $nsg `
  -Name "Allow-HTTP-OnPrem" `
  -Protocol Tcp -Direction Inbound -Priority 100 `
  -SourceAddressPrefix "192.168.1.0/24" -SourcePortRange "*" `
  -DestinationAddressPrefix "*" -DestinationPortRange "8080" `
  -Access Allow | Set-AzNetworkSecurityGroup

# Attach the NSG to the NIC
$nic.NetworkSecurityGroup = $nsg
$nic | Set-AzNetworkInterface
```

---

## Step 4: Perform the Cutover

Schedule a maintenance window (e.g., Friday 10 PM – 2 AM). Notify affected users in advance.

**At the start of the maintenance window:**

1. In the Azure portal, go to the Recovery Services Vault → **Replicated items** → click **HR-APP-01**.
2. Click **Failover** → **Test Failover** first (using an isolated test network) to confirm the VM boots and IIS responds inside Azure. If the test failover succeeds, clean it up by clicking **Cleanup test failover**.
3. Click **Failover** (not test) → select the latest recovery point → uncheck **Shut down machine before beginning failover** (you will do this manually in the next step).

**On the on-premises server, gracefully stop the application:**

```powershell
# Run on HR-APP-01
Stop-Service -Name "W3SVC"   # Stop IIS
Stop-Service -Name "MSSQLSERVER"  # Stop SQL Server
# Wait 2 minutes for in-flight transactions to complete, then:
Shutdown-Computer -ComputerName HR-APP-01 -Force
```

4. Back in the Azure portal, confirm the failover and wait for the VM to start in Azure. It will use the most recent replication snapshot — taken within the last 15 minutes.
5. Once the VM is running, connect via RDP through the Bastion host (or a jump box) and verify IIS and SQL Server started automatically. Run a quick database query to confirm data integrity.

---

## Step 5: Update DNS

Once the Azure VM is confirmed working, redirect the DNS entry so clients resolve `hr-app.nig-e-mart.local` to the new Azure private IP:

```powershell
# Run on the primary on-premises domain controller
$dnsServer = "192.168.1.10"
$zone      = "nig-e-mart.local"

# Remove the old record pointing to the on-premises server
Remove-DnsServerResourceRecord -ComputerName $dnsServer `
  -ZoneName $zone -Name "hr-app" -RRType "A" -Force

# Add the new record pointing to the Azure VM
Add-DnsServerResourceRecordA -ComputerName $dnsServer `
  -ZoneName $zone -Name "hr-app" -IPv4Address "10.0.2.50"

# Confirm resolution from an on-premises client
Resolve-DnsName "hr-app.nig-e-mart.local" -Server $dnsServer
# Expected output: 10.0.2.50
```

DNS changes propagate to on-premises clients based on the zone's TTL (default 1 hour). Clients that have the old IP cached can be flushed manually with `ipconfig /flushdns`.

---

## Step 6: Post-Cutover Validation

Run a structured validation before declaring the migration complete:

```powershell
# From an on-premises client machine
$appUrl = "http://hr-app.nig-e-mart.local:8080"
$response = Invoke-WebRequest -Uri $appUrl -UseDefaultCredentials
Write-Output "HTTP Status: $($response.StatusCode)"
# Expected: 200
```

Also complete the following user acceptance tests manually:

1. Log in to the HR application with a standard user account — confirm the login screen loads and authentication succeeds.
2. Create a test employee record and save it. Confirm the record persists after a browser refresh.
3. Run a report or search query that hits the database. Confirm the results match what was visible on the old system.
4. Upload a document if the application supports it. Confirm the file is stored and retrievable.

If any test fails, the on-premises server is still shut down but intact. You can fail back to it by running an ASR failback from the Azure portal while you diagnose the issue — do not decommission until all tests pass.

---

## Step 7: Decommission the On-Premises Server

After at least 7 days of stable operation in Azure with no user-reported issues, decommission HR-APP-01.

**Day 1 (immediately post-cutover):** Confirm the server is powered off. Leave it in this state as a safety net.

**Day 7:** Verify no users or services are still trying to connect to the old IP (`192.168.1.50`). Check firewall logs and DNS query logs for any traffic to that address.

**Day 30:** If no issues have been reported:

```powershell
# Remove the VM from Active Directory
Remove-ADComputer -Identity "HR-APP-01" -Confirm:$false

# Update the asset inventory spreadsheet — mark HR-APP-01 as decommissioned
# If it is a physical server, coordinate with facilities for hardware removal or reuse
# If it is a Hyper-V VM, remove it from the Hyper-V host:
Remove-VM -Name "HR-APP-01" -Force -ComputerName "HVHOST-01"
```

Remove the ASR replication item from the Recovery Services Vault:

1. Azure portal → Recovery Services Vault → **Replicated items** → **HR-APP-01**.
2. Click **Disable replication** → confirm. This stops billing for the replication storage.

Finally, update the DNS zone to remove any lingering records that pointed to the old server, and update the project asset register to reflect the new VM location.

---

## Completion Checklist

- Performance baseline captured from the on-premises server before migration
- ASR replication enabled and status reached **Protected** before cutover
- Test failover completed and cleaned up successfully
- Maintenance window cutover executed: on-prem server shut down, Azure VM confirmed healthy
- IIS and SQL Server confirmed running in Azure after cutover
- DNS record updated to `10.0.2.50` and verified resolving correctly
- All user acceptance tests passed (login, CRUD operations, reports, file upload)
- Seven-day stability period observed with no issues
- On-premises VM removed from Hyper-V and AD after 30-day hold
- ASR replication item disabled after decommission

---

## Next Step

Proceed to [Phase 9 – File Services & Access](../10-phase-9-file-services-access/01-file-services-access.md).

