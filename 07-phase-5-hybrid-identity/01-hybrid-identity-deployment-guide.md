# Phase 5: Hybrid Identity Deployment and Azure AD Connect

## Phase Overview

This critical phase establishes hybrid identity by deploying on-premises Active Directory Domain Services and synchronizing identities to Azure Entra ID via Azure AD Connect. This is the foundation enabling seamless single sign-on across on-premises, Azure, and Microsoft 365 services.

**Duration**: 3 weeks  
**Key Objectives**: AD DS deployment, Azure AD Connect sync, identity validation, hybrid authentication testing

---

## Task 1: Deploy On-Premises Active Directory Domain Services

### Step 1.1: Prepare Windows Server VM

**VM Specifications:**
- Operating System: Windows Server 2019 or 2022 (recommended 2022)
- RAM: Minimum 4 GB (8 GB recommended)
- Storage: 50 GB+ C: drive for AD database
- Network: Static IP address assigned
- Connectivity: Network connectivity to Azure (for future VPN)
- Hypervisor: Proxmox, Hyper-V, or VMware

**Network Configuration:**

1. Assign static IP address (example: 192.168.1.10):
```powershell
# Configure static IP via PowerShell
New-NetIPAddress -InterfaceAlias "Ethernet" `
                 -IPAddress "192.168.1.10" `
                 -PrefixLength 24 `
                 -DefaultGateway "192.168.1.1"

Set-DnsClientServerAddress -InterfaceAlias "Ethernet" `
                           -ServerAddresses "192.168.1.10" `
                           -Validate
```

2. Configure DNS:
   - Primary DNS: Point to self (localhost, 127.0.0.1 or server's own IP)
   - This allows forward lookup zones for domain

3. Rename server:
```powershell
Rename-Computer -NewName "DC-Primary" -Force -Restart
```

4. Update Windows to latest patches:
```powershell
# Download and install Windows updates
Update-Help
Invoke-WebRequest "https://aka.ms/PSWindowsUpdate" -OutFile PSWindowsUpdate.zip
Expand-Archive PSWindowsUpdate.zip -DestinationPath C:\PSWindowsUpdate
```

### Step 1.2: Install Active Directory Domain Services Role

1. Open **Server Manager** (automatic on Windows Server startup)
2. Click **Add Roles and Features**
3. Select role:
   - **Role**: Active Directory Domain Services
   - Click **Next**
4. Features to include:
   - [ ] Active Directory Domain Services
   - [ ] Group Policy Management
   - [ ] Remote Desktop Services
5. Click **Install**
6. Wait for installation to complete (~5 minutes)

**PowerShell Installation:**
```powershell
# Install AD DS and management tools
Add-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

# Verify installation
Get-WindowsFeature -Name AD-Domain-Services | Where-Object {$_.Installed}
```

### Step 1.3: Promote Server to Domain Controller

1. In **Server Manager**, click **Notifications** (flag icon top right)
2. Click **Promote this server to a domain controller**
3. Select **Add a new forest**:
   - **Root domain name**: "contoso.local" (or your organization)
   - Note: Use .local for on-premises, reserve .onmicrosoft.com for cloud
4. Configure directories:
   - **Database Location**: C:\Windows\NTDS
   - **Log Location**: C:\Windows\NTDS
   - **SYSVOL Location**: C:\Windows\SYSVOL
5. Provide DSRM password (disaster recovery):
   - Set complex password for emergency access
   - Store securely in password manager
6. Review configuration:
   - Forest Functional Level: Default (usually 2016 or 2019)
   - Domain Functional Level: Default
7. Click **Install** and wait for server to restart

**PowerShell Promotion:**
```powershell
# Import AD Deployment Module
Import-Module ADDSDeployment

# Promote to domain controller
Install-ADDSForest -DomainName "contoso.local" `
                   -DomainNetbiosName "CONTOSO" `
                   -ForestMode Default `
                   -DomainMode Default `
                   -CreateDnsDelegation:$false `
                   -SafeModeAdministratorPassword (ConvertTo-SecureString "ComplexPassword123!@#" -AsPlainText -Force) `
                   -NoRebootOnCompletion:$false `
                   -Force:$true
```

### Step 1.4: Post-Promotion Validation

After server restarts:

1. Verify domain controller is functioning:
```powershell
# Test AD functionality
dcdiag.exe /v

# Test DNS functionality
dnscmd.exe /info
nslookup contoso.local

# List domain controllers
Get-ADDomainController -Discover
```

2. Verify Active Directory Users and Computers:
```powershell
# Open Active Directory Users & Computers (GUI)
dsa.msc

# Or use PowerShell to list domain info
Get-ADDomain -Identity "contoso.local"
```

3. Create test organizational unit:
```powershell
# Create OU structure
New-ADOrganizationalUnit -Name "Users" -Path "dc=contoso,dc=local"
New-ADOrganizationalUnit -Name "Computers" -Path "dc=contoso,dc=local"
New-ADOrganizationalUnit -Name "Servers" -Path "dc=contoso,dc=local"
New-ADOrganizationalUnit -Name "Groups" -Path "dc=contoso,dc=local"

# Verify structure
Get-ADOrganizationalUnit -Filter 'DisplayName -like "*"'
```

---

## Task 2: Deploy Azure AD Connect

Azure AD Connect is the synchronization bridge between on-premises AD and Azure Entra ID.

### Step 2.1: Download and Install Azure AD Connect

1. Download from Microsoft:
   - Navigate to https://www.microsoft.com/download/details.aspx?id=47594
   - Download "AzureADConnect.msi"

2. Run installer on domain controller or dedicated server:
   - Right-click **AzureADConnect.msi** → **Run as administrator**
   - Accept license terms
   - Click **Continue**

3. Configure installation:
   - **Express Settings** (recommended for first installation):
     - Automatic configuration
     - Password hash sync with MFA support
     - Enables automatic upgrade
   - **Custom Settings** (if specific configuration needed)

### Step 2.2: Configure Azure AD Connect Sync

1. In Azure AD Connect setup wizard:
   - **Connect to Azure AD**: Provide global admin credentials (MFA may be required)
   - **Connect to AD DS**: Provide on-premises admin credentials
   - **Azure AD Sign-In Configuration**: 
     - Select sign-in method: "Password Hash Synchronization" (recommended for hybrid)
     - Enable single sign-on (SSO)

2. **Optional Features**:
   - [x] Exchange Hybrid Deployment (if applicable)
   - [x] Password sync (enables cloud authentication if on-prem unavailable)
   - [x] Prevent accidental deletes (safety measure)

3. **Filtering**:
   - By default, sync all users and computers
   - Can filter by OU if only specific departments needed

4. Review and apply configuration

### Step 2.3: Configure Sync Rules

After initial sync, confirm or customize sync rules:

1. Open **Synchronization Service Manager**:
```powershell
miisclient.exe
```

2. In Synchronization Service Manager:
   - Go to **Connectors**
   - Verify both connectors present:
     - "contoso.local" (on-premises AD)
     - "organization.onmicrosoft.com" (Azure AD)
   - Both should show status "Ready"

3. Confirm sync rules:
   - Go to **Metaverse Designer**
   - Verify user objects flowing from AD to Azure AD

### Step 2.4: Test Synchronization

1. Create test user in on-premises AD:
```powershell
# Create test user in on-premises AD
New-ADUser -Name "Test User" `
           -GivenName "Test" `
           -Surname "User" `
           -UserPrincipalName "testuser@contoso.local" `
           -SamAccountName "testuser" `
           -AccountPassword (ConvertTo-SecureString "TempPassword123!@#" -AsPlainText -Force) `
           -Enabled $true `
           -Path "cn=Users,dc=contoso,dc=local"
```

2. Trigger manual sync:
```powershell
# Initiate synchronization
Start-ADSyncSyncCycle -PolicyType Delta

# For full sync:
Start-ADSyncSyncCycle -PolicyType Initial
```

3. Wait 2-3 minutes for sync to complete

4. Verify user appeared in Azure AD:
```powershell
# Connect to Azure AD
Connect-AzureAD

# Search for synced user
Get-AzureADUser -Filter "userPrincipalName eq 'testuser@organization.onmicrosoft.com'"
```

5. Expected output shows user synced to cloud

---

## Task 3: Configure Password Hash Synchronization

### Step 3.1: Understand Password Hash Sync

**Password Hash Synchronization (PHS):**
- Hashes of on-premises passwords sync to Azure (NOT passwords themselves)
- Enables authentication to cloud services if on-premises down
- Works with MFA
- Enables Conditional Access
- Does NOT require direct internet connectivity for on-premises users

**Alternative: Pass-Through Authentication (PTA):**
- Validates password against on-premises AD
- No password hashes in cloud
- More complex infrastructure
- Requires on-premises agent on multiple servers

For this implementation, **Password Hash Sync is recommended**.

### Step 3.2: Verify PHS Configuration

1. In Azure AD Connect:
   - Go to **Configure Synchronization Options**
   - Verify **Password Hash Synchronization** is enabled
   - Save configuration

2. Confirm password sync:
```powershell
# In PowerShell on Azure AD Connect server
Import-Module ADSync

# Check if password sync is enabled
Get-ADSyncAADPasswordSyncConfiguration

# Expected: PasswordSyncEnabled = $true
```

### Step 3.3: Test Password Hash Sync

1. Change password for test user on-premises:
```powershell
# Change password for test user
Set-ADAccountPassword -Identity "testuser" `
                      -NewPassword (ConvertTo-SecureString "NewPassword456!@#" -AsPlainText -Force) `
                      -Confirm:$false
```

2. Trigger sync cycle
3. Wait 2-3 minutes
4. Test cloud authentication:
   - Go to https://login.microsoftonline.com
   - Sign in as testuser@organization.onmicrosoft.com
   - Use new password (from on-premises)
   - Should authenticate successfully

---

## Task 4: Configure Single Sign-On (SSO)

### Step 4.1: Enable Seamless SSO

Seamless SSO automatically signs users into cloud services when on domain-joined devices:

1. In Azure AD Connect:
   - Go to **User Sign-In** page
   - Enable **Single Sign-On**
   - Provide domain admin credentials
   - Click **Enable**

2. Sync completes automatically

3. Test SSO:
   - From domain-joined computer, open PowerShell:
```powershell
# Test Kerberos ticket availability
klist
# Should show TGT and service tickets

# Access cloud resource
Start-Process "https://portal.office.com"
# Should authenticate automatically without prompting for password
```

---

## Task 5: Create Organizational Unit Structure

Proper OU structure enables group policy application and delegation:

```
contoso.local
├── Users
│   ├── IT Department
│   ├── HR Department
│   ├── Finance Department
│   └── Operations Department
├── Computers
│   ├── Workstations
│   ├── Servers
│   └── Virtual Machines
├── Groups
│   ├── Distribution Groups
│   ├── Security Groups
│   └── Delegated Groups
└── Service Accounts
    └── Application Service Accounts
```

**Create OU structure:**

```powershell
# Create parent OUs
$domain = "dc=contoso,dc=local"
New-ADOrganizationalUnit -Name "Users" -Path $domain -Description "User accounts"
New-ADOrganizationalUnit -Name "Computers" -Path $domain -Description "Computer objects"
New-ADOrganizationalUnit -Name "Groups" -Path $domain -Description "Group objects"
New-ADOrganizationalUnit -Name "Service Accounts" -Path $domain -Description "Service account objects"

# Create department-specific OUs
$pathUsers = "ou=Users,$domain"
New-ADOrganizationalUnit -Name "IT Department" -Path $pathUsers
New-ADOrganizationalUnit -Name "HR Department" -Path $pathUsers
New-ADOrganizationalUnit -Name "Finance Department" -Path $pathUsers
New-ADOrganizationalUnit -Name "Operations Department" -Path $pathUsers
```

---

## Task 6: Validate Hybrid Identity Configuration

### Validation Checklist

- [ ] Domain controller operational (dcdiag shows no errors)
- [ ] DNS resolving correctly (nslookup contoso.local)
- [ ] Test user created in on-premises AD
- [ ] Azure AD Connect installed and syncing
- [ ] Test user synced to Azure AD (verified in Azure portal)
- [ ] Password sync working (test user password allows cloud login)
- [ ] SSO functional (automatic authentication from domain device)
- [ ] OU structure created
- [ ] Secure Score improved with hybrid identity

### Test Scenarios

**Scenario 1: User Authentication to Microsoft 365**
1. From domain-joined device, open https://outlook.office.com
2. Sign in with UPN (user@organization.onmicrosoft.com)
3. Expected: Auto-authenticated via SSO, no password prompt
4. Verify: Outlook loads and email accessible

**Scenario 2: Azure Portal Access**
1. From domain-joined device, open https://portal.azure.com
2. Sign in with UPN
3. Expected: Auto-authenticated, portal loads
4. Verify: Can navigate resources and dashboards

**Scenario 3: Off-Network Authentication**
1. From non-domain-joined device (internet cafe, personal laptop)
2. Open https://portal.office.com
3. Sign in with UPN and password
4. Expected: Prompts for password, MFA if configured
5. Verify: Authenticates successfully

---

## Troubleshooting Common Issues

**Issue**: Users not syncing to Azure AD
- **Cause**: Azure AD Connect not running, synchronization disabled
- **Solution**: Check Azure AD Connect service status, trigger manual sync, verify credentials

**Issue**: Password hashes not syncing
- **Cause**: PHS not enabled, synchronization filter excluding users
- **Solution**: Verify PHS enabled in configuration, check sync rules

**Issue**: SSO not working even though PHS configured
- **Cause**: Group Policy not applied, Kerberos not configured
- **Solution**: Verify group policy deployed, check Kerberos TGT available (klist)

**Issue**: Sync conflicts when same user modified both on-prem and cloud
- **Cause**: Conflicting changes in multi-master replication
- **Solution**: Use cloud as source of truth, re-sync user from on-prem

---

## Next Steps

1. Plan secondary domain controller deployment (Phase 6)
2. Configure on-prem to Azure VPN (Phase 7)
3. Migrate legacy applications to cloud (Phase 8)
4. Begin on-premises user migration to cloud groups

---

*Phase 5 Completion Date: ___________*
*Document Version: 1.0*
*Last Updated: March 2, 2026*
