# Phase 6: High Availability & Redundancy

**Duration**: Weeks 11-12 | **Key Result**: Secondary DC deployed, AAD Connect HA configured, failover tested

## Phase Overview

| Item | Details |
|------|---------|
| What | Deploy secondary domain controller, configure AD replication, setup AAD Connect staging mode, test failover |
| Duration | 2 weeks |
| Depends | Phase 5 (hybrid identity - AAD Connect installed) |
| Success | 2 DCs replicating, 0 sync errors, <1 hour failover recovery time |

---

## Week 11: Deploy Secondary Domain Controller in Azure

### Step 1: Provision Secondary DC VM in Azure

**Via Azure Portal (GUI):**

1. Sign in to https://portal.azure.com
2. Go to **Virtual Machines** → Click **+ Create** → **Azure virtual machine**
3. **Project details:**
   - **Subscription**: Your subscription
   - **Resource Group**: Same RG as primary DC (e.g., "Infrastructure-RG")
   - **Region**: Same region as primary (e.g., "East US")

4. **Instance details:**
   - **Virtual machine name**: DC2-Prod-Azure
   - **Image**: Windows Server 2022 Datacenter
   - **Size**: Standard_D2s_v3 (2 vCPUs, 8GB RAM - same as primary)
   - **Admin account**:
     - **Username**: AzureAdmin
     - **Password**: [Complex password, 16+ chars]

5. **Networking:**
   - **Virtual network**: Same vnet as primary DC (e.g., "Prod-VNET")
   - **Subnet**: Infrastructure subnet (e.g., 10.0.1.0/24)
   - **Public IP**: None (private only, like primary)
   - **NIC network security group**: Existing → Select infrastructure-NSG

6. **Management:**
   - **Application & OS disk encryption**: Enabled
   - **Auto-shutdown**: ON (11:00 PM)

7. Click **Review + create** → **Create**

**Wait for deployment:** 3-5 minutes

---

### Step 2: Configure Static IP for Secondary DC

**Via Azure Portal:**

1. Go to the new DC2 VM
2. Click **Networking** → **Network settings**
3. Click the network interface (e.g., "dc2-prod-azure777")
4. Click **IP configurations** (left sidebar)
5. Click **ipconfig1**
6. Change **Private IP assignment**:
   - From: Dynamic
   - To: Static
   - **IP address**: 10.0.1.5 (reserve .5 for secondary DC)
7. Click **Save**

---

### Step 3: Install Active Directory Domain Services on Secondary DC

**RDP into secondary DC (DC2) and execute:**

1. Open **Server Manager**
2. Click **Add Roles and Features**
3. Go to **Server Roles**
4. Check: **Active Directory Domain Services**
5. Click **Add Features** (when prompted)
6. Complete wizard → **Install**
7. Wait 2-3 minutes for installation

---

### Step 4: Promote Secondary VM to Domain Controller

**RDP into DC2 and execute:**

1. Open **Server Manager**
2. Click flag icon (top right) → **Promote this server to a domain controller**
3. **Deployment Configuration:**
   - Select: **Add a domain controller to an existing domain**
   - **Domain**: organization.local (or your domain)
   - Click **Select**
   - Enter credentials: Domain\Administrator + password

4. **Domain Controller Options:**
   - **Forest Functional Level**: 2016 or higher
   - **Replica or New Domain**: Replica DC
   - **Site Name**: AzureSite (create new or select existing)
   - **Directory Services Restore Mode (DSRM) Password**: [Complex password]

5. **DNS Options:**
   - Check: "DNS server" (needed for replication)
   - Check: "Global catalog"

6. **Replication Source:**
   - **From**: [Primary DC - DC1.organization.local]
   - Click **Change** to select

7. Review settings → Click **Install**
8. System **reboots automatically** (5-10 minutes)

**Verify promotion:**
- After reboot, check: `Get-ADDomain` in PowerShell
- Should show replication working

---

### Step 5: Test AD Replication Between DCs

**On Primary DC (DC1), open PowerShell as Admin:**

```powershell
# Force replication to secondary
repadmin /replicate DC2.organization.local DC1.organization.local CN=Configuration,DC=organization,DC=local

# Verify replication status
repadmin /showrepl

# Check for replication errors
repadmin /showrepl | Select-String "Error\|failed"
```

**Expected output:**
```
DC1 → DC2: success
Replication: OK (0 errors)
```

**On Secondary DC (DC2), verify sync:**

```powershell
# Verify DC2 can see DC1
nslookup DC1.organization.local

# Test replication inbound
dcdiag /a /e /v

# Should see: "Summary of test execution"  with "passed for Enterprise Tests"
```

---

### Step 6: Configure Firewall Rules Between DCs

**Azure NSG (Network Security Group):**

1. Go to portal.azure.com → **Network Security Groups**
2. Select infrastructure-NSG
3. Go to **Inbound Security Rules** → **+ Add**

**Add rules for AD replication:**

| Priority | Name | Port | Protocol | Source |
|----------|------|------|----------|--------|
| 100 | AD-RPC-Replication | 135 | TCP | 10.0.1.0/24 |
| 110 | AD-Replication | 49152-65535 | TCP | 10.0.1.0/24 |
| 120 | LDAP | 389 | TCP | 10.0.1.0/24 |
| 130 | GC-LDAP | 3268 | TCP | 10.0.1.0/24 |
| 140 | Kerberos | 88 | TCP/UDP | 10.0.1.0/24 |

Each rule:
1. Click **Add**
2. Set **Destination port ranges**: [Port above]
3. Set **Protocol**: TCP (or TCP/UDP for Kerberos)
4. Set **Source**: IP addresses → 10.0.1.0/24
5. Click **Add**

---

## Week 12: Configure AAD Connect High Availability (Staging Mode)

### Step 7: Prepare Staging AAD Connect Server

**Create new Azure VM for AAD Connect Staging:**

1. Azure Portal → **Virtual Machines** → **+ Create**
2. **Name**: AADConnect-Staging
3. **Image**: Windows Server 2022
4. **Size**: Standard_D2s_v3 (2 vCPUs, 8GB)
5. **Network**: Same as DCs (Prod-VNET, Infrastructure subnet)
6. **IP**: 10.0.1.6 (static, reserve for staging)
7. Create → Wait for provisioning

---

### Step 8: Install AAD Connect on Staging Server

**On AADConnect-Staging VM:**

1. Download Azure AD Connect: https://www.microsoft.com/en-us/download/details.aspx?id=47594
2. Save to: C:\Downloads\AzureADConnect.msi
3. **Double-click** to start installation
4. Accept license → **Continue**
5. Configure:
   - **Express Settings** tab
   - Click **Express Settings** button (Azure AD password hash sync, most common)
   - Select **Do not configure Exchange hybrid**

6. **Azure AD Sign In:**
   - Enter Global Admin credentials (admin@organization.onmicrosoft.com)

7. **On-Premises AD Sign In:**
   - Enter Domain\Administrator + password
   - Select all organizational units (OUs) to sync
   - Uncheck OUs you DON'T want synced

8. **Configure Sign-In:**
   - Select: **Password hash synchronization** (not federation for now)
   - Continue

9. Complete wizard → Click **Install**
10. Wait 5-10 minutes

---

### Step 9: Enable Staging Mode on Secondary AAD Connect

**After installation, configure staging mode (disabled sync):**

1. On AADConnect-Staging, open **Azure AD Connect** application
2. Click **Configure**
3. Select **Configure staging mode**
4. Enter Azure AD Global Admin credentials
5. Review configuration
6. Click **Enable staging mode**
7. Sync configuration is **now disabled** (won't sync to Azure AD yet)

**Verify staging mode is ON:**

```powershell
# On staging server, run:
Get-ADSyncScheduler | Select StagingModeEnabled
# Should output: True
```

---

### Step 10: Configure Primary AAD Connect for Export Only (Failover Prep)

**On Primary AAD Connect Server:**

This ensures primary continues exporting before switching:

1. Open **Azure AD Connect** application
2. Click **View or change current configuration**
3. Select **Export to Azure AD**
4. Verify settings are correct (all OUs selected)
5. Don't enable staging on primary
6. Click **Finish**

---

### Step 11: Document Failover Procedure

**Create runbook for failover (save in shared location):**

**AAD Connect Failover Procedure:**

```
EMERGENCY FAILOVER (when primary AAD Connect server fails):

Step 1: On staging server (AADConnect-Staging)
  - Open Azure AD Connect
  - Go to Configure → Disable staging mode
  - Enter Global Admin credentials
  - This converts staging into ACTIVE server
  
Step 2: Verify replication
  - Wait 2 minutes for provisioning
  - Check: Get-ADUser -Server AADConnect-Staging
  - Run: Start-ADSyncSyncCycle -PolicyType Delta
  
Step 3: Monitor sync
  - Check sync errors: https://admin.azure.com → Problems & fixes
  - Verify 0 sync errors
  - Check user attribute mappings still working
  
Step 4: Notify teams
  - "AAD Connect now running on staging server"
  - "All sync working normally"
  
Step 5: Repair primary server (offline maintenance)
  - Can now take primary offline for repair
  - Install Windows updates
  - Rebuild if needed
  
Step 6: Restore to staging/cold standby
  - After primary repaired, keep staging as active
  - Re-enable staging mode on another server for redundancy
```

---

## Manual Testing: Week 12

### Step 12: Test Failover Procedure (SIMULATED)

**Test without actual switchover:**

1. **On Primary AAD Connect server:**
   ```powershell
   # Simulate failure by stopping sync service
   Stop-Service ADSync
   
   # Wait 5 minutes
   # Verify no sync attempts
   Get-EventLog Application | Where-Object {$_.Source -eq "ADSync"}
   ```

2. **On Staging server:**
   ```powershell
   # Disable staging mode
   Get-ADSyncScheduler | Set-ADSyncScheduler -StagingModeEnabled $false
   
   # Restart sync cycle
   Start-ADSyncSyncCycle -PolicyType Delta
   ```

3. **Verify replication to Azure AD:**
   ```powershell
   Connect-MsolService
   
   # Check last sync time
   Get-MsolDirSyncFeatures
   
   # Should show: Last sync time = current time
   ```

4. **Restore Primary (simulated recovery):**
   ```powershell
   # On primary, restart service
   Start-Service ADSync
   
   # Re-enable into staging again
   Get-ADSyncScheduler | Set-ADSyncScheduler -StagingModeEnabled $true
   ```

---

### Step 13: Monitor Replication Health

**Monthly health check (automated):**

**PowerShell script (save as health-check.ps1):**

```powershell
# AD Replication Health Check Script

$dc1 = "DC1.organization.local"
$dc2 = "DC2.organization.local"

Write-Host "=== AD Replication Health Check ===" -ForegroundColor Green

# Check replication status
Write-Host "`nReplication Status:"
repadmin /showrepl | Select-String "DC1|DC2"

# Check for errors
$errors = repadmin /showrepl | Select-String "failed|error"
if ($errors) {
    Write-Host "⚠ WARNING - Replication errors found:" -ForegroundColor Yellow
    Write-Host $errors
} else {
    Write-Host "✓ No replication errors" -ForegroundColor Green
}

# Check AAD Connect sync status
Write-Host "`nAAD Connect Sync Status:"
Get-ADSyncConnectorRunStatus

# Check last sync time
$lastSync = (Get-Content "C:\ProgramData\AADConnect\SyncStatus.txt" -ErrorAction SilentlyContinue)
Write-Host "Last sync: $lastSync"

# Check password hash sync
Write-Host "`nPassword Hash Sync Status:"
Get-ADSyncSchedulerConfiguration
```

**Run monthly:**

```powershell
.\health-check.ps1
```

---

## PowerShell Automation: Deploy Complete HA Stack

### Option A: Deploy Secondary DC Automatically

```powershell
# Create secondary DC in Azure (via PowerShell)

$resourceGroup = "Infrastructure-RG"
$location = "East US"
$vnetName = "Prod-VNET"

# Create VM
$vmConfig = New-AzVMConfig -VMName "DC2-Prod-Azure" -VMSize "Standard_D2s_v3"
$vmConfig = Add-AzVMNetworkInterface -VM $vmConfig `
  -Id (Get-AzNetworkInterface -Name "dc2-nic" -ResourceGroupName $resourceGroup).Id

$vmConfig = Set-AzVMSourceImage -VM $vmConfig `
  -PublisherName "MicrosoftWindowsServer" `
  -Offer "WindowsServer" `
  -Skus "2022-Datacenter" `
  -Version "Latest"

# Enable disk encryption
$vmConfig = Set-AzVMOSDisk -VM $vmConfig `
  -Caching ReadWrite `
  -CreateOption FromImage `
  -ManagedDiskId (New-AzDisk -ResourceGroupName $resourceGroup `
    -DiskName "dc2-osdisk" `
    -DiskSizeGB 128 `
    -Sku "Premium_LRS").Id

New-AzVM -ResourceGroupName $resourceGroup -VM $vmConfig
Write-Host "✓ Secondary DC VM created"
```

### Option B: Automate AD Replication Setup

```powershell
# Configure AD replication between DCs

$primaryDC = "DC1.organization.local"
$secondaryDC = "DC2.organization.local"
$domain = "organization.local"

# Force replication
Write-Host "Starting AD replication..." -ForegroundColor Yellow
repadmin /replicate $secondaryDC $primaryDC "CN=Config,DC=$domain,DC=local"
repadmin /replicate $secondaryDC $primaryDC "CN=Schema,CN=Config,DC=$domain,DC=local"

# Wait for replication
Start-Sleep -Seconds 30

# Verify
$repStatus = repadmin /showrepl
if ($repStatus -match "success") {
    Write-Host "✓ Replication successful" -ForegroundColor Green
} else {
    Write-Host "⚠ Replication issues detected" -ForegroundColor Yellow
}
```

### Option C: Automate AAD Connect Staging Configuration

```powershell
# Configure AAD Connect HA (staging mode)

$stagingServer = "AADConnect-Staging"
$globalAdminAccount = "admin@organization.onmicrosoft.com"

# Connect to staging server
$session = New-PSSession -ComputerName $stagingServer -Credential (Get-Credential)

Invoke-Command -Session $session -ScriptBlock {
    # Enable staging mode
    Set-ADSyncScheduler -StagingModeEnabled $true
    
    # Verify
    Get-ADSyncScheduler | Select StagingModeEnabled
}

Write-Host "✓ AAD Connect staging mode enabled on $stagingServer" -ForegroundColor Green
```

---

## Configuration Summary

| Component | Configuration | Status |
|-----------|---------------|--------|
| **Primary DC** (DC1) | Windows Server 2022 on-prem | Active |
| **Secondary DC** (DC2) | Windows Server 2022 in Azure | Replicating |
| **Replication** | Multi-master AD replication | 2-way sync |
| **AAD Connect Primary** | Active sync server | Exporting to Azure AD |
| **AAD Connect Staging** | Stand-by server (sync disabled) | Ready for failover |
| **Failover RTO** | Recovery Time Objective | <1 hour |
| **Failover RPO** | Recovery Point Objective | <15 minutes |
| **Monitoring** | Hourly alerts on replication errors | Enabled |

---

## Success Checklist

**Week 11 Completion:**
- [ ] Secondary DC VM provisioned in Azure (DC2-Prod-Azure)
- [ ] DC2 promoted to domain controller
- [ ] AD replication operational (0 errors)
- [ ] Test: `dcdiag /a /e` shows all passed
- [ ] Firewall rules for AD replication configured
- [ ] DNS shows both DCs responsive

**Week 12 Completion:**
- [ ] AAD Connect staging server deployed
- [ ] AAD Connect installed on staging server
- [ ] Staging mode ENABLED (sync disabled)
- [ ] Primary AAD Connect verified exporting to Azure AD
- [ ] Failover procedure tested (simulated)
- [ ] Health check script created and tested
- [ ] Documentation updated with failover runbook

**Post-Deployment (Ongoing):**
- [ ] Monthly health check run (script automated)
- [ ] 0 AD replication errors
- [ ] Every sync cycle succeeds
- [ ] Password changes replicate in <5 minutes
- [ ] Azure AD sync shows 0 queued objects
- [ ] No failed NDR (Non-Delivery Report) for sync service

---

## Monitoring & Alerts

**Setup email alerts for replication failures:**

1. Azure Portal → **Event Grid** → **Create Event Rule**
2. Event source: "Azure Diagnostic Logs"
3. Event type: "AD Replication Error"
4. Action: Send email to IT team
5. Email: [your-it-team@organization.com](mailto:your-it-team@organization.com)

**Alternative - PowerShell scheduled task for hourly checks:**

```powershell
# Save as C:\Scripts\ad-replication-monitor.ps1

$errors = repadmin /showrepl | Select-String "failed|error"
$lastSync = Get-ADReplicationPartnerMetadata -Partition "CN=Configuration,DC=organization,DC=local"

if ($errors -or ($lastSync.LastReplicationSuccess -lt (Get-Date).AddMinutes(-15))) {
    Send-MailMessage -From "monitor@organization.com" `
                     -To "it-team@organization.com" `
                     -Subject "AD Replication Alert" `
                     -Body "Replication error detected: $errors"
}

# Schedule as Windows Task: Runs every hour
```

---

## Troubleshooting

### Issue: "The replication operation failed"
```
Cause: DC2 cannot reach DC1 on required ports
Solution:
  1. Verify firewall rules (ports 135, 389, 3268, 88)
  2. Check DNS resolves both DCs: nslookup DC1, nslookup DC2
  3. Restart NetLogon: Restart-Service Netlogon
  4. Force replication: repadmin /replicate DC2 DC1 CN=Config,DC=...
```

### Issue: "Staging mode still enabled" after disabling
```
Cause: AAD Connect service needs restart
Solution:
  1. PS: Set-ADSyncScheduler -StagingModeEnabled $false
  2. Restart-Service ADSync
  3. Verify: Get-ADSyncScheduler | Select StagingModeEnabled
```

### Issue: "Failover took >1 hour"
```
Cause: Slow DNS resolution or network latency
Solution:
  1. Pre-stage DNS records for staging server
  2. Test: nslookup AADConnect-Prod (should resolve immediately)
  3. Verify network latency: ping DC2 should be <20ms
  4. Check sync queue: Get-ADSyncScheduler | Select NextSyncCycle
```

---

## Performance Metrics

**After 1 week:**
- [ ] AD replication latency <5 minutes
- [ ] 0 replication errors
- [ ] All users synced to both DCs

**After 1 month:**
- [ ] Replication uptime >99.5%
- [ ] Average sync cycle time <10 minutes
- [ ] Password changes replicate <5 minutes

---

## Next Phase

→ **Phase 7: Azure Infrastructure & Networking** (Complete VPN, NSGs, DNS, firewalls)

---

**Document Version**: 2.0  
**Last Updated**: March 4, 2026  
**Notes**: Comprehensive HA setup with dual AD replication, AAD Connect staging mode, and tested failover procedures. Supports 99.5%+ availability.
