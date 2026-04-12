# Phase 1.5: Microsoft Defender for Office 365 & Security Baseline

**Depends on**: Phase 1.3 (Exchange Online active), Phase 1.2 (licences assigned)  
**Key Result**: Defender policies protecting email and Teams, audit logging active, legacy authentication blocked, and admin accounts protected by MFA — all before the tenant carries any real user data

---

## Why This Phase Comes First

The policies configured here are deliberately set to monitor-only mode. The goal is to observe what they would have blocked before enforcing anything, so that when Phase 2 switches them to enforcement mode there are no surprises. Running everything in audit mode for the first 7–14 days also populates the Defender dashboards with real data, which makes Phase 2 policy tuning much more accurate.

---

## Step 1: Enable Admin MFA

Admin accounts are the highest-value targets in any tenant. Enable MFA on all admin accounts before doing anything else in this phase.

```powershell
# Run the MFA enablement script for the admin scope
.\13-automation\powershell\08-enable-mfa.ps1 -Scope admin
```

After the script runs, verify by signing out of the admin account and signing back in. The authentication flow should prompt for the Microsoft Authenticator app or a security key. If it does not, go to https://entra.microsoft.com → **Users** → click the admin account → **Authentication methods** and confirm the method is registered.

If an admin account does not yet have the Authenticator app registered, they will be prompted to register it on their next sign-in. Do not skip this — any admin account without MFA is a single-password compromise away from a full tenant breach.

---

## Step 2: Configure Safe Links

Safe Links rewrites URLs in emails and Office documents so that every link is scanned at click-time against the Microsoft threat intelligence feed. This catches links that were safe when the email arrived but were later weaponised.

1. Go to https://security.microsoft.com → **Email & collaboration** → **Policies & rules** → **Threat policies** → **Safe Links**.
2. Click **+ Create** to create a new policy. Name it `Safe Links — All Users`.
3. On the **Users and domains** page, add `nig-e-mart.com` under **Domains** so the policy applies to everyone in the tenant.
4. On the **URL & click protection settings** page, configure:
   - **On: Safe Links checks a list of known, malicious links when users click links in email** → **On**
   - **Apply Safe Links to email messages sent within the organisation** → **On**
   - **Apply Safe Links to Microsoft Teams** → **On**
   - **Apply real-time URL scanning for suspicious links and links that point to files** → **On**
   - **Track user clicks** → **On** (this populates the click reports in the Defender portal)
   - **Do not let users click through to the original URL** → **Off** for now (switches to On in Phase 2)
5. Leave **Do not rewrite URLs** empty — do not add any exclusions at this stage.
6. Click through to review and **Submit**.

The policy is now active in monitor mode: it rewrites links and tracks clicks, but users can still proceed to blocked pages with a warning. Phase 2 will change the "do not let users click through" setting to On.

---

## Step 3: Configure Safe Attachments

Safe Attachments detonates email attachments in a sandboxed virtual machine before delivery. Malware-infected files never reach the user's inbox.

1. Still in https://security.microsoft.com → **Threat policies** → **Safe Attachments**.
2. Click **+ Create**. Name it `Safe Attachments — All Users`.
3. On the **Users and domains** page, add the `nig-e-mart.com` domain.
4. On the **Settings** page:
   - **Safe Attachments unknown malware response**: select **Monitor** — this delivers the email but logs the detonation result and generates an alert if malware is found. (Phase 2 changes this to **Block**.)
   - **Redirect messages with detected attachments**: check the box and enter `security@nig-e-mart.com` so a copy of any flagged message reaches the security team even in monitor mode.
   - **Enable Safe Attachments for SharePoint, OneDrive, and Microsoft Teams** → **On** — this scans files uploaded to SharePoint and OneDrive, not just email.
5. Click through and **Submit**.

---

## Step 4: Create DLP Policies in Audit Mode

Data Loss Prevention policies flag messages and documents that contain sensitive patterns — credit card numbers, Social Insurance Numbers, health information. Creating them now in audit mode lets you see how often the patterns fire before enforcement causes user disruption.

1. Go to https://compliance.microsoft.com → **Data loss prevention** → **Policies** → **+ Create policy**.
2. On the template page, select **Financial** → **Canada Financial Data**. Click **Next**.
3. Name the policy `DLP — Financial Data (Audit)`. Click **Next**.
4. On **Choose where to apply the policy**, select: **Exchange email**, **SharePoint sites**, **OneDrive accounts**, and **Teams chat and channel messages**. Click **Next**.
5. On **Define policy settings**, leave the default rules (they detect credit card numbers and bank account numbers). Click **Next**.
6. On **Protection actions**, set the mode to **Run the policy in simulation mode** (this is the audit/preview mode). Ensure **Show policy tips while in simulation mode** is checked so users can see when they are about to violate policy — this creates awareness without blocking.
7. Review and **Submit**.

Repeat this process to create a second policy using the **Privacy** → **Canada Personal Information Protection** template. Name it `DLP — PII (Audit)`.

After 7 days, review the simulation results under **Data loss prevention** → **Reports** → **DLP activity**. If false-positive rates are low, Phase 2 will switch both policies to enforcement mode.

---

## Step 5: Verify Audit Logging

Confirm the unified audit log is active. This was configured in Phase 4, but verify it here since Defender alert policies depend on it.

```powershell
Connect-IPPSSession -UserPrincipalName admin@nig-e-mart.com

# Confirm the audit log is not suspended
Get-AdminAuditLogConfig | Select-Object UnifiedAuditLogIngestionEnabled
# Expected output: UnifiedAuditLogIngestionEnabled : True

# If it shows False, enable it:
Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled $true
```

---

## Step 6: Block Legacy Authentication

Legacy authentication protocols (Basic Auth, IMAP, POP3, SMTP AUTH) do not support MFA, making any account that uses them vulnerable to password spray attacks. Block them via a Conditional Access policy.

1. Go to https://entra.microsoft.com → **Protection** → **Conditional Access** → **+ New policy**.
2. Name: `Block Legacy Authentication`.
3. **Assignments → Users**: Select **All users**.
4. **Assignments → Conditions → Client apps**: click **Configure → Yes**. Check all legacy auth options: **Exchange ActiveSync clients**, **Other clients**. Leave modern clients unchecked — those are not blocked.
5. **Access controls → Grant**: select **Block access**.
6. Before saving, ensure your break-glass admin account (configured in Phase 2) is excluded under **Assignments → Users → Exclude**. If you have not created a break-glass account yet, create one now (a cloud-only Global Admin with a 30-character random password stored offline) and add it to the exclusion.
7. Set the policy to **Report-only** for now. Click **Create**.

Leave this policy in **Report-only** mode for 3 days and check **Sign-ins** → **Report-only** in the Entra portal to confirm no legitimate modern-auth users are being caught. Switch to **On** after the 3-day review.

---

## Step 7: Review the Defender Secure Score

After all policies are configured, check the Defender Secure Score to confirm the baseline is improving:

1. Go to https://security.microsoft.com → **Secure Score**.
2. Note the current score out of 100%. With the Phase 1.5 policies in place you should be in the 45–55% range. Each subsequent phase will increase this.
3. Click **Recommended actions** and review the remaining items. Many of them are Phase 2 tasks (switching Safe Attachments to Block mode, enforcing DLP). Do not action them yet — they are intentionally deferred.
4. Record the current score for the baseline. You will compare against this in Phase 4 when monitoring is configured.

---

## Completion Checklist

- Admin MFA active on all Global Admin and Application Admin accounts — tested by signing in manually
- Safe Links policy applied to `nig-e-mart.com` domain covering email and Teams; user click tracking enabled
- Safe Attachments policy applied in Monitor mode; redirect copy sent to `security@nig-e-mart.com`
- Safe Attachments for SharePoint, OneDrive, and Teams enabled
- Two DLP policies created in simulation mode: Financial Data and PII
- Unified audit log confirmed enabled (`UnifiedAuditLogIngestionEnabled : True`)
- Legacy auth Conditional Access policy created and running in Report-only mode
- Secure Score baseline recorded

---

## Next Step

Proceed to [Phase 2 – Security & Compliance](../03-phase-2-security-compliance/01-security-compliance.md). Phase 2 will switch Safe Attachments to Block mode, enforce DLP policies, and expand Conditional Access coverage.

