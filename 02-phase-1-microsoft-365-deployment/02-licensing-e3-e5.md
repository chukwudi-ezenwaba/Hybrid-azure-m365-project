# Phase 1.2: Licensing Configuration (E3 vs E5)

**Duration**: Days 2-4 | **Key Result**: All users assigned correct license tier

## License Overview

| License | Users | Cost | Features |
|---------|-------|------|----------|
| **E3** | Standard users (office staff, general) | ~$20/user/mo | Email, Teams, SharePoint, OneDrive, basic security |
| **E5** | Admins + security-sensitive (finance, HR, execs) | ~$35/user/mo | E3 + advanced threat protection, Advanced Analytics |
| **Defender** | All | add-on | Advanced threat protection (can include in E5) |

## Assignment Strategy

- IT staff: E5
- Finance/HR: E5
- Sales/Marketing: E3
- General users: E3
- Executives: E5

## Execution

1. **Prepare CSV** (see Template below)
2. **Preview** → `.\03-license-assignment.ps1 -licensePath licenses.csv -preview`
3. **Verify** → Check output, adjust licenses if needed
4. **Apply** → `.\03-license-assignment.ps1 -licensePath licenses.csv -apply`
5. **Verify** → Check M365 admin portal for assigned licenses

## CSV Template (licenses.csv)

```
UserPrincipalName,LicenseType
user1@domain.com,E5
user2@domain.com,E3
user3@domain.com,E3
```

## Success Checklist

- [ ] All users have E3 or E5 assigned
- [ ] License types match business roles
- [ ] No unassigned users
- [ ] License consumption < budget

## Next: Phase 1.3

→ Proceed to **Phase 1.3: Exchange & Mailbox Setup**
