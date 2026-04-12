# Security and Access Design

## Security Philosophy

This deployment follows a Zero Trust model: no user, device, or network connection is inherently trusted. Every access request is authenticated and verified against identity, device compliance, location, and risk signals before access is granted. Security is layered across identity, data, devices, email, and networking, so that a failure at any single layer does not compromise the whole environment.

---

## Identity and Authentication

All user identities originate in on-premises Active Directory and are synchronised to Entra ID via Azure AD Connect using Password Hash Synchronisation. This means users authenticate with their familiar AD credentials and Entra ID handles token issuance for cloud services. Legacy authentication protocols — SMTP Auth, IMAP, POP3, and older Office clients — are blocked entirely because they cannot be protected by MFA and are a primary vector for credential-stuffing attacks.

MFA is mandatory for all admin accounts from Phase 1 and enforced for all users by Phase 2. Admin accounts are further protected by Privileged Identity Management (PIM): no admin holds a standing elevated role. When elevated access is needed, the admin activates the role explicitly, provides a justification, completes an MFA challenge, and — for Global Administrator — waits for a second administrator to approve the request. The activation is time-limited and the role is removed automatically when it expires.

Two break-glass accounts are excluded from all Conditional Access policies to allow emergency access if all other admin accounts are locked out. Their credentials are printed and stored offline in a physically secured location. An alert is configured to notify the security team the moment either account signs in.

---

## Conditional Access Policies

Five Conditional Access policies cover all users and workloads. The first requires MFA on every sign-in for all users. The second blocks any sign-in attempt coming from a legacy authentication client. The third restricts M365 access to devices that are enrolled in Intune and confirmed compliant — unenrolled or non-compliant devices are denied regardless of valid credentials. The fourth blocks sign-ins that Entra ID Identity Protection has scored as high-risk, and applies a step-up MFA challenge for medium-risk sign-ins. The fifth enforces MFA for every sign-in by any account assigned an admin directory role, with no network or device exceptions.

All policies are deployed in Report-only mode first, monitored for at least seven days, and only switched to enforcement after confirming no legitimate users are being incorrectly blocked.

---

## Data Protection

All data at rest is protected by AES-256 encryption applied by the Microsoft 365 platform. All traffic in transit must use a minimum of TLS 1.3. Microsoft Purview enforces four sensitivity levels across all content: Public, Internal, Confidential, and Restricted. The default label applied to all new documents is Internal. Any user who removes or downgrades a sensitivity label is required to provide a written justification, which is captured in the audit log.

Data Loss Prevention policies block the external transmission of personally identifiable information and payment card data through email, SharePoint, OneDrive, and Teams. A detected violation triggers a block action and generates a high-severity alert to the Security Admin. External sharing on SharePoint and OneDrive is restricted to verified partner domains and disabled entirely on sensitive document libraries. All M365 data is retained under a seven-year compliance retention policy enforced through Purview.

---

## Email and Endpoint Security

Microsoft Defender for Office 365 applies Safe Links and Safe Attachments protection to all email. Hyperlinks are scanned and sandboxed at click time, and file attachments are detonated in an isolated environment before delivery. This applies to both inbound external mail and internal messages. Defender Advanced Threat Protection runs alongside Windows Defender on all managed endpoints. BitLocker disk encryption is enforced as a mandatory device compliance requirement through Intune — a device that reports no encryption is immediately flagged as non-compliant and loses access to M365 resources.

---

## Monitoring and Alerting

Unified Audit Logging is enabled across all Microsoft 365 workloads with a 90-day hot retention period and a one-year cold archive. Automated alerts fire when five or more failed sign-in attempts occur within one hour on a single account, when a user downloads more than 10GB of data in a session, when any privilege escalation event is detected, or when a DLP policy match occurs. The M365 Secure Score is reviewed monthly with a minimum target of 60%. A compliance report is exported from Purview Compliance Manager each month and stored in the IT SharePoint site.

---

## Role-Based Access Control

Access across Microsoft 365, Azure, and on-premises resources follows a least-privilege RBAC model. Two to three Global Administrators hold full M365 authority. These accounts are PIM-eligible only, meaning the Global Admin role must be explicitly activated for each use and is never held as a permanent standing assignment. In practice, the CTO, IT Manager, and IT Security Lead hold eligible Global Admin assignments.

Department Admins — one per business unit, covering IT, Sales, Finance, and HR — can manage users, licences, and resources within their own department but have no authority outside it. Regular employees access their own content plus shared team resources as granted by their manager. External guest accounts are restricted to specific SharePoint content explicitly shared with them, cannot browse the broader SharePoint environment, cannot access on-premises file shares or systems, and are automatically expired after 90 days of inactivity.

For shared document libraries, each department owns its primary SharePoint site, with the department manager as site owner. Finance reports are accessible only to finance staff and senior management. The archive site is read-only for all users. No department admin can modify the settings or permissions of another department's site.

---

## Access Reviews

Quarterly access reviews are run through Entra ID Identity Governance. Managers review their team's group memberships, SharePoint site permissions, and any assigned M365 roles. Reviewers have 14 days to respond. A non-response defaults to access removal. The results of every review are exported and stored in the IT SharePoint site for audit purposes. In addition to quarterly reviews, access is also updated immediately whenever a user changes department, takes on a new role, or leaves the organisation.

