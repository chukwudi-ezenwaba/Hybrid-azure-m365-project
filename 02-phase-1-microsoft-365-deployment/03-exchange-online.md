# Exchange Online Configuration

## Overview

Exchange Online is Microsoft 365's cloud-based email service. This guide covers mailbox provisioning, mail flow rules, transport rules, address book configuration, and administrative mailbox setup with proper access controls.

**Duration**: 2-3 days  
**Requires**: Global Administrator or Exchange Administrator role  
**Depends On**: Microsoft 365 tenant created, users synchronized

---

## Pre-Configuration Checklist

- [ ] Microsoft 365 tenant with Exchange Online licenses
- [ ] Users created and synced to tenant
- [ ] Custom domain verified in Microsoft 365 (organization.com)
- [ ] MX records updated to point to Microsoft 365 (tenant-*.mail.protection.outlook.com)
- [ ] Global administrator account with MFA enabled
- [ ] Exchange Online PowerShell module installed
- [ ] Backup of existing mail routing rules (if migrating)

---

## Task 1: Access Exchange Online Admin Center

### Step 1.1: Navigate to Exchange Admin Center

1. Go to **Microsoft 365 admin center** → https://admin.microsoft.com
2. Select **Admin centers** → **Exchange**
3. Or direct URL: https://admin.exchange.microsoft.com
4. Sign in with Global Administrator or Exchange Administrator credentials
5. Verify you see **Organization** dashboard with mailbox statistics

**PowerShell Access:**
```powershell
# Connect to Exchange Online
Install-Module -Name ExchangeOnlineManagement -Force
Import-Module ExchangeOnlineManagement

Connect-ExchangeOnline -UserPrincipalName admin@organization.onmicrosoft.com
# Complete MFA challenge

# Verify connection
Get-OrganizationConfig | Select-Object Name, OrganizationId
```

### Step 1.2: Verify Mailbox Quota and Storage

1. In **Exchange admin center** → **Recipients** → **Mailboxes**
2. You should see users listed with provisioned mailboxes
3. For each mailbox, note:
   - **Storage quota**: 50 GB (E3) or 100 GB (E5)
   - **Archive quota**: 100 GB per user (if E3) or unlimited (if E5)
   - **Deleted item retention**: 30 days (default)
   - **Mailbox type**: User Mailbox

**Validation:**
- List mailboxes with PowerShell:
```powershell
Get-Mailbox | Select-Object DisplayName, PrimarySmtpAddress, RecipientType | Format-Table -AutoSize
```

---

## Task 2: Configure Mail Flow and Transport Rules

### Step 2.1: Verify MX Record Configuration

**Current State Check:**
1. Domain registrar (GoDaddy, Namecheap, Network Solutions, etc.)
2. Login to DNS management console
3. Look for existing **MX records**:
   ```
   MX Priority 0: tenant-xxxxxxxx.mail.protection.outlook.com
   MX Priority 1: tenant-xxxxxxxx.mail.protection.outlook.com (secondary, if exists)
   ```

4. If not present, add Microsoft 365 MX record:
   - **Type**: MX
   - **Priority**: 0 (highest priority)
   - **Value**: `<tenant>.mail.protection.outlook.com`
   - **TTL**: 3600 seconds

5. Remove old mail server MX records (if migrating from Exchange Server):
   - Old value: `mail.organization.com` or similar
   - Delete or set to Priority 10 (lower priority) temporarily

**Validation:**
```powershell
# Check MX records from PowerShell
Resolve-DnsName -Name organization.com -Type MX | Select-Object Name, Type, Preference, NameExchange | Format-Table
```

### Step 2.2: Configure Mail Flow Rules (Transport Rules)

Transport rules process all email flowing through Exchange Online, allowing for compliance, security, and routing policies.

1. In **Exchange admin center** → **Mail flow** → **Rules**
2. Click **+ New rule** (or + Create)

**Rule 1: Compliance - Add Disclaimer to External Email**
```
Name: "Add Disclaimer to External Email"
Apply this rule if: The sender is located outside the organization
Insert the following text before the disclaimer: 
"This email originated from outside the organization and may contain links or attachments that could be malicious."

Disclaimer text:
---
This email and any attachments contain confidential information intended only for the addressee. If you received this in error, please notify the sender immediately and delete this message.
---

Apply this rule: [Configure conditions]
```

**Rule 2: Security - Block Dangerous Files**
```
Name: "Block Encrypted or Dangerous Files from External"
Apply if:
  - Sender is outside organization: Yes
  - Attachment has these properties: File name contains [.exe, .msi, .vbs, .bat, .cmd, .scr]
Action: Reject the message with explanation
Explanation: "This message was rejected because it contains a file type that is not allowed."
```

**Rule 3: Routing - Route Email to Department Mailbox**
```
Name: "Route HR Emails to HR Shared Mailbox"
Apply if:
  - Recipients address includes: HR@organization.com
Action: Redirect message to: hr-team@organization.com (shared mailbox for team access)
```

**Rule 4: Audit - Log Sensitive Data**
```
Name: "Log External Email Containing Credit Card Data"
Apply if:
  - Sender is outside organization: Yes
  - Message body contains: Digital Rights Management or Custom patterns (credit card format)
Action: CC message to: audit@organization.com
Also apply: Send incident report to security team
```

**Rule 5: DLP - Prevent Data Exfiltration**
```
Name: "Prevent Sending Confidential Documents Externally"
Apply if:
  - The message property includes: Contains documents marked as "Confidential"
  - Recipient is outside organization
Action: Block message
Notify sender: "This message cannot be sent. It contains confidential information."
```

**PowerShell Configuration:**
```powershell
# Create transport rule for external email disclaimer
New-TransportRule -Name "Add Disclaimer to External Email" `
  -FromScope NotInOrganization `
  -ApplyHtmlDisclaimerLocation "Prepend" `
  -HtmlDisclaimerText "<p>This email originated from outside the organization.</p>"

# Create rule blocking external executables
New-TransportRule -Name "Block Executables from External" `
  -FromScope NotInOrganization `
  -AttachmentHasExecutableContent $true `
  -RejectMessageReasonText "This message contains executable files which are not permitted."

# Create rule redirecting to shared mailbox
New-TransportRule -Name "Route HR to Shared Mailbox" `
  -RecipientAddressContainsWords "HR@organization.com" `
  -RedirectMessageTo "hr-team@organization.com"

# List all transport rules
Get-TransportRule | Select-Object Name, State, Priority | Format-Table
```

### Step 2.3: Configure Connectors for Mail Flow

**Inbound Connector** (receives mail from internet):
1. **Exchange admin center** → **Mail flow** → **Connectors** → **+ New connector**
2. Configure:
   - **From**: Internet
   - **To**: Microsoft 365
   - **Name**: "Inbound from Internet"
   - Enable: **Security restrictions**: Require TLS encryption
   - Enable: **Validate certificate hostname**
   - Save

**Outbound Connector** (for hybrid or conditional routing):
1. Create new connector:
   - **From**: Microsoft 365
   - **To**: Organization mailbox/Internet
   - **Name**: "Outbound to Internet"
   - Set **Route mail through smart host**: If hybrid
   - Enable: **MX record resolution**: If internet only

**PowerShell Configuration:**
```powershell
# Create inbound connector requiring TLS
New-InboundConnector -Name "Inbound from Internet" `
  -ConnectorType Internet `
  -RestrictDomainsToCertificate $true `
  -RestrictDomainsToIPAddresses $false `
  -RequireTls $true

# Create outbound connector
New-OutboundConnector -Name "Outbound to Internet" `
  -Enabled $true `
  -ConnectorType Internet `
  -UseMxRecord $true
```

---

## Task 3: Create and Configure Shared Mailboxes

Shared mailboxes allow multiple users to manage a single email address (support@, info@, sales@, etc.).

### Step 3.1: Create Shared Mailbox for IT Support

1. In **Exchange admin center** → **Recipients** → **Mailboxes**
2. Click **+ New mailbox** → **Shared mailbox**
3. Configure:
   - **Display name**: IT Support Team
   - **Email address**: itsupport@organization.com
   - **Name**: IT Support Team
4. Click **Create**

### Step 3.2: Create Shared Mailboxes for Departments

**Repeat for each department:**

**HR Shared Mailbox:**
```
Display name: HR Team
Email: hr@organization.com
Aliases: hr-team, human-resources
Access: Granted to HR Manager, HR Coordinator
```

**Finance Shared Mailbox:**
```
Display name: Finance Team
Email: finance@organization.com
Aliases: finance-team, accounting
Access: Granted to Finance Manager, Finance Coordinator, Controller
```

**Operations Shared Mailbox:**
```
Display name: Operations Team
Email: operations@organization.com
Aliases: ops, operations-team
Access: Granted to Operations Manager, Operations Coordinator
```

**PowerShell Configuration:**
```powershell
# Create IT Support shared mailbox
New-Mailbox -Name "IT Support Team" `
  -DisplayName "IT Support Team" `
  -PrimarySmtpAddress "itsupport@organization.com" `
  -Type "Shared"

# Grant access to shared mailbox
Add-MailboxPermission -Identity "IT Support Team" `
  -User "john.doe@organization.com" `
  -AccessRights FullAccess,SendAs `
  -InheritanceType All `
  -AutoMapping $true

# Send as permission (for replies from shared mailbox)
Add-RecipientPermission -Identity "IT Support Team" `
  -AccessRights SendAs `
  -Trustee "john.doe@organization.com" `
  -Confirm:$false

# Create aliases (alternative email addresses)
Set-Mailbox -Identity "IT Support Team" `
  -EmailAddresses "itsupport@organization.com","itsupport@organization.net","techsupport@organization.com"
```

### Step 3.3: Grant Access to Shared Mailboxes

1. Select shared mailbox → **Manage mailbox delegation**
2. Add users with permissions:
   - **Full Access**: User can open and manage mailbox
   - **Send As**: User can send email as the mailbox
   - **Send on Behalf**: User can send "on behalf of" the mailbox (shows user's name)

**Validation:**
```powershell
# Verify shared mailbox permissions
Get-MailboxPermission -Identity "IT Support Team" | Select-Object User, AccessRights | Format-Table

# Verify Send As permissions
Get-RecipientPermission -Identity "IT Support Team" | Select-Object Trustee, AccessRights | Format-Table
```

---

## Task 4: Configure Mailbox Policies and Retention

### Step 4.1: Set Default Mailbox Archive Policy

1. **Exchange admin center** → **Compliance management** → **Retention policies**
2. Create new retention policy:
   - **Name**: "Default User Mailbox Archive Policy"
   - **Description**: "Archives emails older than 2 years, deletes after 7 years"

3. Add retention tags:
   - **Tag 1 - Archive**: 2 years
   - **Tag 2 - Delete**: 7 years
   - **Tag 3 - Recover**: 30 days (Deleted Items folder)

**PowerShell Configuration:**
```powershell
# Create retention policy tag (2 year archive)
New-RetentionPolicyTag -Name "Archive 2 Years" `
  -Type All `
  -AgeLimitForRetention 730 `
  -RetentionAction MoveToArchive

# Create retention policy tag (7 year delete)
New-RetentionPolicyTag -Name "Delete 7 Years" `
  -Type All `
  -AgeLimitForRetention 2555 `
  -RetentionAction DeleteAndAllowRecovery

# Create retention policy with tags
New-RetentionPolicy -Name "Default Mailbox Archive Policy" `
  -RetentionPolicyTagLinks "Archive 2 Years","Delete 7 Years"

# Apply to all mailboxes
Get-Mailbox -ResultSize Unlimited | Set-Mailbox -RetentionPolicy "Default Mailbox Archive Policy"
```

### Step 4.2: Configure Mailbox Quotas

1. **Exchange admin center** → **Recipients** → **Mailboxes**
2. Select mailbox → **Edit** → **Mailbox usage**
3. Set quotas:
   - **Storage quota**: 50 GB (standard users)
   - **Warning quota**: 45 GB (alert user)
   - **Prohibit send quota**: 49 GB (prevent new email receipt)
   - **Prohibit send/receive quota**: 50 GB (block all mail activity)

**PowerShell Configuration:**
```powershell
# Set mailbox quota globally for new mailboxes
Set-MailboxPlan -Identity "ExchangeOnlineEnterprise-1GB" `
  -IssueWarningQuota "45 GB" `
  -ProhibitSendQuota "49 GB" `
  -ProhibitSendReceiveQuota "50 GB"

# Apply to specific mailbox
Set-Mailbox -Identity "john.doe@organization.com" `
  -IssueWarningQuota 45GB `
  -ProhibitSendQuota 49GB `
  -ProhibitSendReceiveQuota 50GB
```

### Step 4.3: Configure Deleted Item Retention

1. **Exchange admin center** → **Recipients** → **Mailboxes**
2. Select mailbox → **Edit** → **Mailbox features**
3. Set **Item retention period**: 30 days (default)
   - Users can recover deleted items within 30 days
   - After 30 days, items go to dumpster (admin can recover for 30 more days)

**PowerShell:**
```powershell
# Set deleted item retention to 60 days for user
Set-Mailbox -Identity "john.doe@organization.com" -RetainDeletedItemsFor 60

# Set for all mailboxes
Get-Mailbox -ResultSize Unlimited | Set-Mailbox -RetainDeletedItemsFor 60
```

---

## Task 5: Configure Address Book and Global Address List (GAL)

### Step 5.1: Configure Global Address List (GAL)

**Default GAL includes all users. Configure exclusions:**

1. **Exchange admin center** → **Recipient management** → **Global Address Lists**
2. Select **Default Global Address List**
3. Configure filter:
   - **Recipient types**: User mailboxes, resource mailboxes, contacts
   - **Exclude**: Disabled accounts, guest accounts (if preferred)

**PowerShell:**
```powershell
# View current GAL configuration
Get-GlobalAddressList -Identity "Default Global Address List" | Format-List

# Create custom GAL for specific department
New-GlobalAddressList -Name "Finance Department GAL" `
  -ConditionalCustomAttribute1 "Finance" `
  -IncludedRecipients MailboxUsers

# Hide user from GAL (for service accounts)
Set-Mailbox -Identity "service.account@organization.com" -HiddenFromAddressListsEnabled $true
```

### Step 5.2: Configure Offline Address Book (OAB)

Offline Address Book allows Outlook clients to access GAL when offline.

1. **Exchange admin center** → **Recipient management** → **Offline address books**
2. Select **Default Offline Address Book**
3. Add **Global Address List** to OAB
4. Set **Update frequency**: Daily (generates OAB nightly)

**Validation:**
```powershell
# Generate OAB immediately
Update-OfflineAddressBook -Identity "Default Offline Address Book" -Force

# Verify OAB contents
Get-OfflineAddressBook | Select-Object Name, LastUpdated, ExchangeVersion
```

---

## Task 6: Configure Mailbox Auditing

### Step 6.1: Enable Mailbox Audit Logging

1. **Exchange admin center** → **Compliance management** → **Audit** → **Mailbox audit logging**
2. Configure:
   - **Enable mailbox audit logging**: On
   - **Default audit action**: Enabled for all operations
   - **Retention**: 90 days (logs older than 90 days auto-delete)

**PowerShell:**
```powershell
# Enable mailbox auditing for all mailboxes
Get-Mailbox -ResultSize Unlimited | Set-Mailbox -AuditEnabled $true

# Set audit logging for specific mailbox
Set-Mailbox -Identity "john.doe@organization.com" `
  -AuditEnabled $true `
  -AuditLogAgeLimit 90d

# Configure audit actions
Set-Mailbox -Identity "john.doe@organization.com" `
  -AuditDelegate MailboxLogin,Move,Create,Modify,Delete,SendAs `
  -AuditAdmin Create,Delete,Modify,Move,MoveToDeletedItems,SoftDelete,HardDelete,UpdateFolderPermission `
  -AuditOwner MailboxLogin,Create,Modify,Move,SoftDelete,HardDelete,MailboxLogin
```

### Step 6.2: Search Mailbox Audit Logs

```powershell
# Search audit logs for specific mailbox
Search-MailboxAuditLog -Identity "john.doe@organization.com" `
  -LogonType Delegate `
  -StartDate (Get-Date).AddDays(-7) `
  -EndDate (Get-Date) `
  -ShowDetails

# Export audit log to CSV
Search-MailboxAuditLog -Identity "john.doe@organization.com" `
  -StartDate (Get-Date).AddDays(-30) | Export-Csv "mailbox_audit.csv" -NoTypeInformation
```

---

## Task 7: Configure Outlook Web Access (OWA) Policies

### Step 7.1: Create OWA Mailbox Policy

1. Configure mailbox features accessible via Outlook Web App:

**PowerShell:**
```powershell
# Create custom OWA policy
New-OwaMailboxPolicy -Name "Standard User OWA Policy" `
  -EnableFolderPaneSearchButton $true `
  -EnableOfflineAccess $true `
  -EnableAllAddInsByDefault $true `
  -InstantMessagingEnabled $true

# List OWA-allowed features
Get-OwaMailboxPolicy | Select-Object Name, InstantMessagingEnabled, EnableOfflineAccess

# Apply OWA policy to user
Set-CASMailbox -Identity "john.doe@organization.com" -OwaMailboxPolicy "Standard User OWA Policy"
```

### Step 7.2: Configure Client Access Settings

```powershell
# Enable POP3/IMAP for user (if needed)
Set-CASMailbox -Identity "john.doe@organization.com" `
  -POPEnabled $true `
  -IMAPEnabled $true `
  -ActiveSyncEnabled $true

# Set MAPI protocol access
Set-CASMailbox -Identity "john.doe@organization.com" `
  -MAPIEnabled $true

# Disable older authentication protocols (security best practice)
Set-CASMailbox -Identity "john.doe@organization.com" `
  -OWAEnabled $true `
  -POPEnabled $false `
  -IMAPEnabled $false
```

---

## Task 8: Validation and Testing

### Step 8.1: Test Mail Flow

1. Send test email from external account to user@organization.com
   - Verify email arrives in inbox
   - Verify transport rules applied (disclaimer, encryption, etc.)
   - Check email headers for routing path

2. Send test email to shared mailbox (it-support@organization.com)
   - Verify all team members can access
   - Verify "Send As" works for shared mailbox identity

**PowerShell Test:**
```powershell
# Check mail routing
Test-EmailAddress -EmailAddress "john.doe@organization.com"

# Verify MX records
Resolve-DnsName -Name organization.com -Type MX

# Test SMTP connectivity
Test-SmtpConnectivity -TargetServer "outlook.office365.com"
```

### Step 8.2: Verify Mailbox Configuration

```powershell
# Verify mailbox created and accessible
Get-Mailbox -Identity "john.doe@organization.com" | Select-Object DisplayName, PrimarySmtpAddress, RecipientType

# Verify retention policy applied
Get-Mailbox -Identity "john.doe@organization.com" | Select-Object DisplayName, RetentionPolicy

# Verify audit logging enabled
Get-Mailbox -Identity "john.doe@organization.com" | Select-Object DisplayName, AuditEnabled, AuditLogAgeLimit

# Check mailbox size
Get-MailboxStatistics -Identity "john.doe@organization.com" | Select-Object DisplayName, TotalItemSize, ItemCount
```

### Step 8.3: Validate Transport Rules

```powershell
# List all active transport rules
Get-TransportRule | Where-Object {$_.State -eq "Enabled"} | Select-Object Name, Priority, State | Format-Table

# Test rule application
$Message = @{
  From = "external@contoso.com"
  To = "john.doe@organization.com"
  Subject = "Test from external"
  Body = "Testing transport rules"
}
# Rule should apply disclaimer to body
```

---

## Validation Checklist

- [ ] MX records updated to point to Microsoft 365
- [ ] Mail flowing correctly from external addresses
- [ ] Transport rules applying correctly (disclaimers, blocking rules)
- [ ] Shared mailboxes created for departments
- [ ] Users can access shared mailboxes with Full Access
- [ ] Send As permission working for shared mailboxes
- [ ] Retention policies applied to all mailboxes
- [ ] Mailbox auditing enabled for compliance
- [ ] OWA accessible and working
- [ ] Offline Address Book updated and accessible
- [ ] Outlook clients can sync mail
- [ ] All test emails received without delay

---

## Common Issues & Troubleshooting

| Issue | Cause | Solution |
|-------|-------|----------|
| Email not arriving at tenant | MX records not updated | Verify MX records point to tenant-*.mail.protection.outlook.com |
| Transport rules not applying | Rule priority wrong or disabled | Check rule order in Exchange admin center, enable rule |
| Users can't access shared mailbox | Permissions not delegated | Use Add-MailboxPermission with FullAccess for delegation |
| Send As not working | SendAs permission missing | Use Set/Add-RecipientPermission with SendAs rights |
| Mailbox quota being exceeded | Storage quota too low or user has large attachments | Increase quota or archive old messages |
| Audit logs not appearing | Auditing not enabled for mailbox | Run Get-Mailbox to verify AuditEnabled = $true |
| Retention policy not archiving | Policy not assigned to mailbox | Apply policy using Set-Mailbox RetentionPolicy parameter |

---

## Next Steps

1. Complete Exchange Online configuration
2. Proceed to sharepoint-branding.md for collaboration sites
3. Configure S/MIME for email encryption (if needed)
4. Set up mail flow for hybrid scenarios (if on-premises coexistence needed)
5. Progress to Phase 2: Security Compliance (DLP rules, message encryption)
