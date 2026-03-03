# Phase 3: Collaboration and Governance - SharePoint & OneDrive Setup

## Phase Overview

This phase configures Microsoft 365 collaboration platforms (SharePoint Online, OneDrive) with data governance, lifecycle management, and access control policies.

**Duration**: 2 weeks  
**Key Objectives**: SharePoint sites creation, OneDrive policies, retention management, external sharing controls

---

## Task 1: Create Department SharePoint Sites

### Step 1.1: Create IT Department SharePoint Site

1. Go to **SharePoint Admin Center** (https://admin.microsoft.com → SharePoint)
2. Click **Create site**
3. Select **Team site** (collaborative site with group)
4. Configure:
   - **Site name**: "IT Department"
   - **Site URL**: it-department (auto-populated)
   - **Owner**: Select IT Department group owner
   - **Language**: English
5. Click **Create**

**PowerShell Alternative:**
```powershell
# Connect to SharePoint Online
Connect-SPOService -Url https://organization-admin.sharepoint.com

# Create site
New-SPOSite -Url "https://organization.sharepoint.com/sites/it-department" `
            -Owner "john.smith@organization.onmicrosoft.com" `
            -StorageQuota 1048576 `  # 1 TB
            -Title "IT Department"
```

### Step 1.2: Repeat for Other Departments

Create sites for:
- HR Department
- Finance Department  
- Marketing Department
- Operations Department

---

## Task 2: Configure Document Libraries and Permissions

### Step 2.1: Create Sensitive Document Library

In IT Department site:

1. Click **New** → **List** → **Document library**
2. Name: "Sensitive Documents"
3. Configure permissions:
   - Site owner: Full control
   - IT staff (group): Edit
   - Other departments: No access (inherited, restricted)

### Step 2.2: Set Content Approval Workflow

For HR Department sensitive documents:

1. In HR SharePoint site, select document library
2. Go to **Library Settings** → **Versioning Settings**
3. Enable:
   - **Version history**: Keep all versions
   - **Require check-out**: Yes
   - **Require approval**: Yes (new items)
4. Configure approvers (HR manager and director)

**Validation:**
- Users must check-in documents
- Approvers notified of pending items
- Major/minor versions tracked

---

## Task 3: Configure OneDrive Policies

### Step 3.1: Set OneDrive Storage Limits

1. Go **SharePoint Admin Center** → **Settings**
2. Configure:
   - **Default storage quota**: 1 TB per user
   - **Maximum terabytes per site**: None (unlimited)

### Step 3.2: Configure Retention Policies

1. Go https://compliance.microsoft.com
2. **Information governance** → **Retention policies**
3. Create "OneDrive 5-Year Retention":
   - **Locations**: OneDrive accounts
   - **Retention period**: 5 years
   - **Disposition**: Delete after 5 years
4. Apply policy

### Step 3.3: Restrict External Sharing

1. Go to **OneDrive admin settings**
2. Configure:
   - **Sharing**: Anyone links disabled
   - **External sharing**: "Existing external users" only
   - **Allow guests**: Yes (only existing)
   - **Unverified users**: Block

---

## Task 4: Implement Data Lifecycle Management

Create rules for automatic document archival and deletion:

1. Go to **SharePoint Admin Center** → **Settings** → **Information Management**
2. Create retention label "Archive After 3 Years":
   - Automatically archive documents not modified for 3 years
   - Move to archive storage (lower-cost tier)
   - Keep previous versions for 1 year

---

## Validation Checklist

- [ ] 5 department SharePoint sites created
- [ ] Document libraries created with appropriate permissions
- [ ] Content approval enabled for sensitive documents
- [ ] OneDrive 1 TB quota set per user
- [ ] Retention policies applied (5-year default)
- [ ] External sharing restricted to existing users only
- [ ] Lifecycle rules configured for archival

---

*Phase 3 Completion Date: ___________*
*Document Version: 1.0*
