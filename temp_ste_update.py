from pathlib import Path
import re

root = Path(r"c:\Users\Franklin\OneDrive - George Brown College\Document\IT Files\GitHub Projects\Projects\Hybrid-Azure-m365-project")
files = sorted(root.rglob('*.md'))

replacements = [
    (re.compile(r"\bThis phase implements\b", re.IGNORECASE), "This phase sets up"),
    (re.compile(r"\bThis phase establishes\b", re.IGNORECASE), "This phase sets up"),
    (re.compile(r"\bThis phase configures\b", re.IGNORECASE), "This phase sets up"),
    (re.compile(r"\bThis guide covers:\b", re.IGNORECASE), "This guide shows:"),
    (re.compile(r"\bThis file documents\b", re.IGNORECASE), "This file shows"),
    (re.compile(r"\bThis project documents\b", re.IGNORECASE), "This project shows"),
    (re.compile(r"\bThis solution balances operational control, cloud agility, compliance enforcement, and business continuity\.\b", re.IGNORECASE), "This solution gives control, cloud access, compliance, and business continuity."),
    (re.compile(r"\bThe environment follows a layered hybrid enterprise architecture integrating:\b", re.IGNORECASE), "The environment uses a layered hybrid architecture:"),
    (re.compile(r"\bA failed deployment often results from poor planning, not poor execution\. This phase establishes:\b", re.IGNORECASE), "Poor planning often causes a failed deployment. This phase sets up:"),
    (re.compile(r"\bBefore executing ANY phases, verify:\b", re.IGNORECASE), "Before you start, check:"),
    (re.compile(r"\bnig-e-mart requires an infrastructure that:\b", re.IGNORECASE), "nig-e-mart needs an infrastructure that:"),
    (re.compile(r"\bThe project covers eleven implementation phases, each building on the previous one\. It begins with provisioning the Microsoft 365 tenant and migrating users, then layers on security hardening, hybrid identity synchronisation, Azure infrastructure, high availability through Azure Site Recovery, file services, role-based access controls, and finally endpoint management through Intune\.\b", re.IGNORECASE), "The project has eleven implementation phases. Each phase builds on the one before it. It starts with the Microsoft 365 tenant and user migration. It then adds security, hybrid identity, Azure infrastructure, high availability, file services, role-based access controls, and endpoint management."),
    (re.compile(r"\bThis project delivers a hybrid cloud environment that connects the existing on-premises Active Directory and Hyper-V workloads to Microsoft 365 and Azure\. The end result is a unified identity system where users sign in once and access both local and cloud resources seamlessly, a fully governed Microsoft 365 deployment for email, collaboration, and file management, and an Azure-backed redundancy layer that keeps critical systems available even if the on-premises environment goes offline\.\b", re.IGNORECASE), "This project delivers a hybrid cloud environment. It connects on-premises Active Directory and Hyper-V workloads to Microsoft 365 and Azure. Users can sign in once and use both local and cloud resources. The deployment also gives email, collaboration, file management, and backup for critical systems."),
]

for path in files:
    text = path.read_text(encoding='utf-8')
    new_text = text
    for pattern, replacement in replacements:
        new_text = pattern.sub(replacement, new_text)
    if new_text != text:
        path.write_text(new_text, encoding='utf-8')
        print(f'updated {path.relative_to(root)}')
