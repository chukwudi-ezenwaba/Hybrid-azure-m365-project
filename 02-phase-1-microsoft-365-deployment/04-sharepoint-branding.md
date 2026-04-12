# Phase 1.4: SharePoint Site Setup & Branding

**Depends on**: Phase 1.2 (licences assigned, SharePoint plan active)  
**Key Result**: Department team sites created, company branding applied, document libraries structured, and external sharing locked down

---

## Step 1: Access the SharePoint Admin Centre

Open a browser and navigate to https://admin.microsoft.com. In the left sidebar, click **Show all** → **SharePoint**. This opens the SharePoint admin centre at https://tenant-admin.sharepoint.com (replace `tenant` with your actual tenant prefix, e.g., `nig-e-martadmin.sharepoint.com`).

If you cannot find the SharePoint entry in the admin centre sidebar, confirm the user account you are signed in with has the **SharePoint Administrator** role. Go to **Users** → **Active users** → click the admin account → **Roles** tab → verify SharePoint Administrator is checked.

---

## Step 2: Create Department Team Sites

You will create one team site per department. Team sites provide shared document libraries, lists, and a site mailbox. This is different from a Communication site, which is a one-to-many broadcast page.

**Create the IT Department team site:**

1. In the SharePoint admin centre, click **Sites** → **Active sites** → **+ Create**.
2. Select **Team site** as the site type.
3. Fill in the form:
   - **Site name**: `IT Department`
   - **Group email address**: `it-dept` (auto-populated — leave as is)
   - **Site address**: will appear as `nig-e-mart.sharepoint.com/sites/it-dept`
   - **Privacy settings**: **Private – only members can access this site**
   - **Language**: English
4. Click **Next**, then on the Additional settings page set the **Time zone** to your region.
5. Click **Create site**. The site takes about 1 minute to provision.

Repeat the process for the remaining three sites using these values:

| Site name | Group email | Privacy |
|---|---|---|
| Sales Collaboration | sales-collab | Private |
| Finance Records | finance-records | Private |
| Company News | company-news | **Public** (Communication site — change site type to Communication Site) |

For **Company News**, at the site type selection step choose **Communication site** instead of Team site. Communication sites do not have a group mailbox but they support a larger audience with read access.

---

## Step 3: Apply Company Branding

Apply the nig-e-mart brand to each site so they have a consistent look.

**Apply a theme to a team site:**

1. Navigate to the site (e.g., https://nig-e-mart.sharepoint.com/sites/it-dept).
2. Click the **Settings gear icon** (top right) → **Change the look**.
3. On the Change the look panel, click **Theme**.
4. Choose **Teal** as the base theme, or upload a custom theme JSON if one has been designed. Click **Save**.

**Add the company logo to the site header:**

1. Still in **Change the look**, click **Header**.
2. Set **Layout** to **Standard**.
3. Under **Logo**, click **Change** and upload the nig-e-mart logo file (PNG, max 400×400 px recommended).
4. Enter `nig-e-mart` as the **Logo alt text**.
5. Click **Save**.

**Apply tenant-wide branding (applies to all SharePoint sites):**

1. In the SharePoint admin centre, click **Settings** → **Change the look for your sites**.
2. Upload your logo and choose the brand colours. This sets the default theme for new sites but does not override sites that have already been individually branded.

---

## Step 4: Build Document Libraries

Each team site needs a structured set of document libraries. Navigate to each site and create the following libraries, then configure versioning and retention:

**Create the libraries (do this in each site):**

1. From the site home page, click **+ New** → **Document library**.
2. Name the library `Active Documents`. Leave **Show in site navigation** checked. Click **Create**.
3. Repeat to create `Templates` and `Archive`.

**Enable versioning on Active Documents:**

1. Open the **Active Documents** library.
2. Click the **Settings gear icon** → **Library settings** → **Versioning settings**.
3. Set **Create a version each time you edit a file** to **Yes**.
4. Set **Keep the following number of major versions** to `30`.
5. Click **OK**.

**Set the Templates library to read-only for non-owners:**

1. Open the **Templates** library → **Settings gear icon** → **Library settings** → **Permissions for this document library**.
2. Click **Stop Inheriting Permissions**, then click **OK** on the confirmation.
3. Select the **Members** group and click **Edit User Permissions**. Change the permission level from **Edit** to **Read**. Click **OK**.

The Archive library will have a retention label applied to it in Phase 2 (Microsoft Purview). Leave its permissions inheriting from the site for now.

---

## Step 5: Configure Site Permissions

Each site has three default groups: Owners, Members, and Visitors. Assign the right AD users or M365 groups to each role.

**For the IT Department site:**

1. Click **Settings gear icon** → **Site permissions** → **Advanced permissions settings**.
2. Click on **IT Department Owners** → **New** → **Add Users**. Add the IT Manager account.
3. Click on **IT Department Members** → **New** → **Add Users**. Add the M365 group `M365-IT-Staff`.
4. Leave **IT Department Visitors** empty for now (no read-only visitors needed for an internal IT site).

Repeat for each site, substituting the relevant M365 group names (e.g., `M365-Finance`, `M365-Sales`).

For the **Company News** communication site, add all staff as Visitors so they can read company announcements, and add the Communications team as Members so they can publish:

```powershell
# Connect to SharePoint Online
Install-Module PnP.PowerShell -Scope CurrentUser -Force
Connect-PnPOnline -Url "https://nig-e-mart.sharepoint.com/sites/company-news" -Interactive

# Add all users as visitors
Add-PnPGroupMember -LoginName "M365-AllStaff@nig-e-mart.com" -Group "Company News Visitors"
```

---

## Step 6: Disable External Sharing

By default, SharePoint Online allows site owners to share files and sites with people outside the organisation. This must be restricted for a company of nig-e-mart's security posture.

1. In the **SharePoint admin centre**, click **Policies** → **Sharing**.
2. Under **External sharing**, drag the slider for SharePoint to **Only people in your organization**.
3. Repeat for OneDrive (set it to **Only people in your organization** as well).
4. Click **Save**.

You can verify this setting has taken effect by navigating to any team site → **Settings gear** → **Site permissions**. The **Sharing** button should show **Only people in your organization can access this site**.

If a specific future scenario requires guest access to a particular site (e.g., a project with an external contractor), it can be re-enabled per-site with appropriate controls — but the tenant default remains locked down.

---

## Completion Checklist

- Four sites created: IT Department, Sales Collaboration, Finance Records, Company News
- Company logo and colour theme applied to all sites
- Active Documents, Templates, and Archive libraries created in each team site
- Versioning enabled (30 versions) on Active Documents libraries
- Templates library set to read-only for Members
- Site permissions configured with the correct M365 groups in each role
- External sharing disabled at the tenant level for both SharePoint and OneDrive
- Test file upload and download confirmed working in each site

---

## Next Step

Proceed to [Phase 1.5 – Defender for Office 365](05-defender-security.md).

