# Phase 8: Workload Migration & File Services

**Duration**: Weeks 15-16 | **Key Result**: On-prem files migrated to SharePoint/OneDrive

## Phase Overview

| Item | Details |
|------|---------|
| What | Migrate file shares, mailboxes, content to M365 |
| Duration | 2 weeks (staggered) |
| Depends | Phase 5-7 (infrastructure ready) |

## Migration Components

1. **File Share Migration** → SharePoint/OneDrive
2. **Mailbox Migration** → Exchange Online (if hybrid)
3. **Archive Migration** → Compliance centers

## Execution Steps

### Week 15: Prepare Migration
- Inventory on-prem file shares
- Create migration batches (by department)
- Pre-stage data to Azure Blob storage
- Prepare user mailboxes

### Week 16: Execute Migration
- Migrate file shares (off-peak hours)
- Migrate mailboxes (rolling schedule)
- Validate migration success (checksums)
- Decommission local shares (soft-delete first)

## Success Checklist

- [ ] File migration successful (100% content copied)
- [ ] Users can access via SharePoint/OneDrive
- [ ] Mailbox migration complete
- [ ] No data loss reported
- [ ] Old shares retired (archived)

## Next: Phase 9

→ **Phase 9: File Services & Permissions**
