# Assign Microsoft 365 Licenses
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$CsvPath,
    
    [switch]$Apply
)

Write-Host "=== Assigning Microsoft 365 Licenses ===" -ForegroundColor Cyan
Write-Host "Mode: $(if ($Apply) { 'EXECUTE' } else { 'PREVIEW' })" -ForegroundColor $(if ($Apply) { 'Red' } else { 'Yellow' })

if (-not (Test-Path $CsvPath)) {
    Write-Host "✗ File not found: $CsvPath" -ForegroundColor Red
    exit 1
}

$assignments = Import-Csv -Path $CsvPath
$skus = Get-MgSubscribedSku

foreach ($assignment in $assignments) {
    try {
        $user = Get-MgUser -Filter "userPrincipalName eq '$($assignment.UserPrincipalName)'"
        $sku = $skus | Where-Object { $_.SkuPartNumber -eq $assignment.SkuId } | Select-Object -First 1
        
        Write-Host "Processing: $($assignment.UserPrincipalName)..." -ForegroundColor Cyan
        
        if ($Apply) {
            Set-MgUserLicense -UserId $user.Id `
                -AddLicenses @(@{ SkuId = $sku.SkuId }) `
                -RemoveLicenses @()
            Write-Host "  ✓ License assigned" -ForegroundColor Green
        }
        else {
            Write-Host "  [PREVIEW] Would assign license" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "  ✗ Error: $_" -ForegroundColor Red
    }
}
