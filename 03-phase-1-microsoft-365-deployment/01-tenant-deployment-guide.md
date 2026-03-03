# Phase 1: Microsoft 365 Tenant Deployment and Configuration

## Phase Overview

This phase establishes the Microsoft 365 tenant as the foundation for cloud services, security, and collaboration. The focus is on deploying a secure tenant configuration with proper licensing, bulk user provisioning, security baselines, and organizational group structure.

**Duration**: 2 weeks  
**Key Objectives**: Tenant setup, security baseline configuration, bulk user import, licensing assignment, M365 group creation

---

## Pre-Implementation Checklist

- [ ] Azure subscription created and active
- [ ] Microsoft 365 E3/E5 tenant license purchased
- [ ] Organizational domain registered and verified (e.g., organization.onmicrosoft.com)
- [ ] Administrator mailbox created with MFA-approved device
- [ ] CSV file prepared with 10+ user records (UPN, email, first name, last name, department, job title)
- [ ] Stakeholder communication plan established
- [ ] Success criteria and validation procedures reviewed

---

## Task 1: Create and Configure Microsoft 365 Tenant

### Step 1.1: Access Microsoft 365 Admin Center

1. Navigate to https://admin.microsoft.com
2. Sign in with global administrator credentials (MFA-protected account)
3. Complete MFA challenge using approved device
4. Verify you're in the correct tenant (display name shown in top right)

**Validation:**
- Access confirmed with no permission errors
- MFA successfully completed
- Tenant name displayed correctly

### Step 1.2: Configure Organization Information

1. Go to **Settings** → **Organization Settings**
2. Click **Organization Profile**
3. Update the following fields:
   - **Organization Name**: Your organization name (e.g., "Contoso Corporation")
   - **Address**: Full organizational headquarters address
   - **Phone**: Main organizational contact number
   - **Technical Contact Email**: Security team email for Microsoft notifications
   - **Preferred Language**: Organization's primary language
4. Click **Save**

**Command (PowerShell alternative):**
```powershell
Connect-MsolService
Get-MsolCompanyInformation | Select-Object DisplayName, PhoneNumber, Address
Set-MsolCompanyInformation -PhoneNumber "+1-555-123-4567" -Street "123 Main St" -City "Anytown" -State "CA" -PostalCode "12345"
```

**Validation:**
- Organization profile updated without errors
- Changes visible in tenant settings after page refresh

### Step 1.3: Enable Security Defaults

1. Navigate to **Settings** → **Security & Privacy** → **Azure Entra ID** (or visit https://entra.microsoft.com)
2. Select **Properties** → **Authentication methods**
3. Click **All Users** to enable security defaults
4. Confirm MFA requirement for all users
5. Enable legacy authentication blocking
6. Click **Save**

**Validation:**
- Security defaults status shows "Enabled"
- Legacy authentication blocked (SMTP, POP without Modern Auth rejected)
- MFA prompts appear when authentication required

### Step 1.4: Configure Password Policy

1. Go to **Settings** → **Security & Privacy** → **Password Policy**
2. Set parameters:
   - **Password Expiration Days**: 90 days (enterprise standard)
   - **Password Length**: Minimum 8 characters
   - **Password Complexity**: Enabled (require uppercase, lowercase, numbers, symbols)
   - **Password History**: Prevent reuse of last 5 passwords
3. Click **Save**

**Validation:**
- Policy applied without errors
- Test user password change enforces new policy requirements

---

## Task 2: Configure Licensing Strategy

### Step 2.1: Understand Licensing Tiers

**Microsoft 365 E3:**
- Exchange Online (50 GB mailbox)
- SharePoint Online (1 TB per user)
- Microsoft Teams
- OneDrive for Business (1 TB)
- Office web apps
- Standard DLP policies
- Basic compliance features

**Microsoft 365 E5 (Recommended for this implementation):**
- Everything in E3, plus:
- Advanced threat protection (Defender for Office 365)
- Advanced analytics (attack simulator)
- Insider risk management
- Advanced DLP with fingerprinting
- Advanced eDiscovery
- Microsoft Information Protection
- Privileged Access Management

For this hybrid implementation, **E5 is recommended** for comprehensive threat protection and compliance features.

### Step 2.2: Assign Licenses via Admin Center

1. Go to **Billing** → **Licenses**
2. Select **Microsoft 365 E5** license
3. Click **Assign Licenses**
4. Select users to receive licenses (initially, assign to at least 10 test users)
5. Confirm assignment
6. Click **Assign**

**Expected Outcome:**
- Selected users now have E5 licenses
- License count decreases in available pool
- Users receive welcome email with M365 access instructions

**PowerShell Alternative (Bulk Assignment):**
```powershell
# Connect to Microsoft 365
Connect-MsolService

# Get all users not yet licensed
$unlicensedUsers = Get-MsolUser -All | Where-Object {$_.IsLicensed -eq $false}

# Assign E5 license (set-msoluser command)
foreach ($user in $unlicensedUsers) {
    Set-MsolUserLicense -UserPrincipalName $user.UserPrincipalName -AddLicenses "organization:ENTERPRISEPREMIUM"
}

# Verify licensing
Get-MsolUser -All | Where-Object {$_.IsLicensed -eq $true} | Measure-Object
```

**Validation:**
- All target users show "Microsoft 365 E5" in their license details
- License count matches assignment
- Users can access M365 services (Outlook, Teams, SharePoint)

---

## Task 3: Bulk Import Users via CSV

### Step 3.1: Prepare CSV File

Create a CSV file with the following columns:

```csv
FirstName,LastName,DisplayName,JobTitle,Department,Office,MobilePhone,Email
John,Smith,John Smith,Senior Cloud Architect,IT,New York,555-1234,john.smith@organization.onmicrosoft.com
Jane,Doe,Jane Doe,Microsoft 365 Administrator,IT,New York,555-5678,jane.doe@organization.onmicrosoft.com
Robert,Johnson,Robert Johnson,Security Engineer,IT,Boston,555-9012,robert.johnson@organization.onmicrosoft.com
Sarah,Williams,Sarah Williams,HR Manager,HR,New York,555-3456,sarah.williams@organization.onmicrosoft.com
Michael,Brown,Michael Brown,Finance Director,Finance,Chicago,555-7890,michael.brown@organization.onmicrosoft.com
Emily,Davis,Emily Davis,Operations Manager,Operations,Los Angeles,555-2345,emily.davis@organization.onmicrosoft.com
David,Miller,David Miller,Marketing Lead,Marketing,New York,555-6789,david.miller@organization.onmicrosoft.com
Lisa,Wilson,Lisa Wilson,IT Support Specialist,IT,Boston,555-0123,lisa.wilson@organization.onmicrosoft.com
James,Moore,James Moore,Compliance Officer,Security,New York,555-4567,james.moore@organization.onmicrosoft.com
Patricia,Taylor,Patricia Taylor,Database Administrator,IT,Chicago,555-8901,patricia.taylor@organization.onmicrosoft.com
```

**Important Notes:**
- Email (UPN) must be unique and end with your organization's domain
- FirstName and LastName are required; others are optional
- Save as UTF-8 encoding to support special characters
- Maximum 30,000 users per import

### Step 3.2: Perform Bulk Import

1. Go to **Users** → **Active Users**
2. Click **Bulk Import** (or **Bulk add users** depending on blade)
3. Download the CSV template or use your prepared file
4. Click **Upload CSV file** and select your prepared file
5. Click **Submit**
6. Monitor progress - import typically completes within 5-10 minutes
7. Review import results - confirm all users imported successfully

**Alternative: PowerShell Bulk Import**

```powershell
# Install required modules
Install-Module -Name MSOnline
Install-Module -Name AzureAD

# Connect to Microsoft 365
Connect-MsolService
Connect-AzureAD

# Import CSV and create users
$userCSV = Import-Csv -Path "C:\Users\bulk_users.csv"

foreach ($user in $userCSV) {
    # Create password
    $password = ConvertTo-SecureString -String "TempPassword123!@#" -AsPlainText -Force
    
    # Create new user
    New-MsolUser -UserPrincipalName $user.Email `
                 -DisplayName $user.DisplayName `
                 -FirstName $user.FirstName `
                 -LastName $user.LastName `
                 -Department $user.Department `
                 -Office $user.Office `
                 -MobilePhone $user.MobilePhone `
                 -Password $password `
                 -PasswordNeverExpires $false `
                 -ForceChangePassword $true
}
```

**Validation:**
- All users appear in Active Users list
- User count in tenant matches import amount
- Each user has correct department and job title
- All users have E5 license assigned automatically

### Step 3.3: Force Password Change at First Login

Users created via bulk import should change their temporary password at first login:

1. In Admin Center, select each new user
2. Ensure **Password** status shows "Change password at next sign-in"
3. Send users a welcome email with instructions to access Microsoft 365
4. Users will be prompted to change password upon first authentication

---

## Task 4: Configure User Profiles

### Step 4.1: Add Profile Pictures

Profile pictures improve user experience and help with visual identification in teams and meetings.

**Via Admin Center:**
1. Go to **Users** → **Active Users**
2. Select a user
3. Click the profile picture placeholder
4. Upload image (JPG, PNG - maximum 4 MB)
5. Crop if needed and click **Save**

**Via PowerShell**:
```powershell
# Upload profile photo from file
Set-UserPhoto -Identity john.smith@organization.onmicrosoft.com -PictureUrl "C:\path\to\photo.jpg"

# Verify upload
Get-UserPhoto -Identity john.smith@organization.onmicrosoft.com | Select-Object Identity
```

### Step 4.2: Update User Profile Attributes

Complete organizational profile attributes for all users:

**In Admin Center:**
1. Select user
2. Click **Personal Info** tab
3. Update:
   - Job title (already set but can refine)
   - Department (already set)
   - Office location
   - Phone number
   - Mobile phone
   - Manager (select from organization list - ties to organizational hierarchy)
   - Direct reports (auto-populated based on manager assignment)
4. Click **Save**

**Via PowerShell**:
```powershell
# Update single user
Set-MsolUser -UserPrincipalName john.smith@organization.onmicrosoft.com `
             -Office "New York - 5th Floor" `
             -Title "Senior Cloud Architect" `
             -Department "Information Technology"

# Sync to Azure AD
Connect-AzureAD
Set-AzureADUser -ObjectId john.smith@organization.onmicrosoft.com `
                -JobTitle "Senior Cloud Architect" `
                -Department "Information Technology"
```

**Validation:**
- Profile attributes visible in GAL (Global Address List)
- Manager/direct report relationships correctly established
- Profile pictures display in Outlook, Teams, SharePoint

---

## Task 5: Create Microsoft 365 Groups

### Step 5.1: Create Department Groups

Create security-enabled groups for each department. These will be used for access control to SharePoint sites, Teams, and file shares.

**Groups to Create:**
1. IT Department
2. HR Department
3. Operations Department
4. Marketing Department
5. Finance Department

**Via Admin Center:**

1. Go to **Teams & Groups** → **Active Teams & Groups**
2. Click **Add a Group**
3. Select **Group Type**: "Microsoft 365"
4. Fill in details:
   - **Group Name**: "IT Department"
   - **Group Email Address**: it-department@organization.onmicrosoft.com
   - **Privacy**: "Private" (only members can see content)
   - **Description**: "IT department team collaboration space"
5. Click **Next**
6. Add members:
   - Select 3-4 users from IT department
   - Designate 1 as group owner
7. Click **Create Group**

**Via PowerShell**:
```powershell
# Connect to Teams PowerShell
Connect-MicrosoftTeams

# Create IT Department Group
New-Team -DisplayName "IT Department" `
         -MailNickname "itdepartment" `
         -Description "IT department team collaboration space" `
         -Visibility "Private" `
         -Owner "john.smith@organization.onmicrosoft.com"

# Add members to group
Add-TeamUser -GroupId $(Get-Team -DisplayName "IT Department").GroupId `
             -User jane.doe@organization.onmicrosoft.com `
             -Role Member

Add-TeamUser -GroupId $(Get-Team -DisplayName "IT Department").GroupId `
             -User lisa.wilson@organization.onmicrosoft.com `
             -Role Member
```

### Step 5.2: Assign Uses to Groups

Assign users to appropriate department groups:

**Assignment Matrix:**
| User | IT | HR | Operations | Marketing | Finance |
|------|----|----|-----------|-----------|---------|
| John Smith | Owner | | | | |
| Jane Doe | Member | | | | |
| Robert Johnson | Member | | | | |
| Sarah Williams | | Owner | | | |
| Michael Brown | | | | | Owner |
| Emily Davis | | | Owner | | |
| David Miller | | | | Owner | |
| Lisa Wilson | Member | | | | |
| James Moore | Member | | | | |
| Patricia Taylor | Member | | | | |

---

## Task 6: Configure Secure Score Baseline

### Step 6.1: Review Current Secure Score

1. Navigate to **Security** → **Secure Score** (or go to https://securescore.microsoft.com)
2. Review current score (typically 0-30% for new tenant)
3. Review **Recommended Actions** prioritized by impact
4. Identify top 5-10 highest-impact improvements

**Typical Recommended Actions:**
- Enable MFA for all users (high impact)
- Configure DLP policies (high impact)
- Enable Safe Links and Safe Attachments (high impact)
- Configure Conditional Access (high impact)
- Enable audit logging (medium impact)

### Step 6.2: Implement Quick Wins

**Action 1: Enable Multi-Factor Authentication**
1. Go to **Settings** → **Azure AD** → **MFA**
2. Enable MFA for all users (all users or targeted roll-out)
3. Increase Secure Score

**Action 2: Enable Audit Logging**
1. Go to **Settings** → **Org Settings** → **Search & Intelligence**
2. Enable "Audit"
3. This enables unified audit logging (automatically enabled in most tenants)

**Action 3: Ensure Modern Authentication**
1. Already configured with security defaults
2. Confirm legacy protocols disabled

**Monitoring Secure Score:**
- Target: 40-50% after Phase 1
- Target: 60-70% after Phase 2 (security configuration)
- Target: 70%+ after all phases complete

---

## Validation Checklist

- [ ] Tenant created and accessible via admin.microsoft.com
- [ ] Security defaults enabled
- [ ] Password policy configured (90 days, complexity enabled)
- [ ] 10+ users imported and verified in Active Users
- [ ] All users assigned E5 licenses
- [ ] User profiles updated with job titles, departments, photos
- [ ] 5 department groups created with appropriate membership
- [ ] Secure Score baseline documented (expected 25-35%)
- [ ] Welcome emails sent to all new users
- [ ] Users can access Outlook, Teams, and SharePoint

---

## Common Issues & Troubleshooting

**Issue**: Users cannot access M365 services after bulk import
- **Cause**: License not assigned or user not synced
- **Solution**: Verify license assignment, wait 15 minutes for sync, reset user password

**Issue**: Bulk import fails with "Invalid email format"
- **Cause**: Email addresses don't match organization domain
- **Solution**: Ensure all emails end with organization's domain (organization.onmicrosoft.com first, then custom domain after verification)

**Issue**: Profile pictures not displaying in Teams
- **Cause**: Photo upload failed or permissions issue
- **Solution**: Re-upload image, ensure file <4MB, use JPG or PNG format

**Issue**: Group members can't access group resources
- **Cause**: Owner not properly assigned or permission inheritance issue
- **Solution**: Re-add user to group, verify owner has necessary permissions

---

## Next Steps

1. Document actual configuration values for reference
2. Test user access to all M365 services
3. Proceed to Phase 2: Security & Compliance configuration
4. Begin preparing for Phase 5: Hybrid Identity (Azure AD Connect setup)

---

*Phase 1 Completion Date: ___________*
*Completed By: ___________*
*Validated By: ___________*

*Document Version: 1.0*
*Last Updated: March 2, 2026*
