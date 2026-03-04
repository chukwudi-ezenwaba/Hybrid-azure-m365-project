# SharePoint Online and Branding Configuration

## Overview

SharePoint Online serves as the platform for collaborative document management, team sites, and organizational content. This guide covers site provisioning, branding, permissions management, and organizational portal setup.

**Duration**: 2-3 days  
**Requires**: Global Administrator or SharePoint Administrator role  
**Depends On**: Microsoft 365 tenant created, users synchronized

---

## Pre-Configuration Checklist

- [ ] Microsoft 365 tenant created with SharePoint Online
- [ ] Users created and mailboxes provisioned
- [ ] Company branding assets prepared (logo, color scheme, fonts)
- [ ] Site structure and governance policies defined
- [ ] Global administrator credentials with MFA
- [ ] SharePoint admin permissions assigned
- [ ] Company website (intranet) domain created or migrated

---

## Task 1: Access SharePoint Admin Center

### Step 1.1: Navigate to SharePoint Admin Center

1. Go to **Microsoft 365 admin center** → https://admin.microsoft.com
2. Select **Admin centers** → **SharePoint**
3. Or direct URL: https://admin.sharepoint.com
4. Sign in with Global Administrator or SharePoint Administrator credentials
5. Verify dashboard displays:
   - Active site collections
   - Storage utilization
   - Shared links and access requests

**PowerShell Access:**
```powershell
# Install SharePoint Online Management Shell
Install-Module -Name Microsoft.Online.SharePointOnline.PowerShell -Force
Import-Module Microsoft.Online.SharePointOnline.PowerShell

# Connect to SharePoint Admin Center
$AdminSiteURL = "https://organization-admin.sharepoint.com"
Connect-SPOService -Url $AdminSiteURL

# Verify connection
Get-SPOTenant | Select-Object DisplayName, StorageQuota, Owner
```

### Step 1.2: Verify SharePoint Storage Quota

1. In **SharePoint admin center** → **Settings**
2. Verify:
   - **Default storage quota per site**: 100 GB (minimum)
   - **StorageQuota for teams**: 1 TB recommended
   - **Auto-scaling**: Enabled (allows sites to scale beyond quota if available)

**Validation:**
```powershell
# Check storage quota settings
Get-SPOTenant | Select-Object StorageQuotaGB, DefaultSiteStorageQuotaGB

# List all sites and storage usage
Get-SPOSite -Limit All | Select-Object Url, StorageUsagCurrent, StorageQuotaGB | Format-Table
```

---

## Task 2: Configure Organizational Portal (Intranet)

### Step 2.1: Create Communication Site

1. In **SharePoint admin center**, go to **Active sites**
2. Click **+ Create** → **Communication site**
3. Configure:
   - **Site name**: "Contoso Intranet"
   - **Site address**: https://organization.sharepoint.com/sites/intranet
   - **Language**: English
   - **Design template**: Topic (recommended for intranet)

4. Click **Next** → **Finish**

### Step 2.2: Apply Organizational Branding

#### Set Organization Logo

1. In the intranet site, click **Settings** (gear icon)
2. Select **Site information** → **Site details**
3. Upload company logo:
   - **Logo**: Company PNG/JPG file (200x100 px recommended)
   - **Logo description**: "Contoso Inc. Logo"
4. Click **Save**

#### Apply Company Colors and Theme

1. **Settings** → **Design** → **Themes**
2. Select theme matching company colors:
   - Default themes: Blue, Teal, Red, Green, Orange
   - Or create custom theme with hex color codes

3. Custom theme example:
   ```
   Primary color: #0078D4 (Microsoft Blue)
   Secondary color: #50E6FF (Light Blue)
   Tertiary color: #005A9E (Dark Blue)
   Neutral colors: #F5F5F5 (Light Gray)
   ```

#### Configure Site Header

1. **Settings** → **Design** → **Site header**
2. Configure:
   - **Header background**: Company color
   - **Logo location**: Left (default)
   - **Site title font**: Size 28pt, Bold
   - **Navigation bar color**: Matching header

#### Add Organizational Footer

1. **Settings** → **Site pages** → **Footer**
2. Add footer content:
   ```
   Copyright © 2024 Contoso Inc. All rights reserved.
   Privacy Policy | Terms of Use | Accessibility | Contact IT
   [Company Logo]
   ```

**PowerShell Configuration:**
```powershell
# Set organization logo
$LogoUrl = "https://organization.sharepoint.com/sites/intranet/logo.png"
Set-SPOSiteGroup -Identity "Contoso Intranet" -Logo $LogoUrl

# Configure theme colors
$ThemeColors = @{
    "Shade0"= "#ffffff"  # White
    "Shade1"= "#f5f5f5"  # Light Gray
    "Shade2"= "#e0e0e0"  # Medium Gray
    "Shade3"= "#0078D4"  # Primary Blue
    "Shade4"= "#50E6FF"  # Accent Blue
    "Shade5"= "#005A9E"  # Dark Blue
    "Shade6"= "#004B50"  # Dark Teal
}
# Apply through UI (PowerShell theme APIs limited)
```

---

## Task 3: Create Team and Department SharePoint Sites

### Step 3.1: Create IT Department Site

1. **SharePoint admin center** → **+ Create** → **Team site**
2. Configure:
   - **Site name**: "IT Department"
   - **Site address**: https://organization.sharepoint.com/sites/it-department
   - **Owner**: IT Manager (user@organization.com)
   - **Owners**: IT Manager email
   - **Description**: "Collaboration and resource repository for IT team"
   - **Privacy**: Private (members only)

### Step 3.2: Create HR Department Site

1. Repeat site creation:
   - **Site name**: "HR Department"
   - **Site address**: https://organization.sharepoint.com/sites/hr-department
   - **Owner**: HR Manager
   - **Privacy**: Private

### Step 3.3: Create Finance Department Site

1. Repeat site creation:
   - **Site name**: "Finance Department"
   - **Site address**: https://organization.sharepoint.com/sites/finance-department
   - **Owner**: Finance Manager
   - **Privacy**: Private

### Step 3.4: Create Operations Department Site

1. Repeat site creation:
   - **Site name**: "Operations Department"
   - **Site address**: https://organization.sharepoint.com/sites/operations-department
   - **Owner**: Operations Manager
   - **Privacy**: Private

**PowerShell Configuration:**
```powershell
# Create team sites programmatically
$Sites = @(
    @{Name="IT Department"; Url="it-department"; Owner="it-manager@organization.com"},
    @{Name="HR Department"; Url="hr-department"; Owner="hr-manager@organization.com"},
    @{Name="Finance Department"; Url="finance-department"; Owner="finance-manager@organization.com"},
    @{Name="Operations Department"; Url="operations-department"; Owner="ops-manager@organization.com"}
)

foreach ($Site in $Sites) {
    New-SPOSite -Url "https://organization.sharepoint.com/sites/$($Site.Url)" `
                -Owner $Site.Owner `
                -StorageQuota 1000 `
                -CompatibilityLevel 2021 `
                -Title $Site.Name
}
```

---

## Task 4: Configure Site Collections and Document Libraries

### Step 4.1: Create Document Libraries

For **IT Department** site, create libraries:

1. **Policies and Procedures**
   - Purpose: IT governance documents
   - Retention: 7 years
   - Content types: Policy, Procedure, Standard

2. **Project Documentation**
   - Purpose: Project plans, status, deliverables
   - Retention: Per project (typically 2 years post-completion)
   - Content types: Project Plan, Status Report, Deliverable

3. **Asset Inventory**
   - Purpose: Hardware/software inventory
   - Retention: 3 years
   - Content types: Hardware List, License Registry, URL List

**Steps to Create:**
1. In site → **Site contents**
2. Click **+ New** → **Document library**
3. Configure:
   - **Name**: "Policies and Procedures"
   - **Description**: "IT governance and procedures"
   - **Advanced settings**: Versioning On, Retention On
4. Click **Create**

**PowerShell:**
```powershell
# Create document libraries
$SiteUrl = "https://organization.sharepoint.com/sites/it-department"

# Connect to site
Connect-PnPOnline -Url $SiteUrl -Interactive

# Create Policies library
New-PnPList -Title "Policies and Procedures" `
            -Template DocumentLibrary `
            -Url "Policies-Procedures" `
            -Description "IT governance documents"

# Enable versioning on library
Set-PnPList -Identity "Policies and Procedures" -EnableVersioning $true

# Set retention policy
Set-PnPListItemRetentionEnforced -List "Policies and Procedures" `
                                 -RetentionDays 2555 `
                                 -Action MoveToRecycleBin
```

### Step 4.2: Configure Document Metadata and Columns

For each library, add custom columns for organization:

**IT Department - Asset Library Columns:**
```
1. Asset Type (Dropdown): Computer, Network Device, Software License, Other
2. Asset Location (Text): New York, Toronto, Remote
3. Owner (Person): Assigned staff member
4. Acquisition Date (Date): When asset acquired
5. Warranty Expiry (Date): Maintenance schedule
6. Cost Center (Dropdown): IT, Operations, Finance, HR
7. Criticality (Dropdown): Critical, High, Medium, Low
```

**Steps:**
1. Site → **Document library** → **Settings** (gear)
2. → **Create column**
3. Enter **Column name**: "Asset Type"
4. Select **Column type**: Choice
5. Enter choices: Computer, Network Device, Software License, Other
6. Click **Save**

Repeat for other columns.

**PowerShell:**
```powershell
# Add metadata columns
$Fields = @(
    @{Name="Asset Type"; Type="Choice"; Choices=@("Computer","Network Device","Software License","Other")},
    @{Name="Asset Location"; Type="Text"},
    @{Name="Owner"; Type="User"},
    @{Name="Acquisition Date"; Type="DateTime"},
    @{Name="Warranty Expiry"; Type="DateTime"},
    @{Name="Cost Center"; Type="Choice"; Choices=@("IT","Operations","Finance","HR")}
)

foreach ($Field in $Fields) {
    Add-PnPField -List "Asset Inventory" -DisplayName $Field.Name -FieldType $Field.Type
}
```

---

## Task 5: Configure Permissions and Access Control

### Step 5.1: Set Site Permissions

**IT Department Site - Permission Matrix:**

| Role | Permissions | Users |
|------|------------|-------|
| **Owner** | Full Control, Add/Remove members | IT Manager (john.doe@organization.com) |
| **Member** | Contribute, Edit documents | IT Staff (5 people) |
| **Visitor** | Read-only, View documents | Other departments (for reference) |

**Steps:**
1. Site → **Settings** → **Site members**
2. Click **+ Invite people**
3. Enter **Names/Emails**: John Doe (IT Manager)
4. Select **Permission Level**: Full Control (Owner)
5. Click **Share**

6. Repeat for IT Staff:
   - Names: All IT team members
   - Permission Level: Edit (Contributor)

7. Repeat for Visitors:
   - Department managers
   - Permission Level: View Only (Visitor)

### Step 5.2: Configure Advanced Sharing Settings

1. **Site** → **Settings** → **Access and sharing**
2. Configure:
   - **Sharing**: "Existing guests and members" (most restrictive)
   - **External sharing**: Disabled (prevent external access unless needed)
   - **Advanced sharing options**: Disable "Allow any authenticated user" option
   - **Unshare links**: Auto-disable sharing links after 30 days

**PowerShell:**
```powershell
# Set site sharing permissions
Set-PnPSite -Identity $SiteUrl `
            -ShowPeoplePickerSuggestionsForGuestUsers $false `
            -DefaultLinkPermission View `
            -DefaultLinkType Internal `
            -DefaultSharingLinkExpiration 30

# Restrict external sharing
Set-SPOSite -Identity $SiteUrl `
            -CommentingRestrictions Restricted `
            -SocialBarOnSitePagesEnabled $false `
            -DefaultLinkToExistingAccess $true
```

### Step 5.3: Prevent Accidental Data Loss via Versioning

1. Document library → **Settings** → **Versioning settings**
2. Configure:
   - **Create major and minor versions**: Major only
   - **Keep draft versions**: Last 10 versions
   - **Require Check Out**: Yes (ensures audit trail)

**PowerShell:**
```powershell
# Set versioning policy
Set-PnPList -Identity "Policies and Procedures" `
            -EnableVersioning $true `
            -MajorVersions 10 `
            -MajorWithMinorVersions 0 `
            -EnableMinorVersions $false
```

---

## Task 6: Configure Content Type Management

### Step 6.1: Create Custom Content Types

Custom content types enforce consistent document structure and metadata.

**Create "Policy" Content Type:**
1. Site → **Settings** → **Site content types**
2. Click **+ Create**
3. **Name**: "Policy"
4. **Description**: "Official organizational policy documents"
5. **Content Type**: Document
6. Click **Next**

7. **Add columns**:
   - Policy ID (Text)
   - Effective Date (Date)
   - Review Date (Date)
   - Owner (Person)
   - Status (Choice): Draft, Approved, Active, Superseded

8. Click **Create**

### Step 6.2: Create Information Management Policy

1. **Site** → **Settings** → **Information management policy**
2. For "Policy" content type:
   - **Retention**: Keep for 10 years, then delete
   - **Auditing**: Monitor edits, access
   - **Barcodes**: Generate barcode for each version
   - **Labels**: Print date, author, status code

**PowerShell:**
```powershell
# Create retention schedule
Set-PnPContentType -Identity "Policy" `
                   -UpdateChildren $true `
                   -RetentionTime 3650 `
                   -RetentionAction Delete
```

---

## Task 7: Enable Search and Discovery

### Step 7.1: Configure Search Schema

1. **SharePoint admin center** → **Settings** → **Search Settings**
2. Verify:
   - **Search Center URL**: Configured to main search site
   - **Scoped Search Center**: Optional (for specific site searching)
   - **Delegated Search Center**: Disabled (unless using external search)

### Step 7.2: Configure Managed Properties

Managed properties enable advanced searching and filtering:

```
Property Name: AssetType
Source: Crawled property "ows_Asset_x0020_Type"
Type: Text
Searchable: Yes
Queryable: Yes
Retrievable: Yes

Property Name: AssetLocation
Source: Crawled property "ows_Asset_x0020_Location"
Type: Text
Retrievable: Yes

Property Name: CostCenter
Source: Crawled property "ows_Cost_x0020_Center"
Type: Text
Refinable: Yes
```

**PowerShell - Index Content:**
```powershell
# Request full search re-index of site
$Site = Get-SPOSite -Identity "https://organization.sharepoint.com/sites/it-department"
Request-SPOSiteImmediateIndexing -Url $Site.Url
```

---

## Task 8: Configure Mobile Access and Sync

### Step 8.1: Enable OneDrive Sync

1. Each user automatically gets **OneDrive for Business** (1 TB)
2. Users can sync SharePoint document libraries to desktop:
   - Click **Sync** button on document library
   - Select folder to sync locally
   - Files auto-sync between desktop and cloud

### Step 8.2: Configure Mobile Apps

1. Users install **SharePoint mobile app** (iOS/Android)
2. Login with credentials: user@organization.com
3. Access all sites and document libraries on mobile

### Step 8.3: Configure Offline Access

1. Document library → **Open in app** → **Sync to mobile**
2. Enables offline access to documents
3. Changes sync when device reconnects to internet

---

## Task 9: Implement Information Governance

### Step 9.1: Configure Retention Labels

1. **Microsoft 365 Compliance Center** → **Information governance** → **Retention**
2. Create retention label:
   - **Name**: "Active Policy"
   - **Retention period**: 10 years
   - **Action**: Delete (after 10 years, auto-delete)
   - **Record labeling**: Optional

3. Publish label:
   - **Publishing locations**: Selected sites
   - **Allow users to apply**: Yes (users manually apply)

**Steps to Apply:**
1. Document → **Edit** → **Info** panel
2. Select **Apply label** → "Active Policy"
3. Label applied; retention period starts

**PowerShell:**
```powershell
# Create retention label
New-RetentionLabel -Name "Active Policy" `
                   -Retention Enabled `
                   -RetentionDays 3650 `
                   -RetentionType Delete `
                   -IsRecordLabel $false

# Publish label
New-RetentionLabelPolicy -Name "Policy Retention Labels" `
                         -RetentionLabel "Active Policy" `
                         -Locations @("https://organization.sharepoint.com/sites/it-department")
```

### Step 9.2: Configure Hold and eDiscovery

For compliance/legal holds:

1. **Compliance Center** → **eDiscovery** → **Core**
2. Create new case:
   - **Name**: "Case Number 2024-001"
   - **Description**: "Litigation hold for document retention"
3. Add **Hold**:
   - **Locations**: Select SharePoint sites
   - **Query**: Optional (specific documents only)
   - **Hold duration**: Indefinite (until case resolved)

---

## Task 10: Validation and Testing

### Step 10.1: Test Site Access

1. Log in as each user role (Owner, Member, Visitor)
2. Verify permissions:
   - Owners can create/delete sites
   - Members can contribute documents
   - Visitors can only read content

### Step 10.2: Test Document Upload and Versioning

1. Upload document: "IT Policy - 2024.docx"
2. Edit document in browser
3. Verify:
   - Major version incremented (1.0 → 2.0)
   - Version history shows all changes
   - Can restore previous version

### Step 10.3: Test Search and Discovery

1. Upload 5+ documents with metadata
2. Navigate to **Search** (magnifying glass)
3. Search for document by:
   - Title: "Policy"
   - Metadata: "Department: IT"
   - Content: Text within document
4. Verify search results accurate

**Validation:**
```powershell
# Verify site creation and storage
Get-SPOSite -Identity "https://organization.sharepoint.com/sites/it-department" `
            | Select-Object Url, Title, Owner, StorageUsagCurrent, StorageQuotaGB

# Verify document libraries exist
Get-PnPList -Identity "Policies and Procedures"

# Count documents
(Get-PnPListItem -List "Policies and Procedures").Count
```

---

## Validation Checklist

- [ ] Organizational intranet site created and branded
- [ ] Department sites created (IT, HR, Finance, Operations)
- [ ] Logo and colors applied to sites
- [ ] Document libraries created with metadata columns
- [ ] Versioning enabled on all libraries
- [ ] Permissions configured correctly for each role
- [ ] External sharing restricted/disabled
- [ ] Search functionality working
- [ ] Users can sync libraries to desktop
- [ ] Mobile app accessible
- [ ] Retention labels configured and applied
- [ ] Documents discoverable and searchable
- [ ] OneDrive configured for all users (1 TB quota)

---

## Common Issues & Troubleshooting

| Issue | Cause | Solution |
|-------|-------|----------|
| Site not accessible | User not added to site | Add user with Share button, verify permission level |
| Logo not appearing | Image URL broken | Re-upload logo, verify file size <200x100 px |
| Search not finding documents | Content not crawled | Run Request-SPOSiteImmediateIndexing to force re-index |
| Sync not working | OneDrive app not installed | Install OneDrive app, restart, login with credentials |
| Version history not showing | Versioning not enabled | Enable versioning in library settings |
| Retention label not applying | Label not published to site | Publish label to specific site collection in policy |
| External user can't access | External sharing disabled | Enable "Guest" option in sharing settings if needed |

---

## Next Steps

1. Complete SharePoint configuration and branding
2. Proceed to licensing-e3-e5.md for license assignment strategy
3. Train users on SharePoint navigation and collaboration features
4. Configure OneDrive governance and quotas
5. Progress to Phase 2: Security Compliance (DLP for document classification)
