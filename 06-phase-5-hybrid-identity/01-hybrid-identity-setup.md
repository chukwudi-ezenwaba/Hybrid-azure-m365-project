# Phase 5: Hybrid Identity & Azure AD Connect

**Duration**: Weeks 9-10 | **Key Result**: On-premises AD synced with Entra ID, hybrid identity working

## Phase Overview

| Item | Details |
|------|---------|
| What | Deploy AAD Connect, sync on-prem AD to Entra ID |
| Duration | 2 weeks |
| Depends | Phase 1 (cloud users ready) |

## Architecture

On-Premises AD ←→ Azure AD Connect ←→ Entra ID ←→ M365

## Execution Steps

### Week 9: AAD Connect Setup
- Install Azure AD Connect on domain controller
- Configure sync (user + group sync)
- Configure password hash sync
- Run initial sync (all users)
- Verify user count matches

### Week 10: Hybrid Identity
- Enable writeback (if needed for on-prem)
- Configure alternate login ID (email as UPN)
- Setup password reset from cloud (SSPR)
- Test user SSO from on-prem workstations
- Configure conditional access for on-prem access

## Success Checklist

- [ ] AAD Connect installed + sync running
- [ ] All on-prem users synced to Entra ID
- [ ] Users can SSO to M365 from on-prem
- [ ] Password sync working
- [ ] Conditional access rules enforced

## Next: Phase 6

→ **Phase 6: High Availability & Redundancy**
