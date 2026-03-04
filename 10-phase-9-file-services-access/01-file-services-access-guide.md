# Phase 9: File Services and Access Control

## Phase Overview

This phase establishes departmental file shares with proper NTFS and SMB permissions, enforcing role-based access control and least privilege principles across the hybrid infrastructure.

**Duration**: 2 weeks  
**Key Objectives**: File share creation, permission configuration, cross-department access policies, remote access validation

---

## Task 1: Create Departmental File Shares

### Step 1.1: Create File Server VM (On-Premises)

On-premises file server (primary):

```powershell
# On Proxmox/Hyper-V hypervisor, create Windows Server 2022 VM
# Name: FS-Primary
# Storage: 500 GB+ for shared folders
# Network: Same VLAN as servers (isolated from user VLAN)
# IP: Static 192.168.1.30
```

### Step 1.2: Create Shares on Primary File Server

**Share 1: IT Department Share**

```powershell
# Create shared folder
New-Item -Path "D:\Shares\IT" -ItemType Directory

# Create SMB share
New-SMBShare -Name "IT" `
            -Path "D:\Shares\IT" `
            -ChangeAccess "CONTOSO\IT Department" `
            -FullAccess "CONTOSO\Domain Admins"

# Verify share
Get-SMBShare -Name "IT"
```

**Share 2: HR Department Share (Sensitive)**

```powershell
# Create folder
New-Item -Path "D:\Shares\HR" -ItemType Directory

# Create share - HR only, restricted domain-wide
New-SMBShare -Name "HR" `
            -Path "D:\Shares\HR" `
            -ChangeAccess "CONTOSO\HR Department" `
            -FullAccess "CONTOSO\Domain Admins"

# Note: HR share permissions more restrictive than others
```

**Share 3: Finance Department Share**

```powershell
New-Item -Path "D:\Shares\Finance" -ItemType Directory

New-SMBShare -Name "Finance" `
            -Path "D:\Shares\Finance" `
            -ChangeAccess "CONTOSO\Finance Department" `
            -FullAccess "CONTOSO\Domain Admins" `
            -ReadAccess "CONTOSO\Operations Department"  # Operations reads finance reports
```

**Share 4: Operations Department Share**

```powershell
New-Item -Path "D:\Shares\Operations" -ItemType Directory

New-SMBShare -Name "Operations" `
            -Path "D:\Shares\Operations" `
            -ChangeAccess "CONTOSO\Operations Department" `
            -FullAccess "CONTOSO\Domain Admins"
```

---

## Task 2: Configure NTFS Permissions

NTFS permissions control file-level access (more granular than share permissions):

### Step 2.1: Configure IT Share Permissions

```powershell
# Remove default permissions
$share = "D:\Shares\IT"
icacls $share /inheritance:r /grant:r "CONTOSO\IT Department:(M)" "CONTOSO\Domain Admins:(F)"

# Verify permissions
icacls $share

# Output should show:
# IT Department: Modify (M)
# Domain Admins: Full Control (F)
# Everyone: None (removed)
```

### Step 2.2: Configure HR Share Permissions (Most Restrictive)

```powershell
$share = "D:\Shares\HR"

# Create subdirectories for organization
New-Item -Path "$share\Personnel" -ItemType Directory
New-Item -Path "$share\Payroll" -ItemType Directory
New-Item -Path "$share\Benefits" -ItemType Directory

# Set folder-level permissions
icacls "$share\Personnel" /inheritance:r /grant:r "CONTOSO\HR Department:(M)"
icacls "$share\Payroll" /inheritance:r /grant:r "CONTOSO\HR Department:(M)" "CONTOSO\Finance Department:(R)"
icacls "$share\Benefits" /inheritance:r /grant:r "CONTOSO\HR Department:(M)"

# Prevent accidental outside access
icacls $share /inheritance:r /grant:r "CONTOSO\HR Department:(M)"

# Verify - HR full access, others blocked
icacls $share /T  # /T = Traverse subtree
```

### Step 3.3: Configure Finance Share with Cross-Department Access

```powershell
$share = "D:\Shares\Finance"

# Create finance-specific structure
New-Item -Path "$share\Reports" -ItemType Directory
New-Item -Path "$share\Budgets" -ItemType Directory
New-Item -Path "$share\Transactions" -ItemType Directory

# Set permissions
icacls "$share\Reports" /inheritance:r `
                       /grant:r "CONTOSO\Finance Department:(M)" `
                       /grant:r "CONTOSO\Operations Department:(R)" `
                       /grant:r "CONTOSO\Executive Management:(R)"

icacls "$share\Budgets" /inheritance:r /grant:r "CONTOSO\Finance Department:(M)"
icacls "$share\Transactions" /inheritance:r /grant:r "CONTOSO\Finance Department:(M)"
```

---

## Task 3: Deploy Secondary File Server (Azure)

### Step 3.1: Create Azure File Server VM

```powershell
# Create VM in Azure
$vmName = "fs-secondary-azure"
$vmSize = "Standard_D4s_v3"
$storageSize = 500  # GB

# Deploy VM (similar to Phase 8 workload migration)
# Should be domain-joined via VPN
# IP: 10.0.2.50 in Azure
```

### Step 3.2: Configure Replication (One Share)

Rather than maintaining 4 separate share replicas, replicate one critical share to Azure:

**Replicate: Finance Department Share**

```powershell
# Option 1: File Sync via Azure File Sync (recommended)
# Option 2: DFS Replication (legacy but reliable)
# Option 3: Manual sync via File Server Resource Manager

# Using DFS Replication (simplest):
# 1. Configure DFS namespace pointing to both servers
# 2. Set up replication schedule
# 3. Primary updates replicate to Azure within 15 minutes
```

---

## Task 4: Test Remote Access

### Step 4.1: Access Shares from Domain-Joined Client

```powershell
# From domain-joined workstation
# Map network drives

net use z: \\fs-primary\IT /persistent:yes
net use y: \\fs-primary\Finance /persistent:yes
net use x: \\fs-primary\HR /persistent:yes

# Verify access
dir z:\  # Should show IT share contents
dir y:\  # Should show Finance share contents
dir x:\  # Should show HR share contents (if user is HR)
```

### Step 4.2: Test Cross-Department Access

```powershell
# As Operations user, try accessing Finance reports
# Should succeed (read-only)
dir y:\Reports

# Try accessing HR share
# Should fail (access denied)
dir x:\  
# Output: "Access is denied"
```

### Step 4.3: Test from Non-Domain Device (Edge Case)

```powershell
# From non-domain machine via VPN
# Must provide explicit credentials
net use \\fs-primary /user:CONTOSO\username password

# Verify credentials required
# Then access limited to user's group
```

---

## Task 5: Implement Backup and Recovery

```powershell
# Backup file shares to Azure Backup
# Configure backup schedule (daily snapshots)
# Test recovery: Restore a file from backup

# Validation: Verify backed up files are recoverable
```

---

## Validation Checklist

- [ ] 4 departmental shares created on-premises FS
- [ ] NTFS permissions configured (least privilege)
- [ ] SMB share permissions set correctly
- [ ] IT staff can access IT share
- [ ] HR staff can access HR share only
- [ ] Finance staff can access Finance + read Operations
- [ ] Operations staff can access Operations + read Finance
- [ ] Secondary file server in Azure deployed
- [ ] Finance share replicated to Azure
- [ ] Remote access from VPN tested
- [ ] Cross-department permissions tested (positive and negative cases)
- [ ] Backup procedures verified

---

## Access Control Matrix

| User/Group | IT | HR | Finance | Operations |
|-----------|----|----|---------|-----------|
| IT Staff | RW | -- | -- | -- |
| HR Staff | -- | RW | -- | -- |
| Finance Staff | -- | -- | RW | R |
| Operations Staff | -- | -- | R | RW |
| Executives | R | R | R | R |
| Domain Admins | F | F | F | F |

Legend: RW = Read/Write, R = Read-only, F = Full Control, -- = No Access

---

*Phase 9 Completion Date: ___________*
*Document Version: 1.0*
