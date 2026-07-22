# Phase 10: Role-Based Access Control (RBAC) Design and Implementation

## Phase Overview

This phase sets up role-based access control in Azure and Microsoft 365. It uses least privilege. Users get only the permissions they need for their job.

**Duration**: 2 weeks  
**Key Objectives**: RBAC implementation, PIM configuration, audit trail establishment, access review procedures

---

## Task 1: Understand RBAC Architecture

### RBAC Components

**Three fundamental elements:**
1. **Security Principal**: User/group/service principal requesting access
2. **Role Definition**: Collection of permissions (read, write, delete, manage)
3. **Scope**: Resource or resource group where permissions apply

**Scope Hierarchy (narrowest to broadest):**
```
Individual Resource (VM, database)
    ↑
Resource Group
    ↑
Subscription
    ↑
Management Group
```

**Principle of Least Privilege:**
- Assign minimum permissions necessary
- Use resource group scope when possible (simplifies management)
- Use individual resource only for exceptions
- Never use broad "Contributor" or "Owner" for operational roles

---

## Task 2: Define RBAC Roles

### Step 2.1: Built-in Roles Overview

**High-Level Roles:**
- **Owner**: Full management including access assignment (use sparingly)
- **Contributor**: Create and modify resources but not assign access
- **Reader**: Read-only access, no modifications

**Specialized Roles:**

1. **Virtual Machine Contributor**
   - Create/modify/delete VMs
   - Cannot manage networking or storage
   - Cannot assign access to VMs
   - Scope: Resource Group or specific VMs

2. **Help Desk Operator** (custom role)
   - Reset user passwords
   - View users and groups
   - Cannot modify group membership
   - Scope: Tenant-wide (Entra ID)

3. **Billing Administrator**
   - View Azure costs and budgets
   - Manage subscriptions
   - Cannot modify resources
   - Scope: Subscription or Management Group

4. **Security Administrator**
   - Manage security policies (NSGs, firewall rules)
   - View security alerts
   - Cannot modify resources directly
   - Scope: Resource Group or specific resources

5. **Intune Administrator**
   - Manage device compliance policies
   - Deploy security baselines
   - Cannot manage Azure resources
   - Scope: Tenant-wide (Entra ID)

### Step 2.2: Create Custom Roles

For specialized functions, create custom roles:

1. In Azure portal, go to **Access Control (IAM)**
2. Click **Create a custom role**
3. Configure:
   - **Name**: "Network Security Operations"
   - **Description**: "Manage NSGs and Azure Firewall"
   - **Baseline**: Start from custom
   - **Assignable scopes**: Subscription
   - **Permissions**:
     - Microsoft.Network/*/read (read all network resources)
     - Microsoft.Network/networkSecurityGroups/joinNetworkSecurityGroup/action
     - Microsoft.Network/firewalls/*/read
4. Save

**PowerShell Custom Role Creation:**
```powershell
# Define custom role permissions
$customRole = @{
    "Name" = "Network Security Operations"
    "Description" = "Manage NSGs and Azure Firewall"
    "AssignableScopes" = @("/subscriptions/{subscriptionId}")
    "Actions" = @(
        "Microsoft.Network/*/read",
        "Microsoft.Network/networkSecurityGroups/joinNetworkSecurityGroup/action"
    )
    "NotActions" = @(
        "Microsoft.Network/*/delete",
        "Microsoft.Network/firewalls/delete"  # Prevent accidental deletion
    )
}

# Create custom role
New-AzRoleDefinition -InputObject $customRole
```

---

## Task 3: Implement RBAC Assignments

### Step 3.1: Assign Virtual Machine Contributor

For infrastructure engineers managing cloud VMs:

1. Go to **Resource Groups** → "rg-hybrid-infrastructure"
2. Click **Access Control (IAM)**
3. Click **Add role assignment**
4. Configure:
   - **Role**: Virtual Machine Contributor
   - **Assign access to**: User, group, or service principal
   - **Select**: [Select Azure users/groups]
   - **Members to assign**: Select 2-3 infrastructure engineers
5. Click **Review + assign**

**PowerShell Assignment:**
```powershell
# Assign VM Contributor role to resource group
$resourceGroupName = "rg-hybrid-infrastructure"
$roleDefinitionName = "Virtual Machine Contributor"
$principalId = (Get-AzADUser -UserPrincipalName "john.smith@nig-e-mart.com").Id

New-AzRoleAssignment -ObjectId $principalId `
                     -RoleDefinitionName $roleDefinitionName `
                     -ResourceGroupName $resourceGroupName
```

### Step 3.2: Assign Billing Administrator

For finance department managing Azure costs:

```powershell
# Assign Billing Administrator at subscription scope
$subscriptionId = "/subscriptions/{subscriptionId}"
$principalId = (Get-AzADUser -UserPrincipalName "michael.brown@nig-e-mart.com").Id

New-AzRoleAssignment -ObjectId $principalId `
                     -RoleDefinitionName "Billing Reader" `
                     -Scope $subscriptionId
```

### Step 3.3: Assign Help Desk Administrator (Microsoft 365)

For IT support staff resetting passwords:

```powershell
# Connect to Microsoft Graph
Connect-MgGraph -Scopes "RoleManagement.ReadWrite.Directory"

# Get the Helpdesk Administrator role (activate it if not yet instantiated in the tenant)
$role = Get-MgDirectoryRole -Filter "DisplayName eq 'Helpdesk Administrator'"
if (-not $role) {
  $roleTemplate = Get-MgDirectoryRoleTemplate | Where-Object { $_.DisplayName -eq 'Helpdesk Administrator' }
  $role = New-MgDirectoryRole -RoleTemplateId $roleTemplate.Id
}

# Assign the role to the support user
$user = Get-MgUser -UserId "lisa.wilson@nig-e-mart.com"
New-MgDirectoryRoleMember -DirectoryRoleId $role.Id `
  -BodyParameter @{ "@odata.id" = "https://graph.microsoft.com/v1.0/directoryObjects/$($user.Id)" }
```

### Step 3.4: Assignment Matrix

| User | Role | Scope | Justification |
|------|------|-------|---------------|
| John Smith | Subscription Owner | Subscription | Cloud architect, overall responsibility |
| Robert Johnson | Security Administrator | Resource Group | Network security specialist |
| Patricia Taylor | Virtual Machine Contributor | Resource Group | Database administrator |
| Lisa Wilson | Helpdesk Administrator | Tenant (M365) | Support staff password resets |
| Michael Brown | Billing Reader | Subscription | Cost tracking and budgets |
| Jane Doe | Intune Administrator | Tenant (M365) | Device management |

---

## Task 4: Configure Privileged Identity Management (PIM)

PIM enables just-in-time (JIT) elevated access requiring approval:

### Step 4.1: Enable PIM

1. Navigate to https://entra.microsoft.com
2. In the left sidebar, go to **Identity Governance** → **Privileged Identity Management**
3. Click **Azure resources** → **Discover resources**
4. Select your subscription and click **Manage resource**
5. PIM is now active for that subscription

### Step 4.2: Configure PIM Policies

1. Go to **Azure Resources** → select subscription
2. Click **Roles**
3. Select **Owner** role
4. Configure settings:
   - **Activation duration**: 4 hours
   - **Require MFA**: Yes
   - **Require justification**: Yes (users must explain why elevated access needed)
   - **Require incident/request ticket**: Yes (specify ticket system: ServiceNow, Jira)
   - **Approval requirement**: Yes (assign approvers)
   - **Approvers**: Select senior engineers (subscription owners)
5. Save policy

### Step 4.3: Request Elevated Access

When infrastructure engineer needs temporary Owner access:

1. Go to **Privileged Identity Management** → **My roles**
2. Under **Eligible roles**, find the role you need elevated access to
3. Click **Activate**
4. Provide justification: "Database migration maintenance window"
5. Set duration (up to the 4-hour maximum)
6. Click **Activate** — the request is sent to the approver
7. Upon approval, you will receive a notification and the role appears under **Active roles**
8. Access revokes automatically when the duration expires

**PowerShell Elevation Request:**
```powershell
# Request PIM elevation
$pimRequest = @{
    RoleDefinitionId = "8e3af657-a8ff-443c-a75c-2fe8c4bcb635"  # Owner role
    PrincipalId = "user-object-id"
    Justification = "Emergency database recovery"
    Duration = "PT4H"  # 4 hours
}

# Submit request (in practice, use PIM Portal or SDK)
```

---

## Task 5: Implement Access Reviews

Access reviews audit who has which permissions and identify orphaned accounts:

### Step 5.1: Create Access Review

1. Go to **Identity Governance** → **Access reviews**
2. Click **+ New access review**
3. Configure:
   - **Review name**: `Q3 2026 Azure RBAC Access Review`
   - **Scope**: Select subscription
   - **Review start date**: First day of the quarter
   - **Frequency**: Quarterly
   - **Auto apply recommendations**: No (manual approval)
   - **Decision makers**: Select senior engineers
4. Click **Create**

### Step 5.2: Execute Access Review

Decision makers receive notification to review access:

1. reviewers access the review
2. For each user with assigned roles:
   - Review if role still needed for current job function
   - Decision: Approve (keep access), Deny (remove access), or N/A (awaiting info)
3. Provide comment explaining decision
4. Upon review completion, approved access remains, denied access is revoked

**PowerShell Access Review:**
```powershell
# Get all role assignments for review
Get-AzRoleAssignment -Scope "/subscriptions/{subscriptionId}" | `
  Select-Object DisplayName, RoleDefinitionName, Scope | `
  Export-Csv -Path "AccessReview_Q1_2026.csv"

# Manually review CSV and identify unnecessary assignments
```

---

## Task 6: Establish Unified Audit Logging

### Step 6.1: Enable Azure Activity Logging

1. Go to **Activity Log**in Azure portal
2. Verify activities logged (should be automatic)
3. Create diagnostic setting to send logs to Log Analytics:
   - **Destination details**: Send to Log Analytics
   - **Log Analytics workspace**: Create new or select existing
   - **Categories**: All

**PowerShell Configuration:**
```powershell
# Create diagnostic setting for Activity Log
$workspaceId = (Get-AzOperationalInsightsWorkspace -ResourceGroupName $rgName -Name "log-analytics-hybrid").ResourceId

Set-AzDiagnosticSetting -ResourceId "/subscriptions/{subscriptionId}" `
                        -WorkspaceId $workspaceId `
                        -Enabled $true `
                        -Category @("Administrative", "Security", "ServiceHealth", "Alert")
```

### Step 6.2: Query Audit Logs

```kusto
// Query for Role Assignment Changes
AzureActivity
| where TimeGenerated > ago(30d)
| where OperationName contains "Create role assignment" or OperationName contains "Delete role assignment"
| project TimeGenerated, OperationName, CallerIpAddress, Caller, Properties

// Query for Privileged Access
AzureActivity
| where TimeGenerated > ago(7d)
| where Authorization contains "Owner" or Authorization contains "Contributor"
| project TimeGenerated, Caller, OperationName, ActivityStatus
```

---

## Validation Checklist

- [ ] RBAC roles defined and documented
- [ ] Virtual Machine Contributor assigned to infrastructure engineers
- [ ] Billing Administrator assigned to finance staff
- [ ] Help Desk Operator assigned to support team
- [ ] Security Administrator assigned to security staff
- [ ] PIM enabled for Owner and Contributor roles
- [ ] MFA required for elevated access
- [ ] Access reviews created and scheduled
- [ ] Activity logging configured for audit trail
- [ ] Role assignment queries working in Log Analytics

---

## Common Issues & Best Practices

**Issue**: Users request permanent elevated access instead of PIM
- **Solution**: Enforce policy that all elevated access goes through PIM with 4-hour limit

**Issue**: Approvers overwhelmed with approval requests
- **Solution**: Establish criteria for auto-approval (maintenance windows, known escalations)

**Best Practice**: Review access quarterly to identify orphaned accounts
- **Action**: Remove access for departed employees within 24 hours

**Best Practice**: Monitor PIM requests for patterns
- **Action**: Investigate frequent requests from same user (possible compromise)

---

*Phase 10 Completion Date: ___________*
*Document Version: 1.0*
*Last Updated: March 2, 2026*
