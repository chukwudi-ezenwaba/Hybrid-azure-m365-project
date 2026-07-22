# Project Plan: Hybrid-Azure-m365

## What This Project Is

nig-e-mart is a growing startup. It needs to modernize its IT infrastructure. It also needs to keep control of its core on-premises systems. This project delivers a hybrid cloud environment. It connects on-premises Active Directory and Hyper-V workloads to Microsoft 365 and Azure. Users can sign in once and use both local and cloud resources. The deployment also gives email, collaboration, file management, and backup for critical systems.

---

## Scope

The project has eleven implementation phases. Each phase builds on the one before it. It starts with the Microsoft 365 tenant and user migration. It then adds security, hybrid identity, Azure infrastructure, high availability, file services, role-based access controls, and endpoint management.

What is not in scope: changes to physical network infrastructure, decommissioning of legacy systems, third-party application integrations, custom development work, or personnel changes. The on-premises Active Directory is assumed to already exist and be healthy.

---

## Key Requirements

For the deployment to succeed, every user must be provisioned into Microsoft 365 and assigned an E3 or E5 licence. Email must route through Exchange Online, and documents, team workspaces, and file storage must be accessible through SharePoint, Teams, and OneDrive respectively. Single sign-on from on-premises workstations must work without users re-entering credentials. All admin accounts must be protected by MFA from day one, and Data Loss Prevention policies must block externally transmitted PII and payment card data. Devices must be enrolled in Intune and confirmed compliant before they can access corporate M365 resources.

On the technical side, the deployment requires an active Azure subscription, Entra ID Premium P1 licences for Conditional Access, a minimum of two domain controllers (primary on-premises and secondary in Azure), and an IPsec VPN gateway for site-to-site connectivity between on-premises and Azure.

Recovery targets for on-premises systems are an RTO of one hour and an RPO of 24 hours. Microsoft 365 services are covered by Microsoft's 99.9% SLA and do not require separate recovery planning.

---

## Assumptions

The project assumes the existing on-premises Active Directory is healthy and operational, with at least one domain controller running Windows Server 2019 or later. A minimum of 10 Mbps internet bandwidth is available. DNS must be updatable at the registrar level to allow SPF and DKIM records to be created for email security. Azure VNet IP ranges must not conflict with on-premises subnets. Three IT staff are allocated to the project with executive sponsorship confirmed, and M365 and Azure licensing is budgeted and approved.

---

## Risks

The most significant risk is user resistance during the transition from familiar on-premises tools to cloud-based services. This is managed through a structured change management programme, including manager briefings and end-user training before go-live. A secondary risk is data loss during file migration, which is mitigated by running validation checksums and maintaining parallel access to original documents until each migration batch is verified. There is also a risk that security policies — particularly Conditional Access — are initially too restrictive and lock out legitimate users. To address this, all new policies will be deployed in Report-only mode first and tested with a pilot group before enforcement is enabled organisation-wide.

---

## Success Criteria

The deployment is considered successful when all users are synchronised to Entra ID and can sign in to Microsoft 365 with SSO from their on-premises workstations, when 95% or more of corporate devices are enrolled in and compliant with Intune, when the M365 Secure Score exceeds 60%, when Azure Site Recovery has completed a successful non-disruptive test failover for all protected VMs, and when the organisation has experienced zero unplanned downtime across the migration window.

| Bandwidth saturation | Slow performance | Off-peak migration, throttling |

## Success Criteria

- 100% user adoption (using M365 daily)
- Zero unplanned downtime
- All files migrated successfully
- Security baseline active
- Monitoring dashboards live
