# Hybrid Infrastructure Deployment for nig-e-mart

A hybrid enterprise environment for **nig-e-mart** combining on-premises AD DS, Hyper-V workloads, and Microsoft 365 with Azure cloud redundancy, Zero Trust security, and Purview governance. See [01-architecture/](01-architecture/) for the full topology diagram.

---

## Stack at a Glance

| Layer | Components |
|---|---|
| Identity | AD DS + Entra ID (Azure AD Connect, Password Hash Sync, Conditional Access, PIM) |
| Productivity | Exchange Online, SharePoint Online, Teams, OneDrive |
| Security | Defender for Office 365, DLP, sensitivity labels, MFA, BitLocker |
| Compliance | Microsoft Purview (retention, eDiscovery, audit logging) |
| Endpoints | Microsoft Intune (Windows, iOS, Android, macOS) |
| Networking | Site-to-Site VPN (IPsec/IKE), Azure VNet, NSGs |
| Redundancy | Secondary DC (Azure VM), Azure Site Recovery (ASR), Azure File Share |
| Monitoring | Azure Monitor, Log Analytics, Defender Dashboard, M365 Audit Logs |

---

## Business Continuity

| System | RTO | RPO | Method |
|---|---|---|---|
| Domain Controller | 1 hr | 24 hr | ASR continuous replication |
| File Server | 2 hr | 24 hr | ASR continuous replication |
| M365 Services | <30 min | Microsoft managed | Built-in geo-redundancy |

M365 data retained under 7-year compliance policy. Quarterly ASR test failovers (non-disruptive).

---

## Deployment Sequence

| Phase | Folder | Key Actions |
|---|---|---|
| 1 – M365 | `02-phase-1-*/` | Tenant setup, users, E3/E5 licensing, Exchange, SharePoint, Teams |
| 2 – Security | `03-phase-2-*/` | Conditional Access, MFA, DLP, Purview, sensitivity labels, PIM |
| 3 – Hybrid Identity | `06-phase-5-*/` | Azure AD Connect, password hash sync, Seamless SSO, user lifecycle |
| 4 – Azure Infrastructure | `08-phase-7-*/` | VNet, Site-to-Site VPN, secondary DC |
| 5 – High Availability | `07-phase-6-*/` | ASR replication, recovery plans, failover testing |
| 6 – Endpoint Management | `12-phase-11-*/` | Intune enrollment, compliance policies |

---

## Troubleshooting

**Users can't SSO to Teams from on-prem**
1. Check Azure AD Connect sync status — should show "Connected"
2. Review Conditional Access policies in Entra > Security > Conditional Access
3. Check audit logs for blocked sign-in reasons

**File shares inaccessible after VPN setup**
1. Confirm NSG allows port 445 (SMB) from the on-prem subnet
2. Verify DNS forwarding — test: `nslookup fileserver.company.local` from Azure VM

**M365 audit logs missing / retention not applying**
1. Enable audit logging: M365 Compliance > Audit
2. Check retention policy scope in Purview > Data lifecycle management
3. Allow 24 hours for policy propagation

---

## Automation

PowerShell deployment scripts are in [`13-automation/powershell/`](13-automation/powershell/) covering user creation, licensing, mailbox setup, MFA enablement, group management, and reporting.

---

*Internal use only – nig-e-mart · v2.1 · April 11, 2026*


