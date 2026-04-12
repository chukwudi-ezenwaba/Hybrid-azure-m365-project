# Azure Site Recovery – Configuration Guide

**Phase**: 6 – High Availability & Redundancy | **Depends on**: Phase 7 (Azure VNet + VPN active), Hyper-V host running  
**Key Result**: On-premises VMs (DC, File Server, Intranet Web Server) continuously replicated to Azure; automated failover testable in under 1 hour

---

## Overview

Azure Site Recovery (ASR) replicates on-premises Hyper-V VMs to Azure, enabling:
- **Continuous replication** with configurable recovery point retention (minimum 15-minute RPO)
- **Test failover** that validates recovery without impacting production
- **Planned/unplanned failover** that brings VMs online in Azure within minutes

**VMs protected by ASR in this deployment:**

| VM | On-prem role | Azure failover target |
|---|---|---|
| DC1-Primary | Primary Domain Controller | Azure Recovery VM (same VNet as DC2) |
| FS-Primary | File Server | Azure Recovery VM |
| INTRANET-Primary | Intranet Web Application Server | Azure Recovery VM |

---

## Step 1: Create a Recovery Services Vault

1. Sign in to https://portal.azure.com
2. Search for **Recovery Services vaults** → Click **+ Create**
3. Configure:
   - **Subscription**: Your subscription
   - **Resource Group**: `Infrastructure-RG` (same as other resources)
   - **Vault name**: `nig-emart-asrvault`
   - **Region**: A different region from your primary Azure resources (e.g., if primary is East US, use West US for actual DR; for lab use the same region)
4. Click **Review + create** → **Create**
5. Once deployed, open the vault

---

## Step 2: Configure the Vault Replication Settings

Inside the Recovery Services Vault:

1. Click **Site Recovery** (under Getting started)
2. Click **Prepare infrastructure**
3. **Protection goal** settings:
   - **Where are your machines located?**: On-premises
   - **Where do you want to replicate your machines?**: To Azure
   - **Are your machines virtualized?**: Yes, with Hyper-V
   - **Are you using System Center VMM?**: No
4. Click **OK**

---

## Step 3: Create a Hyper-V Site

1. In the vault → **Site Recovery Infrastructure** → **Hyper-V Sites** → **+ Add**
2. **Site name**: `nig-emart-onprem-site`
3. Click **OK**

---

## Step 4: Install the Azure Site Recovery Provider on the Hyper-V Host

On the **Hyper-V host server** (not inside a VM):

1. Back in the portal, under **Prepare source** → click **+ Hyper-V Server**
2. Select the site you created (`nig-emart-onprem-site`)
3. Click **Download** to get:
   - **AzureSiteRecoveryProvider.exe** (Provider installer)
   - **Registration key** file (vault credentials `.VaultCredentials`)
4. On the Hyper-V host, run **AzureSiteRecoveryProvider.exe**:
   - Accept the license → **Install**
   - When prompted for the vault credentials file, browse to the downloaded `.VaultCredentials` file
   - Installer registers the Hyper-V host with the vault automatically
5. After installation, confirm the Hyper-V host appears under **Site Recovery Infrastructure** → **Hyper-V Hosts**

---

## Step 5: Create a Replication Policy

1. In the vault → **Site Recovery Infrastructure** → **Replication Policies** → **+ Create and associate**
2. Configure:
   - **Name**: `nig-emart-replication-policy`
   - **Copy frequency**: 5 minutes
   - **Recovery point retention (hours)**: 24 (keeps 24 hours of recovery points)
   - **App-consistent snapshot frequency (hours)**: 1
   - **Initial replication start time**: Immediately
3. Click **OK** — the policy is automatically associated with the Hyper-V site

---

## Step 6: Enable Replication for Each VM

Repeat for each protected VM (DC1-Primary, FS-Primary, INTRANET-Primary):

1. In the vault → **Replicated items** → **+ Replicate**
2. **Source settings**:
   - **Source location**: On-Premises
   - **Source – machine type**: Virtual Machines
   - **Source – Hyper-V site**: `nig-emart-onprem-site`
3. **Virtual machine selection**: Check the VM to protect (e.g., DC1-Primary)
4. **Target settings**:
   - **Subscription**: Your subscription
   - **Post-failover resource group**: `Infrastructure-RG`
   - **Post-failover storage account**: Create or select an existing Standard_LRS storage account
   - **Azure network**: `Prod-VNET` (the VNet created in Phase 7)
   - **Subnet**: `Infrastructure-subnet` (10.0.1.0/24)
5. **Replication settings**:
   - **Replication policy**: `nig-emart-replication-policy`
6. Click **Enable replication**
7. Repeat for FS-Primary and INTRANET-Primary

**Monitor initial replication progress:**

1. Vault → **Replicated items**
2. Each VM starts in **Enabling protection** state
3. Initial replication (full disk copy) takes 1–3 hours depending on disk size
4. Status changes to **Protected** once complete

---

## Step 7: Create a Recovery Plan

A Recovery Plan defines the failover order (DC must come up before other servers):

1. Vault → **Recovery Plans** → **+ Recovery plan**
2. Configure:
   - **Name**: `nig-emart-recovery-plan`
   - **Source**: Your on-prem Hyper-V site
   - **Target**: Microsoft Azure
   - **Allow items with deployment model**: Resource Manager
3. **Select items**: Add all 3 VMs (DC1-Primary, FS-Primary, INTRANET-Primary)
4. Click **OK**

**Customize the failover order:**

1. Open the recovery plan → **Customize**
2. The default is a single group (Group 1). Split into sequenced groups:
   - **Group 1** (boots first): DC1-Primary
   - **Group 2** (boots after Group 1): FS-Primary
   - **Group 3** (boots after Group 2): INTRANET-Primary
3. Add a **Manual action** between Group 1 and Group 2: "Verify DC1 is online and AD services are running before proceeding"
4. Click **Save**

---

## Step 8: Configure Recovery VM Sizes

For each replicated item, set the target VM size for failover:

1. Vault → **Replicated items** → click a VM → **Compute and Network**
2. Configure:
   - **Azure VM size**: Match or exceed the on-prem VM spec (e.g., `Standard_D2s_v3`)
   - **OS disk**: Select the replicated managed disk
   - **Network interfaces**: Assign to `Prod-VNET` / `Infrastructure-subnet`
   - **Set a static private IP** for the DC failover VM (e.g., 10.0.1.10) so DNS entries stay consistent
3. Repeat for all 3 VMs

---

## Step 9: Quarterly Test Failover (Non-Disruptive)

Test failover spins up VMs in an **isolated Azure network** — production is not affected:

1. Vault → **Recovery Plans** → `nig-emart-recovery-plan` → **Test failover**
2. Settings:
   - **Recovery point**: Latest processed (lowest RTO)
   - **Azure virtual network**: Select or create an **isolated test VNet** (e.g., `DR-Test-VNET`) — do NOT use `Prod-VNET`
3. Click **Test failover**
4. Monitor in **Jobs** — the plan boots Group 1 (DC), then Group 2, then Group 3

**Validate the test:**

```powershell
# RDP into the failover DC VM in the test network and verify AD is running
Get-Service ADWS, NTDS, DNS | Select Name, Status
# All should show: Running

# Verify AD replication awareness
repadmin /showrepl

# Check Event Viewer for any critical AD errors
Get-EventLog -LogName "Directory Service" -EntryType Error -Newest 10
```

5. After validation, click **Cleanup test failover** in the portal (this removes the test VMs)
6. Document results: record which VMs came up cleanly, time to first DC response, any errors

---

## Step 10: Actual Failover (Emergency Procedure)

Only execute during a genuine on-premises outage:

1. Vault → **Recovery Plans** → `nig-emart-recovery-plan` → **Failover** (not Test failover)
2. Settings:
   - **Direction**: On-Premises → Azure
   - **Recovery point**: Latest processed OR Latest app-consistent (choose based on situation)
3. Check **"Shut down machine before beginning failover"** — only if on-prem VMs are still reachable
4. Click **Failover**
5. After VMs are running in Azure:
   - Update DNS records if needed (point `dc.organization.local` to Azure DC IP)
   - Notify all staff that services are running from Azure
6. Once on-prem is restored: run **Failback** to replicate Azure VMs back to on-prem before cutting over

---

## Monitoring and Alerts

### Enable ASR Replication Health Alerts

1. Recovery Services Vault → **Alerts** → **+ Create alert rule**
2. **Signal**: `Replication health change`
3. **Condition**: Status changed to `Critical`
4. **Action group**: Email `itops@yourdomain.com`
5. Click **Create**

### Monthly Health Check

```powershell
# Connect to Azure
Connect-AzAccount

# List all protected items and their status
Get-AzRecoveryServicesReplicationProtectedItem `
  -ResourceGroupName "Infrastructure-RG" `
  -VaultName "nig-emart-asrvault" |
  Select FriendlyName, ReplicationHealth, LastSuccessfulFailoverTime |
  Format-Table -AutoSize

# Check for any replication errors
Get-AzRecoveryServicesReplicationProtectedItem `
  -ResourceGroupName "Infrastructure-RG" `
  -VaultName "nig-emart-asrvault" |
  Where-Object { $_.ReplicationHealth -ne "Normal" } |
  Format-Table FriendlyName, ReplicationHealth, HealthErrors
```

**Expected output**: All VMs show `ReplicationHealth: Normal` with a `LastSuccessfulFailoverTime` within the last 24 hours.

---

## RTO/RPO Reference

| VM | Target RPO | Target RTO | ASR Configuration |
|---|---|---|---|
| DC1-Primary | 24 hours | 1 hour | 5-min copy frequency, 24-hr retention |
| FS-Primary | 24 hours | 2 hours | 5-min copy frequency, 24-hr retention |
| INTRANET-Primary | 24 hours | 2 hours | 5-min copy frequency, 24-hr retention |
