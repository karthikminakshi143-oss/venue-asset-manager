$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
Set-Location $Root
Write-Host '=== Venue Asset Manager - Build ===' -ForegroundColor Cyan
npm install --no-audit --no-fund
npm --prefix server install --no-audit --no-fund
npm run build
Write-Host "Build completed: $Root\\dist" -ForegroundColor Green
