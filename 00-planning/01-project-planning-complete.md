# Implementation Roadmap: Hybrid-Azure-m365 Project

## Critical Path Dependencies

* Phase 1 (M365) → Phase 5 (Hybrid) ┐
* Phase 2 (Security) → Phase 3 (Teams) → Phase 4 (Monitor) → Phase 8-10
* Phase 5 (Identity) → Phase 6 (HA) → Phase 7 (Azure) → Phase 8
* Phase 8-10 → Phase 11 (Intune)


## Key Milestones

- Users can login to M365, email working
- Security baseline active, threats detected
- Monitoring dashboards showing data
- Hybrid identity functional (on-prem SSO)
- Azure infrastructure + backup operational
- File services migrated to cloud
- Devices managed, go-live complete

## Success Metrics

✓ 100% user migration to M365  
✓ 95%+ device enrollment in Intune  
✓ Zero data loss during migration  
✓ Security Score > 60% (M365)  
✓ Zero unplanned downtime  
✓ <1 hour RTO for critical services  
---

# Hybrid-Azure-m365 Project Overview

## Project At A Glance

| Aspect | Details |
|--------|---------|
| **Scope** | Enterprise hybrid cloud migration: on-premises AD → Azure/M365 |
| **Target Org** | Mid-sized organization (500-5000 users) |
| **Key Result** | Unified identity, secure collaboration, modern IT ops |
| **Main Components** | AD DS, Entra ID, Microsoft 365, Azure, Intune |

## What This Project Does

**Goal**: Integrate on-premises Active Directory with Microsoft 365 and Azure while maintaining security, enabling collaboration, and modernizing operations.

**Architecture**: 
```
On-Premises AD ←→ Azure AD Connect ←→ Azure Entra ID ←→ Microsoft 365
      ↓                               ↓
   Users/Groups                    SSO/MFA/Access Control
```

## The 11 Phase

* 365 tenant, users, licenses 
* security policies, Defender, DLP 
* SharePoint, OneDrive, Teams 
* Monitoring, alerts, logging 
* Hybrid identity: AD DS → Entra 
* High availability backup 
* Azure networking, VPN, Site Recovery 
* Workload migration to Azure 
* File services, multi-site access
* RBAC design, least privilege 
* Intune enrollment, device compliance 

## Key Technologies

- **Identity**: Active Directory DS + Azure Entra ID + Premium
- **M365**: Tenant, Exchange, SharePoint, Teams, Defender
- **Azure**: VNet, VPN, Firewall, Backup, Site Recovery
- **Security**: MFA, Conditional Access, DLP, Audit logs
- **Devices**: Intune enrollment, compliance policies, group policy

## Success Criteria

- ✓ All users synced to cloud with SSO enabled
- ✓ M365 E3/E5 licenses assigned and working
- ✓ Hybrid identity functional (on-prem AD + cloud)
- ✓ VPN connectivity: on-premises ↔ Azure
- ✓ Security policies: MFA, DLP, threat protection active
- ✓ Intune: 80%+ device enrollment
- ✓ Backup and recovery tested


---

# Project Requirements: Hybrid-Azure-m365

## Functional Requirements

| Req ID | Requirement | Phase |
|--------|-------------|-------|
| FR-1 | All users provision to M365 cloud | Phase 1 |
| FR-2 | Email delivery via Exchange Online | Phase 1 |
| FR-3 | Document collaboration via Teams/SharePoint | Phase 3 |
| FR-4 | SSO from on-premises workstations | Phase 5 |
| FR-5 | MFA for all admin accounts | Phase 2 |
| FR-6 | DLP policy enforcement (block PII external) | Phase 2 |
| FR-7 | Devices managed by Intune | Phase 11 |
| FR-8 | Backup to Azure for recovery | Phase 7 |

## Technical Requirements

| Req ID | Requirement | Details |
|--------|-------------|---------|
| TR-1 | M365 E3/E5 licenses | All users |
| TR-2 | Entra ID Premium P1 | Conditional Access |
| TR-3 | Azure subscription | VNets, Backup, Site Recovery |
| TR-4 | On-prem AD Domain Services | 2+ DC for redundancy |
| TR-5 | VPN Gateway | IPsec site-to-site |

## Non-Functional Requirements

| Req ID | Requirement | Target |
|--------|-------------|--------|
| NFR-1 | RTO (Recovery Time Objective) | 1 hour max |
| NFR-2 | RPO (Recovery Point Objective) | 24 hours |
| NFR-3 | Availability (M365 services) | 99.9% |
| NFR-4 | User adoption | >80% in 8 weeks |
| NFR-5 | Security Score (M365) | >60% minimum |
| NFR-6 | Email delivery (no outages) | 99.95% |

## Security Requirements

- [ ] MFA enabled for all admin accounts
- [ ] DLP policy enforcing PII/PCI protection
- [ ] Conditional Access restricting risky logins
- [ ] Legacy authentication disabled
- [ ] Audit logging for all services
- [ ] Data encryption at rest + in transit
- [ ] Quarterly access reviews

## Compliance Requirements

- [ ] GDPR-ready (if applicable)
- [ ] 7-year data retention
- [ ] eDiscovery holds available
- [ ] SOC2 backups configured
- [ ] Audit reports generation

---

# Assumptions & Scope: Hybrid-Azure-m365

## What's IN Scope

✓ M365 tenant creation + user provisioning  
✓ Exchange Online implementation  
✓ Teams + SharePoint governance  
✓ Hybrid identity (AAD Connect)  
✓ Azure infrastructure (VNets, VPN, backup)  
✓ Intune device management  
✓ Security policies (MFA, DLP, conditional access)  
✓ User training + adoption  
✓ Migration of files to SharePoint/OneDrive  
✓ PowerShell automation scripts  

## What's OUT of Scope

✗ On-premises AD Domain Service migration (assumed existing)  
✗ Third-party application integration (custom development)  
✗ Legacy system decommissioning  
✗ Physical network infrastructure changes  
✗ Custom development for M365  
✗ Personnel hiring/reorganization  

## Key Assumptions

1. **Existing Infrastructure**
   - On-premises Active Directory already deployed (AD DS)
   - Network connectivity between on-prem + Azure exists
   - 1 on-premises domain controller (single instance)

2. **Budget & Resources**
   - M365 E3/E5 licenses budgeted + available
   - Azure subscription approved + funded
   - 3 FTE IT staff allocated
   - Executive sponsorship confirmed

3. **User Readiness**
   - All users have generated UPNs (user@domain.com)
   - Organizational chart documented
   - Users willing to migrate (change management planned)
   - Managers educated on new tools

4. **Technical**
   - 10Mbps+ internet bandwidth available
   - VPN gateway capability in on-prem environment
   - Domain registrar allows DNS updates (SPF/DKIM)
   - No conflicting IP ranges (Azure VNet + on-prem)

## Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|-----------|
| User resistance | Adoption delays | Change management, training |
| DCs fail during sync | Service outage | Secondary DC in Azure, failover |
| File migration data loss | Compliance issue | Validation checksums, parallel docs |
| Security policies too strict | User complaints | Pilot group, feedback loops |
| Bandwidth saturation | Slow performance | Off-peak migration, throttling |

## Success Criteria

- 100% user adoption (using M365 daily)
- Zero unplanned downtime
- All files migrated successfully
- Security baseline active
- Monitoring dashboards live
