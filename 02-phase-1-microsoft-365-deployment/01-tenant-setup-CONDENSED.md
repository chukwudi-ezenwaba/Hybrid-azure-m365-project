# Phase 1: Microsoft 365 Tenant Setup

**Duration**: Weeks 1-2 | **Key Result**: M365 tenant with users, licenses, security configured | **Depends On**: Nothing

## Quick Summary

Set up M365 tenant → Create users → Assign licenses → Configure security → Enable Exchange

## What Gets Done This Phase

1. **Tenant Creation** (Day 1-2)
   - Reserve domain (organization.com or .onmicrosoft.com)
   - Configure Security Score baseline
   - Set password policies, MFA requirements
   - Assign Global Admin accounts

2. **User & License Deployment** (Week 1)
   - Bulk create users from CSV (Script: 02-create-users.ps1)
   - Assign E3/E5 licenses (Script: 03-license-assignment.ps1)  
   - Verify licenses active (portal: M365 admin)

3. **Exchange Setup** (Week 1)
   - Configure mail flow rules
   - Setup shared mailboxes (support@, noreply@)
   - Configure transport rules, compliance

4. **SharePoint & OneDrive** (Week 1-2)
   - Create team sites + communication sites
   - Setup default document libraries
   - Configure sharing permissions

5. **Security Baseline** (Week 1-2)
   - Enable MFA for Admin accounts
   - Configure Safe Links, Safe Attachments
   - Setup DLP policies (draft/preview)
   - Enable audit logging

## Success Indicators

- ✓ Tenant accessible, users login with SSO
- ✓ E3/E5 licenses assigned, functional
- ✓ Email routing working, shared mailboxes created
- ✓ SharePoint sites functional
- ✓ MFA working for admins
- ✓ Defender baseline active

## Quick Checklist

- [ ] Tenant created + domain verified
- [ ] M365 admin accounts secured with MFA
- [ ] Users created (use script 02-create-users.ps1)
- [ ] Licenses assigned (use script 03-license-assignment.ps1)
- [ ] Exchange configured + tested
- [ ] SharePoint sites created + tested
- [ ] Basic security: MFA admin, Safe Links/Attachments
- [ ] Audit logging enabled

## Related Automation Scripts

- `02-create-users.ps1` → Create bulk users from CSV
- `03-license-assignment.ps1` → Assign licenses to users
- `04-mailbox-setup.ps1` → Configure shared mailboxes
- `08-enable-mfa.ps1` → Enable MFA org-wide

## Outputs from This Phase

- Functional M365 tenant
- All users with cloud identities
- E3/E5 licenses deployed
- Email working
- Basic security in place

## Next Phase

→ Phase 2 (Security): Harden policies, enable advanced threat protection, DLP rules
