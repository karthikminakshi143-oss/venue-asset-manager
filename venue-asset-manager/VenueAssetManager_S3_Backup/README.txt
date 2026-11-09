VENUE ASSET MANAGER - MYSQL TO AWS S3 BACKUP
============================================

This package backs up database venue_asset_manager to timestamped SQL files and uploads them to S3 every 30 minutes. It verifies the S3 object, logs results, and retains local files for the configured number of days.

SETUP
1. Copy this folder to the Windows Server, e.g. D:\VenueAssetManager_S3_Backup.
2. Copy backup-config.example.json to backup-config.json and edit S3Bucket, AwsRegion, and MysqldumpPath.
3. Install AWS CLI v2. In the SAME Windows account that runs the scheduled task, verify:
   aws --version
   aws sts get-caller-identity
   Never place AWS access keys in scripts or this JSON file. Prefer an IAM role if the server is hosted on AWS.
4. Use a dedicated MySQL backup account rather than root. Grant appropriate read/metadata privileges for mysqldump (typically SELECT, SHOW VIEW, TRIGGER, EVENT, and SHOW ROUTINE as needed). Create the account using your MySQL administration method.
5. Run create-mysql-options-file.ps1 as Administrator. Enter the dedicated backup username and password. This writes C:\ProgramData\VenueAssetManagerBackup\mysql-backup.cnf and restricts its ACL.
6. Check the MySQL 5.6 mysqldump path in backup-config.json.
7. Run a manual test: .\backup-mysql-to-s3.ps1
   Review .\logs and verify the object in S3. Do not schedule until the manual test succeeds.
8. Open PowerShell as Administrator and run .\setup-task-scheduler.ps1.
9. In Task Scheduler, open VenueAssetManager-MySQL-S3-Backup > Properties > General and choose "Run whether user is logged on or not"; enter that Windows account's password. Ensure AWS credentials and MySQL option file are available to that account. Run the task once manually and inspect Last Run Result.

S3 bucket requirements:
- Create the bucket in AWS first.
- Keep Block Public Access enabled and encryption enabled.
- Restrict permissions to the backup prefix; allow required S3 PutObject and head-object permissions.
- Consider bucket versioning and configure an S3 Lifecycle rule for remote retention.
- This package does not create AWS buckets or IAM policies.

Logs: .\logs\backup-YYYY-MM-DD.log
Local dumps: .\backups\
S3 path: s3://YOUR-BUCKET/venue-asset-manager/mysql/venue_asset_manager-YYYYMMDD-HHMMSS.sql

Check task:
Get-ScheduledTaskInfo -TaskName "VenueAssetManager-MySQL-S3-Backup" | Format-List *
Get-Content .\logs\backup-$(Get-Date -Format yyyy-MM-dd).log -Tail 30

Restore testing:
Always test restore into a separate database, not production. A plain SQL dump is not point-in-time recovery. --single-transaction provides a consistent snapshot for InnoDB tables; other storage engines may need additional consideration.
