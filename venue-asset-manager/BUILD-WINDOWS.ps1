$ErrorActionPreference='Stop'
Write-Host 'Installing frontend dependencies...'
npm install
Write-Host 'Building frontend...'
npm run build
Write-Host 'Installing API dependencies...'
Set-Location server
npm install
Write-Host 'Done. Use dist for IIS and keep server folder for Node API.'
