# Hybrid Microsoft Azure & Microsoft 365 Infrastructure Lab

### Enterprise-Grade Implementation Guide – Comprehensive Hybrid Cloud Architecture

---

## Project Overview

This project provides a complete, enterprise-grade implementation guide for designing and deploying a secure hybrid Microsoft infrastructure environment. It represents a comprehensive capstone project combining Microsoft 365 tenant deployment, Azure infrastructure integration, on-premises Active Directory synchronization, security hardening, device management, and operational governance.

This is not merely a technical lab; it is a **professional implementation blueprint** suitable for:

* **Portfolio presentation** demonstrating advanced cloud administration competencies
* **Technical design documentation** for enterprise architecture review
* **Implementation reference guide** enabling another engineer to fully reproduce the environment from start to finish

The project integrates:

* **Microsoft 365 Tenant** with security baselines, bulk user provisioning, licensing, and group-based access control
* **On-Premises Active Directory** with proper OU structure, group policy, and DNS configuration
* **Azure Entra ID & Azure AD Connect** for enterprise hybrid identity synchronization
* **Azure Infrastructure** with virtual networks, Site-to-Site VPN, and Site Recovery
* **Hybrid Workload Integration** including legacy application migration and file services
* **Security & Compliance** spanning Microsoft Defender, DLP, MFA, Conditional Access, and RBAC
* **High Availability & Disaster Recovery** with secondary domain controllers, replication, and failover validation
* **Endpoint Management** via Microsoft Intune with compliance policies and security baselines
* **Operational Monitoring & Governance** with audit logging, alerts, and best practice frameworks

This repository demonstrates professional-grade hybrid cloud administration competencies aligned with Microsoft enterprise best practices.

---

# Implementation Guide Structure

This project follows a comprehensive 11-phase implementation methodology designed to progressively build a secure, resilient hybrid infrastructure from identity foundations through operational governance. Each phase includes:

* **Detailed step-by-step procedures** with command-line examples
* **Architectural reasoning** explaining design decisions
* **Security justifications** based on best practices
* **Validation & verification steps** to confirm successful implementation
* **Troubleshooting guidance** for common failure scenarios
* **Operational considerations** for long-term management

---

## Phase Architecture Overview

The hybrid infrastructure is organized into interconnected layers:

**Identity Layer**: On-premises Active Directory Domain Services synchronized with Azure Entra ID via Azure AD Connect, providing SSO and consistent identity governance across on-premises, Azure, and Microsoft 365.

**Networking Layer**: Azure Virtual Networks with segmented subnets, Network Security Groups, Azure Firewall, and Site-to-Site VPN connecting on-premises infrastructure to Azure, ensuring encrypted, secure communication across hybrid boundaries.

**Compute Layer**: Domain-joined virtual machines deployed across on-premises (via Proxmox hypervisor) and Azure (IaaS VMs), including domain controllers for redundancy, file servers for departmental shares, and application servers hosting legacy workloads.

**Microsoft 365 Layer**: Tenant-wide security baselines, bulk-provisioned users in departmental groups, Exchange Online for email, SharePoint Online for collaboration, and Microsoft Defender for threat protection.

**Security Layer**: Multi-layered defense including MFA, Conditional Access policies, Data Loss Prevention (DLP), email threat protection (Safe Links, Safe Attachments), RBAC with least-privilege principles, and continuous monitoring.

**Management Layer**: Microsoft Intune for endpoint compliance, Azure AD Premium for advanced identity governance, centralized audit logging, Service Health monitoring, and operational alert policies.

**Disaster Recovery Layer**: Secondary domain controller in Azure with replication, Azure Site Recovery for critical VM failover, backup policies, and documented recovery procedures.

---

# Implementation Phases


## Phase 1: Microsoft 365 Tenant Deployment and Configuration

This foundational phase establishes the Microsoft 365 tenant and configures enterprise-grade security, identity, and licensing frameworks. A new tenant is created and configured with tenant-wide security baselines aligned with Microsoft 365 Enterprise Administration objectives.

**Key Objectives:**
* Create and initialize a new Microsoft 365 tenant with appropriate domain configuration
* Implement tenant-wide security baselines and data protection defaults
* Bulk import 10+ users via CSV, including proper organizational attributes (job title, department, profile pictures, contact information)
* Assign Microsoft 365 E3 or E5 licenses appropriately
* Create departmental M365 Groups (IT, HR, Operations, Marketing, Finance)
* Configure group-based access control for SharePoint and Teams

**Conceptual Foundation:**
The identity model in Microsoft 365 extends beyond simple user accounts to encompass group-based access control and delegated administration. Licensing strategy directly impacts feature availability and security capabilities; E5 includes advanced threat protection and compliance features absent in E3. Modern authentication principles such as OAuth 2.0 and conditional token issuance provide security advantages over legacy authentication methods.

---

## Phase 2: Security and Compliance

Microsoft 365 security is implemented through defense-in-depth using multiple protection layers. This phase configures advanced threat protection, data loss prevention, insider risk management, and unified auditing to establish a Zero Trust security posture.

**Key Objectives:**
* Improve Secure Score through guided remediation recommendations
* Configure Microsoft Defender for Office 365 (Safe Links, Safe Attachments, anti-phishing, anti-malware)
* Implement message encryption for sensitive communications
* Create mail flow rules for automatic encryption of internal email
* Deploy Data Loss Prevention (DLP) policies for sensitive data types
* Enable Insider Risk Management for policy violation detection
* Configure Unified Audit Logging for compliance tracking

**Security Justifications:**
Zero Trust security architecture assumes no implicit trust and requires verification at every layer. Email represents a primary attack vector; Safe Links detonates URLs in isolated sandboxes to detect zero-day exploits, while Safe Attachments analyzes file behavior before delivery. DLP policies prevent accidental or intentional disclosure of sensitive data (PII, credit cards, IP) by detecting patterns and enforcing encryption or deletion. Insider Risk Management detects policy violations and unusual data access patterns, addressing internal threat vectors often overlooked in perimeter-focused security.

---

## Phase 3: Collaboration and Governance

This phase configures SharePoint Online and OneDrive as the foundation for secure content collaboration with role-based permissions, lifecycle management, and retention policies.

**Key Objectives:**
* Create SharePoint team sites for IT, HR, and Marketing departments
* Configure document libraries with role-based permissions and approval workflows
* Enable versioning and content approval for sensitivity control (particularly HR)
* Restrict OneDrive external sharing to approved domains only
* Implement 5-year retention policies for OneDrive content
* Configure lifecycle rules for automatic archival of inactive files
* Configure Viva Engage (Yammer) for internal-only communication

**Governance Framework:**
Data lifecycle management ensures organizations balance accessibility with compliance and cost. Retention policies specify how long data must be available before archival or deletion based on regulatory obligations. Approval workflows for sensitive content (HR, finance) enforce review before publication, preventing unauthorized disclosure. Information governance extends beyond compliance to include data quality, accessibility, and cost optimization through tiered storage strategies.

---

## Phase 4: Monitoring, Reporting, and Operational Oversight

Operational visibility requires comprehensive logging, alerting, and reporting mechanisms. This phase establishes ongoing monitoring for compliance, incident detection, and performance tracking.

**Key Objectives:**
* Configure audit log searches for administrative and user activities
* Create alert policies for multiple failed login attempts (lateral movement indicator)
* Configure mass file deletion alerts (data exfiltration indicator)
* Set DLP violation alerts for policy breaches
* Generate weekly user activity and adoption reports via Microsoft 365 reports
* Automate monthly executive dashboards using Power Automate
* Configure Service Health alerts to monitor platform stability

**Operational Best Practices:**
Proactive monitoring enables incident detection before impact broadens. Failed login alerts detect both credential attacks and user issues. Mass file deletion patterns correlate with data exfiltration scenarios or malicious insider activity. DLP violation trends identify inadequate user training or policy misalignment, enabling preventive action. Service Health monitoring provides early awareness of platform issues affecting business operations, enabling proactive communication and workaround deployment.

---

## Phase 5: Hybrid Identity Deployment

This critical phase establishes on-premises Active Directory and synchronizes identities to Microsoft 365, enabling seamless authentication and consistent user governance across hybrid boundaries.

**Key Objectives:**
* Deploy Windows Server VM on Proxmox hypervisor infrastructure
* Install Active Directory Domain Services and promote to domain controller
* Configure DNS with proper zone delegation and conditional forwarders
* Deploy Azure AD Connect on dedicated domain-joined server
* Configure password hash synchronization with on-premises AD
* Validate hybrid identity login from cloud and on-premises devices
* Deploy file server for departmental file shares
* Deploy IIS server hosting legacy HR application

**Hybrid Identity Architecture:**
Hybrid identity integrates on-premises Active Directory as the authoritative identity source with Azure Entra ID (cloud directory) via Azure AD Connect. When a user changes their password on-premises, Azure AD Connect captures the hash and synchronizes to Entra ID, enabling seamless authentication to cloud services (Exchange Online, SharePoint, Teams) without separate credential management. Password hash sync provides security advantages over pass-through authentication by avoiding direct exposure of on-premises infrastructure and enabling cloud-based anomaly detection and threat protection unavailable to on-premises authentication systems.

Directory synchronization mechanics employ incremental delta sync after initial full synchronization, minimizing bandwidth impact. Specifically, Azure AD Connect maintains a watermark of the last synchronization point on the on-premises directory and queries only changed attributes since that checkpoint, dramatically reducing synchronization overhead for large directories with frequent changes. Phone number updates, job title changes, and group membership modifications flow automatically to cloud services within minutes, maintaining identity consistency.

---

## Phase 6: High Availability and Redundancy

Enterprise infrastructure requires elimination of single points of failure. This phase deploys redundant domain controllers, configures replication, and validates failover scenarios.

**Key Objectives:**
* Deploy secondary domain controller in Azure and join on-premises domain via Site-to-Site VPN
* Configure Active Directory replication across on-premises and Azure environments
* Validate replication latency and conflict resolution
* Test domain controller failover scenarios
* Document FSMO role and GC (Global Catalog) distribution
* Migrate file server to Azure for centralized management
* Migrate legacy HR application server to Azure

**Redundancy Best Practices:**
FSMO (Flexible Single Master Operations) roles include Schema Master, Domain Naming Master, Infrastructure Master, RID Master, and PDC Emulator. While most AD operations are multi-master, these specific roles require single-master architecture for consistency. Distributing FSMO roles across multiple domain controllers prevents single controller failures from blocking administrative operations. In a hybrid environment, deploying a secondary domain controller in Azure ensures domain authentication continues even if on-premises infrastructure fails, supporting business continuity. When an on-premises domain controller becomes unavailable, Azure-based replicas handle authentication, device authentication, and policy application for cloud-hybrid resources with minimal disruption.

---

## Phase 7: Azure Infrastructure Integration

Secure connectivity between on-premises and cloud infrastructure requires encrypted, authenticated VPN tunnels. This phase establishes Site-to-Site VPN and disaster recovery infrastructure.

**Key Objectives:**
* Configure Azure VPN Gateway and on-premises VPN endpoint with IPsec/IKEv2
* Establish Site-to-Site VPN tunnel with encryption and authentication
* Configure conditional routing to use VPN for on-premises traffic
* Deploy Azure Site Recovery to enable VM failover
* Execute test failover procedures validating recovery capabilities
* Document RTO (Recovery Time Objective) and RPO (Recovery Point Objective) for critical workloads

**VPN Gateway Architecture:**
VPN Gateway components include local network gateway (representing on-premises network), virtual network gateway (Azure side), and connection resource binding them with IPsec configuration. IPsec (Internet Protocol Security) provides encryption using algorithms such as AES-256, integrity verification using SHA-256 hashing, and mutual authentication via pre-shared keys or certificates. The tunnel remains persistent, re-establishing automatically if disrupted. Because only encrypted traffic traverses the internet, on-premises users can access Azure VMs using private IP addresses as if locally attached, eliminating the complexity of managing public interfaces for hybrid resources.

**Disaster Recovery Strategy:**
Azure Site Recovery enables continuous replication of on-premises VMs to Azure, creating near-real-time copies for failover. RTO quantifies maximum acceptable outage before business impact becomes unacceptable; RPO quantifies maximum acceptable data loss. A 15-minute RTO with 1-hour RPO indicates business can tolerate 15 minutes for failover and accept up to 1 hour of recent changes being lost. Site Recovery automatically maintains recovery points, enabling "point-in-time" recovery that allows rolling back to moments before corruption or malicious activity. Failover can be tested without affecting production, de-risking recovery procedures through regular drills.

---

## Phase 8: Legacy Application Migration

Enterprise environments typically contain legacy applications that cannot be redeveloped immediately. This phase demonstrates safe migration of existing applications into Azure infrastructure.

**Key Objectives:**
* Migrate Hyper-V VM hosting static HR legacy application to Azure IaaS
* Validate networking and DNS resolution for migrated application
* Confirm application accessibility from domain-joined clients
* Document application dependencies and compatibility issues
* Establish baseline performance and monitoring

**Lift-and-Shift Migration Strategy:**
Lift-and-shift (also called "rehost") moves existing applications into Azure with minimal modifications. This approach minimizes risk and timeline compared to refactoring or rebuilding applications. On-premises VMs are converted to Azure-compatible formats (VHD) using Azure Site Recovery or Hyper-V Manager, then instantiated as Azure VMs. The migration preserves existing OS patches, application configurations, and data structures, reducing testing scope. However, lift-and-shift forgoes cloud-native optimizations such as managed databases, auto-scaling, and serverless frameworks. Applications moved to IaaS VMs retain full OS patching responsibilities, unlike PaaS services that abstract infrastructure maintenance. For legacy HR applications with uncertain support lifecycles or unstable vendor relationships, the stability and control of IaaS provides preferable risk profiles compared to forced modernization.

---

## Phase 9: File Services and Access Control

Departmental file shares require proper segmentation, NTFS permissions, and share protocol access control. This phase establishes file access governance with role-based controls.

**Key Objectives:**
* Create four departmental file shares (IT, HR, Operations, Finance)
* Host one file share on secondary cloud VM for redundancy
* Configure NTFS permissions (file-level access control)
* Configure Share permissions (network-level access control)
* Establish cross-group access policies (e.g., Finance reads Operations reports)
* Validate remote access from domain-joined devices over VPN

**File Access Control Architecture:**
NTFS permissions operate at the file system level and enforce access regardless of access method (local console, SMB network, WebDAV, etc.). Share permissions control network-level SMB access and are evaluated first; the resulting permission is the intersection of Share and NTFS permissions. IT staff accessing file share data must have both appropriate NTFS ACLs AND corresponding Share permission. Least privilege enforcement means granting only necessary access; HR staff might have read-only access to Operations reports but no write permission preventing accidental modification. Groups (Active Directory security groups) simplify permission management across multiple users; rather than granting individual permissions to each user, permissions are assigned to groups (Finance Auditors, HR Admins) and users join appropriate groups. This approach scales to hundreds of users without permission proliferation.

---

## Phase 10: RBAC Design and Least Privilege

Azure and Microsoft 365 implement role-based access control (RBAC) to enforce principle of least privilege across administrative functions. This phase designs and implements RBAC for multiple administrative personas.

**Key Objectives:**
* Implement Azure RBAC roles: Virtual Machine Contributor (manage VMs), Billing Administrator (cost management), Security Administrator (security configuration), Help Desk Operator (password reset, support)
* Assign roles at appropriate scopes (tenant, subscription, resource group, individual resource)
* Document role justification and scope limitation
* Implement PIM (Privileged Identity Management) for just-in-time elevation of privileged roles
* Validate audit trails for privileged operations

**Principle of Least Privilege:**
Organizations often over-provision permissions for convenience, granting Contributor or Owner roles broadly across teams. This violates least privilege by enabling accidental or malicious actions beyond necessary job functions. Proper RBAC applies analytical discipline: Help Desk staff need password reset permissions but should not manage virtual infrastructure, delete storage accounts, or modify billing settings. Virtual Machine Administrators need permissions to manage compute resources but should not modify identity policies or security settings. Billing Administrators require cost analysis capabilities but must not access application data or security configurations. This separation prevents privilege creep and contains blast radius if credentials are compromised.

**Scope Levels and Governance:**
Azure scope hierarchy flows from broad to narrow: Management Group (organizational unit controlling multiple subscriptions) → Subscription (billing boundary) → Resource Group (collection of related resources) → Individual Resource. Assigning roles at Management Group level applies to all containing subscriptions and resources, simplifying administration but reducing control granularity. Assigning at Resource Group level grants access to all resources within a group, enabling team-level permissions. Assigning at individual resource level enables precise control but increases administrative overhead. Well-designed governance typically assigns roles at Resource Group level for team-based access and individual resource level only for exception scenarios requiring unusual permissions.

---

## Phase 11: Endpoint Management and Compliance

Modern security requires managing hundreds of organizational devices with consistent security policies and compliance verification. This phase deploys Microsoft Intune as the Mobile Device Management (MDM) and Computer Management (MCM) platform.

**Key Objectives:**
* Configure Microsoft Intune as the enterprise device management platform
* Create device compliance policies enforcing security requirements (firewall, antivirus, encryption)
* Deploy security baselines (CIS benchmarks for Windows 10/11) via Intune profiles
* Implement Conditional Access policies tied to device compliance
* Deploy endpoint protection configuration profiles
* Validate compliance policies enforce OS updates and antivirus requirements

**Conditional Access Logic:**
Conditional Access policies dynamically evaluate context (user identity, device state, location, application) and enforce access decisions. Example policy: "Allow access to Exchange Online only from managed, compliant devices OR from registered devices using MFA." This prevents malicious actors with valid credentials from accessing email from non-compliant personal devices. Another example: "Block access from unfamiliar locations unless MFA with trusted device is confirmed." Conditional Access integrates device compliance evaluation: devices reporting non-compliant state (missing security patches, disabled firewall) are blocked from accessing sensitive resources regardless of user credentials. This creates security posture awareness where non-compliant devices cannot access resources until remediation (applying patches, enabling encryption) completes.

**Device Compliance vs Configuration Profiles:**
Device compliance policies define requirements and assess pass/fail status (compliant vs non-compliant). Configuration profiles deploy specific settings (firewall rules, whitelisted apps, encryption settings). Compliance policies answer "Does the device meet minimum security requirements?" Configuration profiles answer "What specific settings does this device need?" A single device might be compliant even with varying configurations, but Conditional Access policies use compliance status for access decisions. Configuration profiles ensure standardized settings across organizational devices, reducing rogue configurations that bypass security controls. Together, compliance policies establish minimum security thresholds, and configuration profiles ensure consistent hardening across devices.

---

# Implementation Outcomes



Upon completion of all 11 phases, the following measurable outcomes are achieved:

* **Microsoft 365**: E3/E5 tenant with 10+ bulk-provisioned users, zero-trust security baseline, Defender threat protection, DLP policies, audit logging, departmental groups with role-based access control
* **On-Premises Infrastructure**: Domain-joined Windows infrastructure running Active Directory with proper OU hierarchy, group policy baselines, DNS configuration
* **Hybrid Identity**: 20+ synchronized identities between on-premises AD and Azure Entra ID with seamless SSO, consistent authentication across Microsoft 365
* **Azure Infrastructure**: Virtual networks with subnet segmentation, Site-to-Site VPN encryption, Secondary domain controller replicating with on-premises
* **Backup & Recovery**: Azure Site Recovery configured for failover testing, documented RTO/RPO targets for critical workloads
* **File Services**: Four departmental file shares with NTFS/Share permission controls, least privilege enforcement, cross-group access policies
* **Endpoint Management**: 15+ devices enrolled in Intune with compliance policies, security baselines, Conditional Access enforcement
* **Security & Governance**: Multi-layered RBAC (Help Desk, VM Admin, Billing Admin, Security Admin), MFA, Conditional Access, DLP, audit trails
* **Monitoring & Compliance**: Centralized audit logging, alert policies for suspicious activities, Service Health monitoring, ownership reporting

---

# Documentation Structure

This implementation includes:

* **Detailed Phase Implementation Guides** – Step-by-step procedures with PowerShell and Azure CLI command examples
* **Architecture Diagrams** – Textual descriptions and visual representations of infrastructure components and data flows
* **Security Justification Documentation** – Reasoning behind each security control referenced to Microsoft frameworks and industry standards
* **Validation Procedures** – Test cases and verification steps after each phase to confirm successful implementation
* **Troubleshooting Guides** – Common failure scenarios with resolution steps
* **Operational Runbooks** – Ongoing maintenance, monitoring, and escalation procedures
* **RBAC Implementation** – Detailed role assignments, scope limitations, and governance policies
* **Disaster Recovery Plans** – Backup procedures, failover tests, and recovery documentation

---

# Technologies & Platforms

This implementation leverages:

* **Microsoft 365** (Tenant Creation, Exchange Online, SharePoint Online, Microsoft Teams)
* **Azure Entra ID** (Cloud Directory, Conditional Access, MFA)
* **Active Directory Domain Services** (On-Premises Identity, Group Policy, DNS)
* **Azure AD Connect** (Hybrid Identity Synchronization, Password Hash Sync)
* **Microsoft Azure** (Virtual Networks, VPN Gateway, Virtual Machines, Site Recovery, Azure Firewall)
* **Microsoft Defender for Office 365** (Safe Links, Safe Attachments, Anti-Phishing, Anti-Malware)
* **Microsoft Intune** (Device Management, Compliance Policies, Security Baselines)
* **Proxmox VE** (On-Premises Hypervisor Infrastructure)
* **PowerShell & Azure CLI** (Automation, Bulk User Import, Infrastructure as Code)
* **Data Loss Prevention (DLP)** (Policy Definition, Classification, Encryption)
* **Azure Resource Manager (ARM)** (Infrastructure Deployment and Configuration)
* **Audit & Compliance Tools** (Unified Audit Logging, Alert Policies, Compliance Manager)

---

# Skills Demonstrated

This comprehensive implementation demonstrates mastery of:

## Identity & Access Management
* Hybrid identity architecture design and implementation
* Azure Entra ID and Conditional Access policy configuration
* RBAC with least-privilege principles at multiple scope levels
* Multi-factor authentication enforcement
* Just-in-time privileged access via PIM
* Directory synchronization and password hash management

## Microsoft 365 Administration
* Tenant creation and security baseline configuration
* Bulk user provisioning via CSV import with organizational attributes
* Licensing strategy (E3 vs E5 differentiation)
* Microsoft 365 Group creation and delegation
* SharePoint site creation with role-based permissions
* Exchange Online security policies
* DLP policy creation and testing

## Security & Threat Protection
* Zero Trust architecture implementation
* Microsoft Defender for Office 365 configuration
* Multi-layer email threat protection
* Insider Risk Management policy design
* Data Loss Prevention strategy
* Compliance audit logging and monitoring
* Network segmentation and encryption

## Azure Infrastructure
* Virtual Network design with subnet segmentation
* Site-to-Site VPN configuration with IPsec
* Azure Site Recovery setup and failover testing
* VM deployment and configuration
* Resource Group organization and governance
* Azure Firewall rule implementation

## On-Premises Infrastructure
* Active Directory Domain Services deployment and configuration
* Group Policy design and application
* DNS configuration for hybrid scenarios
* Domain Controller redundancy and replication
* FSMO role management
* File server configuration with NTFS/Share permissions

## Endpoint Management
* Microsoft Intune device enrollment and management
* Device compliance policies and security baselines
* Conditional Access integration with device state
* Configuration profile deployment
* Compliance monitoring and reporting

## Disaster Recovery & High Availability
* High availability architecture design
* Domain Controller redundancy across cloud/on-premises
* Backup and recovery strategy development
* RTO/RPO definition and testing
* Failover procedure validation
* Business continuity planning

## Automation & Scripting
* PowerShell script development for bulk operations
* Azure CLI commands for infrastructure deployment
* Automation of repetitive administrative tasks
* Infrastructure as Code principles

## Governance & Operations
* Audit logging and compliance monitoring
* Alert policy configuration and threshold tuning
* Operational runbook development
* Incident response procedures
* Service Health monitoring
* Ongoing operational visibility and reporting

---

# Repository Structure

```
├── 01-architecture/              # High-level design documents
├── 02-documentation/             # Project planning and requirements
│   ├── 01-project-overview.md
│   ├── 02-requirements.md
│   ├── 03-assumptions-and-scope.md
│   ├── 04-security-design.md
│   ├── 05-rbac-model.md
│   └── 06-lessons-learned.md
├── 03-identity/                  # Identity configuration guides
│   ├── 01-on-prem-ad/           # On-premises AD configuration
│   ├── 02-entra-id/             # Azure Entra ID setup
│   └── 03-lifecycle/            # User provisioning and deprovisioning
├── 04-networking/                # Network configuration
│   ├── azure-vnet.md
│   ├── dns-and-routing.md
│   └── site-to-site-vpn.md
├── 05-microsoft-365/             # M365 configuration guides
│   ├── defender-security.md
│   ├── exchange-online.md
│   ├── licensing-e3-e5.md
│   ├── sharepoint-branding.md
│   └── tenant-setup.md
├── 06-device-management/         # Intune and endpoint configuration
│   ├── compliance-policies.md
│   ├── device-profiles.md
│   ├── endpoint-security.md
│   └── intune-enrollment.md
├── 07-automation/                # PowerShell scripts and automation
│   ├── scripts-readme.md
│   └── powershell/
│       ├── add-user-report.ps1
│       ├── cleanup-disabled-users.ps1
│       ├── create-users.ps1
│       └── license-assignment.ps1
├── 08-security/                  # Security policies and procedures
│   ├── best-practices.md
│   ├── defender-policies.md
│   └── identity-protection.md
└── README.md
```

---

# How to Use This Guide

1. **Review Project Overview**: Start with 02-documentation files to understand project scope, assumptions, and requirements
2. **Study Architecture**: Reference 01-architecture for high-level design and 04-networking for infrastructure layout
3. **Follow Implementation Phases**: Work through 11 phases sequentially, using documentation in 03-identity, 05-microsoft-365, 06-device-management as needed
4. **Validate Steps**: After each phase, complete validation procedures documented in respective guides
5. **Execute Automation**: Use PowerShell scripts in 07-automation for repetitive tasks; modify as needed for your environment
6. **Implement Security**: Configure security baselines and policies per 08-security best practices
7. **Monitor & Document**: Maintain operational dashboards and documentation for ongoing governance

This guide is designed to be comprehensive enough that another engineer could follow it sequentially and fully reproduce the hybrid infrastructure from start to finish.

---


# Important Disclaimer

This implementation guide is created strictly for **educational, demonstration, and portfolio purposes**. The following apply:

* **No Real Data**: No actual organizational data, PII, or confidential information is included in this environment
* **Lab Environment**: This is a controlled demonstration environment aligned with Microsoft best practices, not a production system
* **Cost Considerations**: Running this environment in Azure and Microsoft 365 incurs cloud subscription costs; budget accordingly and clean up resources when not in use
* **Security Assumptions**: While this implementation follows security best practices, it simulates enterprise patterns rather than addressing all possible threat scenarios
* **Licensing**: Requires Microsoft 365 E3 or E5 subscription and Azure subscription; licensing terms and costs apply
* **Hypervisor Infrastructure**: On-premises components assume access to Proxmox or equivalent hypervisor for VM deployment
* **Support**: This guide is provided as-is without vendor support; refer to official Microsoft documentation for production guidance

This repository demonstrates cloud administration competencies suitable for portfolio presentation, technical interviews, and educational purposes.

---

# Conclusion

This hybrid infrastructure lab represents a comprehensive, enterprise-grade implementation of modern cloud administration principles. By progressing through 11 phases from tenant creation through operational governance, this guide demonstrates:

* Deep understanding of hybrid cloud architecture spanning on-premises and cloud
* Security expertise applying defense-in-depth and Zero Trust principles
* Governance competency implementing RBAC, least privilege, and audit controls
* Operational skill managing complex hybrid environments across cloud and on-premises
* Documentation discipline suitable for enterprise technical design review

The implementation integrates identity, networking, security, collaboration, governance, and disaster recovery into a cohesive, documented system. This guide is comprehensive enough that another cloud engineer could follow it step-by-step and fully reproduce the environment.

**For further questions or clarifications, refer to the detailed phase documentation in the respective folders.**

---

*Last Updated: March 2, 2026*
*Version: 1.0*
