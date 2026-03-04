# Hybrid-Azure-m365 Architecture

## Multi-Layer Stack

| Layer | Component | Purpose | Tech |
|-------|-----------|---------|------|
| **Devices** | User endpoints | Managed access | Intune, Windows 10/11 |
| **Identity** | Unified login | SSO, MFA, conditional access | AD DS → Entra ID |
| **Collaboration** | Teams, SharePoint | Projects, files, communication | M365 + OneDrive |
| **Productivity** | Exchange, Office | Email, documents | M365 |
| **Security** | Defender, DLP, MFA | Threat protection, data loss prevention | Microsoft Defender + Conditional Access |
| **Cloud** | Azure | VNets, storage, compute | IaaS/PaaS |
| **Network** | VPN, firewall | Site-to-site connectivity | Azure VPN Gateway + Firewall |

## Trust & Access Model

```
Internet User
    ↓
Conditional Access Policy (Risk evaluation)
    ↓
MFA Challenge (Microsoft Authenticator)
    ↓
Token Issued
    ↓
Access Granted to Resource (SharePoint/Exchange/Azure)
```

## Identity Flow

```
1. User logs in with UPN (john@organization.com)
2. Credential validated in Entra ID
3. MFA challenge issued
4. On-premises AD also synced via Azure AD Connect
5. User receives token with group membership
6. SSO to dependent services (Teams, SharePoint, etc.)
```

## On-Premises ↔ Cloud Integration

| On-Premises | Sync | Cloud |
|-------------|------|-------|
| AD DS (users, groups, devices) | ↔ | Azure Entra ID |
| File shares (smb) | Mirrored | Azure File Shares / SharePoint |
| Exchange (on-prem) | - | Exchange Online (cloud) |
| Infrastructure VMs | VPN/VPN | Azure VMs |

**Connection**: IPse VPN (encrypted tunnel with redundancy)

## High Availability Pattern

```
Primary DC (On-Premises)  ←  Replication  →  Secondary DC (Azure)
         ↓                                           ↓
      Users login                           Failover if primary down
```

## Security Architecture (Zero Trust)

- **Verify identity**: Every login requires authentication + MFA
- **Limit scope**: User can only access assigned resources
- **Assume breach**: DLP policies, threat detection, audit logging
- **Least privilege**: RBAC with minimal permissions
- **Encryption**: In transit (TLS), at rest (AES-256)

## Deployment Topology

**Site A (Primary)**: AD DS, File servers, Exchange (on-prem), Connection to Azure
**Site B (Backup)**: Secondary DC, Backup DC, Cold standby Exchange
**Azure**: Entra ID, M365, VNet, VPN Gateway, backup/DR vault

---

**Phase mapping**: See 02-phase-1 through 12-phase-11 for implementation details
