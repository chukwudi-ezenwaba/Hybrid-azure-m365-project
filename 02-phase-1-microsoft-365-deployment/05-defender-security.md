# Phase 1.5: Microsoft Defender & Security Configuration

**Duration**: Day 5 + during Phase 2 hardening | **Key Result**: Basic security enabled, foundation for Phase 2

## Security Policies This Phase

| Policy | Status | Scope |
|--------|--------|-------|
| **MFA (Admin)** | Enabled immediately | Global Admins, App Admins |
| **Safe Links** | Enabled in preview | Email, Teams |
| **Safe Attachments** | Enabled in preview | Email |
| **DLP Rules** | Draft only | Not blocking yet |
| **Audit Logging** | Enabled | All mailboxes |
| **Authentication Rules** | Basic | Legacy auth disabled |

## Execution Steps

### 1. Admin MFA (Day 5)

Run script:
```powershell
./08-enable-mfa.ps1 -scope "admin"
```

Test: Admin logins require Authenticator app

### 2. Safe Links & Attachments (Day 5)

1. Go to Microsoft 365 Defender admin
2. Enable Safe Links globally (preview mode - log but don't block)
3. Enable Safe Attachments globally (preview mode)
4. Setup policies: Internal + external

### 3. DLP Policies (Day 5 - preview only)

1. Create policies for sensitive data (PII, PCI, passwords)
2. Set to audit-only mode (Phase 2 will enforce)
3. Include templates: Financial, Health, Legal

### 4. Audit Logging (Day 5)

```powershell
Set-AdminAuditLogConfig -UnifiedAuditLogSuspended $false
```

Enable unified audit log for all activity

### 5. Legacy Auth Block (Day 5)

1. Create Conditional Access policy
2. Block legacy auth methods
3. Exclude admin emergency accounts (2 accounts only)

## Success Checklist

- [ ] Admin MFA working, tested
- [ ] Safe Links enabled in preview mode
- [ ] Safe Attachments enabled in preview mode
- [ ] DLP policies created (audit-only)
- [ ] Audit logging enabled + verified
- [ ] Legacy auth blocked (except emergency)

## Monitoring

- Check dashboard daily for alerts
- Review DLP hits (audit mode) - should have few false positives
- Monitor admin login attempts

## Outputs

- Basic security baseline
- Audit trail active
- MFA protecting admin accounts
- Foundation for Phase 2 hardening

## Next: Phase 1 Complete → Phase 2: Security Hardening

→ Move to **Phase 2: Advanced Security & Hardening**
