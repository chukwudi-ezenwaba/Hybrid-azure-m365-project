# Hybrid Infrastructure Architecture Overview

## Executive Summary

This document provides a comprehensive architectural overview of the hybrid Microsoft infrastructure integrating on-premises Active Directory, Microsoft 365, and Azure cloud services. The architecture is designed using defense-in-depth security principles, high availability patterns, and least-privilege access control aligned with Microsoft's Zero Trust framework.

---

## Logical Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        INTERNET / PUBLIC NETWORK                             │
└─────────────────────────────────────────────────────────────────────────────┘
                          ▲                              ▲
                          │                              │
                   ┌──────┴────────┐            ┌────────┴──────────┐
                   │                │            │                   │
         ┌─────────▼─────────┐  ┌──▼────────────▼──┐    ┌───────────▼────┐
         │  Microsoft 365    │  │  Azure Services  │    │  VPN Endpoint  │
         │  (Microsoft SaaS) │  │  (IaaS/PaaS)     │    │  (Gateway)     │
         └────────┬──────────┘  └──┬────────────┬──┘    └────────┬───────┘
                  │                │            │                 │
                  └────────────────┼────────────┼─────────────────┘
                                   │ IPsec VPN  │
                    ┌──────────────┴────────────┴──────────────┐
                    │                                          │
         ┌──────────▼──────────┐                ┌───────────────▼────────┐
         │  ON-PREMISES        │                │    AZURE CLOUD         │
         │  NETWORK            │                │    NETWORK             │
         │  (Proxmox/Hyper-V)  │                │    (Virtual Network)   │
         │                     │                │                        │
         │  ┌─────────────────┐│                │  ┌──────────────────┐ │
         │  │ Domain Controller││                │  │Secondary Domain  │ │
         │  │ (PDC Emulator)   ││   Replication  │  │Controller (Azure)│ │
         │  └────────┬─────────┘│◄───────────────┼─►└──────────────────┘ │
         │           │           │                │                        │
         │  ┌────────▼─────────┐│                │  ┌──────────────────┐ │
         │  │ File Server      ││                │  │Azure Firewall    │ │
         │  │ (HR/IT/Ops/etc)  ││                │  │(Network Security)│ │
         │  └──────────────────┘│                │  └──────────────────┘ │
         │                     │                │                        │
         │  ┌─────────────────┐│                │  ┌──────────────────┐ │
         │  │ Legacy HR App   ││                │  │ Migrated HR App  │ │
         │  │ (IIS Server)    ││   Migration    │  │ (Azure VM)       │ │
         │  └────────┬─────────┘│                │  └─────────┬────────┘ │
         │           │           │                │           │           │
         │  ┌────────▼─────────┐│                │  ┌─────────▼────────┐ │
         │  │Azure AD Connect  ││                │  │ Site Recovery    │ │
         │  │ Sync Engine      ││                │  │ Replication      │ │
         │  └──────────────────┘│                │  └──────────────────┘ │
         └────────┬──────────────┘                └────────┬──────────────┘
                  │           ▲                          ▲
                  │ Sync      │ Password Hash Sync       │
                  │           │ User/Group Changes       │
         ┌────────▼───────────┴──────────────────────────┼─────────┐
         │                                                │         │
         │              AZURE ENTRA ID                   │         │
         │         (Cloud Directory Service)            │         │
         │                                                │         │
         │         • User Identities                    │         │
         │         • Groups & Roles                     │         │
         │         • MFA & Conditional Access          │         │
         │         • Applications (M365, Azure)         │         │
         │                                                │         │
         └────────┬───────────────────────────────────────┼─────────┘
                  │                                       │
         ┌────────▼────────────────────────────────────┐  │
         │                                              │  │
         │    MICROSOFT 365 SERVICES                   │  │
         │    + Azure Services Authentication          │  │
         │                                              │  │
         │  ┌─────────────────┐  ┌────────────────┐   │  │
         │  │Exchange Online   │  │SharePoint      │   │  │
         │  │+ Defender       │  │Online + Viva   │   │  │
         │  └─────────────────┘  │Engage          │◄──┘  │
         │  ┌─────────────────┐  └────────────────┘      │
         │  │OneDrive for     │  ┌────────────────┐      │
         │  │Business         │  │Microsoft Teams │      │
         │  │+ DLP Policies   │  │+ Compliance    │      │
         │  └─────────────────┘  └────────────────┘      │
         │                                              │
         └──────────────────────────────────────────────┘
                           ▲
                           │
                    ┌──────┴──────────┐
                    │                 │
         ┌──────────▼──────┐  ┌────────▼─────────┐
         │   ENDPOINT      │  │ MONITORING &     │
         │   DEVICES       │  │ COMPLIANCE       │
         │   (Intune)      │  │                  │
         │                 │  │• Audit Logs      │
         │   • Windows 10 ◄┼─►│• Alert Policies  │
         │   • Mac         │  │• Reports         │
         │   • Mobile      │  │• Service Health  │
         └─────────────────┘  └──────────────────┘
```

---

## Architectural Layers

### 1. Identity Layer

**Components:**
- **On-Premises Active Directory Domain Services (AD DS)**: Authoritative identity source for organizational users, groups, computers, and policies
- **Azure Entra ID (Cloud Directory)**: Cloud-native identity platform providing authentication, authorization, and identity governance
- **Azure AD Connect**: Synchronization engine bridging on-premises AD and Entra ID, ensuring consistent identity across hybrid boundaries
- **Multi-Factor Authentication (MFA)**: Additional security verification beyond passwords, protecting against credential compromise

**Data Flow:**
1. User credentials entered on domain-joined client
2. AD authentication on on-premises domain controller
3. Token issuance for on-premises resources
4. Azure AD Connect synchronizes user attributes to Entra ID
5. User authenticates to cloud services (Microsoft 365, Azure) using synced credentials with optional MFA

**Security Principles:**
- Password hashes synchronized (never passwords themselves)
- Bidirectional replication via Azure AD Connect ensures consistency
- Conditional Access policies evaluate authentication context (device, location, risk)
- MFA enforced for privileged operations

### 2. Network Layer

**On-Premises Network:**
- Firewalled private network behind organizational perimeter
- Network segmentation with VLANs (management, user, server)
- DNS infrastructure with zone delegation to Azure for hybrid resolution
- VPN endpoint for secure tunnel establishment

**Azure Network:**
- Virtual Network (VNet) with custom address space (typically 10.0.0.0/16)
- Subnet segmentation: Management, Application, Database, Trusted subnets
- Network Security Groups (NSGs) with stateful filtering rules
- Azure Firewall for centralized threat protection and logging
- Application Gateway for load balancing and web application firewall

**Hybrid Connectivity:**
- Site-to-Site VPN using IPsec/IKEv2 protocols
- Encrypted tunnel through internet connecting on-premises VPN endpoint to Azure VPN Gateway
- Conditional routing: traffic for on-premises network ranges uses VPN tunnel
- High availability with redundant VPN connections

### 3. Compute Layer

**On-Premises Infrastructure:**
- Primary Domain Controller running Active Directory services
- File servers hosting departmental shares (HR, IT, Operations, Finance)
- Legacy application servers (IIS hosting HR application)
- Proxmox hypervisor providing virtual machine infrastructure

**Azure Infrastructure:**
- Secondary Domain Controller providing redundancy and replication target
- Migrated workloads (legacy HR application running in Azure VM)
- Site Recovery infrastructure for disaster recovery and failover replication
- Availability Set/Zones for redundancy

### 4. Microsoft 365 Layer

**Services:**
- **Exchange Online**: Cloud email with advanced threat protection, DLP policies, message encryption
- **SharePoint Online**: Collaborative document management with versioning, approval workflows, retention policies
- **OneDrive for Business**: Personal cloud storage with external sharing controls and lifecycle management
- **Microsoft Teams**: Unified communication platform (calling, chat, meetings)
- **Viva Engage**: Internal social networking and communication

**Security:**
- Microsoft Defender for Office 365 protecting all services
- DLP policies preventing data exfiltration
- Insider Risk Management detecting policy violations
- Audit logging for compliance and investigation

### 5. Security Layer

**Authentication & Authorization:**
- Multi-factor Authentication (MFA)
- Conditional Access policies (device compliance, location, risk evaluation)
- Role-Based Access Control (RBAC) across Azure and Microsoft 365
- Privileged Identity Management (PIM) for just-in-time admin access

**Threat Protection:**
- Microsoft Defender for Office 365 (Safe Links, Safe Attachments, anti-phishing)
- Microsoft Defender for Identity (anomaly detection, lateral movement prevention)
- Azure Firewall threat intelligence and filtering
- Endpoint Protection via Windows Defender/Microsoft Defender

**Data Protection:**
- Data Loss Prevention (DLP) policies
- Information Rights Management (IRM)
- Encryption at-rest and in-transit
- File retention and lifecycle management

**Audit & Compliance:**
- Unified Audit Logging in Microsoft 365
- Azure Activity Logs and resource logs
- Alert policies for suspicious activities
- Compliance Manager for regulatory alignment

### 6. Management Layer

**Device Management:**
- Microsoft Intune for MDM/MCM (Mobile Device Management / Mobile Computer Management)
- Device compliance policies enforcing security requirements
- Configuration profiles deploying security baselines
- Conditional Access integration blocking non-compliant devices

**Operational Monitoring:**
- Azure Monitor collecting metrics and logs
- Log Analytics workspace for analytics and queries
- Application Insights application performance monitoring
- Service Health dashboard tracking platform status

**Administration:**
- Azure Portal for resource management
- Microsoft 365 Admin Center for tenant administration
- Microsoft Entra ID Admin Center for identity governance
- PowerShell and Azure CLI for automation

### 7. Disaster Recovery Layer

**Backup:**
- Azure Backup for VM protection with configurable retention
- SQL Database automated backups and point-in-time restore
- SharePoint and OneDrive automated backup (14-day retention)

**Disaster Recovery:**
- Azure Site Recovery for asynchronous VM replication
- Replication targets in secondary Azure region
- Failover runbooks and automated failover capabilities
- Regular failover drills validating recovery procedures

**Business Continuity:**
- RTO (Recovery Time Objective): Maximum acceptable downtime
- RPO (Recovery Point Objective): Maximum acceptable data loss
- Redundant domain controllers enabling failover
- Load balancing across multiple instances

---

## Network Connectivity Model

### On-Premises to Azure VPN

```
On-Premises                          Internet                         Azure
Network                                                              Network
10.x.x.x/16                                                        10.0.0.0/16

┌──────────────────┐                                    ┌──────────────────┐
│ VPN Endpoint     │                                    │ VPN Gateway      │
│ (Firewall/Router)│◄───── IPsec Encrypted Tunnel ────►│ (Azure Service)  │
│ Public IP: x.x.x │        Authentication             │ Public IP: y.y.y │
└────────┬─────────┘        Pre-Shared Key              └────────┬─────────┘
         │                                                       │
         │ Traffic for 10.0.0.0/16                             │
         │ routes through VPN                                   │
         │                                                       │
    On-Premises                                          Azure Resources
    Resources:                                           - Secondary DC
    - Primary DC                                         - Migrated VMs
    - File Servers                                       - Site Recovery
    - Legacy App Servers
    - Clients
```

### Identity Synchronization Flow

```
On-Premises AD          Azure AD Connect          Azure Entra ID
(Authority)             (Synchronization)         (Cloud Directory)

User Created in AD  ─┐
                    │  Initial Sync
Password Changed    │  (Full sync)
Group Added         │
                    ├──►  Azure AD Connect  ──►  User created/updated in Entra ID
Attributes Updated  │     Detects changes       Password hash synced
                    │     Applies transforms    Group membership synced
                    │
                    └──  Delta Sync (every 30 min by default)
                        Only changed objects
                        Minimal bandwidth usage
```

---

## Access Control Model

### Role-Based Access Control (RBAC)

**Azure RBAC Scope Hierarchy:**
```
Management Group (Optional organizational level)
        │
        ├─► Subscription (Billing & resource boundary)
        │           │
        │           └─► Resource Group (Collection of related resources)
        │                     │
        │                     └─► Individual Resource (VM, Database, etc)
```

**Role Assignments:**
- **Subscription-level**: Broad team permissions, simplified management
- **Resource Group-level**: Typical team access, balanced control
- **Resource-level**: Exception scenarios requiring precise permissions

**Built-in Roles:**
- **Virtual Machine Contributor**: Create/manage VMs, but no access to Network or Storage
- **Help Desk Operator**: Password resets, basic user support, no infrastructure access
- **Billing Administrator**: Cost analysis and budget management, no resource access
- **Security Administrator**: Security configuration, policy application, no resource modification

### Microsoft 365 RBAC

**Global Administrator**: Full organizational control, grant sparingly

**Delegated Administrators:**
- **Exchange Administrator**: Email governance and compliance
- **SharePoint Administrator**: Collaboration platform management
- **Teams Administrator**: Communication platform management
- **Intune Administrator**: Device and endpoint management

---

## Data Classification & Retention

### Classification Levels

**Public**: No sensitivity restrictions, can be shared externally
- Marketing materials, general announcements, published documentation

**Internal**: Organizational use only, restricted external sharing
- Internal policies, training materials, operational procedures

**Confidential**: Limited distribution, access by role requirement
- Financial data, strategic plans, customer information

**Restricted**: Maximum protection, audit trails required
- Personal identifiable information (PII), health records, compliance data

### Retention Policies

**OneDrive**: 5-year default retention, lifecycle rules for archived files

**SharePoint**: Department-specific policies (HR sensitive content: 7 years)

**Exchange**: 3-year retention with litigation hold capabilities

**Audit Logs**: 90-day minimum, longer retention for compliance requirements

---

## High Availability & Redundancy

### Domain Controller Redundancy

```
On-Premises          Azure Cloud
Primary DC           Secondary DC
- Holds FSMO roles   - Replica of AD DB
- Receives writes    - Provides failover
- PDC Emulator       - Read requests OK
  ▲
  │ Replication
  │ (Multi-master)
  ▼
Secondary DC         If Primary Fails:
(Azure)              - Secondary becomes authority source
                     - FSMO roles transferrable
                     - Cloud-based authentication available
```

### Network Redundancy
- Primary and secondary VPN connections for failover
- Multiple subnets in different availability zones
- Load balancing distributing traffic

### Data Redundancy
- Database transaction logs backed up separately
- Geo-replicated storage for disaster recovery
- Point-in-time recovery capability

---

## Disaster Recovery Strategy

### RTO/RPO Targets

| Component | RTO | RPO | Method |
|-----------|-----|-----|--------|
| Domain Controllers | 30 min | 0 (replicated) | Secondary DC takeover |
| File Servers | 2 hours | 1 hour | Azure Backup |
| Legacy App | 4 hours | 1 hour | Site Recovery failover |
| Exchange Online | 15 min | 0 (cloud-native HA) | Automatic failover |
| Databases | 2 hours | 30 min | Automated backups |

### Failover Procedures

1. **Detection**: Monitoring alerts or manual detection of failure
2. **Assessment**: Determine scope and impact
3. **Activation**: Initiate failover procedures (secondary DC, Site Recovery)
4. **Validation**: Verify functionality and data integrity
5. **Communication**: Notify stakeholders of status
6. **Failback**: Plan return to primary resources when recovered

---

## Summary

The hybrid infrastructure architecture provides:

✓ **Security**: Multi-layer defense, encryption, identity-driven access control
✓ **Scalability**: Cloud elasticity combined with on-premises control
✓ **Reliability**: Redundancy, high availability, proven failover mechanisms
✓ **Compliance**: Audit trails, retention policies, governance controls
✓ **Integration**: Seamless hybrid identity, SSO across boundaries
✓ **Management**: Unified administration, consistent policy enforcement

This architecture aligns with Microsoft Zero Trust principles and enterprise best practices for hybrid cloud deployments.

---

*Document Version: 1.0*
*Last Updated: March 2, 2026*
