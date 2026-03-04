# Comprehensive Implementation Guide: Hybrid Azure & Microsoft 365 Deployment

**A detailed, step-by-step technical guide for deploying enterprise hybrid cloud infrastructure**

---

## Table of Contents

1. [Planning Phase](#planning-phase)
2. [Phase 1: Microsoft 365 Foundation](#phase-1-microsoft-365-foundation)
3. [Phase 2: Security Hardening](#phase-2-security-hardening)
4. [Phase 3-4: Collaboration & Monitoring](#phase-3-4-collaboration--monitoring)
5. [Phase 5-7: Hybrid Identity & Azure Infrastructure](#phase-5-7-hybrid-identity--azure-infrastructure)
6. [Phase 8-11: Migration, Governance & Device Management](#phase-8-11-migration-governance--device-management)
7. [Automation Best Practices](#automation-best-practices)
8. [Troubleshooting & Support](#troubleshooting--support)

---

## Planning Phase

### Concept: Why Start with Planning?

A failed deployment often results from poor planning, not poor execution. This phase establishes:
- **Clear success criteria** (how will you know it worked?)
- **Resource allocation** (who does what, when?)
- **Risk mitigation** (what could go wrong?)
- **Stakeholder alignment** (does everyone agree on the scope?)

### Pre-Deployment Checklist

Before executing ANY phases, verify:

#### Budget & Licensing
```
✓ M365 E3/E5 licenses purchased (qty: all employees)
✓ Entra ID Premium P1 licenses (qty: all users + buffer)
✓ Azure subscription funded ($500-2000/month budget)
✓ Intune licenses (included in M365 E3+)
✓ Azure Backup/Site Recovery enabled in subscription
```

#### Technical Prerequisites
```
✓ On-premises Active Directory deployed (2+ domain controllers)
✓ AD contains all user accounts (synchronized before AAD Connect)
✓ Network connectivity between on-prem and Azure
✓ VPN Gateway capacity planned (site-to-site IPsec)
✓ DNS forwarder configured for name resolution
✓ Firewall rules allow Office 365 endpoints (outbound 443/TCP)
```

#### Team & Skills
```
✓ Cloud Architect assigned (phases 5-7)
✓ Security Engineer assigned (phases 2-4)
✓ IT Operations staff trained on M365
✓ Helpdesk trained on user provisioning
✓ Executive sponsor identified (project governance)
✓ Change management lead engaged
```

#### Stakeholder Communication
```
✓ Deployment timeline shared with leadership
✓ User communication plan drafted
✓ Department heads briefed on changes
✓ Executive steering committee scheduled (weekly during deployment)
```

---

## Phase 1: Microsoft 365 Foundation

### Concept: Building the Cloud Tenant

Before users can access the cloud, you need:

1. **M365 Tenant** - The "container" for all your cloud services
2. **Users** - Provisioned in the cloud
3. **Licenses** - Assigned to enable features
4. **Email** - Routing configured
5. **Security baseline** - Protecting the tenant from day 1

### Week 1: Tenant Creation & User Provisioning

#### Step 1.1: Claim Your M365 Tenant Domain

**Background**: M365 provides a default `.onmicrosoft.com` domain, but organizations use a custom domain (e.g., `organization.com`) for branding and continuity.

**Execution**:

1. Go to Microsoft 365 Admin Center → **Settings** → **Domains**
2. Click **Add domain** → Enter your custom domain (e.g., `organization.com`)
3. Verify domain ownership:
   - **DNS option**: Add TXT record to your registrar:
     ```
     Record: ms=mxxxxxxxx (provided by M365)
     TTL: 3600
     ```
   - Wait 10-15 minutes for DNS propagation
4. Complete domain setup:
   - Configure mail routing (MX record points to M365)
   - Configure SPF record (authorize M365 to send mail)
     ```
     v=spf1 include:spf.protection.outlook.com ~all
     ```

**Validation**:
```
nslookup organization.com  # Verify MX record points to outlook.com servers
dig organization.com TXT   # Verify SPF record
```

#### Step 1.2: Create Global Admin Accounts

**Background**: Global Admins have unrestricted access to M365. This role is dangerous - minimize the number and protect them rigorously.

**Execution**:

1. M365 Admin Center → **Users** → **Active users**
2. Create 2-3 Global Admin accounts (separate from regular user accounts):
   - `admin@organization.com` (primary)
   - `admin2@organization.com` (backup)
   - `emergencyaccess@organization.com` (break-glass, rarely used)

3. Set strong passwords (20+ characters, symbols, numbers)
4. File passwords in secure vault (not email, not sticky notes)

**Security Best Practice**: Global Admins should use MFA immediately. See Step 1.5.

#### Step 1.3: Bulk-Create Users from CSV

**Background**: Adding 100+ users manually is impractical. PowerShell bulk provisioning is 100x faster and less error-prone.

**Preparation File** (`users.csv`):
```csv
UserPrincipalName,DisplayName,FirstName,LastName,Department,UsageLocation,MailNickname
user1@organization.com,Alice Smith,Alice,Smith,IT,US,alice.smith
user2@organization.com,Bob Johnson,Bob,Johnson,Sales,US,bob.johnson
user3@organization.com,Carol Davis,Carol,Davis,Finance,US,carol.davis
```

**Execution** using `13-automation/powershell/02-create-users.ps1`:

```powershell
cd 13-automation/powershell
.\01-connect-services.ps1  # Authenticate to M365

# Preview (no changes yet)
.\02-create-users.ps1 -csvPath users.csv -preview

# Apply (creates users)
.\02-create-users.ps1 -csvPath users.csv -apply
```

**Output**:
```
Created users: 3 total
- user1@organization.com ✓
- user2@organization.com ✓
- user3@organization.com ✓
Errors: 0
```

**Validation**:
```powershell
# Verify users in cloud
Get-MsolUser | Select UserPrincipalName, DisplayName | ft
```

#### Step 1.4: Assign Microsoft 365 Licenses

**Background**: Without a license, users can't access Exchange, Teams, or SharePoint. E3 vs E5 determines feature access.

**License Comparison**:

| Feature | E3 | E5 |
|---------|----|----|
| Email (Exchange) | ✓ | ✓ |
| Teams | ✓ | ✓ |
| SharePoint | ✓ | ✓ |
| OneDrive 1TB | ✓ | ✓ |
| MFA | ✓ | ✓ |
| Threat Intelligence | ✗ | ✓ |
| Advanced Analytics | ✗ | ✓ |
| eDiscovery | Limited | Full |
| Cost | ~$20/user | ~$35/user |

**Assignment Strategy**:
- **E5**: IT staff, security-sensitive roles (finance, HR), executives
- **E3**: All other employees

**Preparation File** (`licenses.csv`):
```csv
UserPrincipalName,LicenseType
user1@organization.com,E5
user2@organization.com,E3
user3@organization.com,E3
```

**Execution** using `13-automation/powershell/03-license-assignment.ps1`:

```powershell
.\03-license-assignment.ps1 -licensePath licenses.csv -preview

# Review output for errors before applying
.\03-license-assignment.ps1 -licensePath licenses.csv -apply
```

**Validation**:
```powershell
# Verify licenses assigned
Get-MsolUser -All | Select UserPrincipalName, Licenses
```

### Week 2: Exchange Online & SharePoint Setup

#### Step 1.5: Configure Exchange Online

**Background**: Exchange Online handles email routing, shared mailboxes, and mailbox policies for the organization.

**Execution**:

1. Create shared mailboxes (support@, finance@, noreply@):

```powershell
.\04-mailbox-setup.ps1 -sharedMailboxes @('support','finance','noreply')
```

2. Configure mail routing:

```powershell
# Add domain as accepted domain
Set-AcceptedDomain -Identity "organization.com" -Authorized $true

# Enable DKIM signing for brand protection
Set-DkimSigningConfig -Identity organization.com -Enabled $true
```

3. Configure retention policies:

```powershell
# Keep email for 7 years (compliance requirement)
New-RetentionPolicy -Name "7-Year Retention" -RetentionPolicyTagLinks "Default 7 years"

# Deleted items recovery: 30 days
Set-Mailbox -Identity  user@organization.com -RetentionPolicy "7-Year Retention"
```

**Validation**:
```
✓ Send test email from external account to user@organization.com → arrives
✓ Reply works from user@organization.com
✓ Shared mailbox (support@) receives messages
✓ Mail.outlook.com loads without errors
```

#### Step 1.6: Create SharePoint Team Sites

**Background**: SharePoint provides centralized document collaboration and intranet capabilities.

**Execution**:

1. M365 Admin Center → **SharePoint** → **Create site**

2. Create 4 team sites (one per major department):
   - **IT Department** site
   - **Sales Department** site
   - **Finance Department** site
   - **HR Department** site

3. For each site:
   - Set owner (department head)
   - Create default libraries: Documents, References, Archive
   - Configure permissions:
     - Department staff: Edit
     - Other departments: Read (dashboards, company info)
     - External partners: None (by default)

**PowerShell Alternative**:
```powershell
$siteUrl = "https://organization.sharepoint.com/sites/IT"
New-PnPSite -Type TeamSite -Title "IT Department" -Alias "it"

# Add document library
Add-PnPList -Title "Shared Documents"
```

**Validation**:
```
✓ Navigate to SharePoint home: https://organization.sharepoint.com
✓ Team sites visible in "Recent sites"
✓ Upload test document → download works
✓ Version history enabled (previous versions accessible)
```

#### Step 1.7: Establish Security Baseline

**Background**: Security threats begin on Day 1. Activate protections immediately, even if fully configured later.

**Execution**:

1. **Enable Admin MFA** (required for Phase 1 completion):

```powershell
.\08-enable-mfa.ps1 -scope "admin"
```

This requires each admin to:
- Download Microsoft Authenticator app
- Scan QR code to register device
- Test login: requires app approval

2. **Enable Safe Links** (email protection):

```powershell
# Enable Safe Links for all email
Set-SafeLinksPolicy -Identity Default -EnableSafeLinksForOffice -Enabled $true
```

3. **Enable Safe Attachments** (malware scanning):

```powershell
Set-SafeAttachmentPolicy -Identity Default -Enable $true -Action Block
```

4. **Enable Audit Logging**:

```powershell
Set-AdminAuditLogConfig -UnifiedAuditLogSuspended $false
```

**Validation**:
```
✓ Admin login attempt → MFA required in Authenticator app
✓ Admin clicks "Approve" → login succeeds
✓ Admin clicks "Deny" → login fails after timeout
✓ M365 Defender dashboard shows threats blocked
```

---

## Phase 2: Security Hardening

### Concept: Shift from Prevention to Prediction

Phase 1 established basic security. Phase 2 implements advanced threat detection and data protection.

### Conditional Access: Dynamic Security Policy

**Background**: Conditional Access evaluates risk factors at login time and adapts the response:
- User anomaly detected? Require MFA re-verification.
- Login from untrusted location? Block or challenge.
- Non-compliant device? Deny access.

**Setup**:

1. **Rule 1: Block Legacy Authentication**

```
Condition: Legacy auth protocol (IMAP, POP, SMTP AUTH)
Action: Block
Exception: Emergency access accounts (2 only)
```

Legacy auth is 2x more likely to be compromised. Blocking eliminates a major attack vector.

2. **Rule 2: Require MFA for Risky Logins**

```
Condition: Sign-in risk = High (Microsoft AI detects anomaly)
Action: Require MFA + password refresh
Exception: None
```

3. **Rule 3: Restrict Untrusted Locations**

```
Condition: Login location NOT in (Office, VPN, Home IP whitelist)
Action: Block or Require MFA
```

### Data Loss Prevention (DLP): Protecting Sensitive Data

**Background**: DLP scans outbound communications for sensitive patterns:
- Social Security Numbers (SSN: 123-45-6789)
- Credit card numbers (16-digit patterns)
- Driver's license numbers

When detected, DLP can:
- Block (quarantine email)
- Alert (notify security team)
- Log (record for audit)

**Policies to Create**:

```
Policy 1: Block PII in External Email
├─ Trigger: Email contains SSN, credit card, driver's license
├─ Recipient: External (@...)
└─ Action: Block + Alert security team

Policy 2: Large File Transfer Alert
├─ Trigger: Attachment >100MB
├─ Recipient: External
└─ Action: Alert (allow with logging)

Policy 3: Credit Card Detection
├─ Trigger: Email contains credit card pattern
├─ Recipient: Anyone
└─ Action: Block (internal financial info)
```

---

## Phase 3-4: Collaboration & Monitoring

### Teams Governance: Scale Without Chaos

**Background**: Teams enables collaboration but can become chaotic without governance:
- Teams created without control → sprawling team inventory (hard to find teams)
- No naming standard → "team123", "projectX2", "tmp" clutter namespace
- No retention → deleted messages irretrievable
- No member limits → security risk with guest access

**Governance Rules**:

```
1. Team Creation: Department heads only (PowerShell approval)
2. Naming: [DEPT]-[PURPOSE] format (e.g., "IT-Operations", "Sales-Q1Planning")
3. Guest Access: Limited to 30-day expiry (requires re-approval)
4. Retention: 1 year active, 7 years archived
5. External Sharing: SharePoint only (no direct Teams sharing outside company)
```

### Monitoring: Observability Before Incidents

**Background**: You can't fix what you don't see. Monitoring provides:
- **Real-time visibility** into system health
- **Early warning** before incidents impact users
- **Audit trail** for compliance and incident investigation
- **Trending data** for capacity planning

**Dashboards to Create**:

```
1. M365 Security Dashboard
   ├─ Threats blocked (by type)
   ├─ DLP policy hits (by severity)
   ├─ Conditional Access denials (by reason)
   └─ Malware detected (by user)

2. User Adoption Dashboard
   ├─ Email usage (peak hours, volume)
   ├─ Teams active users (daily, weekly)
   ├─ SharePoint site visits (trending)
   └─ OneDrive sync status (healthy/failed)

3. Compliance Dashboard
   ├─ Audit log ingestion (lag < 1 hour)
   ├─ Retention policies active
   ├─ eDiscovery hold count
   └─ Deleted item recovery available
```

---

## Phase 5-7: Hybrid Identity & Azure Infrastructure

### Concept: Connecting Two Worlds

Your organization now has:
- **On-premises identity** (AD DS, authoritative source)
- **Cloud identity** (Entra ID, required for M365)

These must be synchronized and coordinated.

### Azure AD Connect: The Sync Engine

**Background**: AAD Connect is installed on-premises and continuously syncs user identities from AD DS to Entra ID.

**Sync Process**:

```
On-Premises AD
    ↓ (object sync every 30 min delta)
AAD Connect
    ↓ (import + export + password hash)
Entra ID
    ↓ (policies, MFA, conditional access)
M365 Services
```

**Installation & Configuration**:

1. **Server Requirements**:
   - Windows Server 2012 R2+ with .NET 4.5+
   - 4GB RAM, 50GB disk minimum
   - On-premises network connectivity (direct access to AD DS DC)
   - Can be installed on domain controller or separate member server

2. **Installation**:

```powershell
# Download Azure AD Connect from Microsoft
# https://www.microsoft.com/download/details.aspx?id=47594

# Run installer on designated server
AzureADConnect.msi

# Follow wizard to:
# 1. Enter Entra ID admin credentials
# 2. Select desired sync scope (all users, or filter by OU)
# 3. Configure password hash sync (recommended)
# 4. Set sync frequency (30-minute delta)
```

3. **Verification**:

```powershell
# Check sync status
Get-ADSyncConnectorRunStatus

# View user count
Get-ADSyncConnectorSpace | Select ConnectorName, ObjectsAdded, ObjectsDeleted
```

**Validation**:

```
✓ User count in on-prem AD ~= user count in Entra ID
✓ User attributes (name, email, department) match
✓ New on-prem users appear in Entra ID within 30 minutes
✓ Changed passwords sync within 30 minutes
✓ AAD Connect sync status shows "success" (not errors)
```

### Azure Infrastructure: Building Cloud Foundation

**Background**: Before migrating workloads to Azure, build the network foundation:

```
Azure VNet (10.0.0.0/16)
├─ Web Subnet (10.0.1.0/24) - Internet-facing apps
├─ App Subnet (10.0.2.0/24) - Application servers
├─ DB Subnet (10.0.3.0/24) - SQL databases (private)
└─ Mgmt Subnet (10.0.4.0/24) - Bastion, monitoring

Connected via:
├─ VPN Gateway (site-to-site IPsec to on-premises)
└─ Azure Firewall (centralized threat protection)
```

**Execute These Steps** (see `08-phase-7-azure-infrastructure/01-azure-setup.md`):

1. Create VNet with 4 subnets
2. Deploy VPN Gateway (IPsec tunnel to on-premises)
3. Create Network Security Groups (firewall rules per subnet)
4. Deploy Azure Bastion (passwordless RDP/SSH access)
5. Create backup vault (for VM snapshots)

---

## Phase 8-11: Migration, Governance & Device Management

### File Migration: Moving Data to Cloud

**Background**: Organizations typically store 10+ TB of files across file shares, old drives, archived DVDs. Migration must:
- Move data without data loss
- Maintain permissions (who can access what)
- Map old shares to new locations (user retraining)
- Disable old shares (prevent accidental use of outdated files)

**Migration Pattern**:

```
Week 15 (Prepare Phase):
├─ Inventory file shares (size, age, permissions)
├─ Identify "inactive" files (not accessed >1 year) → archive to cold storage
├─ Create migration batches (by department to distribute load)
└─ Stage data to Azure Blob Storage (prep zone)

Week 16 (Execute Phase):
├─ Begin migration overnight (off-peak hours)
├─ Migrate by batch: IT → Sales → Finance (rolling schedule)
├─ Validate checksum (file integrity)
├─ Notify users of new SharePoint/OneDrive location
└─ Decommission old file shares (after 2-week grace period)
```

### RBAC: Least Privilege Governance

**Background**: Not all users should have the same access. RBAC limits permissions to job requirements:

```
Role: Global Admin
├─ Scope: All M365 services
├─ Actions: Create policies, modify settings
├─ Assignment: 2-3 IT staff
└─ MFA: Required + PIM approval

Role: SharePoint Admin
├─ Scope: SharePoint sites only
├─ Actions: Manage sites, permissions, content
├─ Assignment: 1-2 per department
└─ MFA: Required

Role: Teams Admin
├─ Scope: Teams, channels, policies
├─ Actions: Create teams, manage channels
├─ Assignment: 1 per department
└─ MFA: Required

Role: User
├─ Scope: Own files/emails
├─ Actions: Create, read, edit, delete own content
├─ Assignment: All employees
└─ MFA: Optional but encouraged
```

**Access Review Process** (Quarterly):

1. List all users with elevated roles
2. Confirm with their manager: "Does this person still need this access?"
3. Document approvals
4. Remove access for approval rejections
5. Repeat quarterly

### Intune Device Management: Control the Endpoint

**Background**: Devices are the primary attack surface. Intune enforces compliance:

```
Device Enrollment:
├─ Corporate devices: Mandatory
├─ BYOD (personal devices): Optional but encouraged
└─ Coverage target: 80%+

Compliance Policies Enforced:
├─ Password: Min 6 chars, alphanumeric + symbols
├─ Encryption: BitLocker (Windows), FileVault (Mac)
├─ OS updates: Current version required
├─ Antivirus: Windows Defender active + current definitions
└─ Non-compliance action: Block access to M365

Configuration Profiles Deployed:
├─ WiFi: Company network credentials
├─ VPN: Always-on to corporate network
├─ Email: Exchange profile auto-configured
├─ Root certificates: Internal CA trust
└─ App restrictions: Approved apps only
```

**Enrollment & Deployment**:

1. Communicate to users (email + Teams message)
2. Users install Company Portal app
3. Authenticate with M365 credentials
4. Follow enrollment wizard (varies by platform)
5. Compliance policies + configs auto-applied
6. Monitor enrollment dashboard (target >80% in 4 weeks)

---

## Automation Best Practices

### PowerShell Scripting: Scale from 10 to 10,000 Users

**Background**: Manual operations don't scale. PowerShell enables:
- Bulk provisioning (create 1000 users in 5 minutes vs. 500 hours manual)
- Consistency (same configuration applied to all)
- Audit trail (script logs all actions)
- Repeatability (same script works monthly/quarterly)

### Script Development Pattern

```powershell
# 1. Authenticate once
Connect-MgGraph -Scopes User.ReadWrite.All, Mail.Send

# 2. Load input (CSV file)
$users = Import-Csv "users.csv"

# 3. Log setup
$logPath = "log-$(Get-Date -Format yyyy-MM-dd).txt"
$users | ForEach-Object {
    try {
        # 4. Perform action (create user, assign license, etc.)
        New-MgUser -DisplayName $_.DisplayName -UserPrincipalName $_.UPN
        
        # 5. Log success
        "✓ Created $($_.UPN)" | Add-Content $logPath
    }
    catch {
        # 6. Log error and continue
        "✗ Failed $($_.UPN): $_" | Add-Content $logPath
    }
}

# 7. Report results
$successCount = (Get-Content $logPath | grep "✓" | Measure-Object -Line).Lines
$errorCount = (Get-Content $logPath | grep "✗" | Measure-Object -Line).Lines
Write-Host "Completed: $successCount succeeded, $errorCount failed"
```

### Error Handling: Plan for Failure

```powershell
# Bad: Scripts die on first error
$users | ForEach-Object { New-MgUser -DisplayName $_.DisplayName }

# Good: Scripts catch errors and continue
$users | ForEach-Object {
    try {
        New-MgUser -DisplayName $_.DisplayName -ErrorAction Stop
    }
    catch [Microsoft.Graph.PowerShell.Models.ODataErrors.ODataError] {
        Write-Warning "User $($_.DisplayName) already exists"
    }
    catch {
        Write-Error "Unexpected error: $_"
    }
}
```

---

## Troubleshooting & Support

### Common Issues by Phase

#### Phase 1: Users Can't Login

**Symptom**: Users created but cannot authenticate to M365

**Root Causes**:
1. Licenses not assigned (no Exchange/Teams access)
2. Cloud-only users without password set
3. Conditional Access policy blocking access

**Resolution**:
```powershell
# Verify license is assigned
Get-MgUserLicenseDetail -UserId user@organization.com

# Verify license assignment type
Get-MgUser -UserId user@organization.com | Select-Object AssignedLicenses

# If missing, assign E3 license
$sku = Get-MgSubscribedSku | Where-Object {$_.SkuPartNumber -eq "SPE_E3"}
$addLicense = @{
    AddLicenses = @(@{SkuId = $sku.SkuId})
    RemoveLicenses = @()
}
Set-MgUserLicense -UserId user@organization.com -BodyParameter $addLicense
```

#### Phase 2: MFA Not Working

**Symptom**: Admin logins fail with "Authenticator app not recognized"

**Root Causes**:
1. Device time is out of sync (TOTP requires accurate time)
2. Wrong user logged into Authenticator app
3. App not registered properly during setup

**Resolution**:
```powershell
# Force re-register MFA for user
Remove-MgUserAuthenticationPhoneMethod -UserId admin@organization.com -PhoneAuthenticationMethodId {method-id}

# User must re-enroll via:
# https://account.microsoft.com/auth/securityinfo
# Or Azure AD portal → "Security info" → "Add method"
```

#### Phase 5: AAD Connect Sync Stuck

**Symptom**: New on-premises users don't appear in Entra ID after 30 minutes

**Root Causes**:
1. AAD Connect service stopped
2. Credentials expired (connector account password changed)
3. Network connectivity lost

**Resolution**:
```powershell
# Check AAD Connect service status
Get-Service -Name ADSync | Select Status

# Restart if stopped
Start-Service -Name ADSync

# Check sync errors
Get-ADSyncConnectorRunStatus

# Force manual sync
Start-ADSyncSyncCycle -PolicyType Delta
```

#### Phase 11: Device Enrollment Failing

**Symptom**: Users can't enroll devices in Intune

**Root Causes**:
1. Device limit per user exceeded (max 5 personal)
2. Corporate device registration already assigned to different user
3. Enrollment policy blocking platform (iOS/Android)

**Resolution**:
```powershell
# Check device count per user
Get-MgUserOwnedDevice -UserId user@organization.com | Measure-Object

# Remove old/unused devices
Get-MgUserOwnedDevice -UserId user@organization.com | Remove-MgDevice

# Re-enroll device
# Device: Settings → Accounts → Access work/school → "Connect"
```

---

## Validation Checklist: Deployment Complete

When all 11 phases complete, verify:

### Functional Validation

- [ ] **Users**: Can login to https://mail.outlook.com with M365 credentials
- [ ] **Exchange**: Can send/receive email, shared mailboxes working
- [ ] **Teams**: Can create teams, post messages, share files
- [ ] **SharePoint**: Team sites accessible, document upload/download working
- [ ] **OneDrive**: Personal file sync functional
- [ ] **Hybrid SSO**: On-premises users SSO to M365 without re-entering password
- [ ] **Backup**: Last backup timestamp < 24 hours ago

### Security Validation

- [ ] **MFA**: All admin accounts require MFA
- [ ] **DLP**: Policies blocking sensitive data (test with sample PII)
- [ ] **Conditional Access**: Blocking legacy auth (confirm via test login)
- [ ] **Defender**: Threats detected and logged (check dashboard)
- [ ] **Audit Logging**: All user actions recorded (M365 Admin Center → Audit logs)

### Operational Validation

- [ ] **Monitoring**: Dashboards showing real-time metrics
- [ ] **Alerts**: Security team receiving alerts daily
- [ ] **Reports**: Daily/weekly reports generating and sending
- [ ] **Automation**: PowerShell scripts running on schedule without errors
- [ ] **Device Management**: 80%+ of devices enrolled in Intune

---

## Next Steps After Deployment

1. **Lessons Learned** → Complete `00-planning/06-lessons-learned.md`
2. **Knowledge Transfer** → Train IT staff on daily M365 administration
3. **Ongoing Monitoring** → Monitor dashboards daily, adjust policies quarterly
4. **Disaster Recovery Drill** → Test backup/recovery monthly
5. **Security Audits** → Quarterly access reviews, annual penetration testing
6. **Capacity Planning** → Plan for 20% year-over-year user growth

---

**Document Version**: 1.0  
**Last Updated**: March 4, 2026  
**Status**: Production-Ready
