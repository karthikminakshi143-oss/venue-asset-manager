$ErrorActionPreference = 'Stop'
Write-Host '=== Venue Asset Manager Server Pre-Check ===' -ForegroundColor Cyan
$items = @('IIS','URL Rewrite','Node.js','npm','MySQL 5.6')
foreach($i in $items){ Write-Host "Check: $i" }
Write-Host "Node: $((node --version) 2>$null)"
Write-Host "npm : $((npm --version) 2>$null)"
Write-Host "MySQL: $((mysql --version) 2>$null)"
Import-Module WebAdministration -ErrorAction SilentlyContinue
if (Get-Command Get-Website -ErrorAction SilentlyContinue) { Get-Website | Select-Object Name, State, PhysicalPath, Bindings }
Write-Host 'Pre-check complete.' -ForegroundColor Green
