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
