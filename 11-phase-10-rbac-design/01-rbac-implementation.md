# Phase 10: RBAC & Role-Based Access Management

**Duration**: Weeks 19-20 | **Key Result**: Roles defined, permissions enforced, audit ready

## Phase Overview

| Item | Details |
|------|---------|
| What | Implement role-based access across M365 + Azure |
| Duration | 2 weeks |
| Depends | Phase 1-9 (all components deployed) |

## Role Tiers

| Role | Permissions | Users |
|------|-------------|-------|
| Global Admin | All M365 + Azure | 2-3 IT staff |
| SharePoint Admin | Site + content management | 1-2 per dept |
| Teams Admin | Teams + channels | 1 per dept |
| User | Read/edit own content | All employees |
| Guest | Limited read access | External partners |

## Execution Steps

### Week 19: Design RBAC
- Document role matrix (department × function)
- Assign users to roles (PowerShell bulk)
- Test role permissions (sample user)

### Week 20: Audit & Compliance
- Generate role assignments report
- Verify no excess permissions
- Setup quarterly access reviews
- Document approval workflow

## Success Checklist

- [ ] All users assigned correct role
- [ ] No global admins except IT
- [ ] Permissions tested + enforced
- [ ] Access review process ready
- [ ] Audit trail showing permission checks

## Next: Phase 11

→ **Phase 11: Endpoint Management & Intune**
