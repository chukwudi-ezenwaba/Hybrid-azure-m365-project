# Phase 3: Microsoft Teams Setup & Governance

**Duration**: Weeks 5-6 | **Key Result**: Teams deployed, governance enforced

## Phase Overview

| Item | Details |
|------|---------|
| What | Deploy Teams, create channels, enforce governance policies |
| Duration | 2 weeks |
| Depends | Phase 1 (users created), Phase 2 (security baseline) |
| Success | 4+ teams created, governance enforced, guest access working |

---

## Manual Setup: Week 5 - Create Teams & Channels

### Step 1: Create First Team (IT Department)

**Via Microsoft Teams Admin Center (GUI):**

1. Navigate to https://admin.teams.microsoft.com
2. Sign in as Global Admin
3. Click **Teams** → **Manage teams** (left sidebar)
4. Click **+ Add** button (top right)
5. Configure:
   - **Name**: IT
   - **Description**: Information Technology team for IT professionals
   - **Privacy**: Private (only members can access)
   - **Owner**: IT Manager's email
   - **Members**: 
     - Click **Add members**
     - Search for "IT team" group
     - Select all IT department users
   - Click **Create** button

**Verify creation:**
- Wait 30-60 seconds
- Refresh admin center
- Confirm team appears in Manage teams list
- Status should show "Active"

---

### Step 2: Create Teams for Other Departments

Repeat Step 1 for:
- **Sales**: Sales team (Private)
- **Finance**: Finance team (Private)
- **HR**: Human Resources team (Private)

**Expected Result:** 4 teams visible in admin center

---

### Step 3: Create Channels Within Each Team

**For IT Team - Create 6 Channels:**

1. Go to https://teams.microsoft.com (Teams desktop app or web)
2. Click **IT** team (left sidebar)
3. Click **...** (ellipsis) next to team name
4. Select **Manage team**
5. Click **Channels** tab
6. Click **+ Add channel** button

**Channel 1: Announcements**
- **Name**: announcements
- **Privacy**: Standard (within team)
- **Description**: Important IT announcements and updates
- Click **Create**

**Channel 2: Projects**
- **Name**: projects
- **Privacy**: Standard
- **Description**: Ongoing IT projects and initiatives
- Click **Create**

**Channel 3: Infrastructure**
- **Name**: infrastructure
- **Privacy**: Standard
- **Description**: On-prem and Azure infrastructure discussions
- Click **Create**

**Channel 4: Security**
- **Name**: security
- **Privacy**: Standard
- **Description**: Security incident response and best practices
- Click **Create**

**Channel 5: Archive**
- **Name**: archive
- **Privacy**: Standard
- **Description**: Historical conversations (no new posts)
- Click **Create**

**Channel 6: Random**
- **Name**: random
- **Privacy**: Standard
- **Description**: Off-topic discussions
- Click **Create**

**Repeat for Sales, Finance, HR teams** (customize channel names per department needs)

---

### Step 4: Add Members to Teams

**Method 1: Via Admin Center (Bulk)**

1. Go to admin center → **Teams** → **Manage teams**
2. Click **IT** team name
3. Click **Members** tab
4. Click **+ Add members** button
5. Search for department group (e.g., "Sales Group")
6. Select the group
7. Click **Apply** → **Add**
8. Wait for provisioning (1-5 minutes)
9. Verify members appear in the Members list

**Method 2: Via Teams App (Individual)**

1. Open Teams app
2. Click **IT** team
3. Click **...** → **Add members**
4. Type username and click user
5. Choose role:
   - **Owner**: Can manage team settings (limit to 1-2 per team)
   - **Member**: Can participate (default)
6. Click **Add**

---

### Step 5: Add Guest Users (Optional)

**For external partners/contractors:**

1. Teams admin center → Click **IT** team
2. Click **Members** tab
3. Click **+ Add members** button
4. Enter **external email** (e.g., partner@external.com)
5. Choose role: **Member** or **Guest**
6. Click **Add**
7. Guest receives invitation email
8. Guest accepts and joins team

---

## Manual Setup: Week 6 - Configure Governance Policies

### Step 6: Configure Teams Naming Policy

**Via Microsoft 365 Admin Center:**

1. Navigate to https://admin.microsoft.com
2. Go to **Settings** → **Org settings** (left sidebar)
3. Click **Teams**
4. Go to **Teams settings** section
5. Find **Teams naming policy**
6. Enable: "Require prefix" and "Block words"

**Set Naming Convention:**

- **Prefix to Always Add**: [DEPT] (so teams start with department code)
- **Blocked Words**: Add inappropriate words to block (e.g., "Test", "Spam", "Admin")
- Examples of enforced naming:
  - [IT]-Infrastructure ✓ Allowed
  - [SALES]-Q1-Goals ✓ Allowed
  - Test-Team ✗ Blocked (missing [DEPT])

7. Click **Save**

**PowerShell Alternative:**
```powershell
Connect-MicrosoftTeams
$naming = @{
  PrefixSuffixNamingPolicy = "[DEPT]"
}
Set-TeamsFrontendSettings @naming
```

---

### Step 7: Configure Message Retention Policy

**Via Security & Compliance Center:**

1. Navigate to https://compliance.microsoft.com
2. Go to **Data lifecycle management** → **Retention policies** (left sidebar)
3. Click **+ Create policy**
4. **Name**: Teams Message Retention - 1 Year
5. **Description**: Keep Teams messages for 1 year, then delete
6. **Decision**: 
   - Select "Retain then delete"
   - **Duration**: 1 year (365 days)
7. **Locations**:
   - Enable: "Microsoft Teams channel messages"
   - Enable: "Microsoft Teams chats"
   - Disable other locations (if not needed)
8. Click **Next** → **Create**
9. Publish the policy

**Verify:**
- Policy status should show "Published"
- Apply time: 24-48 hours

---

### Step 8: Configure Guest Access Policy

**Via Teams Admin Center:**

1. Navigate to https://admin.teams.microsoft.com
2. Go to **Org-wide settings** → **Guest access** (left sidebar)
3. Enable **Allow guest access in Teams**: Toggle ON
4. Enable **Allow guest access in channel and team membership**: Toggle ON
5. Configure guest permissions:
   - **Allow guest create, update, and delete channels**: OFF (don't allow)
   - **Allow guest delete channels**: OFF
   - **Allow guest calling**: ON (so guests can call)
   - **Allow guest video**: ON
   - **Allow guest screen sharing**: ON
   - **Allow guest screen viewing**: ON
6. Click **Save**

**Optional: Set guest expiration (30 days):**

Via Azure AD admin center:
1. https://aad.portal.azure.com
2. **Groups** → **Expiration**
3. Set "Group expiration period": 30 days
4. Notify before expiration: 30 days
5. Save

---

### Step 9: Create Moderation Rules (Optional)

**Via Teams Admin Center:**

1. Go to https://admin.teams.microsoft.com
2. **Teams** → **Manage teams** → Select **IT** team
3. Click **Settings** tab
4. Find **Moderation and sensitive content**
5. Enable: "Use automated content moderation"
6. Choose filter level:
   - **Off**: No filtering
   - **Moderate**: Filter profanity and some sensitive terms
   - **Strict**: Filter profanity + adult/violent content
7. Select **Moderate** level
8. Click **Save**

---

## Automation: PowerShell Scripts (Alternative to Manual Steps)

### Option A: Create Teams Automatically

```powershell
# Connect to Teams PowerShell
Connect-MicrosoftTeams
Connect-MgGraph -Scopes "Group.ReadWrite.All", "User.Read.All"

# Create IT Team
$ITTeam = New-Team -DisplayName "IT" `
                   -Description "IT Department" `
                   -Visibility Private `
                   -Owner "it.manager@organization.com"

# Create channels
New-TeamChannel -GroupId $ITTeam.GroupId -DisplayName "announcements" -Description "IT announcements"
New-TeamChannel -GroupId $ITTeam.GroupId -DisplayName "projects" -Description "IT projects"
New-TeamChannel -GroupId $ITTeam.GroupId -DisplayName "infrastructure" -Description "Infrastructure"

# Add members
Add-TeamUser -GroupId $ITTeam.GroupId `
             -User "it-team@organization.com" `
             -Role "Member"

Write-Host "✓ IT Team created and configured"
```

### Option B: Bulk Create Teams from CSV

```powershell
# CSV file: teams.csv
# Format:
# TeamName,Description,Visibility,OwnerEmail
# IT,IT Department,Private,it.manager@organization.com
# Sales,Sales Team,Private,sales.manager@organization.com

$teams = Import-Csv "teams.csv"

foreach ($team in $teams) {
    $newTeam = New-Team -DisplayName $team.TeamName `
                        -Description $team.Description `
                        -Visibility $team.Visibility `
                        -Owner $team.OwnerEmail
    
    Write-Output "✓ Created team: $($team.TeamName) (Group ID: $($newTeam.GroupId))"
}
```

**To run:**
```powershell
.\07-create-groups.ps1 -TeamsCSV teams.csv
```

---

## Configuration Summary

| Item | Configuration |
|------|---------------|
| **Teams Created** | 4 (IT, Sales, Finance, HR) |
| **Channels per Team** | 5-7 (General, Announcements, Projects, Archive, + custom) |
| **Privacy** | Private (members only) |
| **Guest Access** | Enabled with 30-day expiration |
| **Naming Policy** | [DEPT]-[PURPOSE] (e.g., [IT]-Infrastructure) |
| **Message Retention** | 1 year active, then delete |
| **Moderation** | Moderate profanity filtering |
| **External Sharing** | SharePoint only (Teams direct disabled) |

---

## Success Checklist

- [ ] 4 teams created (IT, Sales, Finance, HR)
- [ ] 5-7 channels per team created
- [ ] Team owners assigned (1-2 per team)
- [ ] Department members added to appropriate teams
- [ ] Guest access enabled with 30-day expiration
- [ ] Naming policy enforced ([DEPT] prefix required)
- [ ] Message retention policy published (1 year)
- [ ] Moderation filtering enabled (Moderate level)
- [ ] Test: Create a new team → verify naming enforced
- [ ] Test: Add guest → verify 30-day notifications sent
- [ ] All users can login to Teams and see their team

---

## Troubleshooting

### Issue: Team creation fails with "Access Denied"
**Solution:**
- Verify you're using Global Admin account
- Check permissions: `Get-TeamUser -GroupId <id>`
- Retry with `-Owner <global-admin>`

### Issue: Channels not visible to all members
**Solution:**
- Verify members added to team (not just channel owner)
- Check privacy setting: should be "Standard" not "Private"
- Wait 5 minutes for provisioning

### Issue: Guest cannot see team
**Solution:**
- Verify guest was explicitly added to team (not just channel)
- Resend invitation: `Get-TeamUser -GroupId <id> | select User`
- Check conditional access policies not blocking guest

### Issue: Naming policy not enforced
**Solution:**
- Policy takes 24-48 hours to activate
- Verify policy published (not just created)
- Try creating new team after waiting period

---

## Performance Metrics

After 1 week:
- [ ] 100+ users active in Teams
- [ ] 50+ conversations in channels
- [ ] <100ms message latency
- [ ] 0 governance policy violations

After 1 month:
- [ ] 80%+ adoption rate
- [ ] 500+ messages across teams
- [ ] User satisfaction survey >4/5

---

## Next Phase

→ **Phase 4: Monitoring & Compliance** (Implement audit logging, set up dashboards, monitor Teams usage)

---

**Document Version**: 1.0  
**Last Updated**: March 4, 2026  
**Notes**: Combines manual step-by-step GUI instructions with PowerShell automation options. Choose Manual for learning, PowerShell for scale.
