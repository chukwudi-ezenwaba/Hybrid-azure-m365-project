# Phase 3: SharePoint & OneDrive Governance

**Depends on**: Phase 1.4 (team sites created), Phase 2 (Purview retention policies active)  
**Key Result**: Sensitive document libraries configured with content approval, OneDrive governance policies applied, lifecycle rules in place, and external sharing locked to existing users only

---

## Step 1: Create the Remaining Department Sites

Phase 1.4 created the IT Department, Sales Collaboration, Finance Records, and Company News sites. This phase adds the remaining departments that were not part of Phase 1.4.

**Create the HR Department site:**

1. Go to https://admin.microsoft.com → **SharePoint** (in the left sidebar under Admin centers).
2. Click **Sites** → **Active sites** → **+ Create**.
3. Select **Team site**.
4. Fill in:
   - **Site name**: `HR Department`
   - **Group email address**: `hr-dept` (auto-populated)
   - **Privacy settings**: **Private – only members can access this site**
5. Click **Next** → set **Time zone** → **Create site**.

**Create the Operations Department site** using the same process:

- **Site name**: `Operations Department`
- **Group email**: `operations-dept`
- **Privacy settings**: **Private**

**PowerShell alternative** (if you prefer to create all remaining sites in one pass):

```powershell
Connect-SPOService -Url "https://nig-e-martadmin.sharepoint.com"

$sites = @(
  @{ Url = "https://nig-e-mart.sharepoint.com/sites/hr-dept";         Title = "HR Department";         Owner = "hr-manager@nig-e-mart.com" },
  @{ Url = "https://nig-e-mart.sharepoint.com/sites/operations-dept"; Title = "Operations Department"; Owner = "ops-manager@nig-e-mart.com" }
)

foreach ($site in $sites) {
  New-SPOSite -Url $site.Url -Owner $site.Owner -StorageQuota 1048576 -Title $site.Title -Template "STS#3"
  Write-Host "Created: $($site.Title)"
}
```

After creation, add the relevant M365 group as Members of each site (same process as Phase 1.4 Step 5).

---

## Step 2: Create Sensitive Document Libraries

Each department site needs a **Sensitive Documents** library that is isolated from the default site permissions, requires document check-out, enforces content approval, and keeps full version history. The steps below use the IT Department site as the example — repeat for HR and Finance.

**Create the library:**

1. Navigate to https://nig-e-mart.sharepoint.com/sites/it-dept.
2. Click **+ New** → **Document library**.
3. Name: `Sensitive Documents`. Leave **Show in site navigation** checked. Click **Create**.

**Break permission inheritance and restrict access:**

1. Open the **Sensitive Documents** library → click the **Settings gear** → **Library settings**.
2. Click **Permissions for this document library** → **Stop Inheriting Permissions** → confirm.
3. Select the **Members** group row and click **Edit User Permissions**. Change from **Edit** to **Read**. Click **OK**. This means regular site members can only read, not edit, documents in this library.
4. Select the **Visitors** group row and click **Remove User Permissions** → confirm. Visitors have no access to this library.
5. Only the **Owners** group (IT Manager) retains Full Control.

To grant specific individuals edit access (e.g., senior IT staff who need to upload documents):

```powershell
# Grant a specific user Edit on the Sensitive Documents library
Set-SPOUser -Site "https://nig-e-mart.sharepoint.com/sites/it-dept" `
  -LoginName "senior.it@nig-e-mart.com" `
  -IsSiteCollectionAdmin $false

# Then grant contribute via the library's unique permission set through the portal
```

**Enable versioning, check-out, and content approval:**

1. Still in **Library settings**, click **Versioning settings**.
2. Set:
   - **Require content approval for submitted items**: **Yes**
   - **Create a version each time you edit a file in this document library**: **Yes**
   - **Keep the following number of major versions**: `All` (no limit)
   - **Require documents to be checked out before they can be edited**: **Yes**
3. Click **OK**.

**Configure approvers** for the library:

1. In **Library settings**, click **Workflow settings** → if no workflow exists, click **Add a workflow**.
2. Select **Three-state** workflow (built-in), name it `Document Approval`, and set the task list and history list.
3. Set the approver to the department manager's account.

Alternatively, if Power Automate is available, a more flexible approval flow can be built in https://make.powerautomate.com — trigger: **When a file is created or modified**, action: **Start and wait for an approval**.

Repeat this entire Step 2 procedure for the HR Department and Finance Records sites.

---

## Step 3: Configure OneDrive Storage and Policies

**Set the default storage quota:**

1. Go to https://nig-e-martadmin.sharepoint.com → **Settings** (left sidebar) → **OneDrive storage limit**.
2. Set **Default OneDrive storage limit** to `1024 GB` (1 TB). Click **Save**.

**Set a maximum site storage cap** to prevent a single user from consuming excessive storage:

```powershell
# Set 1 TB quota per OneDrive (applies to new OneDrives; existing ones are unaffected unless -WhatIf is removed)
Set-SPOTenant -OneDriveStorageQuota 1048576  # 1 TB in MB
```

---

## Step 4: Apply OneDrive Retention Policy

OneDrive files need a 5-year retention policy so that documents are not permanently deleted before the compliance period expires.

1. Go to https://compliance.microsoft.com → **Data lifecycle management** → **Microsoft 365** → **Retention policies** → **+ New retention policy**.
2. Name: `OneDrive 5-Year Retention`.
3. **Choose what to retain or delete**: Retain items for **5 years** → when the period ends, **Delete items automatically**.
4. **Choose where to apply**: select **OneDrive accounts** only. Leave scope as all accounts.
5. Click **Submit**.

---

## Step 5: Restrict External Sharing

OneDrive and SharePoint external sharing settings must align with the organisation's security posture. External sharing is restricted to existing guest users only — no anonymous links.

1. In the SharePoint admin centre (https://nig-e-martadmin.sharepoint.com) → **Policies** → **Sharing**.
2. Under the **SharePoint** slider, set the level to **Existing guests** — this means only users who have previously been added as guests can be reshared with. New anonymous "Anyone with a link" sharing is disabled.
3. Under the **OneDrive** slider, set the same level: **Existing guests**.
4. Under **File and folder links** → **Default link type**, select **Only people in your organization**. This ensures the default link type when users share a file is internal-only unless they explicitly change it.
5. Click **Save**.

Verify the setting is applied:

```powershell
# Confirm tenant-level sharing settings
Get-SPOTenant | Select-Object SharingCapability, DefaultSharingLinkType, OneDriveSharingCapability
# SharingCapability should show: ExistingExternalUserSharingOnly
```

---

## Step 6: Configure Data Lifecycle Labels

Apply a retention label to the Archive document library in each site so documents placed there are automatically governed by a 7-year rule. The labels were created in Phase 2 (Purview). This step publishes them to SharePoint.

1. Go to https://compliance.microsoft.com → **Data lifecycle management** → **Microsoft 365** → **Label policies**.
2. Find the label policy that publishes your sensitivity/retention labels → click **Edit policy** → on the **Choose locations** page, confirm **SharePoint sites** is included. If it is not, add it and re-publish.
3. Once the policy propagates (up to 24 hours), navigate to any Archive library → click the **Settings gear** → **Library settings** → **Apply label to items in this list or library** → select the `Archive — 7 Year` label → **Save**.

Repeat for the Archive library in each department site.

---

## Completion Checklist

- HR Department and Operations Department team sites created
- Sensitive Documents library created in IT, HR, and Finance sites with broken inheritance
- Member permissions on Sensitive Documents reduced to Read-only; Visitors removed
- Check-out, content approval, and unlimited versioning enabled on all Sensitive Documents libraries
- Document approval workflow configured per library
- OneDrive storage quota set to 1 TB per user
- 5-year OneDrive retention policy active in the compliance portal
- External sharing restricted to Existing guests for both SharePoint and OneDrive
- Default link type set to internal-only
- Archive library retention label applied in each department site

---

## Next Step

Proceed to [Phase 3.2 – Teams Governance](02-teams.md).

