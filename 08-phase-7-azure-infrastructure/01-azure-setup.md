# Phase 7: Azure Infrastructure & Networking

**Duration**: Weeks 13-14 | **Key Result**: Azure network + VPN + backup configured

## Phase Overview

| Item | Details |
|------|---------|
| What | Setup Azure VNets, VPN gateway, backup services |
| Duration | 2 weeks |
| Depends | Phase 5 (hybrid) |

## Azure Components

1. **VNet** for secondary DC + services
2. **VPN Gateway** for site-to-site connectivity
3. **Backup Vault** for on-prem backup
4. **Site Recovery** for business continuity

## Execution Steps

### Week 13: Network Setup
- Create Azure VNet (10.0.0.0/16)
- Create subnet for domain controller
- Deploy secondary DC in Azure
- Configure VPN gateway (IPsec)

### Week 14: Backup & Recovery
- Create Azure Backup Vault
- Configure on-prem backup to Azure
- Setup Site Recovery for VMs
- Test recovery

## Success Checklist

- [ ] VNet created + configured
- [ ] VPN gateway active, connectivity tested
- [ ] Secondary DC in Azure online
- [ ] Backup vault configured
- [ ] Test backup/restore successful

## Next: Phase 8

→ **Phase 8: Workload Migration**
