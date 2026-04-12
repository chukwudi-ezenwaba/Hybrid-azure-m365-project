# Phase 9: File Services and Access Control

**Depends on**: Phase 6 (FS-01 VM created on Hyper-V), Phase 5 (hybrid identity syncing)  
**Key Result**: Five departmental file shares running on FS-01, NTFS permissions scoped per AD security group, SMB encryption and signing enforced, file access audited

---

## Week 17: Create File Shares & Configure Permissions

### Step 1: Provision File Server VM

**Via Hyper-V Manager (On-Premises GUI):**

1. Open **Hyper-V Manager**
2. Right-click Host → **New** → **Virtual Machine**
3. **Name and Location:**
   - **Name**: FS-01
   - **Location**: Default
   - Click **Next**

4. **Specify Generation:**
   - Select: Generation 2
   - Click **Next**

5. **Assign Memory:**
   - **Startup memory**: 4096 MB (4 GB)
   - **Dynamic memory**: Enabled (min: 2GB, max: 8GB)
   - Click **Next**

6. **Configure Networking:**
   - Select: "Infrastructure" virtual switch (same as domain controller)
   - Click **Next**

7. **Connect Virtual Hard Disk:**
   - Select: **Create a new virtual hard disk**
   - **Name**: FS-01.vhdx
   - **Location**: Default
   - **Size**: 500 GB
   - Click **Next**

8. **Installation Options:**
   - Select: **Install an operating system from installation media**
   - Select: **Image file (.iso)**
   - Browse: Windows Server 2022 Datacenter ISO
   - Click **Next**

9. Review and click **Finish**

**Start and configure VM:**
- Right-click FS-01 → **Connect**
- Start the VM
- Complete Windows Server setup (admin password, timezone, etc.)
- Domain-join: 
  1. Right-click **This PC** → **Properties**
  2. Click **Rename this PC (advanced)**
  3. Click **Change**
   - Enter domain name: nig-e-mart.local
  5. Enter domain admin credentials
  6. Restart

---

### Step 2: Create Departmental File Shares (GUI Method)

**Via File and Storage Services:**

1. RDP into file server (FS-01)
2. Open **Server Manager** (automatically opens)
3. Click **File and Storage Services** (left sidebar)
4. Click **Shares** → **SHARES**
5. Click **Tasks** → **New Share**

**Create IT Department Share:**

1. New Share Wizard opens
2. **Share Type:**
   - Select: **SMB Share – Quick**
   - Click **Next**

3. **Share Location:**
   - Go to: **C:\ → New Folder → Name: Shares**
   - Go to: **Shares → New Folder → Name: IT**
   - Select the IT folder
   - Click **Next**

4. **Share Name:**
   - **Name**: IT
   - **Description**: IT Department file share
   - Click **Next**

5. **Other Settings:**
   - Check: **Enable access-based enumeration** (users only see files they can access)
   - Check: **Encrypt data access** (SMB encryption)
   - Click **Next**

6. **Permissions:**
   - Click **Customize permissions**
   - Click **Disable inheritance** → **Convert inherited permissions to explicit permissions on this object**
   - **Add permissions for**: IT Department group
   - Set:
     - Type: Allow
     - Principal: `nig-e-mart\SG-IT` (the AD security group for IT staff)
     - Permissions: **Modify**
   - Click **Apply** → **OK**

7. Click **Create**
8. Verify: Share appears in Shares list with a lock icon indicating encryption

**Create the remaining four shares** using the same wizard process. Use exactly these values for each:

| Share Name | Folder Path | Group (Modify access) |
|---|---|---|
| Finance | C:\Shares\Finance | nig-e-mart\SG-Finance |
| HR | C:\Shares\HR | nig-e-mart\SG-HR |
| Operations | C:\Shares\Operations | nig-e-mart\SG-Operations |
| General | C:\Shares\General | nig-e-mart\Domain Users |

For each share, follow the same wizard steps: SMB Share – Quick → create the subfolder → set the share name → enable access-based enumeration and encrypt data access → customise permissions to remove Authenticated Users and add the specific group with Modify.

**PowerShell shortcut** — create all five shares in one pass instead of using the GUI five times:

```powershell
# Run directly on FS-01
$shareMap = @{
  "IT"         = "nig-e-mart\SG-IT"
  "Finance"    = "nig-e-mart\SG-Finance"
  "HR"         = "nig-e-mart\SG-HR"
  "Operations" = "nig-e-mart\SG-Operations"
  "General"    = "nig-e-mart\Domain Users"
}

foreach ($name in $shareMap.Keys) {
  $path = "C:\Shares\$name"
  New-Item -ItemType Directory -Path $path -Force | Out-Null
  New-SmbShare -Name $name -Path $path `
    -FullAccess "nig-e-mart\Domain Admins" `
    -ChangeAccess $shareMap[$name] `
    -EncryptData $true -FolderEnumerationMode AccessBased
  Write-Host "Created: \\FS-01\$name"
}
```

---

### Step 3: Configure NTFS Permissions (Fine-Grained)

**Via File Explorer GUI:**

1. Open **File Explorer**
2. Navigate to **C:\Shares\IT**
3. Right-click → **Properties**
4. Click **Security** tab
5. Click **Edit** (modify permissions)

**Configure IT Share permissions:**

1. Click **Add** button
2. **Enter the object name to select:**
   - Type: `SG-IT`
   - Click **Check Names** — it should resolve to `nig-e-mart\SG-IT`
   - Click **OK**

3. **Permissions for "SG-IT":**
   - ✓ Read (checked)
   - ✓ Write (checked)
   - ✓ Modify (checked)
   - ✗ Full Control (unchecked - less privilege)
   - Click **Apply**

4. **Add Domain Admins for full control:**
   - Click **Add**
   - Type: `Domain Admins`
   - Click **Check Names** → **OK**
   - Set: Full Control ✓
   - Click **Apply**

5. **Remove default permissions:**
   - Select `CREATOR OWNER`, `Everyone`, or `Authenticated Users` if present
   - Click **Remove** for each
   - Click **Apply**

6. Click **OK** to close properties

**Verify permissions:**
- Test: Try to access from another PC as IT Department user
  - Should see "IT" share ✓
  - Should be able to create/modify files ✓

---

### Step 4: Enable SMB Signing & Encryption

**Via Group Policy (Domain Controller):**

1. RDP into domain controller
2. Open **Group Policy Management** (gpmc.msc)
3. Expand **Forest → Domains → nig-e-mart.local**
4. Right-click → **Create a GPO in this domain, and Link it here**
5. **Name**: SMB-Security-Policy
6. Click **OK**

7. Click GPO: **SMB-Security-Policy** → Right-click → **Edit**

8. Navigate to:
   ```
   Computer Configuration
   → Policies
   → Windows Settings
   → Security Settings
   → Local Policies
   → Security Options
   ```

9. Find and enable:
   - **Microsoft SMB server: Always sign**:
     - Set: Enabled
   - **Microsoft SMB server: Enable signing for SMB traffic**:
     - Set: Enabled
   - **Microsoft SMB server: Encrypt data for SMB traffic**:
     - Set: Required

10. Click **Apply** → **OK**
11. Close Group Policy Editor

**Force update on file server:**
```powershell
# RDP to file server and run:
gpupdate /force
Restart-Computer
```

---

### Step 5: Configure Share-Level Permissions

**Via Shares Properties in Server Manager:**

1. Server Manager → **File and Storage Services** → **Shares**
2. Right-click **IT** share → **Properties**

3. **Share permissions:**
   - Remove default Everyone access
   - Add: IT Department (Change - read/write)
   - Add: Domain Admins (Full Control)
   - Click **Apply** → **OK**

4. Repeat for Finance, HR, Operations shares
5. HR share (most restrictive):
   - Only HR Department: Change
   - Only Domain Admins: Full Control

---

### Step 6: Test File Access (User Perspective)

**From user workstation (NOT admin):**

1. Open **File Explorer**
2. In address bar, type: `\\FS-01\IT`
3. Press Enter
4. **If prompted for credentials:**
   - Username: `nig-e-mart\[username]`
   - Password: [domain password]
   - Check: Remember me
   - Click **OK**
5. Should see empty IT share (or existing files if any)
6. Try creating a test file:
   - Right-click → **New** → **Text Document**
   - Type name: "test.txt"
   - Right-click → **Edit**
   - Add text: "This is a test"
   - Save and close

**Verify:**
- ✓ Can create files
- ✓ Can modify files
- ✓ File shows your username as owner
- ✓ Can delete files

---

## Week 18: Advanced Configuration & Cross-Department Access

### Step 7: Configure HR Share (Most Restricted)

**HR Share special rules:**

1. Server Manager → **File and Storage Services** → **Shares**
2. Right-click **HR** share → **Properties**

3. **Share-level permissions:**
   - Remove `Everyone` and `Authenticated Users` if present
   - Add: `nig-e-mart\SG-HR` — Change
   - Add: `nig-e-mart\Domain Admins` — Full Control
   - Do NOT add SG-Operations, SG-Finance, or any other department group
   - Click **OK**

4. **NTFS permissions (via File Explorer):**
   - Navigate to: C:\Shares\HR
   - Right-click → **Properties** → **Security** → **Advanced**
   - Click **Disable inheritance** → **Convert inherited permissions to explicit permissions**
   - Remove all rows except `nig-e-mart\Domain Admins`
   - Add `nig-e-mart\SG-HR` with **Modify** (applying to This folder, subfolders and files)
   - Click **Apply** → **OK**

5. **Test restrictive access:**
   - From a Finance department PC, open File Explorer and type: `\\FS-01\HR`
   - Should get "Access Denied" — this is the expected and correct result

---

### Step 8: Configure Cross-Department Access (Finance → Operations)

**Scenario: Operations needs read-only access to Finance reports**

1. Server Manager → Shares → **Finance** → **Properties**

2. **Share permissions:**
   - Add: `nig-e-mart\SG-Operations`
   - Set: **Read** (read-only)
   - Click **Apply**

3. **NTFS permissions (C:\Shares\Finance):**
   - Right-click → **Properties** → **Security** → **Edit**
   - Click **Add**
   - Type: `SG-Operations`
   - Click **OK**
   - Set: Read ✓, List Folder Contents ✓
   - Other permissions ✗ (unchecked)
   - Click **Apply** → **OK**

4. **Test cross-department read access:**
   - From an Operations PC, type: `\\FS-01\Finance`
   - Should see Finance share ✓
   - Try to create a file (should fail) ✓
   - Try to read existing files (should work) ✓

---

### Step 9: Enable File Auditing for Compliance

**Track who accesses sensitive files (HR, Finance):**

1. On file server, open **Group Policy Management** (gpmc.msc) from DC
2. Edit the SMB-Security-Policy GPO
3. Navigate to:
   ```
   Computer Configuration
   → Policies
   → Windows Settings
   → Security Settings
   → Advanced Audit Policy Configuration
   → Audit Policies
   → Object Access
   ```

4. Enable:
   - **File Share**: Enabled
   - **Removable Storage**: Enabled
   - **File System**: Enabled

5. Click **Apply** → **OK**

6. **Force update:**
   ```powershell
   gpupdate /force
   ```

**Verify auditing is working:**
```powershell
# On file server:
# Check Event Viewer for audit events
Get-WinEvent -LogName Security | Where-Object {$_.ID -eq 5145} | Select-Object TimeCreated, Message | Head -10
```

---

### Step 10: Configure File-Level Backup

Azure Site Recovery (configured in Phase 6.2) handles VM-level disaster recovery for FS-01 — if the entire VM fails, ASR can restore it within the 15-minute RPO. However, ASR restores the whole VM snapshot, not individual files. A complementary file-level backup lets you recover a single accidentally deleted document without failing over the entire machine.

**Automated daily file-level backup via PowerShell scheduled task:**

1. On file server, open **Notepad**
2. Create scheduled backup script:

```powershell
# Save as: C:\Scripts\backup-shares.ps1

$sourcePath = "C:\Shares"
$backupPath = "E:\Backups"  # External drive or NAS
$retentionDays = 30
$timestamp = (Get-Date).ToString("yyyy-MM-dd_HHmmss")

# Create backup directory if not exists
if (!(Test-Path $backupPath)) {
    New-Item -Path $backupPath -ItemType Directory -Force
}

# Create backup
$backupFile = "$backupPath\FileShares_$timestamp.zip"
Write-Output "Starting backup to: $backupFile"

Compress-Archive -Path $sourcePath -DestinationPath $backupFile -Force -ErrorAction Stop

Write-Output "✓ Backup completed"

# Delete old backups (older than 30 days)
Get-ChildItem -Path $backupPath -Filter "*.zip" |
    Where-Object { $_.CreationTime -lt (Get-Date).AddDays(-$retentionDays) } |
    Remove-Item -Force

Write-Output "✓ Old backups cleaned up (>30 days)"
```

3. Save as: `C:\Scripts\backup-shares.ps1`

4. **Create Scheduled Task:**
   - Open **Task Scheduler**
   - Right-click **Task Scheduler Library** → **Create Task**
   - **Name**: Daily-FileShare-Backup
   - **Description**: Daily backup of all file shares
   - Check: **Run with highest privileges**

5. **Triggers tab:**
   - Click **New**
   - **Begin:**: Daily
   - **Time**: 2:00 AM (off-peak)
   - Click **OK**

6. **Actions tab:**
   - Click **New**
   - **Action**: Start a program
   - **Program**: powershell.exe
   - **Arguments**: `-NoProfile -ExecutionPolicy Bypass -File "C:\Scripts\backup-shares.ps1"`
   - Click **OK**

7. Click **OK** to create task

8. **Test backup:**
   - Right-click task → **Run**
   - Check: `E:\Backups\` should have new ZIP file
   - Size should be reasonable (not 0 bytes)

---

## PowerShell Automation: File Shares via Script

### Option A: Create All Shares Automatically

```powershell
# Create-FileShares.ps1
# Creates all departmental shares with permissions

$domains = @("IT", "Finance", "HR", "Operations", "General")
$fileServerName = "FS-01"
$sharePath = "C:\Shares"

foreach ($dept in $domains) {
    $deptPath = "$sharePath\$dept"
    
    # Create folder
    if (!(Test-Path $deptPath)) {
        New-Item -Path $deptPath -ItemType Directory -Force
        Write-Host "✓ Created folder: $deptPath"
    }
    
    # Create SMB share
    New-SMBShare -Name $dept `
                 -Path $deptPath `
                 -Description "$dept Department Share" `
                 -ChangeAccess "nig-e-mart\SG-$dept" `
                 -FullAccess "nig-e-mart\Domain Admins" `
                 -EncryptData $true
    
    Write-Host "✓ Created share: \\$fileServerName\$dept"
    
    # Set NTFS permissions
    $acl = Get-Acl $deptPath
    $acl.SetAccessRuleProtection($true, $false)  # Disable inheritance
    Set-Acl -Path $deptPath -AclObject $acl
    
    $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
        "nig-e-mart\SG-$dept",
        "Modify",
        "ContainerInherit,ObjectInherit",
        "None",
        "Allow"
    )
    $acl.AddAccessRule($rule)
    Set-Acl -Path $deptPath -AclObject $acl
    
    Write-Host "✓ Configured NTFS permissions for $dept"
}

Write-Host "✓✓ All file shares created and configured"
```

**Run:**
```powershell
.\Create-FileShares.ps1
```

### Option B: Configure Cross-Department Access

```powershell
# Configure-CrossDeptAccess.ps1
# Operations gets read-only access to Finance

$deptPath = "C:\Shares\Finance"

# Grant read-only to Operations
$acl = Get-Acl $deptPath
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
    "nig-e-mart\SG-Operations",
    "ReadAndExecute",  # Read-only
    "ContainerInherit,ObjectInherit",
    "None",
    "Allow"
)
$acl.AddAccessRule($rule)
Set-Acl -Path $deptPath -AclObject $acl

Write-Host "✓ Operations Department now has read-only access to Finance share"
```

---

## Configuration Summary

| Component | Configuration |
|-----------|---------------|
| **File Server** | FS-01 — Windows Server 2022 (4 GB RAM, 500 GB storage) |
| **Shares** | IT, Finance, HR, Operations, General |
| **SMB Encryption** | Required (enforced via GPO) |
| **SMB Signing** | Required (enforced via GPO) |
| **NTFS Permissions** | Role-based (Modify for dept members, Full Control for admins) |
| **HR Share Privacy** | Restricted (HR only + Admins) |
| **Cross-Dept Access** | Operations reads Finance (read-only) |
| **File Auditing** | Enabled for compliance tracking |
| **Backup** | Daily at 2 AM, 30-day retention |
| **Backup Schedule** | Automated via PowerShell scheduled task |

---

## Success Checklist

**Week 17:**
- [ ] File server VM provisioned (FS-01)
- [ ] File server domain-joined to nig-e-mart.local
- [ ] 5 shares created (IT, Finance, HR, Operations, General)
- [ ] NTFS permissions configured per department
- [ ] SMB encryption enabled
- [ ] SMB signing enforced via GPO
- [ ] Test: IT Department user can access IT share
- [ ] Test: Finance user CANNOT access HR share (access denied)

**Week 18:**
- [ ] Cross-department access configured (Operations → Finance read-only)
- [ ] File access auditing enabled
- [ ] Backup script created and tested
- [ ] Scheduled backup task created (2 AM daily)
- [ ] Backup verified (files exist in E:\Backups)
- [ ] Restore tested (can restore from backup)
- [ ] Users report successful share access
- [ ] 0 unauthorized access attempts logged

---

## Troubleshooting

### Issue: "Access Denied" when accessing share
```
Cause: NTFS or share permissions not configured
Solution:
  1. Verify user is member of correct department group
  2. Check NTFS permissions: icacls C:\Shares\IT
  3. Check share permissions: Get-SMBShare -Name "IT"
  4. Add user/group and set "Modify" permission
  5. Wait 15 mins for group policy update
  6. Test again from new command prompt (new session)
```

### Issue: SMB Encryption not working
```
Cause: GPO not applied or SMB version outdated
Solution:
  1. Verify GPO applied: gpupdate /force
  2. Verify from client: net use \\fileserver (should show "Encrypted")
  3. Update to Windows Server 2019+ (required for SMB 3.1.1)
  4. Restart file server for GPO to take effect
```

### Issue: Backup file too large (>200GB)
```
Cause: Too many files or backups accumulating
Solution:
  1. Reduce retention days: $retentionDays = 14 (2 weeks instead of 30)
  2. Compress more: Use 7-zip for better compression
  3. Use incremental backups instead of full
  4. Consider: NAS with higher capacity
```

### Issue: Backup scheduled task not running
```
Cause: Task scheduler disabled or permissions issue
Solution:
  1. Verify task exists: Get-ScheduledTask -TaskName "*backup*"
  2. Check Run With: Should be "SYSTEM" or "Administrator"
  3. Verify script path exists and is readable
  4. Check event log: Get-WinEvent -LogName "Windows PowerShell"
  5. Test manual run: Get-ScheduledTask -Name "Daily-FileShare-Backup" | Start-ScheduledTask
```

---

## Performance Metrics

**After 1 day:**
- [ ] All shares accessible to authorized users
- [ ] 0 unauthorized access attempts
- [ ] Backup completes in <30 minutes

**After 1 week:**
- [ ] 100+ users accessing shares successfully
- [ ] No file corruption reported
- [ ] Backup running on schedule daily

**After 1 month:**
- [ ] 10+ restore tests successful
- [ ] SMB encryption verified on all transfers
- [ ] Audit logs show 0 suspicious access patterns

---

## Next Phase

→ **Phase 10: RBAC Design & Implementation** (Identity-based access, role definitions, conditional policies)

---

**Document Version**: 2.0  
**Last Updated**: March 4, 2026  
**Notes**: Comprehensive file services setup with both GUI manual procedures and PowerShell automation. Includes security (SMB encryption, NTFS RBAC), auditing, and backup for business continuity.
