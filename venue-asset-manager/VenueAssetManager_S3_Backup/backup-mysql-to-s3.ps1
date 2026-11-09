$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ConfigPath = Join-Path $ProjectRoot "backup-config.json"
$LogDir = Join-Path $ProjectRoot "logs"
$LocalBackupDir = Join-Path $ProjectRoot "backups"
New-Item -ItemType Directory -Force -Path $LogDir, $LocalBackupDir | Out-Null
$LogPath = Join-Path $LogDir ("backup-" + (Get-Date -Format "yyyy-MM-dd") + ".log")
function Write-Log([string]$Message) { Add-Content -LiteralPath $LogPath -Value ("{0} [{1}] {2}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $PID, $Message) }
try {
 if (-not (Test-Path $ConfigPath)) { throw "Missing backup-config.json. Copy backup-config.example.json and configure it." }
 $cfg = Get-Content -LiteralPath $ConfigPath -Raw | ConvertFrom-Json
 if ([string]::IsNullOrWhiteSpace($cfg.S3Bucket) -or $cfg.S3Bucket -eq "CHANGE_ME") { throw "Set S3Bucket in backup-config.json." }
 if ([string]::IsNullOrWhiteSpace($cfg.AwsRegion) -or [string]::IsNullOrWhiteSpace($cfg.DatabaseName)) { throw "Set AwsRegion and DatabaseName in backup-config.json." }
 $dump = $cfg.MysqldumpPath
 if ([string]::IsNullOrWhiteSpace($dump) -or -not (Test-Path $dump)) { $cmd = Get-Command mysqldump.exe -ErrorAction SilentlyContinue; if ($null -eq $cmd) { throw "mysqldump.exe not found. Set MysqldumpPath in config." }; $dump = $cmd.Source }
 $aws = Get-Command aws.exe -ErrorAction SilentlyContinue
 if ($null -eq $aws) { throw "AWS CLI not found. Install AWS CLI v2 and configure credentials for the scheduled-task account." }
 $defaultsFile = $cfg.MysqlDefaultsFile
 if ([string]::IsNullOrWhiteSpace($defaultsFile) -or -not (Test-Path $defaultsFile)) { throw "Set MysqlDefaultsFile to a secured MySQL option file." }
 $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
 $fileName = "$($cfg.DatabaseName)-$stamp.sql"
 $localFile = Join-Path $LocalBackupDir $fileName
 $s3Key = (($cfg.S3Prefix.Trim('/')) + "/" + $fileName).TrimStart("/")
 Write-Log "Starting backup: $($cfg.DatabaseName)"
 $dumpArgs = @("--defaults-extra-file=$defaultsFile", "--host=$($cfg.DbHost)", "--port=$($cfg.DbPort)", "--single-transaction", "--routines", "--triggers", "--events", "--hex-blob", "--default-character-set=utf8mb4", $cfg.DatabaseName)
 & $dump @dumpArgs 1> $localFile 2> (Join-Path $LogDir "mysqldump-error.txt")
 if ($LASTEXITCODE -ne 0) { $err = Get-Content (Join-Path $LogDir "mysqldump-error.txt") -Raw -ErrorAction SilentlyContinue; throw "mysqldump failed ($LASTEXITCODE): $err" }
 if (-not (Test-Path $localFile) -or (Get-Item $localFile).Length -lt 100) { throw "Backup file missing or unexpectedly small." }
 $sha = (Get-FileHash -LiteralPath $localFile -Algorithm SHA256).Hash
 $dest = "s3://$($cfg.S3Bucket)/$s3Key"
 & $aws.Source s3 cp $localFile $dest --region $cfg.AwsRegion --only-show-errors
 if ($LASTEXITCODE -ne 0) { throw "AWS S3 upload failed ($LASTEXITCODE)." }
 & $aws.Source s3api head-object --bucket $cfg.S3Bucket --key $s3Key --region $cfg.AwsRegion --query ContentLength --output text 1> (Join-Path $LogDir "s3-head.txt")
 if ($LASTEXITCODE -ne 0) { throw "S3 upload verification failed." }
 Write-Log "SUCCESS: uploaded $dest; bytes=$((Get-Item $localFile).Length); sha256=$sha"
 $days = [int]$cfg.LocalRetentionDays
 if ($days -gt 0) { Get-ChildItem -LiteralPath $LocalBackupDir -File -Filter "$($cfg.DatabaseName)-*.sql" | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$days) } | Remove-Item -Force }
} catch { Write-Log "FAILED: $($_.Exception.Message)"; exit 1 }
