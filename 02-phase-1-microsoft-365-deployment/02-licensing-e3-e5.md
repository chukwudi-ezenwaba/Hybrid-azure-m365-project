# Microsoft 365 Licensing Strategy (E3 vs E5)

## Overview

This guide explains Microsoft 365 licensing tiers (E3 vs E5), helps determine which licenses are appropriate for different user roles, and covers license assignment and management processes.

**Duration**: 1 day  
**Requires**: Global Administrator or License Administrator role  
**Depends On**: Microsoft 365 tenant created, users synchronized

---

## Pre-Configuration Checklist

- [ ] Microsoft 365 tenant created
- [ ] License quantities purchased (E3 and E5)
- [ ] User directory fully synchronized
- [ ] Department and role categories defined
- [ ] Global administrator credentials ready
- [ ] License allocation budget approved by management

---

## Task 1: Understand License Tiers

### E3 License - Standard Users

**Microsoft 365 E3 Includes:**
- **Exchange Online**: 50 GB mailbox + 100 GB archive
- **SharePoint Online**: 1 TB per organization (shared)
- **Teams**: Full collaboration (chat, meetings, calls)
- **OneDrive**: 1 TB per user cloud storage
- **Office Desktop**: Word, Excel, PowerPoint, Outlook (install up to 5 devices)
- **Microsoft Office Mobile**: Access on tablet/phone
- **Yammer**: Enterprise social network
- **Power BI Pro**: Data visualization (100+ users)
- **Project Online**: Basic project management
- **Compliance**: Basic DLP, retention policies, audit logging
- **Security**: MFA, Defender for Office 365 Plan 1, Conditional Access

**Limitations:**
- Archive 2 TB limit (vs unlimited E5)
- Malware/phishing detection basic
- No advanced threat protection
- No Privileged Identity Management (PIM)
- No advanced auditing (90-day limit)

**Recommended For:**
- General staff (sales, HR, operations)
- External collaborators
- Contractors with time limits
- **Typical percentage**: 70-80% of users

**Monthly Cost (Est.)**: $12-14 USD per user

---

### E5 License - Power Users and Administrators

**Microsoft 365 E5 Includes (Everything in E3, PLUS):**
- **Advanced Threat Protection**: Defender for Office 365 Plan 2
  - Safe Links + Safe Attachments
  - Advanced anti-phishing with machine learning
  - Threat investigator (automated incident response)
- **Advanced Auditing**: 10-year retention (vs 1 year E3)
- **Privileged Identity Management (PIM)**: Just-in-time admin access
- **Cloud App Security**: Monitor and control SaaS apps
- **Insider Risk Management**: Detect unauthorized data access
- **eDiscovery Premium**: Advanced legal hold capabilities
- **Endpoint Analytics**: Device security and health monitoring
- **Advanced Compliance**: Custom retention, encryption, advanced DLP
- **Microsoft Defender**: Integrated security dashboard
- **Scheduler**: Meeting room optimization (Teams roaming)
- **Power BI Premium**: Advanced analytics and dashboards
- **Project Online Premium**: Full project management suite
- **Stream**: Video hosting and sharing

**Advantages Over E3:**
- 10x better threat protection (AI-driven)
- Admin access protection via PIM
- Compliance readiness for regulated industries
- Advanced analytics and reporting
- Full insider threat detection

**Recommended For:**
- Administrators (global, security, IT)
- Executives and department heads
- Security team
- Finance/Legal departments
- Compliance officers
- **Typical percentage**: 15-25% of users

**Monthly Cost (Est.)**: $22-24 USD per user

---

## Task 2: Determine License Requirements by Role

### E3 License Assignment Matrix

| Role | Count | Reason | Annual Cost |
|------|-------|--------|------------|
| HR Staff | 5 | Access to employee documents, email | $840-840 |
| HR Managers | 2 | E3 sufficient (team oversight) | $24 |
| Operations Staff | 8 | General email, SharePoint access | $1,152 |
| Operations Manager | 1 | E3 (operational oversight) | $156 |
| Finance Staff | 4 | Financial reports, data analysis | $576 |
| Sales Staff | 10 | Email, Teams, OneDrive | $1,440 |
| Support Staff | 5 | Help desk, ticketing, Teams | $720 |
| | **35 Users** | **Total E3** | **$5,544** |

### E5 License Assignment Matrix

| Role | Count | Reason | Annual Cost |
|------|-------|--------|------------|
| Global Admin | 1 | Full platform access, advanced security | $288 |
| IT Manager | 1 | Access controls, audit logs, PIM | $288 |
| Security Officer | 2 | Threat management, insider risk | $576 |
| Finance Manager | 1 | Compliance, audit, DLP policies | $288 |
| HR Manager (Head) | 1 | Sensitive data, audit access | $288 |
| CEO/Executive | 1 | Full features, strategic data | $288 |
| Compliance Officer | 1 | eDiscovery, legal hold, audit | $288 |
| | **8 Users** | **Total E5** | **$2,688** |

**Total Organization (43 users):**
- E3: 35 users × $156/year = $5,544
- E5: 8 users × $288/year = $2,688
- **Total annual**: $8,232 (~$191/year per user average)

---

## Task 3: Assign Licenses via Admin Center

### Step 3.1: Access License Management

1. **Microsoft 365 admin center** → https://admin.microsoft.com
2. **Billing** → **Products & services** (or **Licenses** in newer interface)
3. View purchased licenses:
   - "Microsoft 365 E3" - quantity, assigned, available
   - "Microsoft 365 E5" - quantity, assigned, available

### Step 3.2: Assign E3 Licenses

1. **Users** → **Active users**
2. Select user: "John Smith"
3. Click **Licenses and apps**
4. Under **Licenses**:
   - Uncheck any current license
   - Check **Microsoft 365 E3**
5. Optionally select apps to disable (e.g., disable Yammer if not needed)
6. Click **Save changes**

7. Repeat for all 35 E3 users

### Step 3.3: Assign E5 Licenses

1. Repeat for E5 users, selecting **Microsoft 365 E5**

**Validation:**
- Assigned licenses match department assignments
- E3 users cannot access E5 features (blocked by policy)
- E5 users have advanced features available

---

## Task 4: Automate License Assignment via PowerShell

### Step 4.1: Prepare User List (CSV)

Create file: `license_assignment.csv`
```csv
DisplayName,Email,Department,Role,LicenseType
John Doe,john.doe@organization.com,IT,Manager,E5
Jane Smith,jane.smith@organization.com,HR,Staff,E3
Bob Johnson,bob.johnson@organization.com,Operations,Manager,E5
Alice Brown,alice.brown@organization.com,Sales,Staff,E3
Charlie Davis,charlie.davis@organization.com,Finance,Manager,E5
```

### Step 4.2: Connect to Microsoft 365

```powershell
# Install required modules
Install-Module -Name MSOnline -Force
Install-Module -Name AzureAD -Force

# Connect to Microsoft 365
Connect-MsolService
# Login with Global Admin credentials

# Verify connection
Get-MsolUser | Select-Object DisplayName, Licenses | Head -5
```

### Step 4.3: Assign Licenses from CSV

```powershell
# Define license SKUs
$E3License = "organization:ENTERPRISEPACK"  # E3 SKU
$E5License = "organization:ENTERPRISEPREMIUM"  # E5 SKU

# Read CSV file
$Users = Import-Csv -Path "license_assignment.csv"

foreach ($User in $Users) {
    $UserEmail = $User.Email
    $LicenseType = $User.LicenseType
    
    # Get user object
    $MsolUser = Get-MsolUser -UserPrincipalName $UserEmail
    
    # Remove existing license
    if ($MsolUser.Licenses) {
        Set-MsolUserLicense -UserPrincipalName $UserEmail -RemoveLicenses $MsolUser.Licenses[0].AccountSkuId
    }
    
    # Assign new license
    if ($LicenseType -eq "E3") {
        Set-MsolUserLicense -UserPrincipalName $UserEmail -AddLicenses $E3License
        Write-Host "Assigned E3 to $UserEmail" -ForegroundColor Green
    } elseif ($LicenseType -eq "E5") {
        Set-MsolUserLicense -UserPrincipalName $UserEmail -AddLicenses $E5License
        Write-Host "Assigned E5 to $UserEmail" -ForegroundColor Green
    }
}

# Verify assignments
Get-MsolUser -All | Where-Object {$_.Licenses} `
    | Select-Object DisplayName, UserPrincipalName, @{N="License";E={$_.Licenses[0].AccountSkuId}} `
    | Export-Csv "license_report.csv" -NoTypeInformation

Write-Host "License assignment complete. Report: license_report.csv"
```

---

## Task 5: Configure License Options and App Assignments

### Step 5.1: Enable/Disable Apps per License

**For E3 Users** (disable unnecessary apps to reduce complexity):

```powershell
# Disable Yammer for E3 users (use Teams instead)
$E3License = "organization:ENTERPRISEPACK"
$YammerSku = "YAMMER_ENTERPRISE"

$E3Users = Get-MsolUser -All | Where-Object {$_.Licenses.AccountSkuId -like "*ENTERPRISEPACK"}

foreach ($User in $E3Users) {
    $LicenseOptions = New-MsolLicenseOptions -AccountSkuId $E3License `
                                             -DisabledPlans $YammerSku
    
    Set-MsolUserLicense -UserPrincipalName $User.UserPrincipalName `
                        -LicenseOptions $LicenseOptions
}
```

**For E5 Users** (keep all features enabled):

```powershell
# E5 users get all features
$E5License = "organization:ENTERPRISEPREMIUM"
$E5Users = Get-MsolUser -All | Where-Object {$_.Licenses.AccountSkuId -like "*ENTERPRISEPREMIUM"}

foreach ($User in $E5Users) {
    # No disabled plans = all E5 features active
    Write-Host "$($User.DisplayName) has full E5 access"
}
```

### Step 5.2: Configure Service Plans

Some organizations disable non-critical services to manage costs or reduce administrative overhead:

```powershell
# Example: Disable Consumer Cloud Services for E3
# (Reduces unauthorized external sharing risk)

$ServicePlans = @(
    "SWAY",  # Designer app (optional)
    "FORMS_PLAN_E3"  # Forms (optional)
)

foreach ($User in $E3Users) {
    $LicenseOptions = New-MsolLicenseOptions `
                        -AccountSkuId $E3License `
                        -DisabledPlans $ServicePlans
    
    Set-MsolUserLicense -UserPrincipalName $User.UserPrincipalName `
                        -LicenseOptions $LicenseOptions
}
```

---

## Task 6: Monitor and Report on License Usage

### Step 6.1: Generate License Report

```powershell
# Export current license assignments
$Report = Get-MsolUser -All | Where-Object {$_.Licenses} `
    | Select-Object DisplayName, `
                    UserPrincipalName, `
                    @{N="License Type";E={$_.Licenses[0].AccountSkuId.Split(':')[1]}}, `
                    @{N="License Status";E={if($_.Licenses){$_.Licenses[0].WarnStatus else "No License"}}}, `
                    @{N="Last Login";E={$_.LastDirSyncTime}}

$Report | Export-Csv "license_audit_$(Get-Date -Format 'yyyy-MM-dd').csv" -NoTypeInformation
$Report | Format-Table -AutoSize
```

### Step 6.2: Monitor Unused Licenses

Identify users who haven't logged in recently:

```powershell
# Find E3 users not logged in for 90 days
$E3Users = Get-MsolUser -All | Where-Object {$_.Licenses.AccountSkuId -like "*ENTERPRISEPACK"}
$InactiveUsers = $E3Users | Where-Object {$_.LastDirSyncTime -lt (Get-Date).AddDays(-90)}

Write-Host "Users inactive 90+ days (eligible for license reassignment):"
$InactiveUsers | Select-Object DisplayName, UserPrincipalName, LastDirSyncTime `
    | Format-Table -AutoSize

# Export for review
$InactiveUsers | Export-Csv "inactive_users_$(Get-Date -Format 'yyyy-MM-dd').csv" -NoTypeInformation
```

### Step 6.3: Create Dashboard

**In Microsoft 365 Admin Center:**
1. **Reports** → **Usage**
2. View:
   - **Microsoft 365 app usage**: Which apps users access
   - **Email activity**: Mailbox usage statistics
   - **File storage**: OneDrive and SharePoint utilization
   - **Teams usage**: Team activity and engagement

**Export for analysis:**
```powershell
# Download detailed user activity report
Get-MsolUser -All | Where-Object {$_.Licenses} `
    | Select-Object DisplayName, UserPrincipalName, `
                    @{N="Department"; E={ `
                        if ($_.DisplayName -like "*HR*") {"HR"} `
                        elseif ($_.DisplayName -like "*Finance*") {"Finance"} `
                        else {"Other"} `
                    }}, `
                    @{N="License"; E={$_.Licenses[0].AccountSkuId}} `
    | Export-Csv "user_license_summary.csv" -NoTypeInformation
```

---

## Task 7: Cost Optimization

### Step 7.1: Identify Downgrade Opportunities

Users currently on E5 who don't need advanced features:

```powershell
# Find E5 users without advanced feature usage
$E5Users = Get-MsolUser -All | Where-Object {$_.Licenses.AccountSkuId -like "*ENTERPRISEPREMIUM"}

# Check last mail activity (via Exchange)
Connect-ExchangeOnline

foreach ($User in $E5Users) {
    $MailboxStats = Get-MailboxStatistics -Identity $User.UserPrincipalName -ErrorAction SilentlyContinue
    
    if ($MailboxStats) {
        $LastActivity = $MailboxStats.LastLogonTime
        
        if ($LastActivity -lt (Get-Date).AddDays(-60)) {
            Write-Host "$($User.DisplayName) - Last activity: $LastActivity - Consider downgrading to E3"
        }
    }
}
```

### Step 7.2: Review and Recommend

**Cost Savings Example:**
- Move 2 E5 users to E3: 2 × ($288 - $156) = $264/year savings
- Move 3 inactive E3 users off platform: 3 × $156 = $468/year savings
- **Total potential savings**: $732/year

---

## Task 8: Validation Checklist

- [ ] All users assigned appropriate licenses (E3 or E5)
- [ ] License counts match team organization
- [ ] E3 users cannot access E5-only features
- [ ] E5 users have advanced features available
- [ ] License report generated and verified
- [ ] Inactive users identified for review
- [ ] Cost tracking implemented
- [ ] License assignment policy documented
- [ ] User awareness training scheduled
- [ ] Finance team notified of licensing costs

---

## Common Issues & Troubleshooting

| Issue | Cause | Solution |
|-------|-------|----------|
| User cannot access advanced features | Licensed as E3 instead of E5 | Verify license assignment in admin center, reassign if needed |
| License assignment fails via PowerShell | User missing from directory | Sync users via Azure AD Connect first, wait 15 min for sync |
| Cost higher than budgeted | Too many E5 licenses allocated | Downgrade non-essential E5 users to E3 |
| User sees "license not found" error | License deleted or not applied | Reassign license, clear cached credentials on device |
| Multiple licenses showing | Licensing conflict | Remove conflicting licenses, keep only one active license |

---

## Next Steps

1. Complete license assignment for all users
2. Monitor usage and adjust licenses quarterly
3. Train teams on differences between E3 and E5
4. Proceed to tenant-setup.md for final tenant configuration
5. Progress to Phase 1 validation and completion
