# Hybrid Microsoft Azure & Microsoft 365 Lab

## Overview
This project demonstrates the design and implementation of a secure hybrid cloud
environment for a fictional organization using Microsoft Azure, Microsoft 365,
Active Directory Domain Services, and Azure Entra ID.

## Key Objectives
- Integrate on-prem Active Directory with Azure Entra ID
- Implement hybrid identity using Azure AD Connect
- Configure Microsoft 365 tenant services (Exchange, SharePoint, Defender)
- Establish secure site-to-site VPN connectivity
- Enforce least-privilege access using Azure RBAC
- Manage devices using Microsoft Intune

## Technologies Used
- Microsoft Azure (VNets, VPN Gateway, RBAC)
- Azure Entra ID
- Active Directory Domain Services
- Azure AD Connect
- Microsoft 365 (E3/E5)
- Exchange Online
- Microsoft Defender
- Microsoft Intune
- PowerShell

## Architecture
See `/architecture` for diagrams.

## Security Considerations
- Least-privilege RBAC
- MFA and Conditional Access
- Defender email and identity protection
- Secure VPN tunneling

## Outcomes
- 20+ synchronized users
- 15+ Intune-managed endpoints
- Hybrid identity and secure connectivity
- Production-style documentation and automation

## Disclaimer
This is a fictional environment built for learning and demonstration purposes.
No real organizational data is used.
