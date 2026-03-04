# Reference Documentation: Security Best Practices and Frameworks

## Zero Trust Architecture Principles

Zero Trust security operates under the assumption that every access request is potentially hostile until verified. Traditional perimeter-based security trusts everything inside the organizational boundary; Zero Trust trusts nobody, not even internal users or devices.

### Zero Trust Pillars

1. **Identity Verification**: Every user and device authenticated before access
   - MFA required for all users
   - Passwordless authentication preferred (Windows Hello, security keys)
   - Continuous risk assessment (device health, anomalies)

2. **Device Security**: Only compliant, secure devices access resources
   - Device enrollment in MDM (Intune)
   - Compliance policy enforcement
   - Known device state (patched, encrypted, antivirus running)
   - Block non-compliant devices

3. **Network Segmentation**: Microsegmentation limits lateral movement
   - VLANs separate departments
   - NSGs restrict inter-subnet traffic
   - Network ACLs restrict suspicious protocols
   - Application layer filtering (WAF)

4. **Application Security**: Apps protected with security controls
   - HTTPS/TLS for all traffic
   - API authentication (OAuth 2.0)
   - Input validation prevents injection
   - Logging and monitoring all access

5. **Data Classification**: Sensitive data protected appropriately
   - Encryption at rest (AES-256)
   - Encryption in transit (TLS 1.2+)
   - DLP policies prevent exfiltration
   - Retention policies enforce data lifecycle

6. **Monitoring & Analytics**: Continuous threat detection
   - Logging all authentication attempts
   - Anomaly detection (impossible travel, mass downloads)
   - Incident response automation
   - Forensic investigation capability

---

## Least Privilege Access Control

Least privilege means granting only necessary permissions for role function, never more:

### Application Examples

**Help Desk Employee**:
- Can reset passwords (necessary for role)
- Cannot assign licenses (unnecessary)
- Cannot manage groups (unnecessary)
- Cannot delete users (unnecessary - use termination workflow)

**Database Administrator**:
- Can modify databases (necessary)
- Cannot manage networking (unnecessary)
- Cannot manage identity policies (unnecessary)
- Cannot assign Azure roles (unnecessary)

**Network Administrator**:
- Can configure firewalls and NSGs (necessary)
- Cannot modify domain policy (unnecessary)
- Cannot manage cloud resources (unnecessary)
- Cannot access databases (unnecessary)

### Implementation Strategies

1. **Role Segmentation**: Separate duties by function
   - IT Infrastructure ≠ Security Administration ≠ Application Administration
   - Create role descriptions defining access scope

2. **Time-Limited Access**: Temporary escalation via PIM
   - Elevated access lasts 4 hours
   - Requires approval and justification
   - Automatic expiration prevents persistence

3. **Scope Limitation**: Grant at narrowest scope
   - Resource level: Only specific VM, database
   - Resource group level: All resources in group
   - Subscription level: All resources in subscription
   - Tenant level: Broadest scope, use rarely

4. **Audit Everything**: Track who accessed what when
   - Search audit logs for privilege usage
   - Alert on suspicious elevations
   - Investigate gaps or unusual patterns

---

## Data Classification and Lifecycle Policy

### Classification Levels

**Level 1 - Public**
- No confidentiality restrictions
- Safe to share externally
- Examples: Marketing materials, published documentation
- Protection: None (no encryption needed)
- Retention: Delete when no longer useful

**Level 2 - Internal**
- Organizational use only
- Not for external distribution
- Examples: Internal policies, HR procedures, org charts
- Protection: Standard DLP policies
- Retention: 3 years standard

**Level 3 - Confidential**
- Limited distribution by department
- Role-based access required
- Examples: Financial reports, strategic plans, customer lists
- Protection: Strong DLP policies, encryption
- Retention: 5-7 years per business needs

**Level 4 - Restricted**
- Maximum protection, audit trails required
- Access log all viewing/modification
- Examples: PII (SSN, health records), compliance data, trade secrets
- Protection: Maximum encryption, restricted access, monitoring
- Retention: As mandated by law (often 7-10 years+)

### Lifecycle Policies

**OneDrive Retention**:
- Active files: 5 years retention before archival
- Archived files: 7 years minimum retention
- Deleted files: 93-day recovery window
- Compliance hold: Override retention if litigation/investigation

**SharePoint Retention**:
- Department-specific (HR: 7 years, Operations: 3 years)
- Versioning: Keep 5 major versions
- Content approval: Required for sensitive departments (HR)
- External sharing: Disabled for departments handling confidential data

**Exchange Retention**:
- Standard emails: 3 years default
- Compliance mailbox: Infinite retention for discovery
- Deleted items: 30-day recovery period
- Litigation hold: Preservation for legal proceedings

### Implementing Classification

1. **Mark Data**: Users or automation tags documents with classification level
2. **Enforce Policies**: DLP rules apply based on classification
3. **Restrict Access**: Role-based permissions enforce distribution limits
4. **Monitor Access**: Audit logs track viewing and modification
5. **Lifecycle Management**: Automatic archival after retention period

---

## Incident Response Framework

### Incident Detection

Automated alerts trigger on:
- Multiple failed logins (brute force attempt)
- Mass file deletion (ransomware indicator)
- Unusual geographic access (impossible travel)
- Privilege escalation patterns (lateral movement)
- DLP violations (data exfiltration attempt)
- Malware detection (endpoint threat)

### Incident Response Workflow

**Phase 1: Detection & Triage** (Minutes 0-10)
- Alert received by security team
- Classify severity (critical/high/medium/low)
- Gather initial context (affected user, resource, scope)
- Contact incident commander

**Phase 2: Investigation** (Minutes 10-60)
- Query audit logs for suspicious activities
- Correlate events across systems
- Interview affected users
- Review Defender alerts and logs
- Determine incident scope (single user vs organization-wide)

**Phase 3: Containment** (Minutes 60-120)
- For compromised account: Reset password, sign out all sessions
- For malware: Isolate affected device from network
- For data exfiltration: Block suspicious entities, revoke external shares
- Preserve forensic evidence (logs, memory dumps)

**Phase 4: Eradication** (Hours 2-24)
- Patch vulnerability (if exploited)
- Remove malware/backdoors (if infection)
- Enforce password reset for compromised users
- Review lateral movement indicators
- Test fixes to prevent recurrence

**Phase 5: Recovery** (Hours 24-72)
- Monitor affected systems closely for re-infection
- Restore data from clean backups if needed
- Document all damage assessment
- Communicate all-clear to business if no ongoing threat

**Phase 6: Lessons Learned** (Days 3-14)
- Post-incident review meeting
- Document root cause
- Identify preventive measures
- Update security policies if needed
- Train users on identified vulnerabilities (phishing, credential hygiene)

### Incident Communication Template

**Initial Alert (30 minutes)**:
- Severity level (Critical/High/Medium/Low)
- Affected users/resources/data
- Status (investigating/contained/resolved)
- Contact for questions

**Updates (every 4 hours)**:
- Current investigation status
- Preliminary findings
- Actions taken so far
- Estimated resolution timeline

**Resolution (once contained)**:
- Root cause summary
- Resources affected
- Data damage assessment (if any)
- Preventive measures implemented
- Follow-up actions

---

## Security Compliance Frameworks

### NIST Cybersecurity Framework

**Identify**: Know data, assets, risks, and business dependencies
- Asset inventory (devices, software, data)
- Risk assessment (threat, vulnerability, likelihood)
- Access control policy

**Protect**: Implement controls to prevent/reduce risk
- Technical controls (encryption, firewalls, MFA)
- Administrative controls (policies, training, procedures)
- Physical controls (locked servers, restricted facilities)

**Detect**: Identify security events in real time
- Monitoring systems (SIEM, endpoint detection)
- Log aggregation and analysis
- Alert policies and triage

**Respond**: React appropriately to incidents
- Incident response procedures
- Communication plans
- Forensic capability

**Recover**: Restore to normal operations
- Backup and recovery procedures
- Business continuity plans
- Testing and validation

### CIS Critical Controls

**Basic Safeguards** (foundational):
1. Inventory of hardware/software
2. Inventory of authorized software
3. Address unauthorized software
4. Secure configurations
5. Access control management
6. Secure access management

**Foundational Safeguards**:
7. Email and web browser protection
8. Defenses against malware
9. Limitation and control of network ports, protocols, services
10. Data recovery capability

**Organizational Safeguards**:
11. Data protection
12. Asset management
13. Access control
14. Secure software development
15. Identity and access management
16. Security awareness and training

---

## Troubleshooting Guide

### Authentication Issues

**Users Cannot Sign In to Microsoft 365**
```
Diagnosis:
1. Check Azure AD sync status (User should exist in cloud)
2. Verify password (reset if uncertain)
3. Check Conditional Access policies (might be blocking)
4. Verify MFA (required? device registered?)

Resolution:
- Reset password in Microsoft 365 admin center
- If sync issue: Trigger immediate Azure AD Connect sync
- If CA blocking: Review policies, temporarily exclude user
- If MFA issue: Register authenticator app or send verification
```

**Hybrid Identity Sync Failures**
```
Diagnosis:
1. Check Azure AD Connect service status
2. Verify on-premises connectivity
3. Review sync errors in Event Viewer
4. Test connectivity to Azure endpoints

Resolution:
- Restart Azure AD Connect service if stopped
- Check firewall rules (allow 443/HTTPS, 80/HTTP)
- Review sync rules (may be excluding user)
- Run Repair function in AAD Connect setup
```

### Network Connectivity Issues

**Users Cannot Access Azure Resources via VPN**
```
Diagnosis:
1. Verify VPN connection status (portal shows "Connected")
2. Check network routing (traffic taking VPN path)
3. Verify on-premises firewall allows VPN traffic
4. Test connectivity from on-premises network

Resolution:
- Check VPN Gateway public IP (may have changed)
- Verify shared key still matches both ends
- Restart VPN connection
- Review NSG rules (likely blocking traffic)
- Packet trace to verify bidirectional traffic
```

### Compliance Issues

**Devices Non-Compliant Despite Remediation**
```
Diagnosis:
1. Check compliance policy requirements
2. Verify device actually applied settings
3. Check for sync delays (device sync up to 15 minutes)
4. Review device logs for failed policy application

Resolution:
- Trigger manual Intune sync
- Force WSUS check for Windows updates
- Verify admin approval for security software
- Re-assign compliance policy
- If persistent: Wipe and re-enroll device
```

---

## Performance and Optimization

### Azure AD Connect Sync Tuning

```powershell
# Check current sync schedule
Get-ADSyncScheduler

# Modify sync interval (default 30 minutes)
Set-ADSyncScheduler -SyncCycleEnabled $true -SyncInterval 30

# Monitor sync performance
Get-ADSync* | Measure-Object

# Track last successful sync
Get-EventLog -LogName Application -Source "Directory Synchronization" | `
  Where-Object { $_.EventID -eq 643 } | Select-Object TimeGenerated | `
  Sort-Object TimeGenerated -Descending | Select-Object -First 1
```

### VPN Throughput Optimization

```
Gateway SKU Performance:
- VpnGw1: 650 Mbps throughput
- VpnGw2: 1 Gbps throughput
- VpnGw3: 1.25 Gbps throughput

For production, use VpnGw2 or higher for adequate throughput
```

---

## Security Hardening Checklist

- [ ] MFA enabled for all administrative users ✓
- [ ] Conditional Access policies enforcing device compliance ✓
- [ ] DLP policies protecting sensitive data ✓
- [ ] Audit logging enabled for all services ✓
- [ ] Endpoint protection deployed (Windows Defender) ✓
- [ ] VPN encrypted with strong protocols (IKEv2, IPsec) ✓
- [ ] RBAC enforcing least privilege ✓
- [ ] PIM limiting elevated access duration ✓
- [ ] Regular access reviews (quarterly) ✓
- [ ] Incident response procedures documented ✓
- [ ] Security training provided to users ✓
- [ ] Backup and recovery tested ✓

---

*Document Version: 1.0*
*Last Updated: March 2, 2026*
