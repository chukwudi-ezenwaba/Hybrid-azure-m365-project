# Phase 4: Monitoring, Operations and Reporting

## Phase Overview

This phase establishes operational visibility through audit logging, alert policies, and comprehensive reporting enabling proactive threat detection and compliance verification.

**Duration**: 2 weeks  
**Key Objectives**: Audit log configuration, alert policies, reporting dashboards, Service Health monitoring

---

## Task 1: Configure Unified Audit Logging

Enable centralized audit logs capturing all M365 activities:

1. Go to **MSC Compliance** (https://compliance.microsoft.com)
2. **Audit** → Verify "Search the audit log" is enabled
3. Set retention:
   - **Audit log retention period**: 1 year (default 90 days)
   - Organizations with E5: Can extend to 10 years

**Validation**: Search audit logs for recent user activities (login, file access, etc.)

---

## Task 2: Create Alert Policies

### Alert Policy 1: Mass File Deletion

1. Go to **Alert Policies**
2. Click **New alert policy**
3. Configure:
   - **Name**: "Mass File Deletion Alert"
   - **Activity**: FileDeleted
   - **Threshold**: 20+ files deleted in 5 minutes
   - **Severity**: High
   - **Notification**: Email security team
   - **Status**: On

### Alert Policy 2: Multiple Failed Login Attempts

1. Create policy:
   - **Name**: "Multiple Failed Sign-In Attempts"
   - **Activity**: UserLoggedIn with failure
   - **Threshold**: 10+ failures in 5 minutes
   - **Severity**: High
   - **Escalation**: Immediate notification

### Alert Policy 3: DLP Violations

1. Create policy:
   - **Name**: "DLP Policy Violation Alert"
   - **Activity**: DLP violation detected
   - **Threshold**: Any violation
   - **Severity**: Medium
   - **Notification**: DLP administrators + security team

**Validation**: Trigger test alert to verify notification delivery

---

## Task 3: Create Reporting Dashboards

### Dashboard 1: User Activity Report

1. Go **Reports** → **User activity** in Microsoft 365 Admin Center
2. Configure:
   - **Metric**: Mail activity, SharePoint activity, Teams usage
   - **Date range**: Last 30 days
   - Export to Excel for executive reporting

### Dashboard 2: Security &amp; Compliance Report

1. Go **Reports** → **Security and Compliance status**
2. View:
   - Secure Score (target: 70%+ after all phases)
   - Policy compliance rates
   - Threat trends
   - DLP violations by department

### Dashboard 3: Device Compliance Dashboard

After Phase 11 (Intune):
1. Navigate to Intune dashboard
2. View:
   - Total enrolled devices
   - Compliance rate by platform (Windows, Mac, iOS, Android)
   - Non-compliance reasons (most common top 5)
   - Trend over time (increasing compliance = success)

---

## Task 4: Service Health Monitoring

### Configure Service Health Alerts

1. Go **Health** → **Service Health**
2. Click **Preferences**
3. Enable notifications for:
   - Identity (Azure AD, Azure AD Connect)
   - Exchange Online
   - SharePoint Online
   - Teams
   - Intune
4. Set email recipients (IT operations team)

**Validation**: Verify notifications received for platform incidents

---

## Task 5: Audit Log Searches

Perform investigative searches on audit logs:

**Search 1: User Activity by Department**
```
Activity: All
Users: All Finance department users
Date range: Last 30 days
Results: Shows all F finance activities (logins, file access, email sent)
```

**Search 2: Sensitive File Access**
```
Activity: FileAccessed
Results include files with names containing: SSN, Credit Card, Confidential
Users and times of access tracked
```

**Search 3: Administrator Changes**
```
Activity: Set-Mailbox, Set-User, Update-DLP
Results: Administrative modifications tracked for compliance/auditing
```

---

## Validation Checklist

- [ ] Audit logging enabled for all services
- [ ] Audit log retention set to 1+ years
- [ ] Alert policies created (mass delete, failed logins, DLP)
- [ ] Alerts tested and notifications verified
- [ ] Reporting dashboards configured
- [ ] Service Health monitoring active
- [ ] Executive reports exported monthly
- [ ] Audit log search queries documented

---

*Phase 4 Completion Date: ___________*
*Document Version: 1.0*
