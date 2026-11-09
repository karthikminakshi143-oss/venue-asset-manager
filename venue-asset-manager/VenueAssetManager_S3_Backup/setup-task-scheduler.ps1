$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$BackupScript = Join-Path $ProjectRoot "backup-mysql-to-s3.ps1"
if (-not (Test-Path $BackupScript)) { throw "Backup script not found: $BackupScript" }
if (-not (Test-Path (Join-Path $ProjectRoot "backup-config.json"))) { throw "Create backup-config.json from the example and configure it first." }
$TaskName = "VenueAssetManager-MySQL-S3-Backup"
$PowerShell = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
$action = New-ScheduledTaskAction -Execute $PowerShell -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$BackupScript`"" -WorkingDirectory $ProjectRoot
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(2) -RepetitionInterval (New-TimeSpan -Minutes 30) -RepetitionDuration (New-TimeSpan -Days 3650)
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -MultipleInstances IgnoreNew -ExecutionTimeLimit (New-TimeSpan -Minutes 25)
$principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive -RunLevel Highest
Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Description "Backs up venue_asset_manager MySQL database to AWS S3 every 30 minutes." -Force | Out-Null
Write-Host "Created task: $TaskName"
Write-Host "For unattended runs, open task Properties > General, select Run whether user is logged on or not, and configure credentials for the same Windows account. Confirm AWS credentials and MySQL option file are accessible to that account."
Write-Host "Start now: Start-ScheduledTask -TaskName '$TaskName'"
Write-Host "Check status: Get-ScheduledTaskInfo -TaskName '$TaskName' | Format-List *"
