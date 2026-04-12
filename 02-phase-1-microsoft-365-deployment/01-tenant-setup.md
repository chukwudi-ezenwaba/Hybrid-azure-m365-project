# Phase 1.1: Microsoft 365 Tenant Setup

**Depends on**: Nothing — this is the starting point  
**Key Result**: M365 tenant live with a verified custom domain, all users provisioned and licensed, admin accounts secured with MFA

---

## Step 1: Create the Microsoft 365 Tenant

Go to https://admin.microsoft.com and sign up for a Microsoft 365 business plan. During sign-up you will be asked to create an initial domain in the format `yourorg.onmicrosoft.com` — this is your permanent fallback domain and cannot be changed later, so choose the organisation name carefully. You will also create the first Global Administrator account during this step. Use a dedicated admin account with a format like `admin@yourorg.onmicrosoft.com` rather than a personal user account.

Once sign-up is complete, sign in to the Microsoft 365 admin centre at https://admin.microsoft.com and confirm the tenant is active.

---

## Step 2: Add and Verify Your Custom Domain

nig-e-mart should use its own domain (e.g. `nig-e-mart.com`) rather than the `.onmicrosoft.com` address for user-facing email and sign-in.

1. In the admin centre, go to **Settings** → **Domains** → **Add domain**.
2. Enter your domain name and click **Use this domain**.
3. Microsoft will display a TXT record, for example:  
   `MS=ms12345678`  
   Log in to your DNS registrar (e.g. Cloudflare, GoDaddy, Namecheap) and add this as a TXT record on the root of the domain (`@`). DNS propagation typically takes 5–30 minutes.
4. Return to the admin centre and click **Verify**. Once verified, Microsoft will show a list of additional DNS records needed for email (MX, CNAME, SPF). Add all of them at your registrar.
5. After adding all DNS records, click **Continue** to finish the domain setup. The domain status will change to **Healthy**.

---

## Step 3: Secure the Global Administrator Account Immediately

Before doing anything else, protect the initial Global Admin account with MFA. This account has unrestricted access to the entire Microsoft 365 environment and must never be used without a second authentication factor.

1. In the admin centre, go to **Users** → **Active users** → click the Global Admin account.
2. Under the **Account** tab, click **Manage multifactor authentication**.
3. Find the admin account, click **Enable**, then **Enable multi-factor auth** to confirm.
4. Sign out, sign back in, and complete the MFA registration wizard. Use the Microsoft Authenticator app, not SMS, as SMS can be intercepted through SIM-swapping attacks.

Create a second Global Administrator account now as a backup:

1. **Users** → **Active users** → **Add a user**.
2. Fill in the name and set the username to something like `admin2@yourorg.onmicrosoft.com`.
3. Under **Roles**, select **Global Administrator**.
4. Complete creation, then immediately enable MFA on this account using the same steps above.

---

## Step 4: Bulk Create Users from CSV

Rather than creating users one by one, use the PowerShell script in the automation folder. The script reads from a CSV file and creates all accounts in one run.

**Prepare the CSV file** at `13-automation/powershell/SAMPLE-users.csv`. It requires the following columns: `DisplayName`, `UserPrincipalName`, `Department`, `JobTitle`, `Password`. For each user, the UPN should be in the format `firstname.lastname@nig-e-mart.com`. Set a strong temporary password that users will be required to change on first login.

**Run the script**:

```powershell
# Open PowerShell as Administrator and connect to Microsoft 365
Connect-MsolService

# Run the user creation script
.\13-automation\powershell\02-create-users.ps1 -CSVPath ".\SAMPLE-users.csv"
```

Once the script completes, verify the users were created:

1. In the admin centre, go to **Users** → **Active users**.
2. Confirm the count matches your CSV row count.
3. Spot-check two or three users to confirm their department and UPN are set correctly.

Send each department head a list of the temporary passwords for their staff. Users will be prompted to set a new password when they first sign in.

---

## Step 5: Assign Licences

Each user needs an E3 or E5 licence to access Microsoft 365 services. E3 covers Exchange, SharePoint, Teams, and OneDrive. E5 adds Defender for Office 365 Plan 2, Purview advanced compliance, and Entra ID Premium P2 for PIM — assign E5 to IT staff and senior management.

**Prepare the licences CSV** at `13-automation/powershell/SAMPLE-licenses.csv` with columns: `UserPrincipalName`, `LicenseType` (values: `E3` or `E5`).

**Run a preview first** to see what will be assigned without making any changes:

```powershell
.\13-automation\powershell\03-license-assignment.ps1 -CSVPath ".\SAMPLE-licenses.csv" -Preview
```

Review the preview output. Once satisfied, apply the licences:

```powershell
.\13-automation\powershell\03-license-assignment.ps1 -CSVPath ".\SAMPLE-licenses.csv" -Apply
```

Verify in the admin centre by going to **Users** → **Active users** and checking that each user shows a licence under the **Licenses and apps** column. Any users showing **Unlicensed** must be corrected before proceeding.

If you run out of available licence seats during this step, go to **Billing** → **Your products** in the admin centre to purchase additional licences.

---

## Step 6: Enable MFA for All Admin Accounts

All accounts assigned any administrative role must have MFA enabled before Phase 2 begins. Use the automation script to enforce this across all admin accounts in one step:

```powershell
.\13-automation\powershell\08-enable-mfa.ps1
```

After running the script, test MFA by signing in from a private browser window with one of the admin accounts. The user should be prompted for a second factor. If the MFA prompt does not appear, check that the account is correctly targeted by the script output.

For general user MFA, this will be enforced through a Conditional Access policy deployed in Phase 2 — do not enable per-user MFA for regular users here as it conflicts with Conditional Access.

---

## Step 7: Apply the Security Baseline

Before anything else goes live, apply a minimal security baseline so the tenant is protected even during the remaining setup.

**Block legacy authentication** — this prevents sign-in via older protocols that cannot enforce MFA:

1. In the admin centre, go to **Settings** → **Org settings** → **Modern authentication**.
2. Ensure **Turn on modern authentication for Outlook 2013 for Windows and later** is checked.
3. Ensure all legacy protocol checkboxes are unchecked.

**Enable unified audit logging** — all admin and user activity in Microsoft 365 is captured and queryable once this is on:

```powershell
Connect-IPPSSession -UserPrincipalName admin@nig-e-mart.com

Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled $true

# Confirm it is enabled
Get-AdminAuditLogConfig | Select-Object UnifiedAuditLogIngestionEnabled
# Expected output: True
```

**Enable Safe Links and Safe Attachments in audit mode** — full enforcement comes in Phase 2, but enabling these now means protection begins immediately:

1. Go to https://security.microsoft.com → **Email & collaboration** → **Policies & rules** → **Threat policies**.
2. Open **Safe Links** → click the default policy → set **On** for URLs in email messages and Office applications.
3. Open **Safe Attachments** → click the default policy → set the action to **Monitor** (audit only for now — enforcement is configured in Phase 2).

---

## Completion Checklist

Before moving to Phase 1.2, confirm all of the following:

- Custom domain verified and DNS records (MX, CNAME, SPF) all show as Healthy in the admin centre
- Two Global Administrator accounts exist, both with MFA enabled and tested
- All users have been created from the CSV and are visible in Active Users
- All users have an E3 or E5 licence assigned with no Unlicensed accounts remaining
- Unified audit logging is enabled and confirmed via PowerShell
- Safe Links and Safe Attachments are turned on (Monitor mode)
- Legacy authentication is disabled

---

## Next Step

Proceed to [Phase 1.2 – Licensing Deep Dive](02-licensing-e3-e5.md) or [Phase 1.3 – Exchange Online Setup](03-exchange-online.md).

