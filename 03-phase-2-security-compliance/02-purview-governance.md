# Microsoft Purview – Governance & Compliance Configuration

**Phase**: 2 – Security & Compliance | **Depends on**: Phase 1 (M365 tenant active, audit logging enabled)  
**Key Result**: Sensitivity labels deployed, DLP blocking external PII/PCI sharing, retention policies active for all workloads, eDiscovery ready for legal holds

---

## Overview

Microsoft Purview provides data governance, compliance, and risk management across Microsoft 365 workloads. This guide covers:

1. Enabling unified audit logging
2. Sensitivity labels (classification)
3. Data Loss Prevention (DLP) policies
4. Retention policies (Exchange, SharePoint, OneDrive, Teams)
5. eDiscovery configuration
6. Insider Risk Management (basic setup)

All steps are performed in the **Microsoft Purview compliance portal**: https://compliance.microsoft.com

---

## Step 1: Enable Unified Audit Logging

Audit logging must be on before retention and eDiscovery work correctly.

**Via Purview portal:**

1. Go to https://compliance.microsoft.com
2. Navigate to **Audit** (left sidebar)
3. If you see "Start recording user and admin activity", click it → **Turn on**
4. Wait up to 60 minutes for activation

**Via PowerShell:**

```powershell
Connect-IPPSSession -UserPrincipalName admin@yourdomain.com

# Enable unified audit log
Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled $true

# Verify it's on
Get-AdminAuditLogConfig | Select UnifiedAuditLogIngestionEnabled
# Expected: True
```

---

## Step 2: Sensitivity Labels

Sensitivity labels classify documents and emails so that protection travels with the content.

### 2.1 – Create Labels

1. Go to **Information protection** → **Labels** → **+ Create a label**

Create the following four labels in order (parent labels first):

| Label | Description | Color |
|---|---|---|
| Public | No restrictions; for externally shareable content | Green |
| Internal | Default for all internal business documents | Blue |
| Confidential | Restricted to named staff; encryption recommended | Orange |
| Restricted | Highest sensitivity; encryption required, no external sharing | Red |

**Configuration for each label (example: Confidential):**

- **Name**: Confidential
- **Display name**: Confidential
- **Description for users**: Contains sensitive business data. Do not share externally.
- **Encryption**: Turn on → Assign permissions now
  - Click **Add or remove users** → Add domain: `yourdomain.com`
  - Permissions: Co-Author (read, edit, can't remove label)
- **Content marking**:
  - Header: `CONFIDENTIAL – nig-e-mart Internal Use Only`
  - Watermark: `CONFIDENTIAL`
- Click **Next** through remaining pages → **Create label**

### 2.2 – Publish the Labels

After creating all labels, publish them so users see them in Office apps:

1. **Information protection** → **Label policies** → **+ Publish label**
2. Select all 4 labels
3. **Assign to users and groups**: All users
4. **Policy settings**:
   - Default label for documents: **Internal**
   - Require users to justify removing or downgrading a label: **Yes**
5. **Policy name**: `nig-emart-sensitivity-policy`
6. Click **Submit**

Allow 24 hours for labels to appear in Word, Excel, Outlook, Teams, and SharePoint.

---

## Step 3: Data Loss Prevention (DLP) Policies

DLP policies detect and block sensitive data from leaving the organisation.

### 3.1 – Policy: Block External PII Sharing

```powershell
Connect-IPPSSession -UserPrincipalName admin@yourdomain.com

# Create DLP policy to block external PII sharing
New-DlpCompliancePolicy `
  -Name "Block External PII" `
  -ExchangeLocation All `
  -SharePointLocation All `
  -OneDriveLocation All `
  -TeamsLocation All `
  -Mode Enforce

# Add rule: detect Canadian SIN or credit card numbers, block external send
New-DlpComplianceRule `
  -Name "Block PII External" `
  -Policy "Block External PII" `
  -ContentContainsSensitiveInformation @(
      @{Name="Canada Social Insurance Number"; minCount="1"},
      @{Name="Credit Card Number"; minCount="1"}
  ) `
  -SentToScope NotInOrganization `
  -BlockAccess $true `
  -NotifyUser Owner `
  -GenerateIncidentReport SiteAdmin `
  -ReportSeverityLevel High

Write-Host "PII DLP policy created" -ForegroundColor Green
```

### 3.2 – Policy: Block External PCI Sharing (Credit Cards)

```powershell
New-DlpCompliancePolicy `
  -Name "Block External PCI" `
  -ExchangeLocation All `
  -SharePointLocation All `
  -OneDriveLocation All `
  -Mode Enforce

New-DlpComplianceRule `
  -Name "Block PCI External" `
  -Policy "Block External PCI" `
  -ContentContainsSensitiveInformation @(
      @{Name="Credit Card Number"; minCount="1"}
  ) `
  -SentToScope NotInOrganization `
  -BlockAccess $true `
  -NotifyUser Owner `
  -GenerateIncidentReport SiteAdmin `
  -ReportSeverityLevel High

Write-Host "PCI DLP policy created" -ForegroundColor Green
```

### 3.3 – Verify DLP Policies via Portal

1. **Data loss prevention** → **Policies**
2. Confirm both policies show **Status: On**
3. Go to **DLP** → **Reports** → Review any policy match alerts (check after 48 hours)

---

## Step 4: Retention Policies

Retention policies ensure business records are kept for the required period and then deleted.

### 4.1 – Exchange Email: 7-Year Retention

```powershell
# Create 7-year email retention policy
New-RetentionCompliancePolicy `
  -Name "Exchange 7-Year Retention" `
  -ExchangeLocation All

New-RetentionComplianceRule `
  -Name "Exchange 7-Year Rule" `
  -Policy "Exchange 7-Year Retention" `
  -RetentionDuration 2555 `
  -RetentionDurationDisplayHint Days `
  -ExpirationDateOption CreationAgeInDays `
  -RetentionComplianceAction Keep

Write-Host "Exchange retention policy created" -ForegroundColor Green
```

### 4.2 – SharePoint & OneDrive: 5-Year Retention

```powershell
New-RetentionCompliancePolicy `
  -Name "SharePoint OneDrive 5-Year Retention" `
  -SharePointLocation All `
  -OneDriveLocation All

New-RetentionComplianceRule `
  -Name "SharePoint 5-Year Rule" `
  -Policy "SharePoint OneDrive 5-Year Retention" `
  -RetentionDuration 1825 `
  -RetentionDurationDisplayHint Days `
  -ExpirationDateOption CreationAgeInDays `
  -RetentionComplianceAction Keep

Write-Host "SharePoint/OneDrive retention policy created" -ForegroundColor Green
```

### 4.3 – Microsoft Teams Messages: 1-Year Retention

```powershell
New-RetentionCompliancePolicy `
  -Name "Teams Messages 1-Year Retention" `
  -TeamsChannelLocation All `
  -TeamsChatLocation All

New-RetentionComplianceRule `
  -Name "Teams 1-Year Rule" `
  -Policy "Teams Messages 1-Year Retention" `
  -RetentionDuration 365 `
  -RetentionDurationDisplayHint Days `
  -ExpirationDateOption CreationAgeInDays `
  -RetentionComplianceAction Keep

Write-Host "Teams retention policy created" -ForegroundColor Green
```

### 4.4 – Verify Retention Policies

1. **Data lifecycle management** → **Retention policies**
2. All three policies should show **Status: On** and **Locations** correctly mapped

---

## Step 5: eDiscovery Configuration

eDiscovery enables legal holds and content searches for litigation, investigations, or regulatory requests.

### 5.1 – Create an eDiscovery Case

1. Go to **eDiscovery** → **Standard** → **+ Create a case**
2. Configure:
   - **Name**: `Case-2026-001` (use a naming convention)
   - **Description**: Brief description of the matter
3. Click **Save**
4. Open the case → **Members** tab → Add the legal/compliance team members who can access this case

### 5.2 – Place a Legal Hold

A hold preserves content even if users delete it:

1. Open the case → **Hold** tab → **+ Create**
2. **Name**: `Hold-2026-001-CustodianName`
3. **Locations**:
   - Exchange mailboxes: Search for and add the custodian's account
   - SharePoint sites: Add any relevant sites
   - OneDrive: Add the custodian's OneDrive
4. **Query-based hold** (optional): Add keywords to limit the hold scope
5. Click **Next** → **Create this hold**

### 5.3 – Export Search Results (Content Search)

1. **eDiscovery** → **Standard** → open the case → **Searches** tab → **+ New search**
2. Configure:
   - Locations: Exchange, SharePoint, OneDrive for relevant users
   - Keywords: relevant search terms
3. Run the search → review results count
4. Click **Actions** → **Export results** to download for review

---

## Step 6: Monitor Compliance Status

### Monthly Compliance Check

```powershell
Connect-IPPSSession -UserPrincipalName admin@yourdomain.com

# Check DLP policy match counts (last 30 days)
Get-DlpDetailReport -StartDate (Get-Date).AddDays(-30) -EndDate (Get-Date) |
  Group-Object PolicyName |
  Select Name, Count |
  Sort-Object Count -Descending

# Check for any retention policy errors
Get-RetentionCompliancePolicy | Select Name, Mode, DistributionStatus

# Audit log query: admin activities in the last 7 days
Search-UnifiedAuditLog -StartDate (Get-Date).AddDays(-7) -EndDate (Get-Date) `
  -RecordType ExchangeAdmin `
  -ResultSize 50 |
  Select CreationDate, UserIds, Operations, AuditData |
  Format-Table -AutoSize
```

### Compliance Score (Compliance Manager)

1. Go to https://compliance.microsoft.com → **Compliance Manager**
2. Review your current score and improvement actions
3. Address any high-impact items flagged under **Identity**, **Data protection**, and **Device** categories
4. Export the compliance report monthly and save to SharePoint → `IT/Compliance-Reports/YYYY-MM.pdf`
