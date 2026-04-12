# Phase 4: Monitoring, Operations, and Reporting

**Depends on**: Phase 2 (security policies active), Phase 3 (Teams and SharePoint configured)  
**Key Result**: Audit logs retained for 12 months, alert policies fire on real security events, Service Health notifications reach the IT team

---

## Step 1: Enable and Extend Unified Audit Logging

Microsoft 365 unified audit logging captures activity across Exchange, SharePoint, Teams, Entra ID, and other services into a single searchable record. It is enabled by default on new tenants, but you should verify it is on and extend the retention period beyond the default 90 days.

1. Go to https://compliance.microsoft.com → **Audit** (in the left sidebar under Solutions).
2. If you see a banner saying "Start recording user and admin activity", click it to enable auditing.
3. If the banner is absent, the audit log is already active. You will see the search interface.

To extend log retention to 12 months (requires E3 or E5 licence):

```powershell
# Connect to Security & Compliance PowerShell
Connect-IPPSSession -UserPrincipalName admin@nig-e-mart.com

# Create a custom audit retention policy for 12 months (applies to all record types)
New-UnifiedAuditLogRetentionPolicy `
  -Name "12-Month Audit Retention" `
  -Description "Retain all audit log records for 12 months" `
  -RetentionDuration TwelveMonths `
  -RecordTypes AzureActiveDirectory, ExchangeAdmin, ExchangeItem, SharePoint, SharePointFileOperation, Teams `
  -Priority 1
```

Verify the policy was created:

```powershell
Get-UnifiedAuditLogRetentionPolicy | Select-Object Name, RetentionDuration, RecordTypes
```

---

## Step 2: Create Alert Policies

Alert policies monitor the audit log and send email notifications when specific events match your criteria. They are configured at https://compliance.microsoft.com → **Policies** → **Alert policies**.

**Alert 1: Mass file deletion**

This fires when a large number of files are deleted in a short window — a common indicator of ransomware or a disgruntled employee:

1. Click **+ New alert policy**.
2. Name: `Mass File Deletion Alert` | Severity: **High** | Category: **Data management**
3. Click **Next**. Under **Choose what to alert on**, set:
   - **Activity**: select `Deleted file` (FileDeleted in the SharePoint category)
   - Expand **Alert threshold**: set **Send an alert when this activity happens** to **More than 20 times** in **5 minutes**
4. Under **Decide if you want to notify people**: check **Send email notifications** and enter the security team distribution list (e.g., `security@nig-e-mart.com`). Set frequency to **Every time an activity matches the rule**.
5. Click **Next** → review → **Finish**. Ensure the toggle shows **On**.

**Alert 2: Multiple failed sign-in attempts**

```powershell
# Create via PowerShell for precision
New-ActivityAlert `
  -Name "Multiple Failed Sign-In Attempts" `
  -Description "10+ failed logins within 5 minutes — possible brute force" `
  -Operation "UserLoginFailed" `
  -Threshold 10 `
  -TimeWindow 5 `
  -Severity High `
  -NotifyUser "security@nig-e-mart.com" `
  -UserId $null  # Monitor all users
```

**Alert 3: DLP policy match**

This alert fires any time a DLP policy blocks or flags a message or document. Because DLP policies are configured in Phase 2, this alert ensures violations reach the security team even if they are already being logged.

1. In **Alert policies**, click **+ New alert policy**.
2. Name: `DLP Policy Violation` | Severity: **Medium** | Category: **Data loss prevention**
3. Under **Choose what to alert on**, set **Activity** to `DLP rule matched` (under the Compliance category).
4. Leave the threshold at **Every time** (alert on every individual violation, not a rolling count).
5. Send notifications to `security@nig-e-mart.com` and the DLP admin account.
6. Finish and verify the toggle is **On**.

---

## Step 3: Testing Alert Delivery

Before trusting that alerts work, trigger each one in a controlled way:

**Test the mass deletion alert**: Navigate to a test SharePoint library, upload 25 empty text files, then delete them all within a few minutes. The alert email should arrive within 10–15 minutes of the threshold being crossed.

**Test the failed sign-in alert**: Attempt to sign in to a non-admin test account with the wrong password 12 times in quick succession. The alert should fire and notify the security mailbox.

If an alert email does not arrive, check your spam folder, then go to **Alert policies** → click the policy → **View alerts** to confirm the policy detected the activity. If it detected it but no email was sent, verify the notification email address is correct and that the sending address (`no-reply@microsoft.com`) is not blocked.

---

## Step 4: Audit Log Searches

Audit log searches let you investigate activity on demand. Access them at https://compliance.microsoft.com → **Audit** → **New Search**.

**Search 1: All Finance department activity (last 30 days)**

In the search form:
- **Start date / End date**: set the 30-day range
- **Users**: enter each Finance user's UPN, separated by commas
- **Activities**: leave as **All activities**
- Click **Search**

The results will show every action those users took in Exchange, SharePoint, and Teams during the period — logins, file accesses, emails sent, and admin changes.

**Search 2: Sensitive file access**

This identifies who accessed files that might contain sensitive data based on filename keywords:
- **Activities**: `Accessed file` (FileAccessed)
- **File, folder, or site**: enter `*SSN*` in the search box, then after the first search run another pass for `*Confidential*` and `*Credit*`
- Export the results to CSV for review

**Search 3: Admin change audit**

Compliance frameworks require that administrative actions be logged and reviewable. Run this monthly:

```powershell
# Search for admin-level Exchange and directory changes in the last 30 days
$startDate = (Get-Date).AddDays(-30)
$endDate = Get-Date

Search-UnifiedAuditLog `
  -StartDate $startDate `
  -EndDate $endDate `
  -RecordType AzureActiveDirectory `
  -Operations "Add member to role","Remove member from role","Update user","Reset user password" `
  -ResultSize 1000 |
  Select-Object CreationDate, UserIds, Operations, AuditData |
  Export-Csv -Path ".\Admin-Changes-$(Get-Date -Format 'yyyyMMdd').csv" -NoTypeInformation
```

Review this export and flag any actions that were not part of planned change requests.

---

## Step 5: Set Up Service Health Notifications

Service Health notifications alert the IT team when Microsoft 365 services experience an outage or degradation, so you are not blindsided by user complaints.

1. Go to https://admin.microsoft.com → **Health** → **Service health** → **Preferences** (top right).
2. On the **Email** tab, check **Send me email notifications about service health**.
3. Add the IT operations email address (e.g., `it-ops@nig-e-mart.com`) in the **Send to** field.
4. Under **Send notifications about these services**, check:
   - Exchange Online
   - Microsoft Teams
   - SharePoint Online
   - Microsoft Entra (Azure Active Directory)
   - Microsoft Intune
5. Click **Save**.

You can also subscribe to the Microsoft 365 Status Twitter/X feed and RSS feed as secondary channels, but the email preference is the primary alert path for nig-e-mart operations.

---

## Step 6: Configure Monthly Reporting

The Microsoft 365 admin centre provides built-in usage reports that you should export monthly for management visibility.

**Usage reports (Microsoft 365 admin centre):**

1. Go to https://admin.microsoft.com → **Reports** → **Usage**.
2. Under **Active users — Microsoft 365 services**, set the date range to **Last 30 days** and click **Export**. This shows which users are actively using Exchange, SharePoint, Teams, and OneDrive.
3. Navigate to **Email activity** and **Teams user activity** and export those reports as well.

**Secure Score tracking:**

1. Go to https://security.microsoft.com → **Secure Score**.
2. Record the current score and note which recommended actions remain incomplete. The Secure Score dashboard tracks your improvement over time.
3. Target a score of 70% or above once all phases are complete. Save a screenshot monthly to track progress.

---

## Completion Checklist

- Unified audit logging confirmed active in the compliance portal
- 12-month audit log retention policy created and verified
- Three alert policies created: mass file deletion (High), failed sign-ins (High), DLP violation (Medium)
- All three alert policies tested and email notifications confirmed delivered
- Audit log searches run and results exported for Finance, sensitive file access, and admin changes
- Service Health email notifications configured for all five services
- Monthly report exports run and saved
- Secure Score baseline recorded

---

## Next Step

Proceed to [Phase 5 – Hybrid Identity](../06-phase-5-hybrid-identity/01-hybrid-identity.md).

