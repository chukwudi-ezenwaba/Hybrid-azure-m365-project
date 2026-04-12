# Phase 1.2: Licensing Configuration (E3 vs E5)

**Depends on**: Phase 1.1 (users created)  
**Key Result**: Every user has a licence assigned that matches their role; no unlicensed accounts remain

---

## Which Licence Goes to Whom

Microsoft 365 E3 and E5 both include Exchange Online, SharePoint, Teams, OneDrive, and Intune. The difference is in security depth. E5 adds Microsoft Defender for Office 365 Plan 2, Entra ID Premium P2 (required for PIM and risk-based Conditional Access), and advanced Purview compliance features. Assigning E5 only where it is needed keeps licensing costs under control while ensuring the highest-risk users have the strongest protections.

For nig-e-mart, the assignment strategy is:
- **E5**: IT staff, Finance department, HR department, and Executives — these roles handle sensitive data or have elevated system access
- **E3**: Sales, Marketing, and general office staff

---

## Step 1: Check Available Licence Seats

Before assigning, confirm you have enough of each licence type.

1. Sign in to the Microsoft 365 admin centre at https://admin.microsoft.com.
2. Go to **Billing** → **Your products**.
3. Click on the **Microsoft 365 E3** subscription. Note the **Assigned** and **Available** counts.
4. Repeat for **Microsoft 365 E5**.

If you do not have enough seats, click **Buy more licences** on the same page and purchase additional seats before proceeding. Licence provisioning is usually immediate.

---

## Step 2: Prepare the Licences CSV

Open `13-automation/powershell/SAMPLE-licenses.csv` and populate it with a row for every user. The file requires two columns:

```
UserPrincipalName,LicenseType
john.smith@nig-e-mart.com,E5
jane.doe@nig-e-mart.com,E3
sarah.jones@nig-e-mart.com,E5
```

Every user who was created in Phase 1.1 must have a row here. Save the completed file as `licenses.csv` in the same folder.

---

## Step 3: Connect to Microsoft 365 via PowerShell

Open PowerShell as Administrator and connect to the Microsoft Graph module:

```powershell
# Install the module if not already installed
Install-Module Microsoft.Graph -Scope CurrentUser -Force

# Connect (a browser window will open for sign-in)
Connect-MgGraph -Scopes "User.ReadWrite.All", "Organization.Read.All"
```

---

## Step 4: Preview the Assignments Before Applying

Run the licence script in preview mode first. This shows you exactly what will be assigned without making any changes, so you can catch mistakes in the CSV before they affect users.

```powershell
.\13-automation\powershell\03-license-assignment.ps1 -licensePath ".\licenses.csv" -Preview
```

The output will list each user and the licence they would receive. Check that:
- IT and Finance staff are all showing E5
- No staff are showing the wrong tier
- The total E3 and E5 counts match what you purchased

If you spot an error, correct the CSV and re-run the preview until the output looks right.

---

## Step 5: Apply the Licences

Once the preview output is correct, apply the assignments:

```powershell
.\13-automation\powershell\03-license-assignment.ps1 -licensePath ".\licenses.csv" -Apply
```

The script will process each row and output a success or failure message per user. Any failures — typically caused by a typo in the UPN or an exhausted licence pool — will be listed at the end.

---

## Step 6: Verify in the Admin Portal

After the script finishes, verify the results in the admin centre:

1. Go to https://admin.microsoft.com → **Users** → **Active users**.
2. In the **Licenses** column, each user should show either **Microsoft 365 E3** or **Microsoft 365 E5**. Any user still showing **Unlicensed** must be investigated and re-processed.
3. To check an individual user, click their name → **Licenses and apps** tab. The assigned licence should be checked, and you can expand it to see which individual service plans are enabled.

You can also run a quick PowerShell check to find any remaining unlicensed accounts:

```powershell
# List any users with no licence assigned
Get-MgUser -All -Property DisplayName,UserPrincipalName,AssignedLicenses |
  Where-Object { $_.AssignedLicenses.Count -eq 0 } |
  Select-Object DisplayName, UserPrincipalName
```

If any users appear in this output, add them to the CSV and re-run the apply step.

---

## Step 7: Confirm Service Plans Are Active

A licence is assigned, but some service plans within it can be individually disabled. Confirm the key plans are active for a sample E3 and E5 user:

```powershell
# Check enabled service plans for a specific user
Get-MgUserLicenseDetail -UserId "john.smith@nig-e-mart.com" |
  Select-Object -ExpandProperty ServicePlans |
  Where-Object { $_.ProvisioningStatus -eq "Success" } |
  Select-Object ServicePlanName |
  Sort-Object ServicePlanName
```

For an E3 user you should see `EXCHANGE_S_ENTERPRISE`, `SHAREPOINTENTERPRISE`, `TEAMS1`, and `INTUNE_A` among others. For an E5 user you should additionally see `THREAT_INTELLIGENCE` (Defender Plan 2) and `AAD_PREMIUM_P2`.

---

## Completion Checklist

- All users have either E3 or E5 assigned — zero unlicensed accounts in the portal
- E5 is assigned to IT, Finance, HR, and Executives
- Key service plans (Exchange, SharePoint, Teams) show `Success` provisioning status for a sample of users
- Licence seat counts in Billing → Your products show expected consumption

---

## Next Step

Proceed to [Phase 1.3 – Exchange Online Setup](03-exchange-online.md).

