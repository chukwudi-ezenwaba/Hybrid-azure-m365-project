# Phase 11: Endpoint Management and Security Baselines

## Phase Overview

This final implementation phase deploys Microsoft Intune for comprehensive endpoint management, enforcing device compliance policies, deploying security baselines, and integrating Conditional Access to block non-compliant devices.

**Duration**: 2 weeks  
**Key Objectives**: Intune enrollment, compliance policies, security baselines, Conditional Access integration

---

## Task 1: Enable Microsoft Intune

### Step 1.1: Activate Intune in Tenant

1. Navigate to https://admin.microsoft.com
2. Go to **Device Management** → **Intune**
3. If Intune not activated, click **Activate** (requires E3 or higher license)
4. Wait for activation to complete (~5 minutes)

**PowerShell Activation:**
```powershell
# Connect to Microsoft Graph
Connect-MgGraph -Scopes "DeviceManagementManagedDevices.ReadWrite.All"

# Verify Intune available
Get-MgDeviceManagementDeviceConfiguration
```

### Step 1.2: Configure Intune Tenant Settings

1. Navigate to https://intune.microsoft.com (Intune admin center)
2. Go to **Tenant Administration** → **Tenant properties**
3. Configure:
   - **Tenant display name**: "Contoso Corporation"
   - **MDM authority**: Microsoft Intune (if not already set)
   - **Mobile threat defense connector**: Microsoft Defender for Endpoint
4. Scroll to **Endpoint protection**
   - Enable **Enhanced jailbreak detection**
   - Enable **Secure boot requirement**
5. Save changes

---

## Task 2: Create Device Compliance Policies

Compliance policies define minimum security requirements devices must meet:

### Step 2.1: Create Windows Compliance Policy

1. In Intune admin center, go to **Device compliance** → **Create policy**
2. Select **Platform**: Windows 10 and later
3. Configure policy:
   - **Name**: "Device Compliance - Windows Managed"
   - **Description**: "Minimum security requirements for organizational devices"

4. Configure compliance settings:

**Device Health:**
- Require Secure Boot: Yes
- Require code integrity: Yes
- Antivirus engine required: Yes
- Antimalware signatures up-to-date: Yes
- Real-time protection required: Yes

**Device Properties:**
- Minimum OS version: 21H2 (Windows 10 latest version)
- Maximum OS version: (leave blank - allows latest)
- Valid certificate issuer: Windows Defender

**System Security:**
- Firewall required: Yes (Windows Defender Firewall)
- UAC: Require/Enable
- Require encryption of removable storage: Yes
- Home page protection enabled: Yes

**Password:**
- Require password: Yes
- Minimum password length: 12 characters
- Password expiration (days): 90
- Characters required: Uppercase, lowercase, numbers, special characters
- Block compromised passwords: Yes

5. Next, configure **Actions for non-compliance**:
   - **Mark device as non-compliant**: Immediately
   - **Email notification**: Send to security team
   - **Remote lock**: After 7 days non-compliance
   - **Retire device**: After 30 days non-compliance

6. Scope assignments:
   - **Include**: All users
   - **Exclude**: None (or VIPs if needed)

7. Click **Create**

**PowerShell Compliance Policy:**
```powershell
# Create Windows compliance policy
$compliancePolicy = @{
    DisplayName = "Device Compliance - Windows Managed"
    Description = "Minimum security requirements"
    Platform = "windows10AndLater"
    OsMinimumVersion = "21H2"
    PasswordRequired = $true
    PasswordMinLength = 12
    PasswordExpirationDays = 90
    SecureBootRequired = $true
    AntivirusEngineRequired = $true
    RtpEnabled = $true
    FirewallRequired = $true
}

# Create policy (use Graph API or PowerShell module)
New-MgDeviceManagementDeviceCompliancePolicy -BodyParameter $compliancePolicy
```

### Step 2.2: Create macOS Compliance Policy

1. Create policy for macOS devices
2. Similar settings:
   - Firewall required: Yes
   - Gatekeeper enabled: Yes
   - System Integrity Protection enabled: Yes
   - Password required: Yes, 12+ characters
   - OS minimum version: macOS 12 (Monterey)

### Step 2.3: Create iOS/Android Mobile Device Policy

1. For BYOD (Bring Your Own Device) scenarios
2. Less stringent than managed Windows:
   - Firewall: N/A (mobile firewalls limited)
   - Password: Required, 6+ characters (longer on corporate devices)
   - Encryption: Required
   - App Protection policies: Required (detect jailbroken/rooted devices)

---

## Task 3: Deploy Security Baselines

Security baselines are pre-configured settings following CIS/Microsoft recommendations:

### Step 3.1: Create Device Configuration Profile

1. In Intune, go to **Configuration Devices** → **Create profile**
2. Select **Platform**: Windows 10 and later
3. Select **Profile type**: **Templates** → search "Security baseline"
4. Select **Microsoft Defender for Endpoint baseline** or **Windows 10/11 security baseline**
5. Configure:
   - **Name**: "Windows Security Baseline - Standard"
   - **Description**: "CIS benchmark hardening"
6. Review recommended settings (pre-populated based on template):
   - Account Policies
   - User Rights Assignments
   - Security Options
   - Advanced Audit Policy
   - System Services
   - Registry Settings
7. Click through settings, adjust if needed (most defaults recommended)
8. Scope: Assign to all users
9. Click **Create**

**Key Settings in Baseline:**
```
Windows Firewall Configuration:
- Enable Windows Defender Firewall
- Drop unsolicited inbound connections
- Enable logging for dropped packets

Local Policies:
- Require password complexity
- Minimum password length: 14 characters
- Account lockout after 5 failed attempts
- UAC prompt for elevated operations

Advanced Audit Policy:
- Audit process creation (tracks suspicious processes)
- Audit sensitive privilege use
- Audit account logon events
```

### Step 3.2: Deploy to Pilot Group (Testing)

Before org-wide deployment, test with pilot group:

1. Create pilot user group: "Pilot Device Users" (5-10 users)
2. Assign profile to pilot group only
3. Monitor for 2 weeks:
   - Check device compliance status
   - Monitor for support requests
   - Review for false positives
4. If successful, expand to all users
5. If issues, refine settings and retest

**Validation:**
- Devices report compliance status
- Non-compliant devices identified and remediated
- No widespread support disruption

---

## Task 4: Configure Conditional Access with Device Compliance

Conditional Access blocks non-compliant devices from accessing corporate resources:

### Step 4.1: Create Conditional Access Policy

1. Navigate to Azure AD → **Conditional Access**
2. Click **New policy**
3. Configure:
   - **Name**: "Block Non-Compliant Devices"
   - **Conditions**:
     - Users: All users (or specific groups)
     - Cloud apps: Microsoft 365 services (Office, Teams, SharePoint)
     - Device platforms: All
     - Device compliance: Mark as required (device must be compliant)
   - **Access Controls**:
     - **Grant**: Require device to be marked as compliant
     - **Block access**: If not compliant
   - **Enable policy**: Report-only mode first (2 weeks)
4. Transition to enforcement after monitoring

### Step 4.2: Test Conditional Access

1. From compliant device:
   - User should access resources without issue
   
2. From non-compliant device (not enrolled in Intune):
   - Access blocked with message: "Your device doesn't meet your organization's security policies"
   - User prompted to enroll in Intune/apply baseline

3. From enrolled but non-compliant device:
   - Same blocking behavior
   - Suggest remediation steps (update OS, enable encryption, etc.)

**PowerShell Conditional Access:**
```powershell
# Create conditional access policy
$policy = New-MgIdentityConditionalAccessPolicy -DisplayName "Block Non-Compliant Devices" `
                                                -State "enabledForReportingButNotEnforced" `
                                                -Conditions @{
                                                    Applications = @{ IncludeApplications = "Office365" }
                                                    Devices = @{ IncludeDeviceStates = "Compliant" }
                                                    Users = @{ IncludeUsers = "All" }
                                                } `
                                                -GrantControls @{
                                                    Operator = "OR"
                                                    BuiltInControls = @("compliantDevice")
                                                }
```

---

## Task 5: Enroll Devices in Intune

### Step 5.1: Automatic Enrollment (Recommended)

1. Go to **Azure AD** → **Devices** → **Device settings**
2. Configure:
   - **Users may join devices to Azure AD**: All users
   - **Additional local administrators on Azure AD joined devices**: None (restrict admin scope)
   - **User may register personal devices**: All (if BYOD enabled)

3. Enable automatic Intune enrollment:
   - Go to **Device Enrollment** → **Enrollment Restrictions**
   - Set "MDM User scope": All users
   - Devices automatically enroll when users sign in to Windows using work account

### Step 5.2: Manual Device Enrollment

For devices not auto-enrolling:

**Windows 10/11 Enrollment:**
1. Open **Settings** → **Accounts** → **Access work or school**
2. Click **Connect**
3. Enter work email (user@organization.onmicrosoft.com)
4. MFA challenge
5. Device joins Azure AD and enrolls in Intune
6. Compliance policies download and apply
7. Device restarts if updates needed

**PowerShell Enrollment Check:**
```powershell
# Check device enrollment status
Get-MgDeviceManagementManagedDevice | Select-Object DeviceName, WindowsProductName, ComplianceState
```

### Step 5.3: Monitor Enrollment

1. In Intune admin center, go to **Devices** → **All devices**
2. View dashboard:
   - Total enrolled: 15+ devices expected
   - Compliance rate: 80%+ target (100% after all devices update)
   - Non-compliant reasons: Update OS, enable encryption, update antivirus
3. For each device showing non-compliant:
   - Review reasons
   - Send user guidance for remediation
   - Schedule OS updates during maintenance window

---

## Task 6: Mobile Device Management (Optional BYOD)

If enabling BYOD (Bring Your Own Device):

### Step 6.1: Create iOS Enrollment Profile

1. Go to **Device Enrollment** → **iOS/iPadOS enrollment**
2. Configure Apple enrollment:
   - Requires Apple Business Manager (ABM) account
   - Creates DEP enrollment profile
   - Devices auto-enroll when users power on

3. Create compliance policy for iOS:
   - Passcode required: Yes
   - Minimum passcode length: 6
   - Encryption: Yes
   - Maximum OS version: Allow latest
   - Blocks jailbroken devices

### Step 6.2: Create Android Enrollment Profile

1. Go to **Device Enrollment** → **Android enrollment**
2. Choose enrollment method:
   - "Android device administrator" (older method)
   - "Android Enterprise work profile" (recommended)
3. Create compliance policy for Android:
   - Screen lock required: Yes
   - Require encryption: Yes
   - Blocks rooted devices

---

## Task 7: Monitoring and Reporting

### Step 7.1: Create Compliance Report

1. In Intune, go to **Reports** → **Device compliance**
2. View:
   - Compliance status by platform (Windows, macOS, iOS, Android)
   - Non-compliance reasons
   - Trends over time (are more devices becoming compliant?)
3. Export report for executive dashboard

### Step 7.2: Monitor Alerts

1. Go to **Alerts**
2. Create alert for:
   - Devices with failed compliance
   - No enrollment activity in 7 days
   - Multiple policy violations
3. Alert actions: Notify security team

### Step 7.3: Device Health Dashboard

1. Go to **Reports** → **Device enrollment**
2. Monitor:
   - Enrollment success rate
   - Time to enrollment (should be <1 hour)
   - Enrollment failures (troubleshoot as needed)

---

## Validation Checklist

- [ ] Intune activated and tenant configured
- [ ] Windows compliance policy created and assigned
- [ ] macOS compliance policy created and assigned
- [ ] Mobile device policies created (if BYOD enabled)
- [ ] Security baseline deployed to pilot group (2 weeks observation)
- [ ] Expanded baseline to all users
- [ ] Conditional Access policy in report-only mode (2 weeks)
- [ ] Transitioned Conditional Access to enforcement
- [ ] 15+ devices enrolled in Intune
- [ ] 80%+ devices in compliance state
- [ ] Monitoring dashboards and alerts configured
- [ ] Non-compliant devices identified and remediation guidance provided

---

## Common Issues & Troubleshooting

**Issue**: Devices stuck in non-compliant state after OS update
- **Cause**: Baseline detection lag (device syncs baseline after reboot)
- **Solution**: Manual device sync (Settings → Accounts → Access work or school → Info → Sync)

**Issue**: Users report enrollment taking too long
- **Cause**: Network bandwidth, antivirus scanning during setup
- **Solution**: During off-hours enrollment, add enrollment priority for executives

**Issue**: Conditional Access blocking legitimate users
- **Cause**: Device not properly marked compliant, sync delay
- **Solution**: Manual Intune sync, verify device meets all requirements

**Issue**: Apple iOS devices not enrolling via DEP
- **Cause**: ABM account not linked, enrollment profile misconfigured
- **Solution**: Verify ABM account, recreate enrollment profile

---

## Best Practices

- **Stagger Baseline Deployment**: Don't deploy to all devices simultaneously; use staged rollout (pilot → departments → organization)
- **Monitor Compliance Trend**: Track if device compliance increasing (good) or decreasing (concerning)
- **Provide User Guidance**: When devices non-compliant, send clear remediation instructions
- **Regular Policy Reviews**: Quarterly review compliance policies; adjust if too restrictive
- **Separate Corporate vs BYOD Policies**: Corporate devices can require stricter baseline vs BYOD

---

## Next Steps

1. All 11 phases complete
2. Transition to ongoing operational management:
   - Monthly compliance reporting
   - Quarterly access reviews
   - Semi-annual security assessments
   - Regular user feedback incorporation

---

*Phase 11 Completion Date: ___________*
*Project Completion Date: ___________*
*Document Version: 1.0*
*Last Updated: March 2, 2026*
