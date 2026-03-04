# Phase 3: Microsoft Teams & Collaboration

**Duration**: Weeks 5-6 | **Key Result**: Teams deployed, governance enforced

## Phase Overview

| Item | Details |
|------|---------|
| What | Deploy Teams, create channels, enforce governance |
| Duration | 2 weeks |
| Depends | Phase 2 (security) |

## Governance Rules

| Item | Config |
|------|--------|
| Team Creation | Department heads only (via PowerShell approval) |
| Guest Access | Allowed, 30-day expiry |
| Channel Naming | [DEPT]-[PURPOSE] format |
| Retention | 1 year active, 7 years archived |
| External Share | SharePoint only, not Teams direct |

## Execution Steps

### Week 5: Create Teams & Channels
- Create 4+ teams (IT, Sales, Finance, HR)
- Create 5-7 channels per team (General, Announcements, Projects, Archive)
- Configure channel policies (no @channel/@all)
- Add members + guests

### Week 6: Governance Policies
- Configure Teams naming policy
- Setup message retention (1 year default)
- Configure guest access (30-day expiry)
- Setup moderation rules (keyword triggers)

## Automation
- Script: `07-create-groups.ps1` (creates Teams groups)

## Success Checklist

- [ ] 4+ teams functional
- [ ] Channel structure organized
- [ ] Naming policy enforced
- [ ] Governance policies active
- [ ] Guest access working + expiring

## Next: Phase 4

→ **Phase 4: Monitoring & Compliance**
