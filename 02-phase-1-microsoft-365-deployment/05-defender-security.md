# Microsoft Defender for Office 365 Configuration

## Overview

Microsoft Defender for Office 365 provides advanced threat protection for email, collaboration tools, and cloud environments. This guide covers setup and configuration of Safe Links, Safe Attachments, anti-phishing policies, and threat intelligence integration.

**Duration**: 1-2 days  
**Requires**: Global Administrator or Security Administrator role  
**Depends On**: Microsoft 365 tenant with E5 or Defender for Office 365 licenses

---

## Pre-Configuration Checklist

- [ ] Microsoft 365 tenant created and verified
- [ ] Global Administrator access confirmed
- [ ] E5 or standalone Defender for Office 365 licenses assigned
- [ ] All users synchronized to tenant
- [ ] Exchange Online mailboxes provisioned
- [ ] MFA enabled on admin account
- [ ] Browser with Microsoft 365 admin access ready

---

## Task 1: Enable Microsoft Defender for Office 365

### Step 1.1: Verify Defender License

1. Navigate to **Microsoft 365 admin center** → https://admin.microsoft.com
2. Go to **Billing** → **Licenses**
3. Verify license availability:
   - E5 includes Defender for Office 365 Plan 2
   - Standalone: Microsoft Defender for Office 365 (Plan 1 or 2)
4. Check **User licenses** to ensure users are assigned E5

**PowerShell Verification:**
```powershell
Connect-ExchangeOnline
Get-MsolUser | Where-Object {$_.Licenses} | Select-Object DisplayName, Licenses
# Look for: SPO_Enitity License shows E5 or Defender for Office 365
```

### Step 1.2: Enable Defender Features

1. Go to **Security & Compliance Center** → https://protection.office.com
2. Navigate to **Threat Management** → **Policy** → **Safe Links**
3. Verify "Global settings" shows **Defender for Office 365 Plan 2** enabled
4. Repeat check for:
   - **Safe Attachments** (under Threat Management)
   - **Anti-phishing** (under Threat Management)
   - **Anti-spam** settings
5. All should show green checkmarks indicating active protection

**Validation:**
- Global settings display current Defender edition
- All threat protection policies accessible without errors
- Sample policy templates visible in each category

---

## Task 2: Configure Safe Links Policy

Safe Links checks URLs in real-time when users click them, protecting against phishing and malware hosted on external sites.

### Step 2.1: Create Organization-Wide Safe Links Policy

1. In **Microsoft 365 Defender** portal → https://security.microsoft.com
2. Go to **Email & Collaboration** → **Policies & Rules** → **Threat policies** → **Safe Links**
3. Click **+ Create** (or edit "Default" if exists)
4. **Name**: "Organization-Wide Safe Links Policy"
5. **Description**: "Protects all users against malicious URL clicks"

### Step 2.2: Configure Safe Links Settings

**URL Rewriting Settings:**
1. Under **Email** section:
   - Enable ✓ **Rewrite URLs and check through Microsoft Defender for Office 365 when user clicks the link**
   - Enable ✓ **Apply Safe Links to email messages sent within the organization**
2. Under **Microsoft Teams** section:
   - Enable ✓ **Apply Safe Links to Microsoft Teams**
3. Under **Office 365 Apps** section:
   - Enable ✓ **Apply Safe Links to Office 365 desktop applications**
   - Enable ✓ **Track URL clicks** (useful for forensics)

**Click Protection Settings:**
1. Set **Do not let users click through to the original URL**: **On**
   - This prevents users from bypassing Safe Links warnings
2. Set **Notification**: "Block the access, show warning message"
3. Enable ✓ **Warn users before tracking if Office 365 apps are used**

### Step 2.3: Configure User Click Behavior

1. Set **Timeout**: 3 seconds (gives Microsoft time to check URL)
2. Enable ✓ **Warn users if the URL is identified as malicious**
3. Enable ✓ **Show warning to users when they click suspicious links**
4. Set **Allow users to click through safe**: **Off** (enforce protection)

**PowerShell Configuration:**
```powershell
# Create Safe Links policy
New-SafeLinksPolicy -Name "Organization-Wide Safe Links Policy" `
  -IsEnabled $true `
  -AllowClickThrough $false `
  -DisableUrlRewrite $false `
  -ScanUrls $true `
  -TrackClicks $true `
  -DeliverMessageAfterScan $true

# Create Safe Links rule
New-SafeLinksRule -Name "Apply Safe Links to All Recipients" `
  -SafeLinksPolicy "Organization-Wide Safe Links Policy" `
  -RecipientDomainIs "organization.onmicrosoft.com" `
  -Priority 0
```

### Step 2.4: Validate Safe Links Deployment

1. Send test email from internal user to external email address with URL:
   ```
   Test URL: https://www.microsoft.com
   ```
2. Recipient clicks link, should see:
   - URL appears rewritten as: `https://nam01.safelinks.protection.outlook.com/?url=...`
   - Minimal delay (3 seconds) while Safe Links checks URL
   - Browser warning if URL is flagged as malicious
3. Check Safe Links logs:
   - **Threat Management** → **Review** → **Threat Logs**
   - Filter: URLs, Malware, Phishing

**Validation Checklist:**
- [ ] URL rewriting occurs transparently
- [ ] No delay >5 seconds per click
- [ ] Safe Links warning displays correctly
- [ ] Users cannot bypass protection
- [ ] Logs show URL checks processed

---

## Task 3: Configure Safe Attachments Policy

Safe Attachments detonates suspicious attachments in isolated sandbox environment before delivery.

### Step 3.1: Create Safe Attachments Policy

1. In **Microsoft 365 Defender** → **Email & Collaboration** → **Policies & Rules** → **Threat policies** → **Safe Attachments**
2. Click **+ Create**
3. **Name**: "Organization-Wide Safe Attachments Policy"
4. **Description**: "Sandboxes suspicious attachments for 24-48 hours"

### Step 3.2: Configure Attachment Protection

**Detection Mode:**
1. Set **Safe Attachments unknown malware response**: **Block** (most restrictive)
   - Options: Off, Monitor, Block, Replace
   - Block = prevents delivery until cleared by sandbox
2. Enable ✓ **Redirect attachments on detection**
   - Set Administrator email: security@organization.com
   - Allows security team to review flagged attachments

**Dynamic Delivery:**
1. Enable ✓ **Apply dynamic protection**
   - Allows users to open Office documents while scanning
   - Protects from macro-based malware
2. Set **Timeout**: 60 seconds (wait time before allowing document)
3. Enable ✓ **Send preview text** during analysis period

### Step 3.3: File Type Extensions

1. Ensure following extensions are always scanned:
   - Executable: .exe, .msi, .cmd, .bat, .scr, .vbs, .ps1
   - Documents: .docm, .xlsm, .pptm, .jar
   - Archives: .zip, .rar, .7z
   - Other: .iso, .img, .vhd

2. Set **Exception** for safe file types (optional):
   - .pdf (if external PDFs trusted)
   - .jpg, .png, .txt (rarely malicious)
   - NOTE: Be conservative; recommend blocking all unknowns

**PowerShell Configuration:**
```powershell
# Create Safe Attachments policy
New-SafeAttachmentPolicy -Name "Organization-Wide Safe Attachments Policy" `
  -Enable $true `
  -Action Block `
  -Redirect $true `
  -RedirectAddress "security@organization.com" `
  -UnknownMalwareAction Block

# Create Safe Attachments rule
New-SafeAttachmentRule -Name "Apply Safe Attachments to All Recipients" `
  -SafeAttachmentPolicy "Organization-Wide Safe Attachments Policy" `
  -RecipientDomainIs "organization.onmicrosoft.com" `
  -Priority 0
```

### Step 3.4: Test Safe Attachments

1. Use **EICAR test file** (recognized safe malware test):
   ```
   X5O!P%@AP[4\PZX54(P^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*
   ```
2. Create .txt file with above content, compress to .zip
3. Send from external email to internal user
4. Expected behavior:
   - Email reaches inbox with attachment blocked/sandboxed
   - Administrator receives redirect notification
   - Safe Attachments report shows detection

**Validation Checklist:**
- [ ] Suspicious attachment blocked from delivery
- [ ] Administrator notified of flagged attachment
- [ ] User receives notification of blocked attachment
- [ ] Attachment released after sandbox clearance (24-48 hours)
- [ ] Safe Attachments report logs detection

---

## Task 4: Configure Anti-Phishing Policies

Anti-phishing detects impersonation attacks targeting executives and employees.

### Step 4.1: Create Organization Anti-Phishing Policy

1. In **Microsoft 365 Defender** → **Email & Collaboration** → **Policies & Rules** → **Threat policies** → **Anti-phishing**
2. Click **+ Create**
3. **Name**: "Organization-Wide Anti-Phishing Policy"
4. **Description**: "Protects against executive impersonation and domain spoofing"

### Step 4.2: Configure Impersonation Protection

**User Impersonation:**
1. Enable ✓ **Enable impersonation protection**
2. Add protected users (executives, high-value targets):
   ```
   CEO@organization.com
   CFO@organization.com
   CTO@organization.com
   Security Admin@organization.com
   ```
3. Set **If email is sent by an impersonated user**: **Quarantine**
   - More restrictive than Junk; requires admin review

**Domain Impersonation:**
1. Enable ✓ **Enable domain impersonation protection**
2. Add custom domains:
   ```
   organization.com
   organization.net
   subsidiary.com
   ```
3. Set **If email is sent by an impersonated domain**: **Quarantine**
4. Enable ✓ **Enable mailbox intelligence**
   - Machine learning learns normal communication patterns
   - Detects anomalous sender behavior

**Spoof Intelligence:**
1. Enable ✓ **Enable spoof intelligence**
   - Identifies domains spoofing your organization
2. Set **Apply spoofing protection**: **Enabled**
3. Set **Unauthenticated sender notification**: **Enabled**
   - Shows "?" icon in Outlook for unverified senders

### Step 4.3: Configure Authentication Safeguards

**DMARC/SPF/DKIM:**
1. Ensure DMARC policy published (subdomain):
   ```
   _dmarc.organization.com: v=DMARC1; p=reject; fo=1; rua=mailto:security@organization.com
   ```
2. SPF record must exist:
   ```
   v=spf1 include:spf.protection.outlook.com ~all
   ```
3. Verify DKIM signing enabled:
   - **Settings** → **Domains** → organization.com → **Records**
   - Confirm CNAME records for DKIM selector1, selector2

### Step 4.4: Configure Safety Tips

1. Set **Show (?) for unauthenticated senders**: **On**
   - Users see "?" badge for emails lacking SPF/DKIM/DMARC
2. Set **Show user impersonation safety tip**: **On**
3. Set **Show domain impersonation safety tip**: **On**
4. Set **Show strange characters safety tip**: **On**
   - Detects homograph attacks (е vs e in Cyrillic)

**PowerShell Configuration:**
```powershell
# Create anti-phishing policy
New-AntiPhishPolicy -Name "Organization-Wide Anti-Phishing Policy" `
  -EnableAntispoofEnforcement $true `
  -EnableMailboxIntelligence $true `
  -EnableMailboxIntelligenceProtection $true `
  -Enabled $true `
  -PhishThresholdLevel 2 `
  -AllowedToSpoof @() `
  -ImpersonationProtectionState On

# Add protected users
Set-AntiPhishPolicy -Identity "Organization-Wide Anti-Phishing Policy" `
  -ExcludedDomains @("trusted-partner.com") `
  -TargetedDomainProtectionAction Quarantine `
  -TargetedUserProtectionAction Quarantine

# Create anti-phishing rule
New-AntiPhishRule -Name "Apply Anti-Phishing to All Recipients" `
  -AntiPhishPolicy "Organization-Wide Anti-Phishing Policy" `
  -RecipientDomainIs "organization.onmicrosoft.com" `
  -Priority 0
```

### Step 4.5: Test Anti-Phishing

1. **Impersonation Test**: Send email appearing from CEO@organization.com (from external account)
   - Should be quarantined; flagged as impersonation attempt
   - Security admin can review in Quarantine folder

2. **Domain Spoof Test**: Send from attacker@organization-typo.com (domain variation)
   - Should show (?) safety tip
   - May be quarantined depending on DMARC policy

**Validation Checklist:**
- [ ] Impersonation email properly quarantined
- [ ] Safety tips display in Outlook
- [ ] DMARC/SPF/DKIM records verified
- [ ] Protected user list updated
- [ ] Anti-phishing report shows detections

---

## Task 5: Configure Malware and Spam Policies

### Step 5.1: Malware Detection Settings

1. **Microsoft 365 Defender** → **Email & Collaboration** → **Policies & Rules** → **Threat policies** → **Anti-malware**
2. Configure **Default anti-malware policy**:
   - **Malware Scanning**: On
   - **Common Attachments Type Filtering**: On
   - **Execute**: Quarantine
   - **Admin Notifications**: security@organization.com

### Step 5.2: Spam and Bulk Email Settings

1. Go to **Threat policies** → **Anti-spam inbound policy**
2. Set **Spam threshold**: 7 (high sensitivity, 1=highest)
3. Set **High confidence spam action**: Quarantine
4. Enable ✓ **Bulk email action**: Quarantine
5. Set **Quarantine retention**: 30 days

### Step 5.3: Advanced Filtering Settings

1. Go to **Settings** → **Mail flow** → **Exchange transport rules**
2. Create rule to block dangerous file types:
   ```
   Name: "Block Dangerous File Extensions"
   Apply this rule: If attachment has these properties: Include any of these words
   Attachments have properties: File name includes [.exe, .msi, .bat, .cmd, .vbs, .scr, .com]
   Action: Block the message
   ```

3. Create rule to block external executable files:
   ```
   Name: "Block External Executables"
   Apply this rule: If sender location is: Outside the organization
   AND attachment has these properties: Include [.exe, .msi]
   Action: Block the message and send notification
   ```

**Validation Checklist:**
- [ ] Spam emails properly redirected to Junk
- [ ] Malware attempts blocked/quarantined
- [ ] Dangerous file types blocked on entry
- [ ] Admin receives notifications

---

## Task 6: Configure Threat Investigation and Response (TIER)

### Step 6.1: Enable Automated Investigation

1. **Microsoft 365 Defender** → **Settings** → **Email & collaboration** → **Automated investigation and response**
2. Enable ✓ **Automatically run investigation**
3. Set **Threat level to trigger investigation**: Medium and High
4. Enable ✓ **Automatically take remedial actions when threats are detected**
5. Set **Approval level**: Security operator approval for critical actions

### Step 6.2: Configure Alert Policies

1. Go to **Microsoft 365 Defender** → **Alerts** → **Alert policies**
2. Create new alert:
   - **Name**: "Malware Detected in Email"
   - **Activity**: Malware detected in email
   - **Alert detection**: For each activity
   - **Recipients**: security@organization.com
   - **Severity**: High

3. Create another alert:
   - **Name**: "Phishing Email Detected"
   - **Activity**: Phishing email detected
   - **Recipients**: security@organization.com
   - **Severity**: High

### Step 6.3: Review Threat Logs

1. **Microsoft 365 Defender** → **Threat analytics**
2. View current threat trends
3. Subscribe to relevant threat analytics reports
4. Set up scheduled reports:
   - **Report Type**: Threat analytics summary
   - **Frequency**: Weekly
   - **Recipients**: security@organization.com

---

## Task 7: Monitor and Report

### Step 7.1: Access Security Dashboards

1. **Microsoft 365 Defender** → **Reports** → **Email & collaboration** → **Threat protection status**
2. Shows:
   - Malware detections (chart)
   - Phishing detections (chart)
   - Spam detections (chart)
   - Top malware/phishers/senders

### Step 7.2: Export Reports

**PowerShell Command:**
```powershell
# Export malware report
Get-MailTrafficATPReport -AggregateBy Day -StartDate (Get-Date).AddDays(-30) | Export-Csv "malware_report.csv"

# Export phishing report
Get-PhishFilterPolicy | Export-Csv "phishing_policy_report.csv"

# Export Safe Links clicks
Get-SafeLinksDetailedReport -StartDate (Get-Date).AddDays(-7) | Export-Csv "safe_links_report.csv"
```

### Step 7.3: Create Dashboard in Power BI (Optional)

1. Connect to Microsoft 365 Defender API
2. Pull threat logs and create visualizations:
   - Malware detections by day
   - Phishing attempts by sender domain
   - User click-through rates (Safe Links)
   - Attachment block rates

---

## Validation Checklist

- [ ] Safe Links policy created and applied globally
- [ ] Safe Attachments policy blocks suspicious files
- [ ] Anti-phishing detects domain spoofing
- [ ] Malware detection rules active
- [ ] Spam policies configured
- [ ] Admin receives threat notifications
- [ ] Test emails trigger appropriate responses
- [ ] Threat logs accessible and searchable
- [ ] Security dashboards display metrics
- [ ] Team trained on Defender features

---

## Common Issues & Troubleshooting

| Issue | Cause | Solution |
|-------|-------|----------|
| Safe Links not rewriting URLs | Policy not assigned to users | Verify rule applies to recipients, check rule priority |
| Users bypass Safe Links warnings | AllowClickThrough set to True | Set AllowClickThrough to False in policy |
| False positives blocking legitimate emails | Detection threshold too aggressive | Adjust Phish Threshold Level to 1-2, not 3 |
| Attachments not being sandboxed | Dynamic Delivery not enabled | Enable "Apply dynamic protection" in Safe Attachments policy |
| Malware not detected | Anti-malware policy not assigned | Create explicit anti-malware rule for all recipients |
| Spam reaching inbox | Spam threshold set too low | Increase threshold to 7-9; verify SPF/DKIM/DMARC records |

---

## Next Steps

1. Complete Microsoft Defender configuration
2. Proceed to exchangeonline.md for email routing and transport rules
3. Configure anti-spam and anti-malware at organization level
4. Train security team on threat investigation tools
5. Establish incident response procedures using TIER alerts
6. Progress to Phase 2: Security Compliance (DLP, encryption, audit logging)
