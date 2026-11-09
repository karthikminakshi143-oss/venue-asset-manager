$ErrorActionPreference = 'Stop'

Write-Host '=== Venue Asset Manager - IIS + MySQL 5.6 setup ===' -ForegroundColor Cyan

if (-not (Get-Command node -ErrorAction SilentlyContinue)) { throw 'Node.js is not installed. Install Node.js 18 LTS or newer.' }
if (-not (Get-Command npm -ErrorAction SilentlyContinue)) { throw 'npm is not installed.' }

Write-Host 'Installing frontend dependencies...'
npm install --no-audit --no-fund

Write-Host 'Installing backend dependencies...'
npm --prefix server install --no-audit --no-fund

Write-Host 'Building React frontend...'
npm run build

Write-Host ''
Write-Host 'Build complete. IIS should point to:' -ForegroundColor Green
Write-Host (Join-Path $PWD 'dist')
Write-Host ''
Write-Host 'Start the backend with:'
Write-Host '  cd server'
Write-Host '  npm start'
Write-Host ''
Write-Host 'Required IIS features: URL Rewrite + Application Request Routing (ARR) with proxy enabled.' -ForegroundColor Yellow
