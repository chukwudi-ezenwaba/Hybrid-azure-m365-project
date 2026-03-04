# Hybrid-Azure-m365 Project: Automation Suite

## Project Context

This automation suite supports the **Hybrid-Azure-m365 Deployment Project**, automating the deployment of Microsoft 365 tenant, license assignment, user/group management, and ongoing operations following Phase 1-11 implementation phases.

**Project Scope**: Enterprise hybrid environment with on-premises AD bridging to Azure/Microsoft 365

---

## Execution Workflow

### Phase 1: Setup & Connection
```powershell
cd powershell
.\01-connect-services.ps1
```
**Output**: Connected to Graph, Exchange, Teams (shows org name)

### Phase 2: User Provisioning
```powershell
.\02-create-users.ps1 -CsvPath "users.csv"
```
**Input**: CSV with FirstName, LastName, Email, JobTitle, Department
**Output**: `created-users-[timestamp].csv` with new user IDs

### Phase 3: License Deployment
```powershell
# Preview
.\03-license-assignment.ps1 -CsvPath "licenses.csv"

# Execute
.\03-license-assignment.ps1 -CsvPath "licenses.csv" -Apply
```
**Input**: CSV with UserPrincipalName, SkuId (ENTERPRISEPACK/ENTERPRISEPREMIUM)
**Output**: License assignment summary

### Phase 4: Infrastructure Setup
```powershell
.\04-mailbox-setup.ps1 -CreateSharedMailbox -SharedMailboxEmail "support@org.com"
.\07-create-groups.ps1 -CsvPath "groups.csv"
.\08-enable-mfa.ps1 -UserEmail "*"
```
**Outcomes**: Shared mailboxes configured, groups created, MFA policy enabled

### Phase 5: Operations & Monitoring
```powershell
.\05-generate-reports.ps1 -OutputPath ".\reports"
.\06-cleanup-disabled-users.ps1 -DaysAfterDisable 30 -Apply
```
**Outputs**: User reports, license utilization, disabled account cleanup

---

## Scripts Summary

| # | Script | Purpose | Input | When to Run |
|---|--------|---------|-------|------------|
| 00 | master-orchestration | Menu/reference | - | Documentation |
| 01 | connect-services | Authenticate to M365 | Admin account | First, always |
| 02 | create-users | Bulk user creation | users.csv | After tenant setup |
| 03 | license-assignment | Assign E3/E5 licenses | licenses.csv | After users created |
| 04 | mailbox-setup | Configure Exchange | Email domain | After users provisioned |
| 05 | generate-reports | Export user/license data | - | Weekly/monthly |
| 06 | cleanup-disabled-users | Remove disabled accounts | - | Monthly maintenance |
| 07 | create-groups | Create distribution lists | groups.csv | During org setup |
| 08 | enable-mfa | Configure MFA policy | User email or * | Before production |

---

## CSV Specifications

### users.csv (for script 02)
```
FirstName,LastName,Email,JobTitle,Department
John,Smith,j.smith,Senior Developer,Engineering
Sarah,Johnson,s.johnson,Product Manager,Product
```
Email → `[email]@organization.onmicrosoft.com` | Password auto-generated | Account enabled immediately

### licenses.csv (for script 03)
```
UserPrincipalName,SkuId
j.smith@organization.onmicrosoft.com,ENTERPRISEPACK
s.johnson@organization.onmicrosoft.com,ENTERPRISEPREMIUM
```
SKU options: ENTERPRISEPACK (E3) | ENTERPRISEPREMIUM (E5)

### groups.csv (for script 07)
```
DisplayName,Email,Description,Type,Members
Engineering,engineering@org.com,Engineering team,M365Group,j.smith@org.com;s.johnson@org.com
IT Support,itsupport@org.com,Support team,DistributionList,
```
Types: M365Group (modern, Teams-enabled) or DistributionList (traditional)

---

## Setup

### Prerequisites
- PowerShell 5.1+ (Windows 10+) or PowerShell 7+ (any OS)
- Global Administrator account with MFA device
- Permissions: User.ReadWrite.All, Group.ReadWrite.All, Organization.Read.All

### First Run
```powershell
Install-Module -Name Microsoft.Graph, ExchangeOnlineManagement, MicrosoftTeams
.\01-connect-services.ps1
Copy-Item SAMPLE-users.csv users.csv
# Edit users.csv with your data
```

---

## Script Capabilities

| Script | Function | Safety Feature | Duration |
|--------|----------|-----------------|----------|
| 01 | Connect to services | - | 2-5 min (MFA) |
| 02 | Create users | Exports created user IDs | 1-2 min per user |
| 03 | Assign licenses | Preview mode (default), requires -Apply | 30 sec per license |
| 04 | Setup mailboxes | Creates shared mailboxes, applies policies | 1-2 min |
| 05 | Generate reports | CSV export with user/license data | 2-5 min |
| 06 | Cleanup deleted users | PREVIEW mode (default), requires -Apply, grace period | 1-2 min |
| 07 | Create groups | M365 or Distribution List | 1 min per group |
| 08 | Enable MFA | Conditional Access policy (report-only initially) | 1 min |

---

## Error Troubleshooting

| Error | Cause | Solution |
|-------|-------|----------|
| Module not found | Not installed | `Install-Module -Name [module]` |
| Permission denied | Not Global Admin | Use Global Admin account |
| CSV not found | Path incorrect | Use full path: `C:\path\file.csv` |
| User not found | UPN doesn't exist | Run script 02 first |
| License unavailable | Insufficient stock | Check M365 admin center |
| Already licensed | Duplicate | Script skips, try different SKU |

---

## Project Timeline

| Week | Phase | Action | Script |
|------|-------|--------|--------|
| 1 | Setup | Connect to services | 01 |
| 1-2 | User provisioning | Create users | 02 |
| 2 | Licensing | Preview licenses | 03 |
| 2-3 | Licensing | Apply licenses | 03 -Apply |
| 3 | Infrastructure | Setup mailboxes | 04 |
| 3 | Organization | Create groups | 07 |
| 3-4 | Security | Enable MFA | 08 |
| 4+ | Ops (weekly) | Generate reports | 05 |
| 4+ | Maintenance (monthly) | Cleanup disabled | 06 |

---

## Sample Execution

```powershell
PS C:\hybrid-azure-project\13-automation\powershell>

.\01-connect-services.ps1
# ✓ Connected to Graph, Exchange, Teams (org: Company Corp)

.\02-create-users.ps1 -CsvPath ".\users.csv"
# ✓ Successfully created 25 users

.\03-license-assignment.ps1 -CsvPath ".\licenses.csv"
# [PREVIEW] Would assign 25 licenses (no changes)

.\03-license-assignment.ps1 -CsvPath ".\licenses.csv" -Apply
# ✓ Assigned 25 licenses, 0 failed

.\04-mailbox-setup.ps1
.\07-create-groups.ps1 -CsvPath ".\groups.csv"
.\08-enable-mfa.ps1 -UserEmail "*"
# ✓ Infrastructure configured

.\05-generate-reports.ps1
# ✓ Reports exported to .\reports\
```

---

## Integration with Project Phases

- **Phase 1** (M365 Deployment): Scripts 01-04
- **Phase 2** (Security): Script 08
- **Phase 3** (Collaboration): Script 07
- **Phase 4** (Monitoring): Script 05  
- **Ongoing**: Script 06 (monthly maintenance)

See phase documentation in `02-phase-*-*` folders and `01-architecture`.
