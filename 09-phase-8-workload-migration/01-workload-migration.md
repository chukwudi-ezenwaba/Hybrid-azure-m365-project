# Phase 8: Legacy Workload Migration to Azure

## Phase Overview

This phase demonstrates migration of legacy on-premises applications (HR application) to Azure infrastructure using lift-and-shift methodology, preserving existing configurations while gaining cloud benefits.

**Duration**: 2 weeks  
**Key Objectives**: Application VM migration, DNS validation, network testing, performance baselining

---

## Task 1: Pre-Migration Assessment

### Step 1.1: Document Current Application

1. On-premises HR application server details:
   - **Server Name**: HR-APP-01
   - **OS**: Windows Server 2019
   - **Application**: Custom IIS-hosted HR management system
   - **Database**: SQL Server 2017 local instance
   - **Storage**: 100 GB application + database
   - **Users**: 50-100 concurrent
   - **Performance baseline**: Document CPU, memory, network usage

### Step 1.2: Network Assessment

```powershell
# Baseline current performance (on-premises server)
Get-Counter -Counter "\Processor(_Total)\% Processor Time" -SampleInterval 5 -MaxSamples 20
Get-Counter -Counter "\Memory\Available MBytes" -SampleInterval 5 -MaxSamples 20
Get-Counter -Counter "\Network Interface(*)\Bytes Received/sec" -SampleInterval 5 -MaxSamples 20

# Export to CSV for comparison post-migration
```

---

## Task 2: Prepare Target Azure Infrastructure

### Step 2.1: Configure Application Subnet

In Azure vnet-hybrid, verify subnet-application:
```powershell
# Verify subnet exists and has capacity
Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name "subnet-application"

# Should have plenty of available IPs in 10.0.2.0/24 range
```

### Step 2.2: Create Azure VM for Migrated Application

```powershell
# Create VM specifications matching on-prem (or better)
$vmName = "hr-app-azure"
$vmSize = "Standard_D4s_v3"  # 4 vCPU, 16 GB RAM (improved from original)
$image = "WindowsServer2019"  # Match current OS

# Create VM
$vm = New-AzVMConfig -VMName $vmName -VMSize $vmSize
$vm = Set-AzVMOperatingSystem -VM $vm -Windows -ComputerName $vmName `
                              -Credential (Get-Credential)
$vm = Set-AzVMSourceImage -VM $vm -PublisherName "MicrosoftWindowsServer" `
                          -Offer "WindowsServer" -Skus "2019-Datacenter" -Version "latest"
$vm = Add-AzVMNetworkInterface -VM $vm -Id $nic.Id

New-AzVM -ResourceGroupName $resourceGroupName -VM $vm
```

---

## Task 3: Migrate Application Data

### Step 3.1: Create Backup of On-Premises Server

```powershell
# Use Windows Server Backup to create image
wbadmin start backup -backupTarget:E: -include:C:,D: -allCritical -quiet

# Or use third-party imaging tool (Acronis, Veeam, etc.)
```

### Step 3.2: Copy Application Files to Azure

Option 1: **VPN + File Share**
```powershell
# From on-premises, copy via file share over VPN
Copy-Item -Path "E:\HR-APP" `
          -Destination "\\hr-app-azure\c$\HR-APP" `
          -Recurse -Force `
          -Credential (Get-Credential AZURE\azureuser)

# Verify files copied
Get-ChildItem -Path "\\hr-app-azure\c$\HR-APP" -Recurse
```

Option 2: **Azure Storage Account blob upload**
```powershell
# Upload to Azure Storage (for very large transfers)
$storageAccount = Get-AzStorageAccount -ResourceGroupName $resourceGroupName -Name "stgmigration"

# Create container
New-AzStorageContainer -Name "hr-app-backup" -Context $storageAccount.Context

# Upload VHD or backup files
Set-AzStorageBlobContent -File "C:\Backups\hr-app-image.vhd" `
                         -Container "hr-app-backup" `
                         -Blob "hr-app-image.vhd" `
                         -Context $storageAccount.Context
```

### Step 3.3: Restore Application and Database

```powershell
# RDP to Azure VM
# Install IIS and SQL Server
# Restore database from backup
# Restore application files

# Test application locally (localhost)
Start-Process "http://localhost:8080"
```

---

## Task 4: Update DNS and Network Configuration

### Step 4.1: Update DNS Record

```powershell
# On-premises HR app was: hr-app.contoso.local -> 192.168.1.50
# Update to Azure VM private IP: 10.0.2.100

# In on-premises DNS (on primary DC)
$dnsServer = "192.168.1.10"
Remove-DnsServerResourceRecord -ComputerName $dnsServer `
                               -ZoneName "contoso.local" `
                               -Name "hr-app" -RecordType "A" -Force

Add-DnsServerResourceRecordA -ComputerName $dnsServer `
                             -ZoneName "contoso.local" `
                             -Name "hr-app" `
                             -IPv4Address "10.0.2.100"

# Verify DNS resolves to Azure
nslookup hr-app.contoso.local
# Should return: 10.0.2.100
```

### Step 4.2: Configure Application for New Location

```powershell
# In application config files, update:
# - Database connection: new IP or compute name
# - File paths: if changed
# - Service endpoints: if changed

# Restart application services
Restart-Service -Name "W3SVC"  # IIS
Restart-Service -Name "MSSQL*"  # SQL Server
```

---

## Task 5: Test and Validate Migration

### Step 5.1: Connectivity Test

```powershell
# From on-premises client, access migrated application
$appUrl = "http://hr-app.contoso.local:8080"
Invoke-WebRequest -Uri $appUrl

# Expected: HTTP 200, application responsive
```

### Step 5.2: Application Functionality Test

User acceptance testing (UAT):
- [ ] Application loads without errors
- [ ] Can login with test credentials  
- [ ] Can create/edit/delete records
- [ ] Reports generate correctly
- [ ] File uploads work
- [ ] Database queries responsive

### Step 5.3: Performance Comparison

```powershell
# During peak usage, compare metrics:
# Metric | On-Premises | Azure
# CPU    | 40%        | 25%  (improved)
# Memory | 70%        | 50%  (improved)
# Network| 100 Mbps   | 50 Mbps (reduced bandwidth = cost savings)

# Conclusion: Azure VM performing better with increased resources
```

---

## Task 6: Decommission On-Premises Server

After successful migration and UAT sign-off:

1. **Backup**: Final full backup of old server
2. **Disconnect**: Remove from network
3. **Decommission**: Mark for removal after 30-day retention
4. **Document**: Update asset inventory
5. **Reclaim**: Return hardware or repurpose

---

## Validation Checklist

- [ ] Azure VM deployed and configured
- [ ] Application files migrated
- [ ] Database restored and validated
- [ ] DNS records updated (resolves to Azure)
- [ ] VPN connectivity confirmed
- [ ] Application accessible from on-premises
- [ ] UAT passed (100% test cases passing)
- [ ] Performance baseline established
- [ ] Backup procedures tested
- [ ] on-premises server decommissioned or repurposed

---

*Phase 8 Completion Date: ___________*
*Document Version: 1.0*
