# Role-Based Access Control (RBAC) Model

## Azure AD Role Hierarchy

| Role | Scope | Responsibilities |
|------|-------|-----------------|
| **Global Admin** (2-3 people) | All M365 | Emergency access, policy changes |
| **Usage Location Admin** (1 per dept) | Department | User management, licenses |
| **SharePoint Admin** (1 per dept) | SharePoint sites | Site + content management |
| **Teams Admin** (1 per dept) | Teams | Team creation, channels, policies |
| **Security Admin** | M365 security | Threat management, DLP policy |
| **User** (all employees) | Own content | Read/edit own files, teams |
| **Guest** (external) | Shared content | Read-only shared resources |

## Assignment Strategy

**Global Admin**: CTO, IT Manager, IT Security Lead  
**Department Admins**: Department heads (1 per: IT, Sales, Finance, HR)  
**Regular Users**: All other employees  
**Guests**: External contractors, clients (time-limited)

## Permission Matrix

| Resource | Global Admin | Dept Admin | User | Guest |
|----------|------------|-----------|------|-------|
| Create user | ✓ | ✓ (own dept) | ✗ | ✗ |
| Manage teams | ✓ | ✓ (own dept) | ○ (own) | ✗ |
| Edit files | ✓ | ✓ | ✓ (own) | ○ (shared) |
| Delete files | ✓ | ✓ | ○ (own) | ✗ |
| View audit | ✓ | ✓ (own) | ✗ | ✗ |

Legend: ✓=Full, ○=Limited, ✗=No

## Access Review Process

- **Quarterly**: Review all role assignments (90-day cadence)
- **On Change**: Update when employee joins/leaves/transfers
- **Removal**: Automatic revoke after 30 days inactivity (disabled users)
- **Approval**: Manager approval required for access changes

## OneDrive/SharePoint Permissions

| Site/Library | Owner | Editor | Viewer |
|----------|-------|--------|--------|
| IT Shared | IT Manager | IT staff | All |
| Finance Reports | Finance Manager | Finance staff | Mgmt |
| Sales Files | Sales Manager | Sales staff | Finance |
| Archive (read-only) | IT Lead | None | All |

## Least Privilege Principle

- No permanent Global Admins (rotate or emergency-only)
- Department admins cannot edit other departments
- Guest + external access is time-expire (31 days)
- Monthly audit of excessive permissions
