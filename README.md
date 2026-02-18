# Hybrid Microsoft Azure & Microsoft 365 Infrastructure Lab

### Cloud Administration Capstone – Unified Architecture & Identity Deployment

---

## Project Overview

This project demonstrates the design, deployment, and hardening of a secure, enterprise-grade hybrid cloud infrastructure integrating on-premises Active Directory with Microsoft Azure and Microsoft 365 services.

The lab environment simulates a real-world enterprise modernization initiative involving hybrid identity, secure network connectivity, workload migration, cloud-native application deployment, device management, and governance enforcement. The architecture follows Microsoft best practices for Zero Trust security, least-privilege access control, high availability, and operational monitoring.

The solution integrates:

* On-premises Active Directory Domain Services (AD DS)
* Azure Entra ID (formerly Azure AD)
* Microsoft 365 tenant services
* Azure IaaS and PaaS workloads
* Hybrid identity synchronization
* Site-to-site VPN connectivity
* Cloud security, monitoring, and disaster recovery

This repository represents a production-style implementation and documentation of hybrid cloud administration competencies.

---

# Architecture Overview

The environment is built using a layered hybrid architecture composed of identity, networking, compute, security, governance, and monitoring components.

---

## 1. Hybrid Identity Architecture

Hybrid identity is implemented by integrating:

* **Active Directory Domain Services (AD DS)**
* **Azure Entra ID**
* **Azure AD Connect**

### Identity Design

* On-prem AD DS acts as the authoritative identity source.
* Azure AD Connect synchronizes users, groups, and password hashes to Entra ID.
* Hybrid authentication enables seamless Single Sign-On (SSO).
* 20+ user accounts are synchronized to the cloud directory.

### Governance Controls

* Multi-Factor Authentication (MFA)
* Conditional Access policies
* Privileged Identity Management (PIM)
* Passwordless authentication
* Quarterly access review framework
* Least-privilege RBAC enforcement

This configuration ensures identity consistency across on-premises and cloud workloads while enforcing Zero Trust principles.

---

## 2. Azure Network Architecture

The cloud infrastructure is deployed within an Azure Virtual Network (VNet) using segmented subnets for workload isolation.

### Subnet Segmentation

* Web Subnet
* Application Subnet
* Database Subnet
* Management Subnet

### Network Security Components

* Network Security Groups (NSGs)
* Azure Firewall with rule-based filtering
* Azure Bastion for secure administrative access
* Site-to-Site VPN for encrypted connectivity between on-prem and Azure

The Site-to-Site VPN establishes secure IPsec tunneling between the on-premises environment and Azure, enabling hybrid resource communication without exposing private infrastructure to the public internet.

---

## 3. Compute & Application Layer

### Infrastructure-as-a-Service (IaaS)

* Azure Virtual Machines for Web and Application tiers
* Azure Load Balancer for high availability
* Availability Zones for redundancy

### Platform-as-a-Service (PaaS)

* Azure App Service deployed with Managed Identity
* Azure SQL Database secured with Private Endpoint
* Private DNS integration for internal resolution

The App Service uses Managed Identity to securely access Azure resources (such as storage or database services) without storing credentials in configuration files.

---

## 4. Microsoft 365 Integration

The Microsoft 365 tenant is configured with enterprise-grade security and collaboration services.

### Services Configured

* Exchange Online
* SharePoint Online
* Microsoft Defender for Identity and Email Protection
* Microsoft Intune for endpoint management

### Endpoint Management

* 15+ endpoints enrolled in Microsoft Intune
* Compliance policies enforced
* Device configuration baselines applied
* Conditional Access integrated with device compliance

This ensures secure access to corporate resources from managed devices only.

---

## 5. Security & Governance Model

Security is implemented across identity, network, compute, and monitoring layers.

### Identity Security

* MFA enforced for privileged roles
* PIM with Just-in-Time (JIT) elevation
* Conditional Access based on risk and device state

### Network Security

* Azure Firewall traffic inspection
* NSG segmentation
* Private endpoints for database workloads
* Bastion-based RDP/SSH access

### Data Protection

* Defender email filtering and identity protection
* Secure VPN tunneling
* Centralized logging and auditing

---

## 6. Backup, Disaster Recovery & Monitoring

Operational resilience is implemented using:

* Azure Backup for VM protection
* Cross-region replication via Azure Site Recovery
* Azure Monitor and Log Analytics for performance and security tracking
* Alerting rules for CPU, network, and suspicious login activity

This ensures business continuity and proactive incident detection.

---

# Implementation Highlights

* Designed and deployed hybrid identity synchronization using Azure AD Connect
* Configured secure VNet with subnet isolation and NSGs
* Implemented Azure Firewall and Bastion secure access
* Deployed highly available web and application tiers
* Configured Azure SQL Database with Private Endpoint
* Enabled MFA, Conditional Access, and Privileged Identity Management
* Enrolled and managed endpoints using Microsoft Intune
* Configured backup, site recovery, and centralized monitoring

---

# Technologies Used

* Microsoft Azure (VNets, VM, VPN Gateway, Firewall, RBAC)
* Azure Entra ID
* Active Directory Domain Services
* Azure AD Connect
* Microsoft 365 (E3/E5 licensing model)
* Exchange Online
* Microsoft Defender
* Microsoft Intune
* Azure App Service
* Azure SQL Database
* PowerShell Automation

---

# Outcomes & Measurable Results

* 20+ synchronized hybrid identities
* 15+ Intune-managed endpoints
* Secure site-to-site VPN connectivity
* High-availability web and application tiers
* Enforced Zero Trust identity and access controls
* Production-style documentation and automation workflows

---

# Skills Demonstrated

* Hybrid Identity & Entra ID Governance
* Azure Networking & Security Administration
* Infrastructure Deployment & High Availability Design
* Cloud Security Hardening & RBAC Implementation
* Endpoint Management with Intune
* Backup & Disaster Recovery Planning
* Monitoring, Logging & Operational Visibility
* PowerShell-Based Automation

---

# Disclaimer

This environment is built strictly for educational, demonstration, and portfolio purposes. No real organizational data is used. The infrastructure simulates enterprise architecture patterns aligned with Microsoft best practices and cloud governance frameworks.


