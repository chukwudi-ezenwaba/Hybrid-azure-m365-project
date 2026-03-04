# Security Design: Hybrid-Azure-m365

## Security Stack

| Layer | Component | Policy |
|-------|-----------|--------|
| **Identity** | Entra ID + Conditional Access | MFA required, location checks |
| **Authentication** | Password hash sync + SSPR | Min 14 chars, no legacy auth |
| **Data** | DLP policies | Block PII/PCI external, quarantine |
| **Threats** | Defender Advanced Threat Protection | Email sandbox, malware detection |
| **Endpoints** | Intune compliance | Encryption, updates mandatory |
| **Audit** | Unified Audit Log | Retention 90d hot, 1y cold storage |

## MFA Strategy

- **Admins**: Authenticator app required on every login (Phase 1)
- **Sensitive users**: Authenticator optional, enforced Phase 2
- **General users**: SSPR self-service (Phase 4)
- **Exception**: 2 emergency access accounts (no MFA, locked)

## DLP Policies

| Policy | Scope | Action |
|--------|-------|--------|
| PII Block | External email | Block + alert |
| PCI Block | External email | Block + alert |
| Password Detection | All email | Alert + remove |
| Large Transfer Alert | >100MB external | Log + alert |

## Conditional Access Rules

| Rule | Condition | Action |
|------|-----------|--------|
| Legacy Auth Block | Legacy clients | Block |
| Untrusted Network | Unknown location | Require MFA |
| Risky Sign-In | Anomalous behavior | Re-authenticate |
| App Protection | No device compliance | Denied |

## Encryption Standards

- **At Rest**: AES-256 (M365 default)
- **In Transit**: TLS 1.3 minimum
- **Backups**: Azure encryption + offline copy

## OneDrive/SharePoint Security

- [ ] Disable external sharing (or domain-only)
- [ ] 30-day retention for deleted files
- [ ] Enable version history (keep 30 versions)
- [ ] Block malicious files (sandboxing)

## Monitoring & Alerts

- Alert on >5 failed logins in 1 hour
- Alert on privilege escalation
- Alert on >10GB downloads
- Daily security score report
