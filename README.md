# Hybrid Infrastructure Deployment for nig-e-mart

## Executive Summary

This project documents the design and deployment of a secure, scalable, and governance-driven hybrid infrastructure for **nig-e-mart**, a startup modernizing its IT operations while maintaining control of critical on-premises systems.

The architecture integrates:

- On-premises Active Directory Domain Services (AD DS)
- Hyper-V virtualization hosting internal workloads
- Intranet web application (VM-based)
- File server (VM-based)
- Microsoft 365 tenant services
- Microsoft Intune device management
- Microsoft Purview compliance & governance
- Microsoft Defender security protections
- Azure cloud redundancy
- Secure Site-to-Site VPN connectivity
- Hybrid identity synchronization
- Zero Trust security model implementation

This solution balances operational control, cloud agility, compliance enforcement, and business continuity.

---

# Business Objectives

nig-e-mart requires an infrastructure that:

- Maintains on-premises control of core identity and file services
- Enables secure cloud productivity (Exchange, OneDrive, SharePoint)
- Provides Azure-based redundancy for critical systems
- Enforces compliance and governance policies
- Secures endpoints and user access
- Implements industry security best practices
- Supports long-term scalability and availability

---

# Architecture Overview

The environment follows a layered hybrid enterprise architecture integrating:

- On-prem identity & virtualization
- Microsoft 365 cloud services
- Azure redundancy infrastructure
- Governance & compliance controls
- Secure VPN-based hybrid connectivity

### Multi-Layer Technology Stack

```
┌─────────────────────────────────────────────────────────────┐
│  USER LAYER: Devices + Applications                         │
│  • Windows/iOS/Android managed by Intune                    │
│  • M365 apps (Teams, OneDrive, Exchange)                    │
└──────────────────────┬──────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│  IDENTITY LAYER: Authentication & Authorization             │
│  • On-prem: AD DS (LDAP, Kerberos, NTLM)                    │
│  • Cloud: Entra ID (OAuth, SAML, MFA)                       │
│  • Sync: Azure AD Connect (delta + password hash)           │
│  • Policies: Conditional Access, PIM, JIT access           │
└──────────────────────┬──────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│  SECURITY LAYER: Threat Prevention & Compliance             │
│  • Network: Azure Firewall, NSGs, Private Endpoints         │
│  • Email: Defender, Safe Links, Safe Attachments           │
│  • Data: DLP policies, encryption, quarantine queues        │
│  • Audit: Unified logs, alerts, retention policies          │
└──────────────────────┬──────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│  SERVICE LAYER: Productivity & Collaboration                │
│  • Exchange Online (email, shared mailboxes)                │
│  • SharePoint Online (team sites, document management)      │
│  • Teams (channels, governance, retention)                  │
│  • OneDrive (personal file sync, backup)                    │
└──────────────────────┬──────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│  INFRASTRUCTURE LAYER: Compute & Networking                 │
│  • On-prem: Domain Controller, Hyper-V host, file server    │
│  • Azure: VMs (redundancy), VNet, VPN Gateway               │
│  • Connectivity: Site-to-Site VPN (IPsec/IKE)              │
│  • Storage: File shares, OneDrive, Azure storage            │
└─────────────────────────────────────────────────────────────┘
```

---

# 1. On-Premises Infrastructure

## 1.1 Domain Controller

- Hosts Active Directory Domain Services (AD DS)
- Serves as the authoritative identity source
- Manages:
  - User and group accounts
  - Group Policy Objects (GPOs)
  - DNS services
  - Authentication and authorization

Identity remains centralized and synchronized to the cloud.

---

## 1.2 Hyper-V Virtualization Host

The Hyper-V server hosts the organization's internal workloads as virtual machines:

### Intranet Web Application Server (VM)
- Hosts internal company web application
- Integrated with AD authentication
- Used as corporate intranet portal

### File Server (VM)
- Centralized file storage
- NTFS permissions aligned with AD security groups
- Department-based access segmentation
- Primary repository for business data

Hyper-V ensures workload isolation, scalability, and simplified backup operations.

---

# 2. Hybrid Connectivity – Site-to-Site VPN

Secure connectivity between on-prem and Azure is established using an IPsec Site-to-Site VPN.

## Components

- Azure Virtual Network (VNet)
- Azure VPN Gateway
- Local Network Gateway
- On-prem firewall/VPN device
- IPsec/IKE encrypted tunnel

## Purpose

- Enable secure communication between on-prem and Azure resources
- Support failover and redundancy scenarios
- Maintain encrypted traffic end-to-end
- Comply with data residency requirements

---

# 3. Microsoft 365 Tenant Deployment

## Services Implemented

- **Exchange Online**: Email, shared mailboxes, calendar management
- **SharePoint Online**: Team sites, document libraries, intranet
- **Teams**: Chat, channels, video conferencing, collaboration
- **OneDrive**: Personal file synchronization and backup
- **Microsoft Defender for Office 365**: Email threat protection
- **Data Loss Prevention (DLP)**: PII protection, compliance enforcement

---

# 4. Hybrid Identity Architecture

## Configuration

- **Azure AD Connect**: Synchronizes on-premises users to Entra ID
- **Password Hash Sync**: Secure password authentication bridge
- **Conditional Access**: MFA, device compliance, location-based policies
- **Privileged Identity Management (PIM)**: JIT access for admins

---

# 5. Endpoint Management – Microsoft Intune

## Intune Configuration

- Device enrollment (Windows, iOS, Android, macOS)
- Compliance policies (encryption, updates, antivirus)
- App deployment and management
- Conditional access integration

---

# 6. Governance & Compliance – Microsoft Purview

## Governance Controls

- Data classification and labeling
- Retention policies (90-day M365 logs, 7-year data retention)
- eDiscovery holds for legal compliance
- Audit logging and monitoring

---

# 7. Security & Zero Trust Implementation

## Identity Security
- MFA mandatory for all admin accounts
- Risk-based Conditional Access policies
- Privileged Access Management (PIM) for elevated roles
- Regular access reviews and attestations

## Device Security
- Intune compliance policies enforced
- Antivirus (Windows Defender) + Defender ATP enabled
- Disk encryption (BitLocker) mandatory
- Automatic app deployment and patching

## Email & Collaboration Security
- Safe Links: URL sandboxing in email
- Safe Attachments: File detonation and scanning
- DLP: Block PII/PCI external transmission
- Threat Analytics: AI-powered incident investigation

## Secure Score Monitoring
- M365 Secure Score tracked monthly (target >60%)
- Security recommendations prioritized and tracked
- Executive reporting on security posture

---

# 8. Azure Cloud Redundancy Strategy

## Secondary Domain Controller (Azure VM)
- Replica domain controller in Azure for failover
- Supports Azure workload authentication
- Automated backup and recovery

## Secondary Intranet Web Server (Azure VM)
- Mirrors on-prem application
- Load-balanced failover capability
- Automated deployment via ARM templates

## Azure File Share
- Secondary storage location
- Geodistributed backup copy
- Automated sync from on-prem file server

---

# 9. Monitoring, Auditing & Logging

- **Azure Monitor**: Infrastructure metrics and alerts
- **Log Analytics**: Centralized event collection
- **M365 Audit Logs**: Activity tracking (90-day retention)
- **Defender Dashboard**: Threat intelligence and incident response

---

# 10. Business Continuity & Resilience

### RTO/RPO Targets
- Domain Controller: RTO 1 hour, RPO 24 hours
- File Server: RTO 2 hours, RPO 24 hours
- M365 Services: RTO <30 min, RPO varies (Microsoft managed)

### Backup Strategy
- Daily incremental file server backups
- Weekly full backups to external storage
- M365 retention policies: 7-year compliance window
- Quarterly disaster recovery testing

---

# Core Technologies & Key Concepts

## Hybrid Identity Management

**What it means**: Users authenticate once locally but seamlessly access both on-prem and cloud resources.

**How it works**:
1. User enters AD credentials at workstation login
2. Azure AD Connect syncs identity to Entra ID (30-min delta)
3. Entra ID issues OAuth token for M365 services
4. Conditional Access validates device/location/risk
5. User gets SSO to Teams, OneDrive, SharePoint, etc.

**Authentication flows**:
- On-prem: Kerberos (Windows integrated)
- Cloud: OAuth 2.0, SAML, MFA
- Bridge: Azure AD Connect with password hash sync

---

## Zero Trust Security Model

**Principles**:
- **Never trust, always verify**: Every access request is authenticated and authorized
- **Multi-factor authentication**: MFA on all privileged accounts
- **Principle of least privilege**: Users get minimum necessary permissions
- **Assume breach**: Design for containment and response

**Controls implemented**:
- Conditional Access policies blocking risky logins
- Device compliance mandatory for M365 access
- Audit logs tracking all admin actions
- DLP policies preventing sensitive data exfiltration

---

## High Availability & Disaster Recovery

**On-premises redundancy**:
- Secondary DC in Azure for failover
- File server replication to Azure storage
- Automated daily backups with quarterly restore testing

**Cloud redundancy (M365 managed)**:
- 99.9% uptime SLA
- Geo-distributed datacenters
- Automatic database failover
- 93-day mailbox soft-delete recovery

**Network redundancy**:
- Site-to-Site VPN with network failover
- ISP backup connectivity (optional)
- Azure front-end load balancing

---

## Governance & Compliance

**Data governance**:
- Classification labels (Public, Internal, Confidential, Restricted)
- DLP rules preventing external PII leakage
- Retention policies (90-day audit logs, 7-year legal hold)
- eDiscovery for litigation holds

**Access governance**:
- Role-based access control (RBAC) per department
- Quarterly access reviews and attestations
- Privileged Identity Management for admins
- Group Policy security baseline on-premises

---

# Project Folder Structure

```
00-planning/                           → Project roadmap, requirements, security design
01-architecture/                       → Hybrid infrastructure design & topology
02-phase-1-microsoft-365/              → Tenant, users, licenses, email, security
03-phase-2-security/                   → Security policies, threat protection, DLP
04-phase-3-collaboration/              → SharePoint, OneDrive, Teams, governance
05-phase-4-monitoring/                 → Logging, alerts, compliance monitoring
06-phase-5-hybrid-identity/            → AD DS + Entra ID sync, hybrid setup
07-phase-6-high-availability/          → Backup, redundancy, disaster recovery
08-phase-7-azure-infrastructure/       → VNets, VPN, connectivity
09-phase-8-workload-migration/         → Move workloads to Azure
10-phase-9-file-services/              → File sharing, multi-site access
11-phase-10-rbac/                      → Role-based access control
12-phase-11-endpoint-mgmt/             → Intune, device enrollment, compliance
13-automation/                         → PowerShell scripts for deployment
14-reference/                          → Security best practices, reference docs
```

---

# Quick Start Guide

## Prerequisites

- Azure subscription with owner/contributor access
- On-premises domain admin credentials
- Microsoft 365 tenant (E3 or E5 licenses)
- Network connectivity & firewall access
- Administrative workstation (Windows 10/11 or macOS)

## Phase Overview (Logical Sequence, Not Timeline)

### Phase 1: M365 Deployment
- Create tenant, configure domain
- Add users and assign E3/E5 licenses
- Configure Exchange, SharePoint, Teams

### Phase 2: Security Hardening
- Enable MFA for all admin accounts
- Configure Conditional Access rules
- Deploy DLP policies and threat protection

### Phase 3: Hybrid Identity
- Install Azure AD Connect
- Configure password hash sync
- Test on-premises + cloud SSO

### Phase 4: Azure Infrastructure
- Create VNet and subnets
- Provision secondary DC in Azure
- Configure Site-to-Site VPN

### Phase 5: Governance & Compliance
- Configure Purview retention policies
- Set up audit logging and eDiscovery
- Document access control procedures

### Phase 6: Device Management
- Enroll devices in Intune
- Deploy compliance policies
- Configure conditional app launching

---

# Support & Troubleshooting

## Common Issues & Solutions

### Issue: Users can't SSO to Teams from on-premises workstation
**Cause**: Azure AD Connect not syncing or Conditional Access blocking.
**Solution**:
1. Verify Azure AD Connect sync status (should show "Connected")
2. Check Conditional Access policies in Entra > Security > Conditional Access
3. Review audit logs for blocked sign-in reasons
4. Test from a different device or network

### Issue: File server shares not accessible after VPN setup
**Cause**: NSG rules blocking SMB traffic or DNS not resolving.
**Solution**:
1. Verify Network Security Group allows port 445 (SMB)
2. Check DNS forwarding in on-prem environment
3. Test connectivity: `nslookup fileserver.company.local` from Azure VM
4. Review VPN connection status and routing tables

### Issue: M365 audit logs not appearing or retention not working
**Cause**: Audit logging not enabled or retention policy misconfigured.
**Solution**:
1. Verify audit logging enabled: M365 > Compliance > Audit (search for "Audit log search on or off")
2. Check retention policy scope in Purview > Data lifecycle management
3. Verify user/admin roles have permission to configure policies
4. Allow 24 hours for policy application

---

# Why This Architecture Works for nig-e-mart

1. **Control**: On-premises identity and file storage remain under local administration
2. **Agility**: Cloud services (M365) provide rapid deployment and scalability
3. **Security**: Defense-in-depth with network, identity, and data layers
4. **Compliance**: Audit trails, retention policies, and access controls meet regulatory needs
5. **Resilience**: Redundancy at every layer (identity, storage, compute)
6. **Cost efficiency**: Leverage cloud economies without over-provisioning on-premises

---

# Deployment Approach

This project uses a **phased, modular approach**:

✓ Each phase builds on prior phases  
✓ Phases can be repositioned based on business priorities  
✓ PowerShell automation reduces manual effort  
✓ Security is integrated throughout (not added at the end)  
✓ Monitoring enables rapid issue detection and resolution  

---

# Conclusion

The hybrid infrastructure for nig-e-mart provides a modern, secure, and scalable foundation for cloud adoption while maintaining on-premises control where needed. By following this deployment guide and best practices, nig-e-mart can achieve a robust, compliant, and resilient enterprise IT environment.

**Key success factors**:
- Executive sponsorship and clear business objectives
- Dedicated deployment team with cloud + on-prem skills
- Rigorous testing and validation at each phase
- User communication and training on new tools
- Continuous monitoring and optimization post-deployment

---

# License

[Internal use only - nig-e-mart proprietary documentation]

---

**Document Version**: 2.0  
**Last Updated**: March 4, 2026  
**Notes**: Merged baseline architecture with enterprise deployment best practices. Emphasizes hybrid approach, zero trust, and business continuity. Excludes timeline estimates to allow flexible implementation.
