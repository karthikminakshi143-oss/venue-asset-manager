$ErrorActionPreference = "Stop"
$dir = "C:\ProgramData\VenueAssetManagerBackup"
$file = Join-Path $dir "mysql-backup.cnf"
New-Item -ItemType Directory -Force -Path $dir | Out-Null
$secure = Read-Host "Enter password for the dedicated MySQL backup user" -AsSecureString
$ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
try { $password = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr) } finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr) }
$user = Read-Host "Enter MySQL backup username"
$content = "[client]`r`nuser=$user`r`npassword=`"$($password.Replace('\','\\').Replace('"','\"'))`"`r`nhost=127.0.0.1`r`nport=3306`r`n"
[IO.File]::WriteAllText($file, $content, [Text.Encoding]::ASCII)
$password = $null
& icacls.exe $file /inheritance:r /grant:r "Administrators:(R)" "SYSTEM:(R)" | Out-Null
if ($LASTEXITCODE -ne 0) { throw "Failed to secure MySQL option file." }
Write-Host "Created secured MySQL option file: $file"
