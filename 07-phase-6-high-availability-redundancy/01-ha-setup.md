# Phase 6: High Availability & Redundancy

**Duration**: Weeks 11-12 | **Key Result**: Redundancy configured, failover tested

## Phase Overview

| Item | Details |
|------|---------|
| What | Setup backup DC, AAD Connect HA, failover testing |
| Duration | 2 weeks |
| Depends | Phase 5 (hybrid identity) |

## HA Architecture

- **Primary DC** (on-prem): Production AD
- **Secondary DC** (Azure VM or on-prem): Failover AD
- **AAD Connect HA**: Staging server (hot standby)

## Execution Steps

### Week 11: Setup Secondary DC
- Promote secondary domain controller
- Configure replication between DCs
- Test AD replication

### Week 12: AAD Connect HA
- Install AAD Connect on staging server
- Configure in staging mode (disabled)
- Enable failover capability
- Test failover (manual switch)

## Success Checklist

- [ ] Secondary DC replicating
- [ ] Failover DC tested + working
- [ ] AAD Connect staging server ready
- [ ] Failover tested (users can still sync)
- [ ] Recovery time <1 hour

## Next: Phase 7

→ **Phase 7: Azure Infrastructure & Networking**
