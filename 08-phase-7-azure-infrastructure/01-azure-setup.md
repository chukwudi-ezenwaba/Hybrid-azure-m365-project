# Phase 7: On-Premises Application Integration & Identity

**Depends on**: Phase 5 (Azure AD Connect syncing, Entra ID active), Phase 6 (AD DS and file server VMs running on Hyper-V)  
**Key Result**: HR web application authenticates users via Kerberos SSO, file server shares are secured with SMB encryption and NTFS permissions, file access is audited, and VM-level protection is covered by ASR

---

## Overview

This phase sets up the on-premises Hyper-V VMs. The HR application server and the file server use the existing Active Directory credentials. The file server also uses a locked-down SMB configuration and object-level file access auditing. Azure Site Recovery covers disaster recovery for both servers (see Phase 6.2).

---

## Step 1: Verify AD Sync Is Current

Before configuring Kerberos delegation, confirm that the accounts you need are present in both on-prem AD and Entra ID. A sync mismatch here will cause SSO to fail silently.

```powershell
# Count on-prem users
$onPremCount = (Get-ADUser -Filter *).Count

# Count Entra ID (cloud) synced users
Connect-MgGraph -Scopes "User.Read.All"
$cloudCount = (Get-MgUser -All -Filter "onPremisesSyncEnabled eq true").Count

Write-Host "On-prem AD users : $onPremCount"
Write-Host "Entra ID synced  : $cloudCount"
```

The counts should be equal or within 1–2 of each other (service accounts that are intentionally excluded from sync are the typical difference). If the gap is larger, run a manual sync and check the Azure AD Connect Health portal before proceeding:

```powershell
# Trigger a manual delta sync from the Azure AD Connect server
Import-Module ADSync
Start-ADSyncSyncCycle -PolicyType Delta
```

---

## Step 2: Create and Configure the HR App Service Account

The IIS application pool that hosts the HR web app must run as a dedicated domain service account — not as Local System or Network Service — so that Kerberos delegation can be scoped to it.

**On the domain controller:**

```powershell
# Create the service account
New-ADUser `
  -Name "svc_hrapp" `
  -SamAccountName "svc_hrapp" `
  -UserPrincipalName "svc_hrapp@nig-e-mart.local" `
  -AccountPassword (ConvertTo-SecureString "P@ssw0rd!SVC2026" -AsPlainText -Force) `
  -PasswordNeverExpires $true `
  -CannotChangePassword $true `
  -Enabled $true `
  -Description "Service account for HR application IIS app pool"

# Register the Service Principal Name so Kerberos knows this account represents the HR web service
setspn -A HTTP/hr-app.nig-e-mart.local svc_hrapp
setspn -A HTTP/hr-app svc_hrapp

# Verify SPNs were registered
setspn -L svc_hrapp
```

**Enable constrained delegation on the service account** (allows it to delegate user identity to SQL Server, so the database layer also authenticates as the end user):

```powershell
Set-ADAccountControl -Identity "svc_hrapp" -TrustedForDelegation $false  # Disable unconstrained first
Set-ADUser -Identity "svc_hrapp" `
  -Add @{ "msDS-AllowedToDelegateTo" = "MSSQLSvc/HR-APP-01.nig-e-mart.local:1433" }

# Verify
Get-ADUser -Identity "svc_hrapp" -Properties "msDS-AllowedToDelegateTo" |
  Select-Object -ExpandProperty "msDS-AllowedToDelegateTo"
```

---

## Step 3: Configure the IIS Application Pool on HR-APP-01

RDP into HR-APP-01 and configure IIS to use the service account and Windows Authentication:

1. Open **Internet Information Services (IIS) Manager** (run `inetmgr` from the Start menu).
2. In the left tree, expand **HR-APP-01** → **Application Pools**.
3. Right-click the app pool for the HR application (e.g., `HRAppPool`) → **Advanced Settings**.
4. Under **Process Model** → **Identity**: click the `...` button → select **Custom account** → **Set** → enter `nig-e-mart\svc_hrapp` and the password. Click **OK**.

5. Still in IIS Manager, navigate to the HR application under **Sites** → **HR Application** → click **Authentication** in the Features view.
6. Disable **Anonymous Authentication** (right-click → **Disable**).
7. Enable **Windows Authentication** (right-click → **Enable**).
8. Click **Windows Authentication** → **Providers** (right panel) → ensure **Negotiate** is listed first (above NTLM). If NTLM is first, select it and click **Move Up** to put Negotiate at the top. Negotiate is the provider that enables Kerberos; NTLM is the fallback.

9. In a browser on an on-premises client machine, navigate to `http://hr-app.nig-e-mart.local:8080`. You should be signed in automatically without a credential prompt. If a login box appears, Kerberos is falling back to NTLM — re-check the SPN registration and ensure the client is on the domain.

---

## Step 4: Secure the File Server (FS-01)

RDP into FS-01 or run the following PowerShell commands via PSRemoting.

**Enable SMB encryption and require signing:**

```powershell
# Require SMB signing and encryption for all connections
Set-SmbServerConfiguration `
  -EncryptData $true `
  -RequireSecuritySignature $true `
  -EnableSMB1Protocol $false `
  -Force

# Verify
Get-SmbServerConfiguration | Select-Object EncryptData, RequireSecuritySignature, EnableSMB1Protocol
# Expected: EncryptData=True, RequireSecuritySignature=True, EnableSMB1Protocol=False
```

Disabling SMB1 is mandatory — SMB1 is the protocol exploited by EternalBlue/WannaCry. Confirm no legacy devices (old printers, NAS devices) rely on SMB1 before disabling it. If they do, those devices need to be updated or isolated before this step.

---

## Step 5: Create Department File Shares with NTFS Permissions

```powershell
# Create the folder structure
$shares = @("Sales", "Finance", "HR", "IT", "Operations")
foreach ($share in $shares) {
  New-Item -ItemType Directory -Path "C:\Shares\$share" -Force | Out-Null
}

# Create SMB shares — grant the corresponding AD group Full Control at the share level
# (NTFS permissions below will be the actual access gate; share-level is set broad)
New-SmbShare -Name "Sales"      -Path "C:\Shares\Sales"      -FullAccess "nig-e-mart\SG-Sales"
New-SmbShare -Name "Finance"    -Path "C:\Shares\Finance"    -FullAccess "nig-e-mart\SG-Finance"
New-SmbShare -Name "HR"         -Path "C:\Shares\HR"         -FullAccess "nig-e-mart\SG-HR"
New-SmbShare -Name "IT"         -Path "C:\Shares\IT"         -FullAccess "nig-e-mart\SG-IT"
New-SmbShare -Name "Operations" -Path "C:\Shares\Operations" -FullAccess "nig-e-mart\SG-Operations"
```

**Apply NTFS permissions** (more granular than SMB share permissions — this is the actual access control layer):

```powershell
# Remove inherited permissions and apply explicit NTFS ACLs
$folderMap = @{
  "C:\Shares\Sales"      = "nig-e-mart\SG-Sales"
  "C:\Shares\Finance"    = "nig-e-mart\SG-Finance"
  "C:\Shares\HR"         = "nig-e-mart\SG-HR"
  "C:\Shares\IT"         = "nig-e-mart\SG-IT"
  "C:\Shares\Operations" = "nig-e-mart\SG-Operations"
}

foreach ($folder in $folderMap.Keys) {
  $acl = Get-Acl $folder
  $acl.SetAccessRuleProtection($true, $false)  # Break inheritance, remove inherited rules
  $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
    $folderMap[$folder], "Modify", "ContainerInherit,ObjectInherit", "None", "Allow"
  )
  $acl.AddAccessRule($rule)
  # Always grant SYSTEM full control so backup agents can access
  $systemRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
    "SYSTEM", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow"
  )
  $acl.AddAccessRule($systemRule)
  Set-Acl -Path $folder -AclObject $acl
  Write-Host "NTFS permissions set on $folder"
}
```

---

## Step 6: Enable File Access Auditing

Auditing records who accessed, modified, or deleted files. This is required for compliance and lets you investigate incidents.

**On a domain controller, enable the audit policy via Group Policy:**

1. Open **Group Policy Management** (gpmc.msc).
2. Right-click the **nig-e-mart.local** domain → **Create a GPO in this domain** → name it `File Access Auditing`.
3. Edit the GPO: navigate to **Computer Configuration** → **Windows Settings** → **Security Settings** → **Advanced Audit Policy Configuration** → **Object Access**.
4. Double-click **Audit File System** → check **Configure the following audit events** → check both **Success** and **Failure**. Click **OK**.
5. Link the GPO to the **Servers** OU so it applies to FS-01. Run `gpupdate /force` on FS-01 to pick it up immediately.

**Apply a SACL (Security Audit Control List) to the shared folders** so Windows knows which file operations to log:

```powershell
# Apply SACL to all share folders — audit all access by all users
foreach ($folder in $folderMap.Keys) {
  $acl = Get-Acl $folder
  $auditRule = New-Object System.Security.AccessControl.FileSystemAuditRule(
    "Everyone", "ReadData,WriteData,Delete", "ContainerInherit,ObjectInherit", "None", "Success,Failure"
  )
  $acl.AddAuditRule($auditRule)
  Set-Acl -Path $folder -AclObject $acl
}
```

File access events will now appear in the **Security** event log on FS-01 (Event ID 4663 for object access). To search for a specific file access:

```powershell
# Find all deletions in the HR share in the last 24 hours
Get-WinEvent -FilterHashtable @{
  LogName   = "Security"
  Id        = 4663
  StartTime = (Get-Date).AddHours(-24)
} | Where-Object { $_.Message -match "C:\\Shares\\HR" -and $_.Message -match "DELETE" } |
  Select-Object TimeCreated, Message
```

---

## Step 7: Confirm Azure Site Recovery Coverage

Both HR-APP-01 and FS-01 should already be enrolled in ASR from Phase 6.2. Verify coverage now before proceeding:

1. Azure portal → your Recovery Services Vault → **Site Recovery** → **Replicated items**.
2. Confirm both **HR-APP-01** and **FS-01** are listed with status **Protected**.
3. If either VM is missing, return to [Phase 6.2 – Azure Site Recovery](../07-phase-6-high-availability-redundancy/02-azure-site-recovery.md) and complete the replication enablement steps for the missing VM.

The ASR replication means that if either server suffers a hardware failure or ransomware event, a clean replica is available in Azure and can be brought online within the 15-minute RPO. This replaces the need for a separate local backup script.

---

## Completion Checklist

- AD user counts match between on-prem and Entra ID (or discrepancy is explained)
- `svc_hrapp` service account created with SPN registered for `HTTP/hr-app.nig-e-mart.local`
- IIS application pool on HR-APP-01 running as `svc_hrapp`
- Windows Authentication enabled on the HR application, Anonymous Authentication disabled
- Negotiate (Kerberos) provider listed first in IIS authentication providers
- Browser test from a domain-joined client confirms silent SSO (no login prompt)
- SMB encryption and signing enabled on FS-01; SMB1 disabled
- Five department shares created with NTFS permissions scoped to their respective AD security groups
- Inheritance broken on all share folders; SYSTEM full-control ACE present on each
- File System audit policy deployed via GPO and applied to FS-01
- SACL applied to all share folders logging ReadData, WriteData, Delete for all users
- HR-APP-01 and FS-01 both showing **Protected** status in the ASR replicated items list

---

## Next Step

Proceed to [Phase 8 – Workload Migration](../09-phase-8-workload-migration/01-workload-migration.md).

