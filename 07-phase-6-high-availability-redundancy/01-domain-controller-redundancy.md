# Phase 6: High Availability and Domain Controller Redundancy

## Phase Overview

This phase deploys a secondary domain controller in Azure, configures replication across on-premises and cloud, and establishes failover procedures ensuring business continuity.

**Duration**: 2 weeks  
**Key Objectives**: Secondary DC deployment, AD replication, failover testing, FSMO role distribution

---

## Task 1: Deploy Secondary Domain Controller in Azure

### Step 1.1: Provision Windows Server VM in Azure

1. Go to Azure Portal → **Virtual Machines** → **Create**
2. Configure:
   - **Name**: dc-secondary-azure
   - **OS**: Windows Server 2022
   - **Size**: Standard_B2s (2 vCPU, 4 GB RAM)
   - **Resource Group**: rg-hybrid-infrastructure
   - **Region**: Same as VNet (East US)
   - **Availability Zone**: Zone 2 (different from primary domain controller's zone if applicable)

3. Configure networking:
   - **Virtual network**: vnet-hybrid
   - **Subnet**: subnet-management
   - **Public IP**: None (accessible via VPN only)
   - **NSG**: Assign nsg-management (allows RDP from on-prem)

4. Create VM

### Step 1.2: Join Secondary Server to Domain

1. RDP to secondary DC via VPN
2. Run PowerShell as Administrator:

```powershell
# Configure DNS to point to primary DC
$primaryDC_IP = "192.168.1.10"  # On-prem primary DC
Set-DnsClientServerAddress -InterfaceAlias Ethernet `
                           -ServerAddresses $primaryDC_IP

# Verify DNS resolves domain
nslookup contoso.local
# Should resolve successfully

# Join to domain
Add-Computer -DomainName "contoso.local" `
             -Credential (Get-Credential) `
             -Restart
```

3. After restart, verify domain join:
```powershell
Get-Computer | Select-Object Name, Domain
# Should show: Domain = CONTOSO
```

---

## Task 2: Promote to Domain Controller

1. On secondary server, install AD DS role:
```powershell
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
```

2. Promote to domain controller (replica):
```powershell
Import-Module ADDSDeployment

Install-ADDSDomainController -DomainName "contoso.local" `
                             -Credential (Get-Credential) `
                             -SafeModeAdministratorPassword (ConvertTo-SecureString "SafeModePassword123!@#" -AsPlainText -Force) `
                             -Force:$true `
                             -NoRebootOnCompletion:$false
```

3. Server restarts and becomes replica domain controller

---

## Task 3: Configure AD Replication

After promotion, AD automatically replicates between primary and secondary DC:

### Step 3.1: Verify Replication Status

```powershell
# Check replication partners
repadmin /partners

# Expected output: Both DC-Primary and DC-Secondary-Azure listed

# Test replication
repadmin /replsum
# Should show successful replication with last sync time
```

### Step 3.2: Monitor Replication Latency

```powershell
# Create test user on primary DC
New-ADUser -Name "Replication Test" `
           -GivenName "Replication" `
           -Surname "Test" `
           -SamAccountName "repl-test" `
           -Path "cn=Users,dc=contoso,dc=local"

# Wait 2-3 minutes
# Query on secondary DC
Get-ADUser -Identity "repl-test"
# Should appear after replication completes
```

---

## Task 4: Distribute FSMO Roles

FSMO (Flexible Single Master Operations) roles must be present on both DCs for redundancy:

### Current FSMO Distribution (Desired State)

```
Primary DC (On-Premises):
- PDC Emulator
- RID Master
- Infrastructure Master

Secondary DC (Azure):
- Schema Master
- Domain Naming Master
```

### Transfer FSMO Roles

```powershell
# Configure RID Master on primary (keep there)
# Transfer Infrastructure Master to secondary

$secondaryDC = "DC-Secondary-Azure"

# Move Infrastructure Master role
Move-ADDirectoryServerOperationMasterRole -Identity $secondaryDC `
                                          -OperationMasterRole InfrastructureMaster

# Verify role transfer
Get-ADForest | Select-Object *Master
Get-ADDomain | Select-Object InfrastructureMaster
```

---

## Task 5: Test Failover Scenario

### Failover Test: Primary DC Unavailable

1. Simulate primary DC failure (in test environment):
   - Shutdown primary DC VM
   - Clients still authenticate via secondary DC

2. Test client authentication:
```powershell
# On domain-joined client
gpupdate /force  # Force group policy update (hits secondary DC)
klist purge      # Clear Kerberos cache
net use * \\dc-secondary-azure\share  # Map to secondary DC share

# Should authenticate successfully via secondary DC
```

3. Monitor Azure secondary DC:
   - CPU at 15-20% (some spike from handling auth load)
   - Network traffic increased
   - No authentication failures

4. Restore primary DC:
   - Power on primary DC
   - Wait for replication to catch up
   - Verify domain controllers synced

---

## Task 6: Backup and Recovery

### Step 6.1: Back Up AD Database

```powershell
# Create system state backup (includes AD database)
wbadmin start systemstatebackup -backupTarget:E: -quiet

# Verify backup
wbadmin get versions

# Expected: Backup completed successfully
```

### Step 6.2: Recovery Procedure

If secondary DC completely fails:

```powershell
# From primary DC, remove failed DC from AD
Remove-ADComputer -Identity "DC-Secondary-Azure" -Confirm:$false

# Provision new Azure VM
# Promote to DC
# AD replication automatically catches up
```

---

## Validation Checklist

- [ ] Secondary DC deployed in Azure
- [ ] Joined to contoso.local domain
- [ ] Promoted to domain controller (replica)
- [ ] AD replication working (repadmin shows all partners)
- [ ] FSMO roles distributed appropriately
- [ ] Failover tested (primary down, secondary handles auth)
- [ ] Replication latency acceptable (<5 seconds)
- [ ] Backup procedure tested
- [ ] Documentation updated with failover procedures

---

*Phase 6 Completion Date: ___________*
*Document Version: 1.0*
