# Hybrid Azure & Microsoft 365 Enterprise Lab

**A comprehensive phase-based deployment guide for integrating on-premises infrastructure with Azure and Microsoft 365**

> **Business Value**: This project demonstrates enterprise cloud architecture design, hybrid identity management, security governance, and operational excellence for nig-e-mart.

---

## Executive Summary

This project provides a **production-ready architectural blueprint** for deploying a secure, scalable hybrid cloud environment that unifies:

- **On-premises identity** (Active Directory Domain Services)
- **Cloud identity** (Azure Entra ID + Conditional Access)
- **Cloud productivity** (Microsoft 365 tenant)
- **Azure infrastructure** (compute, networking, disaster recovery)
- **Governance & compliance** (Role-Based Access Control, DLP, audit logging)

---

## Why This Architecture?

### Problem Statement
nig-e-mart need to migrate enterprise workloads to the cloud while:
- Maintaining on-premises system compatibility
- Implementing Zero Trust security
- Minimizing user disruption
- Ensuring business continuity
- Establishing compliance audit trails

### Solution Approach
This project implements a **hybrid-first design**:

1. **Identity** is the control plane (not networks) → Unified AD + Entra ID
2. **Security** is layered and shifting → MFA → Conditional Access → DLP → Defender
3. **Operations** are automated and monitored → PowerShell orchestration → Azure Monitor
4. **Resilience** is built-in → Backup, failover, redundancy at every layer

---

## Architecture Overview

### Multi-Layer Technology Stack

```
┌─────────────────────────────────────────────────────────────┐
│  USER LAYER: Devices + Applications                         │
│  • Windows/iOS/Android managed by Intune                    
│  • M365 apps (Teams, OneDrive, Exchange)                    
└──────────────────────┬──────────────────────────────────────┘

┌────────────────────────────────────────────────────────────┐
│  IDENTITY LAYER: Authentication & Authorization            │
│  • On-prem: AD DS (LDAP, Kerberos, NTLM)                   │
│  • Cloud: Entra ID (OAuth, SAML, MFA)                      │
│  • Sync: Azure AD Connect (delta + password hash)          │
│  • Policies: Conditional Access, PIM, JIT access           │
└──────────────────────┬─────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│  SECURITY LAYER: Threat Prevention & Compliance             │
│  • Network: Azure Firewall, NSGs, Private Endpoints         │
│  • Email: Defender, Safe Links, Safe Attachments            │
│  • Data: DLP policies, encryption, quarantine queues        │
│  • Audit: Unified logs, alerts, retention policies          │
└──────────────────────┬──────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│  SERVICE LAYER: Productivity & Collaboration                │
│  • Exchange Online (20k+ mailboxes)                         │
│  • SharePoint Online (departmental sites)                   │
│  • Teams (channels, governance, retention)                  │
│  • OneDrive (personal file sync)                            │
└──────────────────────┬──────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│  INFRASTRUCTURE LAYER: Compute & Networking                 │
│  • Azure VMs (IaaS): Web, app, data tiers                   │
│  • Azure SQL: Private endpoint, encryption                  │
│  • VNet: Segmented subnets, NSGs, UDRs                      │
│  • Connectivity: Site-to-Site VPN (IPsec)                   │
└──────────────────────┬──────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│  DATA PROTECTION LAYER: Backup & Disaster Recovery          │
│  • Backup Vault: VM snapshots, retention 30 days-7 years    │
│  • Site Recovery: RTO 1 hour, RPO 24 hours                  │
│  • Logging: Log Analytics workspace (2 years retention)     │
└─────────────────────────────────────────────────────────────┘
```

### Trust & Access Model

```
On-Premises                   Hybrid Sync                      Cloud
┌────────────────┐           ┌──────────┐          ┌──────────────────┐
│   AD DS        │◄──────────┤ AAD      │─────────►│  Entra ID        │
│   (Source)     │ Password  │ Connect  │ Policy   │  (Authority)     │
│   • Users      │  Hash +   │ (Staging)│          │  • CA Rules      │
│   • Groups     │  Delta    │          │          │  • MFA           │
│   • ACLs       │           │          │          │  • PIM           │
└────────────────┘           └──────────┘          └────────┬─────────┘
                                                             │
                                                    ┌────────▼────────┐
                                                    │  M365 Services  │
                                                    │  • Exchange     │
                                                    │  • SharePoint   │
                                                    │  • Teams        │
                                                    │  • OneDrive     │
                                                    └─────────────────┘
```

---

## Core Technologies

### Identity & Access Management
- **Active Directory Domain Services** (LDAP v3, Kerberos authentication)
- **Azure Entra ID** (formerly Azure AD) with Premium P1
- **Azure AD Connect** with password hash sync
- **Multi-Factor Authentication** (Authenticator app, SMS fallback)
- **Conditional Access** (device compliance, location-based)
- **Privileged Identity Management** (just-in-time elevation)

### Microsoft 365 Services
- **Exchange Online** (mail flow, shared mailboxes, retention)
- **SharePoint Online** (team sites, content libraries, versioning)
- **Microsoft Teams** (channels, governance, eDiscovery)
- **OneDrive** (personal file sync, shared with others)
- **Microsoft Defender** (email protection, threat intelligence)
- **Microsoft Intune** (device enrollment, compliance policies)

### Azure Infrastructure
- **Virtual Networks** (segmented subnets with NSGs)
- **Azure Firewall** (centralized threat protection)
- **Azure Bastion** (passwordless SSH/RDP jumpbox)
- **VPN Gateway** (site-to-site IPsec tunnel)
- **Azure SQL Database** (private endpoint, TDE encryption)
- **Azure App Service** (managed identity, PaaS workloads)
- **Load Balancer** (availability zones, health probes)

### Data Protection & Monitoring
- **Azure Backup** (VM snapshots, retention policies)
- **Azure Site Recovery** (replication, failover automation)
- **Azure Monitor** (metrics, logs, alerts)
- **Log Analytics** (centralized logging, KQL queries)
- **Security Score** (M365 compliance dashboard)

### Automation & Governance
- **PowerShell** (user provisioning, license assignment, bulk operations)
- **Microsoft Graph API** (programmatic M365 administration)
- **Azure Resource Manager** (infrastructure as code templates)
- **Role-Based Access Control** (least privilege enforcement)

---

## Security Posture

### Zero Trust Principles Applied

1. **Verify Identity** - MFA mandatory for admin accounts; conditional access for risky logins
2. **Validate Device** - Intune enrollment required; compliance policies enforced
3. **Assume Breach** - Audit logging enabled; alerts trigger on anomalies; DLP quarantines sensitive data
4. **Encrypt Everything** - TLS 1.3 for transport; AES-256 at rest; private endpoints for databases
5. **Least Privilege** - RBAC limits permissions; PIM requires just-in-time approval; quarterly access reviews

### Security Controls by Layer

| Layer | Control | Mechanism |
|-------|---------|-----------|
| **Network** | Firewall filtering | Azure Firewall + NSGs block unauthorized traffic |
| **Identity** | MFA enforcement | Authenticator app on admin accounts → 2FA required |
| **Data** | DLP policies | External email containing PII/PCI → quarantine |
| **Threats** | Defender scanning | Email sandbox → malware detection → alert |
| **Audit** | Logging & alerting | All admin actions → Log Analytics → dashboard |

---

## Success Criteria & Outcomes

### Functional Outcomes
✓ **100% User Migration** - All employees provisioned to M365, SSO from on-premises workstations  
✓ **Email Operational** - Mail flow working, shared mailboxes configured, retention policies active  
✓ **Collaboration Enabled** - Teams functional, SharePoint sites created, file permissions configured  
✓ **Devices Managed** - 15+ endpoints enrolled in Intune, compliance policies enforced  
✓ **Hybrid Identity** - On-prem AD syncing to Entra ID, password reset working from cloud  

### Security Outcomes
✓ **M365 Security Score > 60%** - Advanced threat protection, DLP, and conditional access active  
✓ **Zero Critical Incidents** - All alerts monitored, false positive rate < 5%  
✓ **Audit Ready** - Retention policies active, eDiscovery available, quarterly access reviews scheduled  
✓ **Ransomware Protected** - Backup + Site Recovery tested monthly, RTO < 1 hour  

### Operational Outcomes
✓ **Monitoring Live** - Dashboards show real-time health, alerts delivered to security team  
✓ **Automation Working** - PowerShell scripts automate provisioning, licensing, reporting  
✓ **Documentation Complete** - Runbooks, troubleshooting guides, lessons learned captured  
✓ **Knowledge Transferred** - IT staff trained on M365, Azure, hybrid administration  

---

## Project Folder Structure

```
Hybrid-Azure-m365-project/
│
├── 00-planning/                          ← Strategic foundation
│   ├── 01-implementation-roadmap.md      (22-week timeline, critical path)
│   ├── 02-requirements.md                (functional, technical, security needs)
│   ├── 03-assumptions-scope.md           (boundaries, risks, mitigations)
│   ├── 04-security-design.md             (MFA, DLP, Conditional Access patterns)
│   ├── 05-rbac-model.md                  (role hierarchy, permission matrix)
│   └── 06-lessons-learned.md             (post-deployment review template)
│
├── 01-architecture/                      ← System design & topology
│   └── 01-hybrid-architecture-overview.md (7-layer stack, trust model, flows)
│
├── 02-phase-1-microsoft-365-deployment/  ← Cloud foundation
│   ├── 01-tenant-setup.md                (tenant creation, users, domains)
│   ├── 02-licensing-e3-e5.md             (license strategy, assignment)
│   ├── 03-exchange-online.md             (mailbox setup, routing, retention)
│   ├── 04-sharepoint-branding.md         (site creation, permissions, branding)
│   └── 05-defender-security.md           (baseline security, threat protection)
│
├── 03-phase-2-security-compliance/       ← Threat hardening
│   └── 01-advanced-security.md           (DLP, CA, InsiderRisk, threat stack)
│
├── 04-phase-3-collaboration-governance/  ← Team collaboration
│   └── 01-teams-setup.md                 (Teams, channels, governance policies)
│
├── 05-phase-4-monitoring-operations/     ← Operational visibility
│   └── 01-monitoring-setup.md            (dashboards, alerts, audit logging)
│
├── 06-phase-5-hybrid-identity/           ← Identity integration
│   └── 01-hybrid-identity-setup.md       (AAD Connect, SSO, password sync)
│
├── 07-phase-6-high-availability-redundancy/ ← Resilience
│   └── 01-ha-setup.md                    (backup, failover, RTO/RPO)
│
├── 08-phase-7-azure-infrastructure/      ← Cloud foundation
│   └── 01-azure-setup.md                 (VNets, VPN, backup vault)
│
├── 09-phase-8-workload-migration/        ← Content movement
│   └── 01-workload-migration.md          (files, mailboxes, archives)
│
├── 10-phase-9-file-services-access/      ← Permissions & retention
│   └── 01-file-services.md               (OneDrive, SharePoint, access policies)
│
├── 11-phase-10-rbac-design/              ← Governance
│   └── 01-rbac-implementation.md         (role assignment, audits)
│
├── 12-phase-11-endpoint-management/      ← Device management
│   └── 01-intune-deployment.md           (Intune enrollment, compliance)
│
├── 13-automation/                        ← Deployment scripts
│   ├── 01-powershell-automation-overview.md
│   ├── scripts-readme.md
│   └── powershell/
│       ├── 00-master-orchestration.ps1   (main entry point)
│       ├── 01-connect-services.ps1       (M365 authentication)
│       ├── 02-create-users.ps1           (bulk user provisioning)
│       ├── 03-license-assignment.ps1     (E3/E5 licensing)
│       ├── 04-mailbox-setup.ps1          (shared mailboxes)
│       ├── 05-generate-reports.ps1       (monitoring & audit)
│       ├── 06-cleanup-disabled-users.ps1 (archive & removal)
│       ├── 07-create-groups.ps1          (M365 groups)
│       ├── 08-enable-mfa.ps1             (MFA rollout)
│       └── samples/
│           ├── SAMPLE-users.csv
│           ├── SAMPLE-licenses.csv
│           └── SAMPLE-groups.csv
│
├── 14-reference/                         ← Best practices & guidelines
│   └── 01-security-best-practices.md     (MFA, DLP, CA patterns, audits)
│
├── LICENSE                               (Apache 2.0)
├── README.md                             ← You are here
└── PROMPT.md                             (original requirements)
```

---

## Quick Start Guide

### Prerequisites
- M365 tenant created (E3/E5 licenses)
- Azure subscription active (minimum $500/month budget)
- AD DS deployed on-premises (2+ domain controllers)
- Network connectivity between on-prem and Azure
- PowerShell 5.1+ installed on admin workstation

### Phase 1: Start Here (Week 1)
1. **Read** → `00-planning/02-requirements.md` (functional needs)
2. **Read** → `01-architecture/01-hybrid-architecture-overview.md` (system design)
3. **Execute** → `02-phase-1-microsoft-365-deployment/01-tenant-setup.md` (M365 foundation)
4. **Automate** → `13-automation/powershell/02-create-users.ps1` (bulk provisioning)

### Phase 2: Secure & Monitor (Weeks 3-8)
1. **Harden** → `03-phase-2-security-compliance/01-advanced-security.md`
2. **Deploy** → `04-phase-3-collaboration-governance/01-teams-setup.md`
3. **Monitor** → `05-phase-4-monitoring-operations/01-monitoring-setup.md`

### Phase 3: Integrate & Extend (Weeks 9-16)
1. **Connect** → `06-phase-5-hybrid-identity/01-hybrid-identity-setup.md` (AAD Connect)
2. **Backup** → `07-phase-6-high-availability-redundancy/01-ha-setup.md` (disaster recovery)
3. **Build** → `08-phase-7-azure-infrastructure/01-azure-setup.md` (cloud infrastructure)

### Phase 4: Migrate & Govern (Weeks 17-22)
1. **Migrate** → `09-phase-8-workload-migration/01-workload-migration.md`
2. **Secure** → `10-phase-9-file-services-access/01-file-services.md`
3. **Control** → `11-phase-10-rbac-design/01-rbac-implementation.md`
4. **Manage** → `12-phase-11-endpoint-management/01-intune-deployment.md`

---

## Automation & Scripts

Pre-built PowerShell scripts automate the deployment:

| Script | Purpose | Execution |
|--------|---------|-----------|
| `00-master-orchestration.ps1` | Main entry point with menu | `.\00-master-orchestration.ps1` |
| `01-connect-services.ps1` | Authenticate to M365 services | Called by master script |
| `02-create-users.ps1` | Bulk create users from CSV | `.\02-create-users.ps1 -csvPath users.csv` |
| `03-license-assignment.ps1` | Assign E3/E5 licenses | `.\03-license-assignment.ps1 -licensePath licenses.csv -preview` |
| `04-mailbox-setup.ps1` | Create shared mailboxes | `.\04-mailbox-setup.ps1 -sharedMailboxes @('support','finance')` |
| `05-generate-reports.ps1` | Generate audit reports | `.\05-generate-reports.ps1 -reportType daily` |
| `06-cleanup-disabled-users.ps1` | Archive disabled accounts | `.\06-cleanup-disabled-users.ps1 -gracePeriod 30` |
| `07-create-groups.ps1` | Create M365 groups | `.\07-create-groups.ps1 -groupsPath groups.csv` |
| `08-enable-mfa.ps1` | Enable MFA org-wide | `.\08-enable-mfa.ps1 -scope admin` |

**Usage**: See `13-automation/01-powershell-automation-overview.md`

---

## Key Concepts

### Hybrid Identity
- **On-premises AD** remains authoritative for users & groups
- **Azure AD Connect** syncs identities in real-time (delta sync every 30 min)
- **Password hash** synced securely (no actual passwords)
- **SSO** enables seamless cloud access from on-premises workstations

### Zero Trust Security
- **Never trust, always verify** - MFA required for all admin access
- **Device compliance** - Non-compliant devices blocked from sensitive resources
- **Data protection** - DLP prevents PII/PCI from leaving the organization
- **Audit everything** - All actions logged for compliance and incident investigation

### High Availability
- **Backup vault** protects VMs & databases (daily snapshots, 30-day retention)
- **Site Recovery** automates failover (RTO <1 hour)
- **Redundant domain controllers** (primary + secondary in Azure)
- **Monitored & alerted** (24/7 monitoring, automated responses)

### Governance & Compliance
- **Role-Based Access Control** limits permissions by department & function
- **Privileged Identity Management** requires just-in-time elevation for sensitive roles
- **Quarterly access reviews** ensure permissions stay current
- **Audit logs** retained for 2 years (enables eDiscovery, incident response)

---

## Deployment Estimates

| Phase | Duration | Effort | Resource |
|-------|----------|--------|----------|
| Planning (Phase 0) | 1 week | Design reviews | Architect |
| Foundation (Phases 1-4) | 8 weeks | User migration, security hardening | IT Operations |
| Integration (Phases 5-7) | 6 weeks | Hybrid setup, infrastructure build | Cloud Engineer |
| Migration (Phases 8-10) | 4 weeks | Data move, access governance | Migration specialist |
| Hardening (Phase 11) | 2 weeks | Device management, compliance | Operations |
| **Total** | **22 weeks** | **~500 hours** | **3 FTE** |

---

## Support & Troubleshooting

### Common Issues & Solutions

**Issue**: AAD Connect sync stuck  
**Solution**: See `06-phase-5-hybrid-identity/01-hybrid-identity-setup.md` → Troubleshooting section

**Issue**: Users cannot login after migration  
**Solution**: Verify password hash sync, check Conditional Access policies blocking access

**Issue**: DLP policies over-blocking legitimate emails  
**Solution**: Review DLP policy hits in `05-phase-4-monitoring-operations/01-monitoring-setup.md`, adjust sensitivity

### Getting Help
- **Architecture questions** → Review `01-architecture/01-hybrid-architecture-overview.md`
- **Scripting issues** → Check `13-automation/01-powershell-automation-overview.md`
- **Security concerns** → Reference `14-reference/01-security-best-practices.md`
- **Phase-specific steps** → See relevant phase folder documentation

---

## Portfolio Value

This project demonstrates:

✓ **Enterprise Architecture** - Multi-layer design integrating on-prem + cloud  
✓ **Security Engineering** - Zero Trust implementation, threat modelling, compliance  
✓ **Cloud Administration** - Azure governance, identity management, disaster recovery  
✓ **Automation** - PowerShell scripting, bulk operations, orchestration  
✓ **Project Management** - 22-week phased approach with dependencies & milestones  
✓ **Operations** - Monitoring, alerting, incident response procedures  
✓ **Documentation** - Enterprise-grade runbooks and implementation guides  

---

## License

Apache License 2.0 - See LICENSE file

---

## Next Steps

1. **Start** with `00-planning/01-implementation-roadmap.md` to understand the timeline
2. **Review** `01-architecture/01-hybrid-architecture-overview.md` for system design
3. **Execute** Phase 1 from `02-phase-1-microsoft-365-deployment/` to deploy the M365 foundation
4. **Reference** automation scripts in `13-automation/` for bulk operations
5. **Document** your deployment in `00-planning/06-lessons-learned.md` upon completion

---

**Last Updated**: March 4, 2026  
**Project Status**: Complete (11 phases documented, 9 automation scripts, ready for production deployment)
