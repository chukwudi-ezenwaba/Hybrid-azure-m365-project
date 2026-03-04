# Create Microsoft 365 Users from CSV
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true, HelpMessage = "CSV file path")]
    [string]$CsvPath
)

Write-Host "=== Creating Microsoft 365 Users ===" -ForegroundColor Cyan

if (-not (Test-Path $CsvPath)) {
    Write-Host "✗ File not found: $CsvPath" -ForegroundColor Red
    exit 1
}

$users = Import-Csv -Path $CsvPath
Write-Host "✓ Loaded $($users.Count) users from CSV" -ForegroundColor Green

$password = ConvertTo-SecureString "TempPass@2024" -AsPlainText -Force
$successCount = 0

foreach ($user in $users) {
    try {
        $upn = "$($user.Email)@organization.onmicrosoft.com"
        $displayName = "$($user.FirstName) $($user.LastName)"
        
        Write-Host "Creating: $displayName..." -ForegroundColor Cyan
        
        New-MgUser -DisplayName $displayName `
            -MailNickname $user.Email `
            -UserPrincipalName $upn `
            -AccountEnabled:$true `
            -PasswordProfile @{ ForceChangePasswordNextSignIn = $true; Password = "TempPass@2024" } `
            -GivenName $user.FirstName `
            -Surname $user.LastName `
            -JobTitle $user.JobTitle `
            -Department $user.Department | Out-Null
        
        Write-Host "  ✓ Created" -ForegroundColor Green
        $successCount++
    }
    catch {
        Write-Host "  ✗ Error: $_" -ForegroundColor Red
    }
}

Write-Host "`n✓ Successfully created $successCount users" -ForegroundColor Green
