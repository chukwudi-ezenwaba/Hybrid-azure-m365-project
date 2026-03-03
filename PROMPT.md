Below is your **fully consolidated, comprehensive master prompt** combining both previous versions into one structured, enterprise-grade instruction set optimized for GitHub Copilot in VS Code.

You can paste this directly into Copilot Chat inside your project folder.

---

# ✅ COMPREHENSIVE MASTER PROMPT FOR GITHUB COPILOT

---

You are acting as a Senior Cloud Architect, Hybrid Infrastructure Engineer, and Technical Documentation Specialist.

Review all files in the current project folder and use them as contextual reference material.

Using the complete project scope provided below, generate a fully detailed, professional, enterprise-grade implementation guide for this hybrid Microsoft environment.

---

# OUTPUT REQUIREMENTS

The final output must:

1. Be written as a formal technical implementation guide.
2. Be structured in clearly defined phases with logical progression.
3. Provide detailed step-by-step implementation procedures.
4. Include comprehensive conceptual explanations written in well-developed paragraphs (not short bullet points).
5. Explain the architectural reasoning behind each configuration.
6. Justify security decisions using best practices and industry standards.
7. Include command-line examples where applicable (PowerShell, Azure CLI, etc.).
8. Clearly separate:

   * Microsoft 365 configuration
   * Azure infrastructure
   * On-premises infrastructure
9. Include diagrams described textually (logical architecture overview).
10. Include validation and verification steps after each major task.
11. Include troubleshooting guidance for common failure scenarios.
12. Include monitoring, governance, and operational considerations.
13. Include RBAC design justification and least privilege explanation.
14. Include disaster recovery and high availability explanations.
15. Be formatted professionally using Markdown headings and subheadings.
16. Follow this logical flow:

    * Planning
    * Architecture Overview
    * Implementation
    * Validation
    * Monitoring
    * Governance
    * Disaster Recovery
    * Security Review
    * Conclusion and Recommendations
17. Be written in a professional enterprise tone suitable for:

    * Portfolio presentation
    * Technical design documentation (TDD)
    * Enterprise lab implementation guide

The final document should be comprehensive enough that another engineer could follow it from start to finish and fully reproduce the environment.

---

# PROJECT SCOPE

This project consists of designing and implementing a secure hybrid Microsoft enterprise environment.

---

# Phase 1: Microsoft 365 Tenant Deployment and Configuration

* Create a new Microsoft 365 tenant.
* Configure tenant-wide security baselines.
* Align configuration with Microsoft 365 Enterprise Administration and Security & Mobility objectives.
* Bulk import at least 10 users using CSV via Microsoft 365 Admin Center.
* Assign Microsoft 365 E3 or E5 licenses.
* Configure user profiles:

  * Profile pictures
  * Job titles
  * Contact information
  * Organizational attributes
* Create Microsoft 365 Groups for:

  * IT
  * HR
  * Operations
  * Marketing
  * Finance
* Assign users appropriately.
* Configure:

  * HR access to sensitive SharePoint documents.
  * Marketing permissions to create/manage Microsoft Teams.

Include explanation of:

* Identity model
* Licensing impact
* Group-based access control
* Modern authentication principles

---

# Phase 2: Security and Compliance

* Improve Secure Score.
* Configure Microsoft Defender for Office 365:

  * Safe Links
  * Safe Attachments
  * Anti-phishing policies
  * Anti-malware policies
* Configure Microsoft 365 Message Encryption.
* Create mail flow rules to automatically encrypt internal email.
* Implement Data Loss Prevention (DLP) policies.
* Configure Insider Risk Management.
* Enable Unified Audit Logging.

Include detailed explanation of:

* Zero Trust model
* Email threat protection layers
* Data classification and retention strategies
* Compliance and audit importance

---

# Phase 3: Collaboration and Governance

* Create SharePoint sites (IT, HR, Marketing).
* Configure document libraries and role-based permissions.
* Enable versioning and content approval (HR).
* Configure OneDrive:

  * Restrict external sharing.
  * Implement 5-year retention policy.
  * Configure lifecycle rule for inactive files.
* Configure Viva Engage for internal-only communication.

Include conceptual explanation of:

* Data lifecycle management
* Information governance
* Collaboration security risks

---

# Phase 4: Monitoring, Reporting, and Operational Oversight

* Configure audit log searches.
* Configure alert policies for:

  * Multiple failed login attempts
  * Mass file deletions
  * DLP violations
* Generate user activity and usage reports.
* Optionally automate monthly reporting (Power Automate).
* Configure Service Health alerts.
* Explain ongoing operational monitoring best practices.

---

# Phase 5: Hybrid Identity Deployment

* Deploy Windows Server VM on Proxmox.
* Install Active Directory Domain Services.
* Promote to Domain Controller.
* Configure DNS correctly.
* Deploy Azure AD Connect.
* Synchronize on-premises users to Microsoft 365.
* Validate hybrid identity login.
* Deploy file server
* Deploy IIS server hosting legacy HR application

Include detailed explanations of:

* Hybrid identity architecture
* Password hash sync vs pass-through authentication
* Directory synchronization mechanics

---

# Phase 6: High Availability and Redundancy

* Deploy secondary Domain Controller in azure and join on-prem domain.
* Configure replication.
* Validate failover.
* Explain FSMO roles and redundancy best practices.
* Migrate file server to cloud
* Migrate legacy HR server to cloud.

---

# Phase 7: Azure Infrastructure Integration

* Configure Site-to-Site VPN between Azure and on-premises.
* Explain VPN gateway components and IPsec configuration.
* Configure Azure Site Recovery for critical VMs.
* Test failover and recovery procedures.
* Include explanation of disaster recovery strategy and RTO/RPO concepts.

---

# Phase 8: Legacy Application Migration

* Migrate Hyper-V VM hosting static HR legacy application to Azure.
* Validate networking and DNS.
* Confirm application accessibility.
* Explain lift-and-shift migration strategy and risks.

---

# Phase 9: File Services and Access Control

* Create four departmental file shares.
* Host one share on secondary VM.
* Configure NTFS and share permissions.
* Configure cross-group access appropriately.
* Validate remote access from domain-joined devices.

Include explanation of:

* Role-based file access
* NTFS vs Share permissions
* Least privilege enforcement

---

# Phase 10: RBAC Design

Implement Azure and Microsoft 365 RBAC roles for:

* Help Desk Administrators
* Virtual Machine Administrators
* Billing Administrators
* Security Administrators

Explain:

* Principle of least privilege
* Scope levels (tenant, subscription, resource group)
* Role separation and governance design
* Justification for each role assignment

---

# Phase 11: Endpoint Management

* Configure Microsoft Intune.
* Create device compliance policies.
* Deploy security baselines.
* Configure Conditional Access.
* Enforce endpoint protection and configuration profiles.

Explain:

* Conditional Access logic
* Device compliance vs configuration profiles
* Modern endpoint security strategy

---

# FINAL DELIVERABLE EXPECTATION

The final document must:

* Present a complete hybrid enterprise deployment blueprint.
* Demonstrate strong understanding of Microsoft 365, Azure, Active Directory, security, governance, and disaster recovery.
* Be structured, detailed, and technically accurate.
* Include validation steps and troubleshooting guidance.
* Conclude with best practice recommendations and architectural improvement suggestions.

The document must read like a professional enterprise implementation guide suitable for technical review or portfolio presentation.

---

End of prompt.

---
