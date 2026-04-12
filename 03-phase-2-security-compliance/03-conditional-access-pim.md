# Conditional Access & Privileged Identity Management (PIM)

**Phase**: 2 – Security & Compliance | **Depends on**: Phase 1 (M365 tenant + MFA baseline), Phase 5 (Azure AD Connect active for hybrid identity)  
**Key Result**: All users protected by Conditional Access; all privileged roles require just-in-time (JIT) activation via PIM

---

## Overview

Conditional Access enforces the Zero Trust principle of **"never trust, always verify"** on every sign-in. PIM enforces **least privilege** by requiring admins to explicitly activate elevated roles and provides a full audit trail.

Both require **Entra ID Premium P1** (Conditional Access) and **Entra ID Premium P2** (PIM) — both are included in M365 E5; P1 is included in E3. Confirm your license in Entra ID → Overview → Licenses before proceeding.

---

## Part 1: Conditional Access Policies

All Conditional Access policies are configured in:  
**Entra admin center** → https://entra.microsoft.com → **Protection** → **Conditional Access**

> **Important**: Always test a new policy in **Report-only** mode first for 7 days before switching to **On**. This prevents accidental lockouts.

---

### Policy 1: Require MFA for All Users

Ensures every user authenticates with MFA regardless of location or device.

**Via portal:**

1. **Conditional Access** → **Policies** → **+ New policy**
2. **Name**: `CA-001 – Require MFA for All Users`
3. **Assignments**:
   - **Users**: All users
   - **Exclude**: Break-glass account (see Step 7)
   - **Target resources**: All cloud apps
4. **Conditions**: (none — applies everywhere)
5. **Access controls – Grant**:
   - Select: **Require multifactor authentication**
   - Click **Select**
6. **Enable policy**: Start with **Report-only** → switch to **On** after validation
7. Click **Create**

**Via PowerShell:**

```powershell
Connect-MgGraph -Scopes "Policy.ReadWrite.ConditionalAccess"

$policy = @{
    DisplayName = "CA-001 – Require MFA for All Users"
    State = "enabledForReportingButNotEnforced"  # Report-only first
    Conditions = @{
        Users = @{
            IncludeUsers = @("All")
            ExcludeUsers = @("break-glass-account-object-id")
        }
        Applications = @{
            IncludeApplications = @("All")
        }
    }
    GrantControls = @{
        Operator = "OR"
        BuiltInControls = @("mfa")
    }
}
New-MgIdentityConditionalAccessPolicy -BodyParameter $policy
Write-Host "CA-001 created in Report-only mode" -ForegroundColor Green
```

---

### Policy 2: Block Legacy Authentication

Legacy authentication protocols (SMTP Auth, IMAP, POP3, older Office clients) cannot use MFA and are a primary attack vector.

1. **New policy**
2. **Name**: `CA-002 – Block Legacy Authentication`
3. **Assignments**:
   - **Users**: All users
   - **Target resources**: All cloud apps
4. **Conditions**:
   - **Client apps** → Check: Exchange ActiveSync clients, Other clients
5. **Access controls – Grant**: **Block access**
6. **Enable policy**: **Report-only** → validate no legitimate users rely on legacy auth → switch to **On**
7. Click **Create**

> Before enabling, run this to check which users are using legacy auth:
> ```powershell
> # Search unified audit log for legacy auth sign-ins (last 30 days)
> Search-UnifiedAuditLog -StartDate (Get-Date).AddDays(-30) -EndDate (Get-Date) `
>   -RecordType AzureActiveDirectoryStsLogon `
>   -ResultSize 200 |
>   Where-Object { $_.AuditData -match '"ClientInfoString":"BAV2ROPC"' `
>     -or $_.AuditData -match '"LegacyClient":"True"' } |
>   Select UserIds, CreationDate
> ```

---

### Policy 3: Require Compliant Device for M365 Access

Ensures only Intune-managed and compliant devices can access M365 services.

1. **New policy**
2. **Name**: `CA-003 – Require Compliant Device`
3. **Assignments**:
   - **Users**: All users
   - **Target resources**: Select apps → Add: Exchange Online, SharePoint Online, Microsoft Teams
4. **Conditions**:
   - **Device platforms**: Windows, iOS, Android, macOS
5. **Access controls – Grant**:
   - **Require device to be marked as compliant**
6. **Enable policy**: **Report-only** first; validate Intune compliance is working → switch to **On**
7. Click **Create**

---

### Policy 4: Block Risky Sign-Ins

Blocks sign-ins that Entra ID Identity Protection has flagged as medium or high risk (requires Entra ID P2 / E5).

1. **New policy**
2. **Name**: `CA-004 – Block High-Risk Sign-ins`
3. **Assignments**:
   - **Users**: All users
   - **Target resources**: All cloud apps
4. **Conditions**:
   - **Sign-in risk**: High
5. **Access controls – Grant**: **Block access**
6. For **Medium risk**, create a separate policy that requires MFA instead of blocking
7. **Enable policy**: **On** (this is safe to enable directly as it only triggers on risky logins)
8. Click **Create**

---

### Policy 5: Require MFA for Admin Roles (Always)

Admins must use MFA regardless of whether they're on a trusted network or compliant device.

1. **New policy**
2. **Name**: `CA-005 – Require MFA for Admins`
3. **Assignments**:
   - **Users** → **Directory roles**: Global Administrator, User Administrator, Security Administrator, Exchange Administrator, SharePoint Administrator, Intune Administrator
   - **Target resources**: All cloud apps
4. **Access controls – Grant**: **Require multifactor authentication**
5. **Enable policy**: **On** (not report-only — enforce immediately for admins)
6. Click **Create**

---

### Step 6: Define Named Locations (Trusted Networks)

Named locations identify trusted corporate IP ranges for use in future policies (e.g., reducing MFA friction for on-prem users).

1. **Conditional Access** → **Named locations** → **+ IP ranges location**
2. **Name**: `Corporate On-Premises Network`
3. **IP ranges**: Add your on-prem public IP address (e.g., `203.0.113.0/24`)
4. Check **Mark as trusted location**
5. Click **Create**

---

### Step 7: Create Break-Glass (Emergency Access) Accounts

Break-glass accounts are excluded from all Conditional Access policies and are used only if all admin access is locked out.

```powershell
Connect-MgGraph -Scopes "User.ReadWrite.All", "RoleManagement.ReadWrite.Directory"

# Create break-glass account
$breakGlassPassword = ConvertTo-SecureString "SuperSecure@BreakGlass2026!" -AsPlainText -Force

$breakGlassUser = New-MgUser -DisplayName "Break Glass Admin" `
  -UserPrincipalName "breakglass@yourdomain.onmicrosoft.com" `
  -PasswordProfile @{ Password = "SuperSecure@BreakGlass2026!"; ForceChangePasswordNextSignIn = $false } `
  -AccountEnabled $true

# Assign Global Admin role
$globalAdminRole = Get-MgDirectoryRole | Where-Object { $_.DisplayName -eq "Global Administrator" }
New-MgDirectoryRoleMember -DirectoryRoleId $globalAdminRole.Id `
  -BodyParameter @{ "@odata.id" = "https://graph.microsoft.com/v1.0/users/$($breakGlassUser.Id)" }

Write-Host "Break-glass account created: $($breakGlassUser.UserPrincipalName)" -ForegroundColor Yellow
Write-Host "Store credentials in a physical, secured location (NOT in password manager)" -ForegroundColor Red
```

**After creation:**
- Record credentials on paper and store in a physically secured location (e.g., safe)
- Set up an alert to notify the Security team if this account ever signs in
- Exclude this account from all Conditional Access policies

---

## Part 2: Privileged Identity Management (PIM)

PIM provides just-in-time (JIT) access — admins have no standing admin privileges and must explicitly activate a role for a limited time.

> PIM requires **Entra ID Premium P2** (included in M365 E5). Verify under Entra ID → Licenses.

---

### Step 2.1 – Enable PIM

1. Go to https://entra.microsoft.com
2. Navigate to **Identity governance** → **Privileged Identity Management**
3. Click **Entra ID roles** → **Manage**
4. If prompted to "Verify your identity", complete the MFA challenge

---

### Step 2.2 – Configure Roles for PIM

For each privileged role, move permanent assignments to **eligible** (JIT):

**Roles to configure:**

| Role | Activation Duration | Require Approval | Require Justification |
|---|---|---|---|
| Global Administrator | 1 hour max | Yes (two approvers) | Yes |
| User Administrator | 4 hours max | No | Yes |
| Security Administrator | 4 hours max | No | Yes |
| Exchange Administrator | 4 hours max | No | Yes |
| SharePoint Administrator | 4 hours max | No | Yes |
| Intune Administrator | 4 hours max | No | Yes |

**Configure each role:**

1. **PIM** → **Entra ID roles** → **Roles** → click the role (e.g., Global Administrator)
2. Click **Settings** → **Edit**
3. Set:
   - **Activation maximum duration**: 1 hour (for Global Admin)
   - **Require justification on activation**: Yes
   - **Require approval to activate**: Yes (for Global Admin)
   - **Approvers**: Add the two most senior IT staff
   - **Require MFA on activation**: Yes
4. Click **Update**

---

### Step 2.3 – Assign Eligible Roles to Admins

```powershell
Connect-MgGraph -Scopes "RoleManagement.ReadWrite.Directory", "PrivilegedAccess.ReadWrite.AzureADGroup"

# Get the role definition ID for Global Administrator
$roleId = (Get-MgRoleManagementDirectoryRoleDefinition | 
            Where-Object {$_.DisplayName -eq "Global Administrator"}).Id

# Get the admin user ID
$adminUser = Get-MgUser -UserId "admin@yourdomain.com"

# Create an eligible assignment (not permanent)
New-MgRoleManagementDirectoryRoleEligibilityScheduleRequest -RoleDefinitionId $roleId `
  -PrincipalId $adminUser.Id `
  -DirectoryScopeId "/" `
  -Action "AdminAssign" `
  -ScheduleInfo @{
      StartDateTime = (Get-Date)
      Expiration = @{ Type = "NoExpiration" }
  } `
  -Justification "Initial PIM eligible assignment for IT Admin"

Write-Host "Eligible Global Admin role assigned to $($adminUser.DisplayName)" -ForegroundColor Green
```

Repeat for each admin user and their appropriate roles.

---

### Step 2.4 – How Admins Activate a Role (JIT)

When an admin needs elevated access:

1. Go to https://entra.microsoft.com → **PIM** → **My roles**
2. Find the eligible role (e.g., User Administrator)
3. Click **Activate**
4. Enter **Reason**: (e.g., "Creating user accounts for new hire batch")
5. Set **Duration**: up to the configured maximum
6. If approval required: request is sent to approvers; access grants once approved
7. The role is active for the specified duration and then automatically removed

---

### Step 2.5 – Access Reviews for Privileged Roles

Run quarterly reviews to confirm all PIM eligible assignments are still needed:

1. **PIM** → **Entra ID roles** → **Access reviews** → **+ New**
2. Configure:
   - **Review name**: `PIM-Review-2026-Q2`
   - **Role**: Check all roles configured above
   - **Reviewers**: Managers of each admin
   - **Duration**: 14 days
   - **Auto-apply results**: Yes (removes access for "deny" responses after review period)
3. Click **Start**

---

## Monitoring

### Check Active Privileged Role Assignments

```powershell
Connect-MgGraph -Scopes "RoleManagement.Read.Directory"

# List all currently ACTIVE (non-JIT) Global Admin assignments
Get-MgRoleManagementDirectoryRoleAssignment |
  Where-Object { $_.RoleDefinitionId -eq (
    Get-MgRoleManagementDirectoryRoleDefinition |
    Where-Object {$_.DisplayName -eq "Global Administrator"}).Id
  } |
  ForEach-Object {
    $user = Get-MgUser -UserId $_.PrincipalId -ErrorAction SilentlyContinue
    [PSCustomObject]@{
        User = $user.DisplayName
        UPN  = $user.UserPrincipalName
        AssignmentType = "Permanent (review needed)"
    }
  }
```

Any permanent Global Admin assignments returned here (other than the break-glass account) should be converted to eligible PIM assignments.

### Set Up Alert: Break-Glass Account Sign-In

In Entra ID → **Monitoring** → **Diagnostic settings** → send Sign-in logs to Log Analytics, then create an alert rule:

- **Condition**: `SigninLogs | where UserPrincipalName == "breakglass@yourdomain.onmicrosoft.com"`
- **Action**: Email `security-team@yourdomain.com`
- **Severity**: Critical
