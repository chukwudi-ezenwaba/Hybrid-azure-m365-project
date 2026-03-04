# Microsoft 365 Automation - Master Entry Point
# Run individual numbered scripts in sequence

Write-Host "=== M365 Automation Suite ===" -ForegroundColor Cyan
Write-Host "Available scripts (run in order):"  -ForegroundColor Green
Write-Host "  SETUP:" -ForegroundColor Yellow
Write-Host "    01-connect-services.ps1"
Write-Host "  DEPLOY:" -ForegroundColor Yellow
Write-Host "    02-create-users.ps1 (CSV: FirstName,LastName,Email,JobTitle,Department)"
Write-Host "    03-license-assignment.ps1 (CSV: UserPrincipalName,SkuId)"
Write-Host "    04-mailbox-setup.ps1"
Write-Host "    07-create-groups.ps1"
Write-Host "  SECURITY:" -ForegroundColor Yellow
Write-Host "    08-enable-mfa.ps1"
Write-Host "  OPERATIONS:" -ForegroundColor Yellow
Write-Host "    05-generate-reports.ps1"
Write-Host "    06-cleanup-disabled-users.ps1"
