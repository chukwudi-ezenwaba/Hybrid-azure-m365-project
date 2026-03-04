# PowerShell Automation Scripts - User Management and Bulk Operations

## Overview

This directory contains PowerShell scripts for automating common hybrid infrastructure tasks including bulk user creation, license management, group operations, and reporting.

---

## Prerequisites

Install required modules:

```powershell
# Install Microsoft 365 PowerShell modules
Install-Module -Name MSOnline
Install-Module -Name AzureAD
Install-Module -Name ExchangeOnlineManagement
Install-Module -Name Microsoft.Teams.PowerShell
Install-Module -Name ActiveDirectory  # On domain controller or RSAT-installed machine
```

---

## Script 1: Bulk User Creation from CSV

**File**: `create-users.ps1`

Creates users in both on-premises Active Directory and Microsoft 365 from CSV file.

**Usage**:
```powershell
.\create-users.ps1 -CsvPath "C:\Users\users-to-create.csv" -ADCredential (Get-Credential)
```

**CSV Format Required**:
```csv
FirstName,LastName,Email,Department,JobTitle
John,Smith,john.smith@organization.onmicrosoft.com,IT,Senior Architect
Jane,Doe,jane.doe@organization.onmicrosoft.com,HR,HR Manager
```

**What it does**:
1. Reads CSV file
2. For each user:
   - Creates user in on-premises AD (if connected to domain controller)
   - Waits for Azure AD Connect to sync (typically 2-3 minutes)
   - Assigns Microsoft 365 E5 license
   - Adds to department group
   - Generates temporary password and sends welcome email
3. Reports completion status

---

## Script 2: License Assignment Automation

**File**: `license-assignment.ps1`

Assigns Microsoft 365 licenses based on department or title.

**Usage**:
```powershell
.\license-assignment.ps1 -Department "IT" -LicenseType "E5"
```

**Script Logic**:
```powershell
# Find users in IT department without E5 license
$unlicensedUsers = Get-MsolUser -All | Where-Object { `
    $_.Department -eq "IT" -and $_.IsLicensed -eq $false
}

# Assign E5 license
foreach ($user in $unlicensedUsers) {
    Set-MsolUserLicense -UserPrincipalName $user.UserPrincipalName `
                        -AddLicenses "organization:ENTERPRISEPREMIUM"
    Write-Host "License assigned to $($user.DisplayName)"
}
```

**Features**:
- Batch assign licenses by department
- Verify license count before assignment
- Generate pre-assignment report
- Log all operations for audit trail

---

## Script 3: User Report Generation

**File**: `add-user-report.ps1`

Generates detailed user activity and licensing report.

**Usage**:
```powershell
.\add-user-report.ps1 -OutputPath "C:\Reports\user-report.xlsx"
```

**Report Includes**:
| Column | Information |
|--------|-------------|
| DisplayName | User full name |
| Email (UPN) | user@organization.onmicrosoft.com |
| Department | User department |
| License Type | E3, E5, or unlicensed |
| Last Login (M365) | Last access to cloud services |
| Last Sync (AD) | Last Azure AD Connect sync time |
| MFA Enabled | Yes/No |
| Compliance Status | Compliant/Non-compliant device status |
| Account Status | Active/Disabled/Deleted |

---

## Script 4: Disabled User Cleanup

**File**: `cleanup-disabled-users.ps1`

Safely removes disabled users from cloud and on-premises directories after retention period.

**Usage**:
```powershell
.\cleanup-disabled-users.ps1 -DisabledDays 90 -WhatIf
```

**Parameters**:
- `-DisabledDays`: Days since disabled before removal (default 90)
- `-WhatIf`: Preview changes without applying (RECOMMENDED for first run)
- `-Confirm`: Requires confirmation before each deletion

**What it does**:
1. Finds users disabled 90+ days ago
2. Removes from M365 groups
3. Revokes all token refresh (forces sign-out)
4. Moves to disabled users OU in AD (soft delete before hard delete)
5. After 30 days in disabled OU, permanently deletes account
6. Generates audit report of all deletions

**Safety Features**:
- `-WhatIf` preview mode
- Requires manual approval for each deletion
- Auditing all changes
- Soft delete with recovery window

---

## Common Automation Patterns

### Pattern 1: Connect to All Services

```powershell
# Establish connections to Microsoft 365 services
Connect-MsolService                                    # MSOnline
Connect-AzureAD                                        # Azure AD
Connect-ExchangeOnline -UserPrincipalName admin@org   # Exchange Online
Connect-MicrosoftTeams                                 # Teams
Connect-IPPSSession -UserPrincipalName admin@org      # Security & Compliance
```

### Pattern 2: Batch Operations with Error Handling

```powershell
# Safely process multiple users with try-catch
$users = Get-MsolUser -All

foreach ($user in $users) {
    try {
        # Operation
        Set-MsolUserLicense -UserPrincipalName $user.UserPrincipalName `
                           -AddLicenses "organization:ENTERPRISEPREMIUM" `
                           -ErrorAction Stop
        Write-Host "SUCCESS: License assigned to $($user.DisplayName)"
    }
    catch {
        Write-Host "ERROR: Failed to license $($user.DisplayName): $_"
        # Log error and continue
    }
}
```

### Pattern 3: Scheduled Tasks via Windows Task Scheduler

```powershell
# Create scheduled task for daily license reconciliation

$action = New-ScheduledTaskAction -Execute "powershell.exe" `
                                 -Argument "-File C:\scripts\license-assignment.ps1"

$trigger = New-ScheduledTaskTrigger -Daily -At 2:00AM

Register-ScheduledTask -Action $action `
                      -Trigger $trigger `
                      -TaskName "Daily License Sync" `
                      -Description "Sync and assign licenses daily" `
                      -User "DOMAIN\ServiceAccount"
```

---

## Best Practices for Automation

1. **Always use -WhatIf first**: Test changes before applying
2. **Implement logging**: Log all automation actions for audit trails
3. **Error handling**: Use try-catch blocks to gracefully handle failures
4. **Service account**: Run scripts with dedicated service account, not admin account
5. **Notification**: Email results to responsible party after automation completes
6. **Scheduling**: Run non-critical automation during business hours initially (9-5), then off-hours after testing
7. **Monitoring**: Set up alerts if automation fails unexpectedly
8. **Documentation**: Document every script's purpose, parameters, and prerequisites

---

## Troubleshooting Automation

**Issue**: PowerShell execution policy blocks scripts
```powershell
# Set execution policy (do this with caution)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**Issue**: Connectivity timeout to Microsoft 365
```powershell
# Increase timeout threshold
$PSDefaultParameterValues['*:OperationTimeout'] = 3600000  # 1 hour
```

**Issue**: Batch operation skips silently
```powershell
# Enable verbose output
$VerbosePreference = "Continue"
$DebugPreference = "Continue"
```

---

## Script Templates for Custom Automation

### Template 1: Bulk Group Membership

```powershell
# Add multiple users to group
$groupId = (Get-AzureADGroup -Filter "DisplayName eq 'IT Department'").ObjectId
$userList = @("user1@org.onmicrosoft.com", "user2@org.onmicrosoft.com")

foreach ($user in $userList) {
    $userId = (Get-AzureADUser -Filter "userPrincipalName eq '$user'").ObjectId
    Add-AzureADGroupMember -ObjectId $groupId -RefObjectId $userId
}
```

### Template 2: Conditional Bulk Operations

```powershell
# Apply policy based on department
$users = Get-MsolUser -All | Where-Object { $_.Department -eq "Finance" }

foreach ($user in $users) {
    # Apply finance-specific policy
    Set-MsolUserPassword -UserPrincipalName $user.UserPrincipalName `
                        -NewPassword "FinanceTemp2024!@#"
    Write-Host "Password reset for $($user.DisplayName)"
}
```

---

## Documentation Template

When creating new scripts:

```powershell
<#
.SYNOPSIS
Brief description of script purpose

.DESCRIPTION
Detailed explanation of what the script does

.PARAMETER ParameterName
Description of parameter

.EXAMPLE
.\script-name.ps1 -ParameterName "value"

.NOTES
Author: Your Name
Created: YYYY-MM-DD
Last Modified: YYYY-MM-DD
#>
```

---

*Document Version: 1.0*
*Last Updated: March 2, 2026*
