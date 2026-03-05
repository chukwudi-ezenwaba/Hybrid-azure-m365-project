# Phase 2: Security and Compliance Configuration

## Phase Overview

This phase implements Microsoft 365 defense-in-depth security architecture protecting against external threats, insider risks, and data loss. Zero Trust principles are enforced through multi-layer threat protection, data classification, and comprehensive audit logging.

**Duration**: 2 weeks  
**Key Objectives**: Defender configuration, DLP policies, message encryption, insider risk management, audit logging

---

## Task 1: Configure Microsoft Defender for Office 365

### Step 1.1: Enable Safe Links

Safe Links provides real-time protection against malicious URLs by detonating links in isolated sandbox environment before delivery.

**Configuration via Security Admin Center:**

1. Navigate to https://security.microsoft.com
2. Go to **Email & Collaboration** → **Policies & Rules** → **Threat policies** → **Safe Links**
3. Configure **Standard Protection**:
   - Click **Edit protection settings** (gear icon)
   - Enable "Block the following URLs"
   - Add URLs to block (examples):
     - `*evil-site.com`
     - `*malware.net`
   - Click **Save**

4. Configure **Policy for specific recipients** (Users):
   - Click **Create** to establish policy
   - **Name**: "Safe Links - All Users"
   - **Description**: "Default Safe Links policy for organization"
   - **Recipients**: Select "All" or specify groups/users
   - **Settings**:
     - Enable "On: Safe Links checks a list of suspicious links..."
     - Enable "Warn on potentially unsafe links"
     - Enable "Don't rewrite URLs, do checks via API"
   - Click **Save**

**PowerShell Configuration:**
```powershell
# Connect to Security & Compliance Center
Connect-IPPSSession

# Enable Safe Links policy
New-SafeLinksPolicy -Name "Safe Links - All Users" `
                    -AdminDisplayName "Safe Links policy for organization" `
                    -IsEnabled $true `
                    -ScanUrls $true `
                    -DeliverMessageAfterScan $true `
                    -TrackClicks $true `
                    -AllowClickThrough $false

# Apply policy to all users
New-SafeLinksRule -Name "Safe Links Rule - All Users" `
                  -SafeLinksPolicy "Safe Links - All Users" `
                  -RecipientDomainIs @("organization.onmicrosoft.com") `
                  -Enabled $true `
                  -Priority 0
```

**Validation:**
- Users receive warning when clicking suspicious links
- Known malicious URLs are rewritten
- No legitimate traffic is blocked

### Step 1.2: Enable Safe Attachments

Safe Attachments prevents zero-day exploits by analyzing file behavior in isolated sandbox before delivery.

1. In **Security Admin Center**, go to **Email & Collaboration** → **Safe Attachments**
2. Create policy:
   - **Name**: "Safe Attachments - All Email"
   - **Description**: "Default Safe Attachments policy"
   - **Safe Attachments Unknown Malware Response**: Select "Block"
   - **Redirect Attachment on Detection**: Enable and enter security team email
   - **Recipients**: All users
3. Click **Save**

**PowerShell Configuration:**
```powershell
# Create Safe Attachments policy
New-SafeAttachmentPolicy -Name "Safe Attachments - All Email" `
                         -AdminDisplayName "Default Safe Attachments protection" `
                         -Action Block `
                         -Enable $true `
                         -Redirect $true `
                         -RedirectAddress "security-team@organization.onmicrosoft.com"

# Create rule applying policy
New-SafeAttachmentRule -Name "Safe Attachments Rule - Organization" `
                       -SafeAttachmentPolicy "Safe Attachments - All Email" `
                       -RecipientDomainIs @("organization.onmicrosoft.com") `
                       -Enabled $true
```

**Validation:**
- Files are scanned before delivery
- Malicious attachments are quarantined
- Users receive notification of blocked file

### Step 1.3: Configure Anti-Phishing Policies

Anti-phishing provides sender verification, domain spoofing prevention, and machine learning-based detection.

1. Go to **Email & Collaboration** → **Anti-Phishing**
2. Configure default policy:
   - Enable "Phishing threshold": Set to "2 - Aggressive"
   - Enable "Impersonation protection":
     - Add users to protect (executives, finance staff)
     - Add domains to protect (organization domain)
   - Enable "Authentication checks":
     - SPF, DKIM, DMARC verification
   - Enable "Mailbox intelligence": Yes
3. Apply to all users
4. Click **Save**

**PowerShell Configuration:**
```powershell
# Create anti-phishing policy
New-AntiPhishPolicy -Name "Anti-Phishing - Organization" `
                    -AdminDisplayName "Default anti-phishing policy" `
                    -Enabled $true `
                    -PhishThresholdLevel 2 `
                    -EnableAntispoofingEnforcement $true `
                    -EnableMailboxIntelligence $true `
                    -EnableMailboxIntelligenceProtection $true

# Add protected users (high-value targets)
Set-AntiPhishPolicy -Identity "Anti-Phishing - Organization" `
                    -ImpersonationProtectionState On `
                    -TargetedUsersToProtect @("CEO@organization.onmicrosoft.com", "CFO@organization.onmicrosoft.com")
```

**Validation:**
- Spoofed emails detected and quarantined
- Protected users receive additional scrutiny
- DKIM/SPF failures result in policy action

### Step 1.4: Configure Anti-Malware Policies

Anti-malware detects and quarantines dangerous file types and malicious code.

1. Go to **Email & Collaboration** → **Anti-Malware**
2. Configure default policy:
   - Enable "Filter executable attachments": Yes
   - Enable "Scan shared attachments": Yes
   - Enable "Notification": Send to admins on detection
   - Enable "Quarantine": store detected malware
3. Click **Save**

**PowerShell Configuration:**
```powershell
# Create anti-malware policy
New-MalwareFilterPolicy -Name "Anti-Malware - Default" `
                        -AdminDisplayName "Default malware protection" `
                        -EnableExternalSenderAdminNotifications $true `
                        -EnableInternalSenderAdminNotifications $true `
                        -Action DeleteMessage `
                        -ZapEnabled $true

# Create rule
New-MalwareFilterRule -Name "Anti-Malware Rule - Organization" `
                      -MalwareFilterPolicy "Anti-Malware - Default" `
                      -SenderDomainIs @("*") `
                      -Enabled $true
```

---

## Task 2: Configure Data Loss Prevention (DLP) Policies

### Step 2.1: Create DLP Policy for Sensitive Data Types

DLP policies prevent accidental or intentional disclosure of sensitive information (PII, credit cards, health records).

1. Navigate to https://compliance.microsoft.com
2. Go to **Data Loss Prevention** → **Policies**
3. Click **Create Policy**
4. Select template: "Financial Information Protection"
5. Configure policy:
   - **Name**: "DLP - Financial Data Protection"
   - **Description**: "Prevents sharing of financial account numbers and credit cards"
   - **Locations**: 
     - Exchange Email: On
     - SharePoint Sites: On
     - OneDrive Accounts: On
     - Teams Chat: On

6. Configure rules:
   - **Rule Name**: "Detect Credit Card Numbers"
   - **Sensitive Info Types**: "Credit Card Number"
   - **Conditions**: 
     - If content contains a credit card number
     - AND is shared with people outside the organization
   - **Action**: 
     - Block users
     - Restrict access
     - Require business justification

7. Create additional rules for:
   - Social Security Numbers (detect SSN patterns)
   - Bank account numbers
   - PII (personal identifiable information)

**PowerShell Configuration:**
```powershell
# Connect to Compliance PowerShell
Connect-IPPSSession

# Create DLP policy
New-DlpCompliancePolicy -Name "DLP - Financial Data Protection" `
                        -Rules $rule `
                        -Comment "Prevents exposure of financial information" `
                        -Enabled $true

# Add sensitive info types to detect
$Rules = @( `
  (New-DlpComplianceRule -Name "DLP Rule - Credit Card" `
                         -Policy "DLP - Financial Data Protection" `
                         -BlockAccess $true `
                         -ContentContainsSensitiveInformation @{Name="Credit Card Number"; minCount="1"} `
                         -NotifyUser OnFailure), `
  (New-DlpComplianceRule -Name "DLP Rule - SSN" `
                         -Policy "DLP - Financial Data Protection" `
                         -BlockAccess $true `
                         -ContentContainsSensitiveInformation @{Name="U.S. Social Security Number (SSN)"; minCount="1"} `
                         -NotifyUser OnFailure)
)
```

### Step 2.2: Test DLP Policies

Before enforcement, test policies to ensure legitimate traffic isn't blocked:

1. Send test email containing sample credit card number: 4532 1234 5678 9010
2. Email should trigger DLP alert (test mode)
3. Verify alert appears in Security Admin Center
4. Adjust rules if false positives occur
5. After validation, move from test to enforcement mode

**Validation:**
- Test emails with sensitive data trigger DLP alerts
- Legitimate emails pass through unaffected
- Alerts visible in DLP reports

---

## Task 3: Configure Message Encryption & Mail Flow Rules

### Step 3.1: Enable Message Encryption

Message Encryption protects sensitive emails using 256-bit encryption:

1. Go to **Email & Collaboration** → **Message Encryption** (or https://admin.microsoft.com → **Mail Flow**)
2. Configure defaults:
   - Enable "Encrypt and Rights Protect"
   - Apply to "All messages"
3. Create mail flow rules:
   - **Rule Name**: "Encrypt Sensitive Emails"
   - **Condition**: If message contains sensitive info type (Credit Card, SSN, Health Record)
   - **Action**: Apply message encryption
   - **Enable**: Yes

**PowerShell Configuration:**
```powershell
# Create mail flow rule for automatic encryption
New-TransportRule -Name "Encrypt Emails with Sensitive Data" `
                  -Comments "Automatically encrypts emails containing sensitive information" `
                  -Priority 0 `
                  -Enabled $true `
                  -FromScope "InOrg" `
                  -ToScope "NotInOrg" `
                  -SubjectOrBodyContainsWords @("confidential", "proprietary", "restricted") `
                  -ApplyRightsProtectionTemplate "Encrypt"
```

**Validation:**
- Emails marked "confidential" are encrypted
- Recipients see "Message Encryption" notification
- Can't forward encrypted email without permission

---

## Task 4: Enable Insider Risk Management

Insider Risk Management detects and responds to risky activities by employees:

1. Go to **Risk Management** → **Insider Risk Management** (https://compliance.microsoft.com/insiderriskmanagement)
2. Click **Settings** → **Policy Templates**
3. Enable policies:
   - **Data Exfiltration**: Flag unusual file downloads, email sending
   - **Policy Violation**: Users accessing restricted documents
   - **Security Violation**: Installation of security tools, bypassing controls
   - **Regulatory Violation**: Unauthorized external communication

4. Configure **Data Loss Prevention** alerts:
   - Sensitivity level: Medium and High
   - Include all users in scope

5. Click **Turn on Insider Risk Management**

**Validation:**
- Risk indicators visible in dashboard
- Alerts triggered for risky activities
- Investigation workflows established

---

## Task 5: Enable Unified Audit Logging

Audit logging provides forensic trails for investigation and compliance:

1. Go to **Compliance** → **Audit** (https://compliance.microsoft.com/auditlogsearch)
2. Verify audit logging is enabled (should be automatic)
3. Configure **Audit Log Retention**:
   - Go to **Settings** → **Audit Log Retention**
   - Set to "1 Year" (organizations can extend to 10 years with E5)

4. Create search to verify logging:
   - Go to **New Search**
   - Select **Activities**: "All activities"
   - **Date Range**: Last 7 days
   - Click **Search**
   - Should see administrative activities logged

**PowerShell Configuration:**
```powershell
# Enable audit logging for all activities
Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled $true

# Search audit logs for specific activity
Search-UnifiedAuditLog -StartDate (Get-Date).AddDays(-30) `
                       -EndDate (Get-Date) `
                       -Activities "New-TransportRule", "Set-TransportRule" `
                       -ResultSize 5000
```

---

## Task 6: Create Audit Alert Policies

Alert policies automate notification of security-relevant events:

1. Go to **Alert Policies** (https://compliance.microsoft.com/alertpolicies)
2. Create policies:

**Policy 1: Mass File Deletion**
- **Name**: "Alert - Mass File Deletion"
- **Trigger**: 20+ files deleted in 5 minutes
- **Severity**: Medium
- **Notification**: Send to security team

**Policy 2: Multiple Failed Email Logins**
- **Name**: "Alert - Multiple Failed Login Attempts"
- **Trigger**: 10+ failed logins in 5 minutes
- **Severity**: High
- **Notification**: Send to security team + incident response

**Policy 3: DLP Policy Violations**
- **Name**: "Alert - DLP Violation"
- **Trigger**: Sensitive data detected in email
- **Severity**: Medium
- **Notification**: Send to security team

**PowerShell Configuration:**
```powershell
# Create mass file deletion alert
New-ActivityAlert -Name "Alert - Mass File Deletion" `
                  -Severity Medium `
                  -AggregationType "SimpleAggregation" `
                  -AlertType "MassDeleteAlert" `
                  -TriggerValue 20 `
                  -NotificationEmails "security-team@organization.onmicrosoft.com"
```

---

## Validation Checklist

- [ ] Safe Links enabled and tested
- [ ] Safe Attachments enabled and tested
- [ ] Anti-phishing policies blocking spoofed emails
- [ ] Anti-malware protection detecting suspicious files
- [ ] DLP policies created and tested (no false positives)
- [ ] Message encryption enabled for sensitive emails
- [ ] Insider Risk Management dashboard showing activities
- [ ] Audit logging enabled (90-day minimum retention)
- [ ] Alert policies created and tested
- [ ] Secure Score improved to 50%+

---

## Common Issues & Troubleshooting

**Issue**: Users report DLP blocking legitimate emails
- **Cause**: Policy rules too aggressive, false positive
- **Solution**: Review rule conditions, add exclusions for departments, adjust sensitivity

**Issue**: Encrypted emails not decrypting for external recipients
- **Cause**: Recipient not set up for encryption, incorrect policy scope
- **Solution**: Verify recipient email format, ensure encryption policy applied correctly

**Issue**: Audit logs not showing recent activities
- **Cause**: Logging not enabled, retention expired, activity not logged type
- **Solution**: Verify audit logging enabled, check activity is auditedtype, provide more time for logs to populate

---

*Phase 2 Completion Date: ___________*
*Document Version: 1.0*
*Last Updated: March 2, 2026*
