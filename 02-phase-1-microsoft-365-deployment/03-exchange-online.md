# Phase 1.3: Exchange Online & Mailbox Setup

**Depends on**: Phase 1.2 (licences assigned)  
**Key Result**: All users have working email; shared mailboxes created; mail flow, retention, and transport rules are active

---

## Step 1: Verify User Mailboxes Are Provisioned

When you assign an Exchange Online licence to a user, Exchange Online automatically provisions a mailbox. Provisioning usually completes within a few minutes, but can take up to 24 hours. Verify that all user mailboxes are ready before proceeding:

```powershell
# Connect to Exchange Online
Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force
Connect-ExchangeOnline -UserPrincipalName admin@nig-e-mart.com

# List all mailboxes and verify count matches your user count
Get-Mailbox -ResultSize Unlimited | Select-Object DisplayName, UserPrincipalName, RecipientTypeDetails |
  Sort-Object UserPrincipalName | Format-Table -AutoSize
```

If any user is missing from the output, go to the Microsoft 365 admin centre → **Users** → **Active users**, click the user, and verify a licence with Exchange Online is assigned. Unlicensed users will not have a mailbox.

---

## Step 2: Create Shared Mailboxes

Shared mailboxes do not consume a licence as long as each mailbox is under 50 GB. They let multiple users send from and read a single address — ideal for support, finance, and no-reply addresses.

Run the mailbox setup script to create the shared mailboxes in one pass:

```powershell
# Creates shared mailboxes defined in the script
.\13-automation\powershell\04-mailbox-setup.ps1
```

To create each mailbox manually in the Exchange admin centre instead: go to https://admin.exchange.microsoft.com → **Recipients** → **Mailboxes** → click **Add a shared mailbox**. Fill in the **Display name** and **Email address**, then click **Create**. Repeat for each mailbox below:

| Display Name | Email Address | Send Permission |
|---|---|---|
| IT Support | support@nig-e-mart.com | IT Helpdesk group |
| Finance Team | finance@nig-e-mart.com | Finance group |
| No-Reply | noreply@nig-e-mart.com | System admin only (send-as, no read) |

After creating each mailbox, add the appropriate members via PowerShell:

```powershell
# Add IT team members to the support mailbox
Add-MailboxPermission -Identity "support@nig-e-mart.com" `
  -User "helpdesk-user@nig-e-mart.com" `
  -AccessRights FullAccess -AutoMapping $true

# Grant send-as permission on the no-reply mailbox (no read access)
Add-RecipientPermission -Identity "noreply@nig-e-mart.com" `
  -Trustee "svc-notifications@nig-e-mart.com" `
  -AccessRights SendAs -Confirm:$false
```

---

## Step 3: Configure Mail Routing (Hybrid Connector)

If you are running Exchange Server on-premises alongside Exchange Online (hybrid configuration as set up in Phase 5), you need a Send connector in Exchange Online and a Receive connector on-prem so mail can flow both ways through the VPN.

**Exchange Online send connector (cloud to on-prem):**

1. Go to https://admin.exchange.microsoft.com → **Mail flow** → **Connectors** → **+ Add a connector**.
2. Set **Connection from** to **Office 365** and **Connection to** to **Your organization's email server**.
3. Name it `To On-Premises`. Click **Next**.
4. Select **Only when email messages are sent to these domains** and enter your internal domain (e.g., `nig-e-mart.local`).
5. On the routing page, choose **Route email through these smart hosts** and enter the public IP or FQDN of your on-premises Exchange server.
6. On security, select **Always use TLS** and **Issued by a trusted certificate authority (CA)**.
7. Click through to finish and save. Run the validation test to confirm the connector can reach the on-prem server.

For the reverse direction (on-prem to cloud), the hybrid configuration wizard in the Exchange Management Console creates that connector automatically. Do not create it manually if you ran the wizard.

---

## Step 4: Configure Retention Policies

nig-e-mart requires a 7-year email retention policy for compliance. Configure this through the Microsoft Purview compliance portal:

1. Go to https://compliance.microsoft.com → **Data lifecycle management** → **Microsoft 365** → **Retention policies** → **+ New retention policy**.
2. Name the policy `Exchange 7-Year Retention`.
3. On the **Choose what to retain or delete** page: set **Retain items for a specific period** → **7 years**, and set the action to **Delete items automatically** when the period ends.
4. On the **Choose where to apply this policy** page: select **Exchange mailboxes**. Leave the scope as all mailboxes.
5. Review the settings and click **Submit**.

The policy will enter a propagation state for up to 24 hours. You can verify it is active by returning to **Retention policies** and checking that the status says **On**.

For deleted item recovery, the default Exchange Online retention period is 14 days. Extend it to 30 days via PowerShell so users have a longer window to recover accidentally deleted emails:

```powershell
# Extend recoverable deleted items window to 30 days for all mailboxes
Get-Mailbox -ResultSize Unlimited | Set-Mailbox -RetainDeletedItemsFor 30
```

---

## Step 5: Create Transport Rules

Transport rules intercept mail in flow and act on it — adding disclaimers, blocking sensitive content, or redirecting messages. Create the following three rules:

**Rule 1: External email disclaimer**

1. Go to https://admin.exchange.microsoft.com → **Mail flow** → **Rules** → **+ Create a rule**.
2. Name: `Add External Disclaimer`.
3. Under **Apply this rule if**, select **The recipient is located** → **Outside the organization**.
4. Under **Do the following**, select **Apply a disclaimer to the message** → **Append a disclaimer**. Paste your legal disclaimer text in the HTML box.
5. Set **Fallback action** to **Wrap** (wraps the original email in an envelope if the disclaimer cannot be appended).
6. Set priority to `0` (first to be evaluated).
7. Save and leave **Mode** as **Enforce**.

**Rule 2: Flag messages with sensitive keywords (audit mode)**

```powershell
# Create a transport rule that stamps a header on emails referencing sensitive keywords
New-TransportRule -Name "Flag Sensitive Keywords" `
  -SubjectOrBodyContainsWords "SSN","credit card","salary","confidential","restricted" `
  -ApplyHtmlDisclaimerText "" `
  -SetHeaderName "X-ComplianceFlag" `
  -SetHeaderValue "SensitiveContent" `
  -Mode AuditAndNotify `
  -NotifySender RejectUnlessExplicitlyAllowed `
  -RejectMessageEnhancedStatusCode "5.7.1"
```

Leave this rule in **AuditAndNotify** mode initially. Review the audit logs after one week to see how often it triggers, then switch to **Enforce** mode once you are confident it is not producing false positives.

**Rule 3: Block external forwarding**

Automatic email forwarding to external addresses is a common data exfiltration path:

```powershell
# Disable automatic forwarding to external recipients at the org level
Set-RemoteDomain Default -AutoForwardEnabled $false

# Create a transport rule to catch any manual forwarding rules users create
New-TransportRule -Name "Block External Auto-Forward" `
  -FromScope "InOrganization" `
  -SentToScope "NotInOrganization" `
  -MessageTypeMatches "AutoForward" `
  -RejectMessageEnhancedStatusCode "5.7.1" `
  -RejectMessageReasonText "Automatic forwarding to external recipients is not permitted."
```

---

## Step 6: Verify End-to-End Mail Flow

Before closing this phase, perform a basic mail flow test:

```powershell
# Send a test message from an admin mailbox to an external address
Send-MailMessage -To "your.personal@gmail.com" `
  -From "admin@nig-e-mart.com" `
  -Subject "Exchange Online Test" `
  -Body "Outbound test" `
  -SmtpServer "smtp.office365.com" `
  -Port 587 `
  -UseSsl `
  -Credential (Get-Credential)
```

Also send an email from an external address into a nig-e-mart mailbox and confirm it arrives. If either direction fails, go to https://admin.exchange.microsoft.com → **Mail flow** → **Message trace** to diagnose the issue.

---

## Completion Checklist

- All user mailboxes visible in the Exchange admin centre
- Three shared mailboxes created (support@, finance@, noreply@) with correct send permissions
- Hybrid mail flow connector configured and validated (if applicable)
- 7-year retention policy active for Exchange mailboxes
- Deleted item recovery set to 30 days
- External disclaimer transport rule enforced
- External auto-forward block rule enforced
- Sensitive keyword rule in audit mode
- Inbound and outbound mail flow tested successfully

---

## Next Step

Proceed to [Phase 1.4 – SharePoint & Site Setup](04-sharepoint-branding.md).

