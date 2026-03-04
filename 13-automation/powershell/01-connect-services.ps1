# Connect to Microsoft 365 Services
[CmdletBinding()]
param(
    [Parameter(HelpMessage = "Admin email")]
    [string]$AdminEmail
)

Write-Host "=== Connecting to Microsoft 365 ===" -ForegroundColor Cyan

$modules = @("ExchangeOnlineManagement", "Microsoft.Graph", "MicrosoftTeams")
foreach ($module in $modules) {
    if (-not (Get-Module -ListAvailable -Name $module)) {
        Write-Host "Installing $module..." -ForegroundColor Yellow
        Install-Module -Name $module -Force -AllowClobber | Out-Null
    }
}

try {
    Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Green
    Connect-MgGraph -Scopes "User.ReadWrite.All", "Group.ReadWrite.All"
    
    Write-Host "Connecting to Exchange Online..." -ForegroundColor Green
    Connect-ExchangeOnline -ShowBanner:$false
    
    Write-Host "Connecting to Microsoft Teams..." -ForegroundColor Green
    Connect-MicrosoftTeams | Out-Null
    
    Write-Host "`n✓ Connected to all Microsoft 365 services" -ForegroundColor Green
    Write-Host "Organization: $(Get-MgOrganization | Select-Object -ExpandProperty DisplayName)" -ForegroundColor Cyan
}
catch {
    Write-Host "✗ Connection failed: $_" -ForegroundColor Red
    exit 1
}
