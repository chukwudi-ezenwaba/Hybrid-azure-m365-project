# Security Best Practices: Hybrid-Azure-m365

## For This Deployment

This guide shows security practices for this Hybrid-Azure-m365 project.

## Password & Authentication

- **Minimum Length**: 14 characters
- **Complexity**: Upper, lower, numbers, symbols
- **No Reuse**: Last 24 passwords blocked
- **Expiry**: No forced expiry (risk of weak passwords)
- **MFA**: All admin accounts, enforced Phase 2

## Conditional Access Policies

### Rule 1: Block Legacy Authentication
```
Condition: Legacy auth protocol
Action: Block
Exception: Emergency access accounts (2 only)
```

### Rule 2: Require MFA for Risky Sign-Ins
```
Condition: Sign-in risk = High
Action: Require MFA + refresh password
```

### Rule 3: Block Untrusted Locations
```
Condition: Location NOT in (Office, VPN, Home)
Action: Block or Require MFA
```

### Rule 4: Require Device Compliance
```
Condition: Accessing sensitive resources
Action: Require Intune-compliant device
```

## DLP Policy Examples

### Policy 1: Block PII in External Email
```
Trigger: Email contains SSN, credit card, drivers license
Recipient: External domain
Action: Block + Alert
```

### Policy 2: Large File Transfer Alert
```
Trigger: File transfer >100MB
Recipient: External
Action: Alert security team
```

## Audit & Monitoring

**Enable These Audits**:
- [ ] User admin activity
- [ ] Mailbox audit (full access, delegate, search)
- [ ] SharePoint site + library access
- [ ] Teams channels + messages (eDiscovery)
- [ ] Conditional Access policy changes
- [ ] User permission changes

**Retention**: 90 days hot, 1 year archive

## Azure Active Directory Best Practices

- [ ] At least 2 Global Admins (not same person)
- [ ] Review privileged role assignments monthly
- [ ] Setup emergency access accounts (break-glass)
- [ ] Enable sign-in log retention (90 days)
- [ ] Configure password writeback (for self-service reset)

## On-Premises Active Directory

- [ ] Domain Controller backup strategy (daily system state backup)
- [ ] Separate DNS server (redundancy)
- [ ] Domain controller replication monitored
- [ ] Backup AD database weekly
- [ ] NTDS.dit encryption enabled
- [ ] Remove SYSVOL unencrypted data

## Backup & Disaster Recovery

- [ ] Back up all VMs to Azure Backup weekly
- [ ] Test recovery monthly
- [ ] RTO target: 1 hour max
- [ ] RPO target: 24 hours
- [ ] Offline copy of critical data
- [ ] Document recovery procedure

## Incident Response

**If Breach Detected**:
1. Isolate affected accounts
2. Reset passwords
3. Force re-authentication (force MFA)
4. Review audit logs (30 days back)
5. Notify security team
6. Document incident

**If Ransomware Detected**:
1. Disconnect affected device from network
2. Restore from backup (air-gapped)
3. Scan with latest malware tools
4. Deploy updated DLP/endpoint protection

## Compliance Checklists

### Weekly
- [ ] No failed admin logins >5/hour
- [ ] No unusual file download patterns
- [ ] No new privileged accounts created

### Monthly
- [ ] Access review (roles & permissions)
- [ ] Disabled user cleanup
- [ ] DLP policy hit analysis
- [ ] Failed backup verification

### Quarterly
- [ ] Disaster recovery drill
- [ ] Security policy review
- [ ] Guest access audit (expiry enforcement)
- [ ] Privileged account audit

### Annually
- [ ] Full security assessment
- [ ] Policy update + refresh training
- [ ] Penetration test (if budget available)
