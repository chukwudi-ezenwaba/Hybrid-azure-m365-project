# Phase 7: On-Premises Application Integration & Identity

**Duration**: Weeks 13-14 | **Key Result**: HR app + file server authenticated via Entra ID, backup configured

## Phase Overview

| Item | Details |
|------|---------|
| What | Integrate Hyper-V VMs with Entra ID identity, configure backups |
| Duration | 2 weeks |
| Depends | Phase 5 (hybrid identity working) |

**Note**: This phase focuses on on-premises Hyper-V infrastructure. No Azure cloud resources are deployed. The HR web app and file server are integrated with Entra ID for unified identity management.

## Architecture

```
On-Premises Infrastructure:

Domain Controller
├─ AD DS (authoritative identity)
├─ DNS server
└─ Kerberos/LDAP

     ↓ (Sync via AAD Connect)

Hyper-V Host
├─ HR Application VM
│  └─ Windows Server + IIS
│     └─ ASP.NET static web app
│     └─ Kerberos authentication
│
└─ File Server VM
   └─ Windows Server
   └─ SMB shares (NTFS permissions)
   └─ Kerberos authentication

     ↓ (User SSO via Entra ID + Kerberos)

M365 Services
├─ Exchange, Teams, SharePoint
└─ Conditional Access policies
```

## Execution Steps

### Week 13: Application Identity Integration

#### 1. Verify AD DS Replication (Domain Controller)

Ensure users and groups are synced from on-premises AD:

```powershell
# Check user count
(Get-ADUser -Filter *).Count

# Verify users are in Entra ID (synced)
Get-MgUser -All | Measure-Object

# Should be ~equal count
```

#### 2. Configure Kerberos for HR Web App

Enable Kerberos delegation so users can SSO to the HR app:

```powershell
# On domain controller, enable Kerberos delegation for IIS service account

$appServerName = "HR-APP-VM"
$serviceAccount = "svc_hrapp"

# Enable delegation for the service account
Set-ADAccountControl -Identity $serviceAccount -TrustedForDelegation $true

# Verify
Get-ADAccountControl -Identity $serviceAccount
```

**What this does**: Users can now access the HR web app without re-entering credentials (single sign-on via Kerberos).

#### 3. Configure File Server SMB Security

Secure the file server with NTFS permissions and audit logging:

```powershell
# On file server VM, configure SMB security
Set-SmbServerConfiguration -EncryptData $true -RequireSecuritySignature $true -Force

# Enable SMB audit logging
Set-SmbServerConfiguration -AuditSmb1Access $true -Force

# Verify settings
Get-SmbServerConfiguration | Select EncryptData, RequireSecuritySignature
```

#### 4. Create File Server Shares with Department Permissions

```powershell
# Create shared folders
New-Item -ItemType Directory -Path "C:\Shares\Sales" -Force
New-Item -ItemType Directory -Path "C:\Shares\Finance" -Force
New-Item -ItemType Directory -Path "C:\Shares\HR" -Force

# Share the folders
New-SmbShare -Name "Sales" -Path "C:\Shares\Sales" -FullAccess "DOMAIN\SalesGroup"
New-SmbShare -Name "Finance" -Path "C:\Shares\Finance" -FullAccess "DOMAIN\FinanceGroup"
New-SmbShare -Name "HR" -Path "C:\Shares\HR" -FullAccess "DOMAIN\HRGroup" -ReadAccess "DOMAIN\AllUsers"

# Set NTFS permissions (more granular than SMB)
icacls "C:\Shares\Sales" /grant "DOMAIN\SalesGroup:(F)"
icacls "C:\Shares\Finance" /grant "DOMAIN\FinanceGroup:(F)"
icacls "C:\Shares\HR" /grant "DOMAIN\HRGroup:(F)" /grant "DOMAIN\AllUsers:(R)"
```

#### 5. Configure File Server Auditing

Enable detailed file access logging:

```powershell
# Enable object access audit (on file server)
auditpol /set /subcategory:"File System" /success:enable /failure:enable

# Enable SACL (System Access Control List) on shared folders
# This logs all file access attempts
icacls "C:\Shares\Sales" /audit:s:dacl /grant:r "SYSTEM:(F)"
```

### Week 14: Backup & Recovery Configuration

#### 1. Configure Nightly Backup (File Server)

Set up automated file server backup to external storage:

```powershell
# Create backup schedule (runs nightly at 1 AM)
$backupTask = @{
    TaskName    = "FileServerBackup"
    ScriptBlock = {
        # Compress files from last 24 hours
        $sourceFolder = "C:\Shares"
        $backupFolder = "E:\Backups"  # External drive/NAS
        $timestamp = (Get-Date).ToString("yyyy-MM-dd_HHmmss")
        $backupFile = "$backupFolder\FileServer_$timestamp.zip"
        
        # Backup
        Compress-Archive -Path $sourceFolder -DestinationPath $backupFile -Force
        
        # Keep only last 30 days of backups
        Get-ChildItem -Path $backupFolder -Filter "*.zip" | 
            Where-Object { $_.CreationTime -lt (Get-Date).AddDays(-30) } | 
            Remove-Item -Force
    }
    Trigger   = New-ScheduledTaskTrigger -Daily -At "1:00 AM"
    User      = "NT AUTHORITY\SYSTEM"
    RunLevel  = "Highest"
}

Register-ScheduledTask @backupTask
```

#### 2. Test Backup & Recovery

```powershell
# Run backup manually to verify
Start-ScheduledTask -TaskName "FileServerBackup"

# Check backup file exists
Get-ChildItem -Path "E:\Backups" -Filter "*.zip" | Select FullName, CreationTime

# Test restore (pull one file from backup)
Expand-Archive -Path "E:\Backups\FileServer_2026-03-04_010000.zip" -DestinationPath "C:\BackupRestore" -Force

# Verify restored files
Get-ChildItem -Path "C:\BackupRestore" -Recurse
```

#### 3. Configure M365 Audit Log Retention

Ensure M365 logs are retained for compliance:

```powershell
# Connect to M365
Connect-ExchangeOnline

# Verify audit logging is enabled
Get-AdminAuditLogConfig

# Set retention to 90 days (default)
Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled $true
```

#### 4. Document Recovery Procedures

Create a runbook for file server recovery:

```
RUNBOOK: File Server Recovery

Scenario: File server crashed, no data loss acceptable

Steps:
1. Provision new Windows Server VM on Hyper-V
2. Name it "FileServer-Recovery"
3. Domain-join to existing AD
4. Create C:\Shares directory structure
5. Restore latest backup from E:\Backups\*.zip
6. Update DNS to point "fileserver" hostname to new IP
7. Test SMB access:
   net use z: \\fileserver\sales /user:DOMAIN\user
8. Users can now access shares (transparent to them)

RTO (Recovery Time Objective): 2 hours
RPO (Recovery Point Objective): 1 day
```

## Success Checklist

- [ ] HR web app accessible via browser (users can login)
- [ ] File server shares accessible (net use works)
- [ ] Users can access shares via Kerberos SSO (no credential prompt)
- [ ] SMB encryption enabled on file server
- [ ] Nightly backup running successfully
- [ ] Backup verified (test restore successful)
- [ ] File access auditing enabled
- [ ] Recovery runbook documented

## Outputs

- HR app integrated with Entra ID identity
- File server secured with encryption + auditing
- Nightly backups configured + tested
- Recovery procedures documented
- Users can SSO to on-prem apps from cloud

## Next: Phase 8

→ **Phase 8: Workload Configuration & File Migration**
