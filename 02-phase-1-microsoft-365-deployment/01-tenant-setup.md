# Phase 1.1: Microsoft 365 Tenant Setup

**Duration**: Days 1-5 | **Key Result**: Functional M365 tenant with security baseline

## Phase Overview

| Aspect | Details |
|--------|---------|
| What's Done | M365 tenant created, users provisioned, licenses assigned, security policies enabled |
| Duration | Days 1-5 of Phase 1 |
| Success | Users can login to M365, SSO works, licenses active |
| Dependencies | None (Phase 1 is first) |

## Execution Steps

### Day 1: Tenant Provisioning

1. Create M365 tenant (Microsoft admin portal)
2. Add custom domain (or use .onmicrosoft.com)
3. Verify domain ownership
4. Create Global Admin accounts (min 2 for redundancy)
5. Enable MFA on Global Admin immediately

### Day 2-3: User Creation

1. Prepare users CSV (see Phase 1 > User CSV spec)
2. Run `02-create-users.ps1` (in automation/powershell/)
3. Verify all users created in Azure AD
4. Send temporary password to department heads
5. Have users update password on first login

### Day 3-4: License Assignment

1. Prepare licenses CSV (E3 vs E5 by department)
2. Run `03-license-assignment.ps1` with --preview first
3. Verify licenses show in user profiles
4. Update to --apply mode
5. Confirm all users have licenses assigned

### Day 5: Security Baseline

1. Enable MFA for all admin accounts (use `08-enable-mfa.ps1`)
2. Configure password policy: min 14 chars
3. Enable Safe Links for email
4. Enable Safe Attachments for email
5. Enable audit logging

## Success Checklist

- [ ] M365 tenant created, custom domain verified
- [ ] Global Admin accounts secured with MFA
- [ ] All users created (CSV processed via script)
- [ ] All users have E3 or E5 licenses
- [ ] Admin MFA working, tested
- [ ] Email works for sample user
- [ ] Security Score baseline > 50%

## Related Scripts

| Script | Purpose |
|--------|---------|
| `02-create-users.ps1` | Bulk create users from CSV |
| `03-license-assignment.ps1` | Assign E3/E5 licenses |
| `08-enable-mfa.ps1` | Enable MFA org-wide |

## Input CSVs Required

1. **users.csv**: DisplayName, UserPrincipalName, Department
2. **licenses.csv**: UserPrincipalName, LicenseType (E3/E5)

## Outputs

- Functional M365 tenant
- All users with cloud accounts
- All users with licenses
- Admin accounts MFA-protected
- Basic security enabled

## Next: Phase 1.2

→ Proceed to **Phase 1.2: Exchange & SharePoint Setup**
