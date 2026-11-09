param(
  [string]$ConfigPath = "..\\Config\\Config.json"
)
$ErrorActionPreference = 'Stop'
Write-Host "=== Venue Asset Manager Build Check ===" -ForegroundColor Cyan
if (-not (Test-Path $ConfigPath)) { throw "Config file not found: $ConfigPath" }
$config = Get-Content $ConfigPath -Raw | ConvertFrom-Json
Write-Host "Application : $($config.ApplicationName)"
Write-Host "Venue ID    : $($config.VenueId)"
Write-Host "Skip venue  : $($config.SkipVenueValidation)"
Write-Host "IIS site    : $($config.IISSiteName)"
Write-Host "Backend     : $($config.BackendPath)"
Write-Host "API port    : $($config.BackendPort)"
Write-Host "Database    : $($config.DatabaseName)"
$checks = @(
  @{Name='Node.js'; Command='node'; Args='--version'},
  @{Name='npm'; Command='npm'; Args='--version'},
  @{Name='MySQL client'; Command='mysql'; Args='--version'}
)
foreach ($c in $checks) {
  if (Get-Command $c.Command -ErrorAction SilentlyContinue) {
    Write-Host "[OK] $($c.Name): $((& $c.Command $c.Args) -join ' ')" -ForegroundColor Green
  } else {
    Write-Host "[MISSING] $($c.Name)" -ForegroundColor Yellow
  }
}
try {
  $svc = Get-Service | Where-Object { $_.Name -like '*mysql*' } | Select-Object -First 1
  if ($svc) { Write-Host "[OK] MySQL service: $($svc.Name) / $($svc.Status)" -ForegroundColor Green }
  else { Write-Host "[WARN] MySQL Windows service not found by name pattern *mysql*" -ForegroundColor Yellow }
} catch {}
Write-Host "Build check completed." -ForegroundColor Green
