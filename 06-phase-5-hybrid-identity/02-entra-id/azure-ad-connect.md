# Azure AD Connect – Configuration Guide

**Phase**: 5 – Hybrid Identity | **Depends on**: Phase 5.1 (AD DS deployed), Phase 1 (M365 tenant active)  
**Key Result**: On-premises users synced to Entra ID, Password Hash Sync active, SSO working end-to-end

---

## Prerequisites

Before starting, confirm:

| Requirement | Detail |
|---|---|
| On-prem Domain Controller | Running Windows Server 2019/2022, AD DS installed |
| M365 tenant | Custom domain verified (`yourdomain.com`) |
| Entra ID Premium P1 | Required for Conditional Access (included in E3/E5) |
| Sync account | Dedicated on-prem AD service account (e.g., `SVC-AADSync`) |
| Global Admin credentials | For M365/Entra ID sign-in during configuration |
| .NET Framework 4.7.2+ | Must be installed on the sync server |
| Sync server | A domain-joined Windows Server (can be the DC for small orgs) |

---

## Step 1: Create a Dedicated Sync Service Account

On the primary domain controller, open **Active Directory Users and Computers**:

1. Right-click the **Service Accounts** OU (or create one) → **New** → **User**
2. Configure:
   - **First name**: AADSync Service
   - **User logon name**: `svc-aadsync`
3. Set a strong password (20+ chars); check **Password never expires**
4. Uncheck **Must change password at next logon**
5. Click **Finish**

**Grant the account the required AD permissions (PowerShell on DC):**

```powershell
# Grant minimal AD permissions needed by AAD Connect
Import-Module ADDSDeployment

$syncAccount = "ORGANIZATION\svc-aadsync"

# Allow reading directory objects (minimum required)
dsacls "DC=organization,DC=local" /G "$syncAccount:GP;;user"
dsacls "DC=organization,DC=local" /G "$syncAccount:GP;;group"
dsacls "DC=organization,DC=local" /G "$syncAccount:GP;;contact"

Write-Host "Sync account permissions configured" -ForegroundColor Green
```

---

## Step 2: Download and Install Azure AD Connect

1. On the sync server, open a browser and go to:  
   https://www.microsoft.com/en-us/download/details.aspx?id=47594
2. Download **AzureADConnect.msi**
3. Double-click the installer
4. Accept the license agreement → Click **Continue**
5. On the **Express Settings** screen — click **Customize** (do NOT use Express; use Custom for OU filtering)

---

## Step 3: Configure Azure AD Connect (Custom Installation)

Work through the wizard pages:

### Page 1 – Install Required Components
- Check **Use an existing service account** → enter `ORGANIZATION\svc-aadsync` + password
- Leave other options at default
- Click **Install**

### Page 2 – User Sign-in Method
- Select **Password Hash Synchronization**
- Check **Enable single sign-on**
- Click **Next**

### Page 3 – Connect to Azure AD
- Enter your **Global Admin** credentials: `admin@organization.onmicrosoft.com`
- Click **Next** (Azure validates the tenant)

### Page 4 – Connect Your Directories
- Click **Add Directory**
- Select **Active Directory**
- Set **Directory type**: Active Directory
- **Forest**: `organization.local`
- Select **Use existing AD account** → enter `ORGANIZATION\svc-aadsync` + password
- Click **Add Directory** → **Next**

### Page 5 – Azure AD Sign-in Configuration
- Confirm your verified domain (`yourdomain.com`) is listed and shows **Verified**
- Select the on-prem attribute to use as the UPN — use **userPrincipalName**
- Click **Next**

### Page 6 – Domain and OU Filtering
- Select **Sync selected domains and OUs**
- Expand your domain tree and check only the OUs that should sync:
  - ✓ `OU=Users,DC=organization,DC=local`
  - ✓ `OU=Groups,DC=organization,DC=local`
  - ✓ `OU=Service Accounts,DC=organization,DC=local`
  - ✗ Uncheck computer accounts or OUs you don't need in Entra ID
- Click **Next**

### Page 7 – Uniquely Identifying Users
- Leave defaults: **Users are represented only once across all directories**
- Click **Next**

### Page 8 – Filter Users and Devices
- **Synchronize all users and devices** (default for full org sync)
- Click **Next**

### Page 9 – Optional Features
- Check **Password hash synchronization** (should already be checked)
- Check **Password writeback** (allows cloud-initiated password resets to flow back to AD)
- Check **Group writeback** (syncs M365 groups back to on-prem)
- Click **Next**

### Page 10 – Configure
- Check **Start the synchronization process when configuration completes**
- Click **Install**
- Wait 5–10 minutes for installation and initial sync

---

## Step 4: Verify Initial Synchronization

**In the Azure/Entra admin portal:**

1. Go to https://entra.microsoft.com
2. Navigate to **Identity** → **Users** → **All users**
3. Confirm on-premises users appear with **Source: Windows Server AD** tag
4. Check sync time: **Identity** → **Overview** → Look for "Last sync" timestamp

**Via PowerShell (on sync server):**

```powershell
# Install the module if not already present
Install-Module -Name MSOnline -Force

Connect-MsolService  # Enter Global Admin credentials

# Check directory sync status
Get-MsolCompanyInformation | Select-Object DisplayName, DirectorySynchronizationEnabled, LastDirSyncTime

# Expected output:
# DirectorySynchronizationEnabled : True
# LastDirSyncTime                  : [recent timestamp]

# Check for sync errors
Get-MsolDirSyncProvisioningError -ErrorCategory PropertyConflict | Format-Table -AutoSize
```

---

## Step 5: Configure the Sync Schedule

By default, Azure AD Connect runs a delta sync every 30 minutes. Verify and optionally adjust:

```powershell
# Check current sync schedule
Get-ADSyncScheduler

# Expected output:
# SyncCycleEnabled      : True
# NextSyncCyclePolicyType : Delta
# NextSyncCycleStartTimeInUTC : [30 min from last sync]
# CurrentlyRunning      : False
# StagingModeEnabled    : False

# Force an immediate delta sync (use after bulk AD changes)
Start-ADSyncSyncCycle -PolicyType Delta

# Force a full sync (use after OU filtering changes)
Start-ADSyncSyncCycle -PolicyType Initial
```

---

## Step 6: Enable Seamless SSO

Seamless SSO lets domain-joined on-prem machines access cloud resources without re-entering passwords.

**Run on the sync server (PowerShell as Domain Admin):**

```powershell
# Import and run the SSO configuration script
Import-Module "C:\Program Files\Microsoft Azure Active Directory Connect\AzureADSSO.psd1"

New-AzureADSSOAuthenticationContext

# Enable seamless SSO for the domain
Enable-AzureADSSO -Enable $true
```

**Deploy via Group Policy:**

1. Open **Group Policy Management** on the DC
2. Create or edit a GPO linked to the Users OU
3. Navigate to: **Computer Configuration → Administrative Templates → Windows Components → Internet Explorer → Internet Control Panel → Security Page → Site to Zone Assignment List**
4. Add: `https://autologon.microsoftazuread-sso.com` → Zone value: `1` (Intranet)
5. Apply GPO and run `gpupdate /force` on a test workstation

---

## Step 7: Validate End-to-End SSO

On a domain-joined workstation (logged in as an AD user):

1. Open a browser and navigate to https://portal.office.com
2. Enter the user's UPN (e.g., `jsmith@yourdomain.com`)
3. The user should be signed in **without being prompted for a password** (or only MFA, not password)
4. Verify access to Teams, OneDrive, and SharePoint works

---

## Step 8: Password Writeback Validation

Test that a cloud-initiated password reset flows back to on-prem AD:

1. In Entra ID admin center: **Identity** → **Users** → select a test user
2. Click **Reset password** → set a new temporary password
3. On the domain controller, verify the password changed:
   ```powershell
   Get-ADUser -Identity "testuser" -Properties PasswordLastSet | Select Name, PasswordLastSet
   # PasswordLastSet should show a recent timestamp
   ```

---

## Monitoring and Troubleshooting

### Check Sync Health (Monthly)

```powershell
# View sync connector run history
Get-ADSyncConnectorRunStatus

# List any objects with sync errors
Get-ADSyncRunStepResult | Where-Object {$_.StepResult -ne "success"} | Format-Table

# View detailed error log
Get-EventLog -LogName Application -Source "ADSync" -EntryType Error -Newest 20
```

### Common Issues

| Issue | Cause | Fix |
|---|---|---|
| Sync showing stale timestamp | ADSync service stopped | `Start-Service ADSync` on sync server |
| Duplicate attribute conflict | Two AD users share same email/UPN | Run `Get-MsolDirSyncProvisioningError` to find conflicts; update AD attributes |
| Password writeback not working | Firewall blocking port 443 to Azure | Verify outbound TCP 443 is open from sync server |
| Users not appearing in Entra ID | OU not included in filter | Re-run configuration wizard and adjust OU selection |
| SSO not working on workstations | GPO not applied or Kerberos issue | Run `gpresult /r` on workstation; verify autologon URL in Intranet zone |

