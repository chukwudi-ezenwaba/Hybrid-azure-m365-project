# Microsoft 365 Tenant Setup and Configuration

## Overview

This guide covers comprehensive Microsoft 365 tenant configuration including domain setup, custom branding, organizational settings, and administrative infrastructure. This is the foundational task for Phase 1.

**Duration**: 3-5 days  
**Requires**: Global Administrator role, domain ownership, Azure subscription  
**Depends On**: Azure subscription created, domain registered

---

## Pre-Configuration Checklist

- [ ] Azure subscription created and active
- [ ] Microsoft 365 licenses purchased (E3/E5)
- [ ] Organization domain registered (e.g., organization.com)
- [ ] Domain registrar access available (for DNS changes)
- [ ] Administrator mailbox planned
- [ ] Organization branding assets prepared (logo, colors)
- [ ] Global administrator account email ready
- [ ] MFA-capable device available

---

## Task 1: Create Microsoft 365 Tenant

### Step 1.1: Sign Up for Microsoft 365

1. Go to https://www.microsoft.com/microsoft-365/business
2. Click **Start your free trial** or **Buy now**
3. Choose plan:
   - Small business: Microsoft 365 Business Standard/Premium
   - Enterprise: Microsoft 365 E1/E3/E5
4. Fill in organization details:
   - **Organization name**: Contoso Inc.
   - **Size**: 1-10 employees (choose appropriate)
   - **Address**: Company headquarters address
   - **Phone**: Business phone number
   - **Website** (optional): company.com
5. Create administrator account:
   - **First name**: Global Administrator first name
   - **Last name**: Administrator last name
   - **Business email**: admin@organization.onmicrosoft.com (temporary)
   - **Password**: Strong password (uppercase, lowercase, numbers, symbols)
6. Set up billing:
   - **Payment method**: Credit card or purchase order
   - **Billing address**: Match organization address
7. Click **Create account**

### Step 1.2: Verify Initial Tenant Setup

1. After sign-up, you receive email: "Your Microsoft 365 account is ready"
2. Navigate to **Microsoft 365 admin center** → https://admin.microsoft.com
3. Login with admin@organization.onmicrosoft.com
4. Complete MFA setup:
   - Verify phone number via SMS or authenticator app
   - Save backup codes in secure location
5. Verify tenant information:
   - **Settings** → **Organization Settings** → **Organization profile**
   - **Tenant ID** displays (UUID format)
   - **Tenant name**: organization.onmicrosoft.com

**PowerShell Verification:**
```powershell
# Connect to Microsoft 365
Connect-MsolService
# Enter admin@organization.onmicrosoft.com credentials and MFA challenge

# Verify tenant
$TenantDetail = Get-MsolCompanyInformation
Write-Host "Tenant Name: $($TenantDetail.DisplayName)"
Write-Host "Tenant Domain: $($TenantDetail.InitialDomain)"
Write-Host "Tenant ID: $($TenantDetail.ObjectId)"
```

---

## Task 2: Add Custom Domain

### Step 2.1: Verify Domain Ownership

1. In **Microsoft 365 admin center** → **Settings** → **Domains**
2. Click **Add domain**
3. Enter **custom domain**: organization.com
4. Click **Next**
5. Select **Verify with TXT record** (faster than MX verification):
   - DNS provider: Select from list (GoDaddy, Namecheap, CloudFlare, etc.)
   - Or choose **Add this TXT record manually**

6. Copy TXT record provided:
   ```
   Name: @
   Type: TXT
   Value: ms=msxxxxxx
   TTL: 3600 seconds
   ```

7. Log into your domain registrar:
   - Navigate to DNS records
   - Add the TXT record exactly as shown
   - Save changes
   - Wait 15-30 minutes for DNS to propagate

8. Return to Microsoft 365 admin center:
   - Click **Verify** (or **I've added the TXT record**)
   - Microsoft confirms domain ownership
   - Dashboard shows: ✓ Verified

**Validation:**
```powershell
# Test DNS record propagation
nslookup -type=TXT organization.com
# Should show: ms=msxxxxxx in results
```

### Step 2.2: Update MX Record (Mail Routing)

Once domain verified, configure email routing to Microsoft 365:

1. **Domains** → your verified domain → **DNS records**
2. Look for MX record setup instructions:
   - **Type**: MX
   - **Priority**: 0 (highest)
   - **Value**: organization-com.mail.protection.outlook.com

3. Update in domain registrar:
   - Delete old MX record (pointing to Exchange Server, if exists)
   - Add new MX record with Microsoft 365 endpoint
   - Set priority to 0
   - TTL: 3600 seconds

4. Wait for propagation (30 minutes to 24 hours)

**Verification:**
```powershell
# Verify MX record updated
Resolve-DnsName -Name organization.com -Type MX
# Output should show: organization-com.mail.protection.outlook.com
```

### Step 2.3: Add SPF and DKIM Records

**SPF Record** (Sender Policy Framework - prevents spoofing):

1. Add SPF TXT record:
```
Name: @
Type: TXT
Value: v=spf1 include:spf.protection.outlook.com ~all
TTL: 3600
```

**DKIM Records** (DomainKeys Identified Mail - signs emails):

1. In **Microsoft 365 admin center** → **Domains** → organization.com
2. Look for CNAME records for DKIM:
   - **Selector1**: <selector1>._domainkey.organization.com
   - **Selector2**: <selector2>._domainkey.organization.com

3. In domain registrar, add two CNAME records:
```
CNAME: selector1._domainkey.organization.com
Value: selector1-organization-com._domainkey.outlook.com
TTL: 3600

CNAME: selector2._domainkey.organization.com
Value: selector2-organization-com._domainkey.outlook.com
TTL: 3600
```

4. In Microsoft 365 admin center:
   - Go to **Domains** → **Exchange and Outlook** section
   - Toggle DKIM signing: **Enabled**
   - Verify status: ✓ DKIM signing active

**Validation:**
```powershell
# Verify SPF record
Resolve-DnsName -Name organization.com -Type TXT
# Should show: v=spf1 include:spf.protection.outlook.com ~all

# Verify DKIM active
Get-DkimSigningConfig -Identity organization.com
# Should show: Enabled = True
```

---

## Task 3: Create Organization Administrator Account

### Step 3.1: Create Global Administrator Account

1. In **Microsoft 365 admin center** → **Users** → **Active users**
2. Click **+ Add user**
3. Fill in user details:
   - **First name**: First name (e.g., "John")
   - **Last name**: Last name (e.g., "Administrator")
   - **Display name**: "Global Administrator"
   - **Username**: admin (creates: admin@organization.com)
   - **Email**: admin@organization.com (using custom domain)
4. **Password**: 
   - Auto-generate or create strong password (minimum 8 characters)
   - Uncheck: "Make this user change their password when they first logs in"
5. **Roles** → Select **Global administrator**
6. Click **Add**

### Step 3.2: Create Security Administrator Account

1. Repeat above:
   - **Username**: security-admin
   - **Email**: security-admin@organization.com
   - **Role**: Security administrator

### Step 3.3: Create SharePoint Administrator Account

1. Repeat:
   - **Username**: sharepoint-admin
   - **Email**: sharepoint-admin@organization.com
   - **Role**: SharePoint administrator

### Step 3.4: Create Exchange Administrator Account

1. Repeat:
   - **Username**: exchange-admin
   - **Email**: exchange-admin@organization.com
   - **Role**: Exchange administrator

**PowerShell Alternative:**
```powershell
# Create Global Administrator via PowerShell
$AdminPassword = "Str0ngP@ssw0rd!" | ConvertTo-SecureString -AsPlainText -Force

# Create global admin user
New-MsolUser -UserPrincipalName admin@organization.com `
             -DisplayName "Global Administrator" `
             -FirstName "John" `
             -LastName "Administrator" `
             -Password $AdminPassword `
             -ForceChangePassword $false

# Add global administrator role
Add-MsolRoleMember -RoleName "Global Administrator" `
                   -RoleMemberEmailAddress admin@organization.com

# Verify
Get-MsolUser -UserPrincipalName admin@organization.com | Select-Object DisplayName, IsLicensed, Roles
```

---

## Task 4: Configure Multi-Factor Authentication (MFA)

### Step 4.1: Enable MFA for Administrators

1. **Microsoft 365 admin center** → **Settings** → **Security & privacy** → **MFA**
2. Enable **Require multi-factor authentication for admin accounts**:
   - Status: **On** (all admin accounts require MFA)

3. For each administrator account:
   - Go to **Users** → **Active users** → Select user
   - **Authentication settings** → **Manage MFA**
   - Select verification method:
     - SMS (text to phone)
     - Phone call
     - Authenticator app (recommended)
   - User receives setup instructions

### Step 4.2: Set Up Authenticator App (For Admin)

1. Download: Microsoft Authenticator, Google Authenticator, or Authy
2. Launch app → **+ Add account** → **Work or school**
3. Login with admin@organization.com
4. Approve request in app
5. App shows 6-digit code refreshing every 30 seconds

### Step 4.3: Create Backup Codes

1. After MFA setup, generate backup codes:
   - **Manage** → **Backup options**
   - **Generate backup codes**
   - Save codes securely: (printed/encrypted file)
   - Download: "Backup codes.txt" or write down

2. Test using one code (removes it from list)

**PowerShell:**
```powershell
# Force MFA for all administrators
$AdminRole = Get-MsolRole -RoleName "Global Administrator"
$AdminUsers = Get-MsolRoleMember -RoleObjectId $AdminRole.ObjectId

foreach ($User in $AdminUsers) {
    Write-Host "MFA required for: $($User.EmailAddress)"
    # MFA enforcement set in admin center UI
}
```

---

## Task 5: Configure Organization Settings

### Step 5.1: Set Organization Profile

1. **Settings** → **Organization Settings** → **Organization profile**
2. Update:
   - **Organization name**: Contoso Inc. (full legal name)
   - **Address**: 123 Main Street, Toronto, Ontario M5V 3A9, Canada
   - **Phone**: +1-416-555-1234
   - **Technical contact email**: admin@organization.com
   - **Preferred language**: English
   - **Website**: www.organization.com

3. Click **Save**

### Step 5.2: Configure Release Preferences

1. **Settings** → **Organization Settings** → **Release preferences**
2. Choose feature rollout schedule:
   - **Targeted release**: New features to selected users first
   - **Standard release**: Normal Microsoft 365 release schedule
   - Select: **Standard release** (for stability in production)

### Step 5.3: Configure Contact Information

1. **Settings** → **Organization settings** → **Contact preferences**
2. Set email preferences:
   - **Send me information about new Microsoft 365 features**: Enable
   - **Send me service health information**: Enable
   - **Send me information about Microsoft 365 plans and products**: Disable (optional)

---

## Task 6: Set Up Organizational Branding

### Step 6.1: Configure Azure AD Branding

1. Go to **Microsoft Entra admin center** → https://entra.microsoft.com
2. Select **Branding and properties**
3. Upload logo and colors:
   - **Logo**: Company logo (PNG, JPG, 200x50 pixels)
   - **Banner background color**: #0078D4 (Microsoft blue)
   - **Text color**: #000000 (black)
   - **Sign-in page background image**: Optional (1200x1055 px)

4. **Localization** (optional):
   - Set language-specific branding
   - Add text for each language

5. Click **Save**

### Step 6.2: Configure Microsoft 365 Theme

1. **Settings** → **Themes**
2. Select or create custom theme:
   - **Primary color**: #0078D4 (Microsoft Blue)
   - **Logo**: Company logo
   - **Logo alternate text**: "Contoso Inc."
   - **Nav bar color**: #105C3E (dark green)
3. Click **Save**

### Step 6.3: Customize Sign-In Page

1. In **Entra Admin Center** → **Branding and properties** → **Customize sign-in experience**
2. Set:
   - **Custom header logo**: Company logo
   - **Sign-in page background**: Company background image
   - **Square logo light** and **Square logo dark**: For different backgrounds
   - **Text**: "Welcome to Contoso Inc."

---

## Task 7: Configure Security Policies

### Step 7.1: Enable Security Defaults

1. **Settings** → **Security & privacy** → **Azure Entra ID**
2. Select **Properties** → **Manage security defaults**
3. Enable:
   - ✓ Security defaults enabled
   - Forces MFA for all users
   - Blocks legacy authentication
   - Requires admins to use MFA

### Step 7.2: Configure Password Policy

1. **Settings** → **Security & privacy** → **Password policy**
2. Set:
   - **Password expiration**: 90 days
   - **Password complexity**: Required (uppercase, lowercase, number, symbol)
   - **Password length**: Minimum 8 characters
   - **Password history**: Last 5 passwords prevented from reuse

3. Click **Save**

### Step 7.3: Configure Session Timeout

1. **Settings** → **Security & privacy** → **Session timeout**
2. Set:
   - **Inactivity timeout**: 30 minutes (web)
   - **Remember sign-in on trusted device**: Optional (user choice)

---

## Task 8: Set Up Directory Synchronization (Hybrid)

### Step 8.1: Install Azure AD Connect

*Skip if cloud-only organization. Use if hybrid with on-premises AD.*

1. Download: https://www.microsoft.com/download/details.aspx?id=47594
2. Run installer: AzureADConnect.msi
3. **Express Settings**:
   - Accept license terms
   - Choose: **Express Settings** (recommended)
   - Connect to on-premises AD
   - Sync users and groups

4. **Advanced Settings** (if needed):
   - Custom sync rules
   - Password hash sync vs pass-through authentication
   - Enable device writeback

5. Start sync:
   - Click **Start the synchronization process when configuration completes**
   - First sync may take 15-30 minutes

**PowerShell Verification:**
```powershell
# After sync completes, verify in cloud
Connect-MsolService

# Check synced users
Get-MsolUser -All | Select-Object DisplayName, UserPrincipalName, DirSyncProvisioningErrors

# Verify no sync errors
Get-MsolDirSyncProvisioningError | Select-Object UserPrincipalName, ErrorCategory
```

---

## Task 9: Validation and Testing

### Step 9.1: Test Tenant Access

1. Sign out from admin@organization.onmicrosoft.com
2. Navigate to **https://office.com**
3. Login with admin@organization.com (custom domain)
4. Verify access to:
   - Outlook Web App
   - SharePoint Online
   - OneDrive
   - Teams
   - Admin Center

### Step 9.2: Test MFA

1. Logout completely from browser
2. Navigate to https://admin.microsoft.com
3. Enter email: admin@organization.com
4. Enter password
5. MFA challenge appears (SMS, call, or app code)
6. Enter MFA code
7. Successfully logged in

### Step 9.3: Verify Domain Configuration

```powershell
# Test DNS records
Resolve-DnsName -Name organization.com -Type MX
Resolve-DnsName -Name organization.com -Type SPF
Get-DkimSigningConfig -Identity organization.com

# Verify email routing
Test-EmailAddress -EmailAddress admin@organization.com
# Should show Message Center updated to use exchange online
```

---

## Validation Checklist

- [ ] Microsoft 365 tenant created successfully
- [ ] Custom domain added and verified
- [ ] MX records updated for email routing
- [ ] SPF and DKIM records configured
- [ ] Global administrator account created
- [ ] Security, SharePoint, and Exchange admins created
- [ ] MFA enabled for all administrators
- [ ] Organization profile updated
- [ ] Company branding applied
- [ ] Security defaults enabled
- [ ] Password policies configured
- [ ] Users can access Microsoft 365 apps
- [ ] Email routing to tenant working
- [ ] Admin can access all services

---

## Common Issues & Troubleshooting

| Issue | Cause | Solution |
|-------|-------|----------|
| Domain verification fails | TXT record not added to DNS | Wait 15-30 min for DNS propagation, verify exact TXT value |
| Email not arriving after MX update | MX record priority incorrect | Set priority to 0 (highest), verify old MX removed |
| MFA login failing | Phone number not verified | Use backup codes instead, update phone in settings |
| Users can't access tenant | Email not in directory | Add users via Users → Active users in admin center |
| Password reset not working | Azure AD not synced | If hybrid, check Azure AD Connect is running, run full sync |
| Admin can't access Exchange | Role not assigned | Verify user has "Exchange Administrator" role in admin center |

---

## Next Steps

1. Complete tenant setup verification
2. Proceed to Phase 1 Task bulk user provisioning (create-users.ps1)
3. Configure Exchange Online (exchange-online.md)
4. Configure Defender security (defender-security.md)
5. Configure SharePoint branding (sharepoint-branding.md)
6. Complete Phase 1 licensing assignment (licensing-e3-e5.md)
7. Move to Phase 2: Security Compliance and DLP
