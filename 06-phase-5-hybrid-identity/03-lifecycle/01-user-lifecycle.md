# User Lifecycle Management

**Phase**: 5 – Hybrid Identity | **Depends on**: Azure AD Connect active, Intune enrolled  
**Key Result**: Consistent, auditable onboarding and offboarding process with no orphaned accounts or licenses

---

## Overview

All user accounts start in on-premises Active Directory. They sync to Entra ID through Azure AD Connect. This file shows the full lifecycle: new hire onboarding, transfers, offboarding, and guest management.

---

## Part 1: User Onboarding

### Step 1.1 – Create On-Premises AD Account

On the primary domain controller, open **Active Directory Users and Computers** or use PowerShell:

```powershell
# Create new user account
New-ADUser `
  -Name "Jane Smith" `
  -GivenName "Jane" `
  -Surname "Smith" `
  -SamAccountName "jsmith" `
  -UserPrincipalName "jsmith@yourdomain.com" `
  -Path "OU=Users,DC=organization,DC=local" `
  -AccountPassword (ConvertTo-SecureString "TempPass@2026!" -AsPlainText -Force) `
  -ChangePasswordAtLogon $true `
  -Enabled $true

# Add user to department security group
Add-ADGroupMember -Identity "GRP-Finance-Users" -Members "jsmith"
Add-ADGroupMember -Identity "GRP-AllStaff" -Members "jsmith"

Write-Host "AD account created for jsmith" -ForegroundColor Green
```

**Required AD attributes to populate (for clean Entra ID sync):**

| Attribute | Example |
|---|---|
| `DisplayName` | Jane Smith |
| `UserPrincipalName` | jsmith@yourdomain.com |
| `Mail` | jsmith@yourdomain.com |
| `Department` | Finance |
| `JobTitle` | Financial Analyst |
| `Manager` | CN=John Doe,OU=Users,DC=organization,DC=local |
| `TelephoneNumber` | +1-416-555-0100 |

---

### Step 1.2 – Trigger Azure AD Connect Sync

After creating the AD account, force an immediate delta sync so the user appears in Entra ID within minutes (instead of waiting up to 30 minutes):

```powershell
# On the Azure AD Connect sync server
Start-ADSyncSyncCycle -PolicyType Delta
```

Verify the user appeared in Entra ID:

1. Go to https://entra.microsoft.com
2. **Identity** → **Users** → **All users**
3. Search for `jsmith` — should show **Source: Windows Server AD**

---

### Step 1.3 – Assign Microsoft 365 License

```powershell
# Connect to Microsoft Graph
Connect-MgGraph -Scopes "User.ReadWrite.All", "Organization.Read.All"

# Get available SKUs
Get-MgSubscribedSku | Select SkuPartNumber, ConsumedUnits, @{N="Available";E={$_.PrepaidUnits.Enabled - $_.ConsumedUnits}}

# Assign E3 license to the new user
# Replace the SkuId with your tenant's actual E3 SkuId (from Get-MgSubscribedSku)
$e3SkuId = (Get-MgSubscribedSku | Where-Object {$_.SkuPartNumber -eq "ENTERPRISEPACK"}).SkuId

$licenseAssignment = @{
    AddLicenses = @(@{ SkuId = $e3SkuId })
    RemoveLicenses = @()
}
Set-MgUserLicense -UserId "jsmith@yourdomain.com" -BodyParameter $licenseAssignment

Write-Host "E3 license assigned to jsmith" -ForegroundColor Green
```

---

### Step 1.4 – Configure Mailbox and Default Settings

The Exchange Online mailbox is created automatically when the E3 license is assigned. Allow 15–30 minutes, then configure defaults:

```powershell
Connect-ExchangeOnline -UserPrincipalName admin@yourdomain.com

# Set mailbox regional settings
Set-MailboxRegionalConfiguration -Identity "jsmith@yourdomain.com" `
  -Language "en-CA" -TimeZone "Eastern Standard Time" -DateFormat "dd/MM/yyyy"

# Add to shared mailbox (if applicable)
Add-MailboxPermission -Identity "finance@yourdomain.com" `
  -User "jsmith@yourdomain.com" `
  -AccessRights FullAccess -InheritanceType All -AutoMapping $true

Write-Host "Mailbox configured for jsmith" -ForegroundColor Green
```

---

### Step 1.5 – Intune Device Enrollment

When the user signs in to their device with their M365 credentials, Intune enrollment is triggered automatically if Auto-enrollment is configured. Verify enrollment:

1. Go to https://intune.microsoft.com
2. **Devices** → **All devices** → Search for the user's device
3. Confirm **Compliance state: Compliant** within 15 minutes of first sign-in

If the device is not auto-enrolled, direct the user to:
- **Settings** → **Accounts** → **Access work or school** → **Connect** → Enter `jsmith@yourdomain.com`

---

### Step 1.6 – Onboarding Checklist

```
[ ] AD account created with all required attributes
[ ] Added to correct department security group(s)
[ ] Azure AD Connect delta sync triggered and user visible in Entra ID
[ ] M365 E3/E5 license assigned
[ ] Mailbox provisioned and accessible
[ ] Device enrolled in Intune and marked Compliant
[ ] MFA registered (user prompted on first M365 sign-in)
[ ] Manager notified of account readiness
```

---

## Part 2: User Transfers (Department/Role Change)

When a user moves departments or changes roles:

```powershell
# Update AD attributes
Set-ADUser -Identity "jsmith" `
  -Department "IT" `
  -Title "IT Analyst" `
  -Manager (Get-ADUser "itmanager")

# Update group memberships
Remove-ADGroupMember -Identity "GRP-Finance-Users" -Members "jsmith" -Confirm:$false
Add-ADGroupMember -Identity "GRP-IT-Users" -Members "jsmith"

# Trigger sync
Start-ADSyncSyncCycle -PolicyType Delta

# Update M365 license if role requires E5 (e.g., security staff)
# [Follow Step 1.3 to swap licenses]
```

**Review SharePoint/OneDrive access** after a transfer: remove the user from old department SharePoint sites and add to new department sites manually via the SharePoint admin center.

---

## Part 3: User Offboarding

### Step 3.1 – Immediately on Last Day (or Termination)

```powershell
# ---- STEP 1: Revoke all active M365 sessions ----
Connect-MgGraph -Scopes "User.ReadWrite.All"
Revoke-MgUserSignInSession -UserId "jsmith@yourdomain.com"
Write-Host "All active sessions revoked" -ForegroundColor Yellow

# ---- STEP 2: Disable the AD account (prevents on-prem + cloud sign-in) ----
Disable-ADAccount -Identity "jsmith"
Write-Host "AD account disabled" -ForegroundColor Yellow

# Force immediate sync of the disabled state to Entra ID
Start-ADSyncSyncCycle -PolicyType Delta

# ---- STEP 3: Remove from all AD security groups ----
$userGroups = (Get-ADUser "jsmith" -Properties MemberOf).MemberOf
foreach ($group in $userGroups) {
    Remove-ADGroupMember -Identity $group -Members "jsmith" -Confirm:$false
}
Write-Host "Removed from all AD groups" -ForegroundColor Yellow
```

---

### Step 3.2 – Within 24 Hours

```powershell
# ---- STEP 4: Convert mailbox to shared mailbox (preserves email history) ----
Connect-ExchangeOnline -UserPrincipalName admin@yourdomain.com
Set-Mailbox -Identity "jsmith@yourdomain.com" -Type Shared
Write-Host "Mailbox converted to Shared" -ForegroundColor Yellow

# Grant manager access to the shared mailbox
Add-MailboxPermission -Identity "jsmith@yourdomain.com" `
  -User "manager@yourdomain.com" `
  -AccessRights FullAccess -InheritanceType All

# Set up Out-of-Office auto-reply
Set-MailboxAutoReplyConfiguration -Identity "jsmith@yourdomain.com" `
  -AutoReplyState Enabled `
  -InternalMessage "Jane Smith has left the organisation. Please contact finance@yourdomain.com." `
  -ExternalMessage "Jane Smith has left the organisation. Please contact finance@yourdomain.com."

# ---- STEP 5: Remove M365 license (mailbox retained as shared, no license needed) ----
$currentLicenses = (Get-MgUserLicenseDetail -UserId "jsmith@yourdomain.com").SkuId
$licenseRemoval = @{
    AddLicenses    = @()
    RemoveLicenses = $currentLicenses
}
Set-MgUserLicense -UserId "jsmith@yourdomain.com" -BodyParameter $licenseRemoval
Write-Host "Licenses removed" -ForegroundColor Yellow
```

---

### Step 3.3 – Within 30 Days

```powershell
# ---- STEP 6: Move AD account to Disabled OU ----
Move-ADObject -Identity (Get-ADUser "jsmith").DistinguishedName `
  -TargetPath "OU=Disabled,DC=organization,DC=local"

# ---- STEP 7: Wipe corporate device via Intune (if applicable) ----
# Go to Intune portal → Devices → find jsmith's device → Retire (removes corporate data only)
# Or use Full Wipe if the device is corporate-owned

Write-Host "Account moved to Disabled OU" -ForegroundColor Yellow
```

---

### Step 3.4 – After 90 Days (Permanent Deletion)

```powershell
# Permanently delete the AD account (only after legal/HR clearance)
Remove-ADUser -Identity "jsmith" -Confirm:$false

# Delete the Entra ID account (Entra ID soft-deletes for 30 days first)
Remove-MgUser -UserId "jsmith@yourdomain.com"

Write-Host "Account permanently deleted" -ForegroundColor Red
```

> **Note:** Before permanent deletion, confirm with HR and Legal that no eDiscovery holds or audits require the account or its data to be retained.

---

### Step 3.5 – Offboarding Checklist

```
[ ] All active M365/Entra ID sessions revoked
[ ] AD account disabled and synced to Entra ID
[ ] Removed from all security groups
[ ] Mailbox converted to Shared with manager access
[ ] Auto-reply configured on mailbox
[ ] M365 licenses removed
[ ] OneDrive data reviewed and ownership transferred (if needed)
[ ] Corporate device wiped or retired in Intune
[ ] AD account moved to Disabled OU
[ ] 90-day review scheduled for permanent deletion
[ ] HR and IT sign-off recorded
```

---

## Part 4: Guest User Management

Guest accounts are Entra ID B2B accounts for external collaborators (vendors, contractors).

### Create a Guest Invitation

```powershell
Connect-MgGraph -Scopes "User.Invite.All"

New-MgInvitation `
  -InvitedUserEmailAddress "contractor@externalcompany.com" `
  -InviteRedirectUrl "https://myapps.microsoft.com" `
  -SendInvitationMessage:$true `
  -InvitedUserDisplayName "External Contractor"
```

### Guest Access Controls

- Guest access is restricted to specific SharePoint sites only (no tenant-wide access)
- Guests cannot access the on-prem network or file shares
- Guest accounts expire automatically after **90 days** of inactivity (configured in Entra ID External Identities settings)
- Invite approval requires a Department Manager + IT Admin sign-off

### Guest Offboarding

```powershell
# Remove guest user
Remove-MgUser -UserId "contractor_externalcompany.com#EXT#@yourdomain.onmicrosoft.com"
Write-Host "Guest account removed" -ForegroundColor Yellow
```

---

## Part 5: Quarterly Access Reviews

Access reviews ensure users only retain the access they need. Run quarterly:

1. Go to https://entra.microsoft.com → **Identity Governance** → **Access reviews**
2. Click **+ New access review**
3. Configure:
   - **Review type**: Teams + Groups
   - **Groups to review**: All department security groups
   - **Reviewers**: Each group's manager
   - **Duration**: 14 days
   - **Actions on non-response**: Remove access
4. Notify managers when review opens
5. After review closes, export results to SharePoint → `IT/Access-Reviews/YYYY-QQ.csv`

```powershell
# List users who haven't signed in for 90+ days (candidates for review)
Connect-MgGraph -Scopes "AuditLog.Read.All", "User.Read.All"

$cutoff = (Get-Date).AddDays(-90)
Get-MgUser -All -Property DisplayName,UserPrincipalName,SignInActivity |
  Where-Object { $_.SignInActivity.LastSignInDateTime -lt $cutoff } |
  Select-Object DisplayName, UserPrincipalName, @{N="LastSignIn";E={$_.SignInActivity.LastSignInDateTime}} |
  Export-Csv "C:\Reports\Inactive-Users-$(Get-Date -Format 'yyyy-MM-dd').csv" -NoTypeInformation

Write-Host "Inactive user report exported" -ForegroundColor Green
```
