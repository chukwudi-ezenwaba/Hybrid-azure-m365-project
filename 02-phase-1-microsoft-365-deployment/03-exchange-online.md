# Phase 1.3: Exchange Online & Mailbox Setup

**Duration**: Days 3-5 | **Key Result**: All users have working email, shared mailboxes configured

## Tasks This Phase

| Task | Duration | Outcome |
|------|----------|---------|
| Shared mailbox setup | 1 day | support@, noreply@, finance@ mailboxes created |
| Mail routing config | 1 day | External/internal mail routing rules active |
| Retention policies | 1 day | Email retention: 7yr for compliance, 30d for deleted items |
| Transport rules | 1 day | Rules for sensitive content, external recipients |

## Execution Steps

### 1. Shared Mailboxes (Day 4)

Run `04-mailbox-setup.ps1`:
```powershell
# Creates shared mailboxes
./04-mailbox-setup.ps1 -sharedMailboxes @('support','finance','noreply')
```

Add members to shared mailboxes:
- support@ → IT Support team
- finance@ → Finance team
- noreply@ → System admin only (send-only)

### 2. Mail Routing (Day 4)

1. Configure external relay (if needed for on-prem servers)
2. Set mail flow rules:
   - Route specific domains to external system
   - Setup connector for hybrid mail flow (if using Phase 5)

### 3. Retention Policies (Day 5)

1. Set default retention: 7 years (compliance requirement)
2. Deleted items: recover for 30 days
3. Litigation hold: Available for specific mailboxes

### 4. Transport Rules (Day 5)

1. Block external send of confidential docs (preview mode)
2. Add disclaimer to external emails
3. Route sensitive content through monitoring queue

## Success Checklist

- [ ] All users have working email (@domain.com)
- [ ] Shared mailboxes created (support@, finance@, noreply@)
- [ ] External email flows (test with external account)
- [ ] Internal email works
- [ ] Retention policy shows in admin portal
- [ ] Transport rules not blocking legitimate email

## Next: Phase 1.4

→ Proceed to **Phase 1.4: SharePoint & OneDrive Setup**
