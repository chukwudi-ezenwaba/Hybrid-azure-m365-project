# Phase 4: Monitoring, Auditing & Compliance

**Duration**: Weeks 7-8 | **Key Result**: Monitoring active, dashboards created, alerts active

## Phase Overview

| Item | Details |
|------|---------|
| What | Setup monitoring, dashboards, alerts, compliance |
| Duration | 2 weeks |
| Depends | Phase 2-3 |

## Monitoring Components

1. **Azure Monitor** - M365 activity logging, suspicious patterns
2. **Security Dashboards** - Threats, compliance, DLP, access
3. **Alert Policies** - Large downloads, MFA failures, privilege escalation
4. **Reporting** - Daily, weekly, monthly compliance reports

## Execution Steps

### Week 7: Setup Monitoring  
- Enable audit logging globally
- Configure alert policies (use templates)
- Create Security Center dashboards
- Setup email alerts for security team

### Week 8: Reporting
- Run `05-generate-reports.ps1` (user activity, licenses, DLP)
- Configure daily automated delivery
- Test alerts with artificial triggers
- Validate false positive rate

## Alerts to Create

| Alert | Trigger |
|-------|---------|
| Large Download | >10GB in 1 hour |
| MFA Failures | >5 failed attempts in 1 hour |
| Privilege Escalation | User given admin role |
| External Sharing | Share with external > 10 users |

## Success Checklist

- [ ] Audit logging enabled
- [ ] Alert policies + tested
- [ ] Dashboards showing data
- [ ] Daily reports running
- [ ] Security team receiving alerts
- [ ] False positives < 5%

## Next: Phase 5

→ **Phase 5: Hybrid Identity & Azure AD Connect**
