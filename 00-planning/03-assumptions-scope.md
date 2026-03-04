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
