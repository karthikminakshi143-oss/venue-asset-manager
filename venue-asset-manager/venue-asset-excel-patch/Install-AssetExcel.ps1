$ErrorActionPreference = 'Stop'
$Project = 'D:\venue-asset-manager'
$IisTarget = 'D:\IIS\VenueAssetManager'
$PatchMain = Join-Path $PSScriptRoot 'src\main.jsx'
$ProjectMain = Join-Path $Project 'src\main.jsx'
$Dist = Join-Path $Project 'dist'

if (-not (Test-Path $PatchMain)) { throw "Patch file not found: $PatchMain" }
if (-not (Test-Path (Join-Path $Project 'package.json'))) { throw "Project package.json not found in $Project" }
if (-not (Test-Path (Join-Path $Project 'src'))) { throw "Project src folder not found in $Project" }

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$sourceBackup = "$ProjectMain.backup-$stamp"
Copy-Item $ProjectMain $sourceBackup -Force
Write-Host "Source backup created: $sourceBackup" -ForegroundColor Green

Copy-Item $PatchMain $ProjectMain -Force
Write-Host 'Excel import/export changes copied into src\main.jsx.' -ForegroundColor Green

Push-Location $Project
try {
    npm run build
    if ($LASTEXITCODE -ne 0) { throw 'npm run build failed. IIS deployment was not changed.' }
} finally {
    Pop-Location
}

if (-not (Test-Path (Join-Path $Dist 'index.html'))) { throw "Build output missing: $Dist\index.html" }
if (Test-Path $IisTarget) {
    $deployBackup = "$IisTarget-backup-$stamp"
    Copy-Item $IisTarget $deployBackup -Recurse -Force
    Write-Host "IIS backup created: $deployBackup" -ForegroundColor Green
}
New-Item -ItemType Directory -Path $IisTarget -Force | Out-Null
Copy-Item (Join-Path $Dist '*') $IisTarget -Recurse -Force
Write-Host "Deployment completed. Open http://localhost/venueassetmanager/assets" -ForegroundColor Green
Write-Host 'Verify Upload Excel, Excel Template, and Download Excel after logging in.' -ForegroundColor Cyan
