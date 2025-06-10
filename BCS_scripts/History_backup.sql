-- 


DECLARE @database_name VARCHAR(MAX) = '_CESA_SSIS'
DECLARE @backupset_type VARCHAR(MAX) = 'L'
DECLARE @history_days INT = 7

SELECT 
	DISTINCT 
	CONVERT(CHAR(100), SERVERPROPERTY('Servername')) AS Server, 
	msdb.dbo.backupset.database_name, 
	msdb.dbo.backupset.backup_start_date, 
	--msdb.dbo.backupset.backup_finish_date, 
	datediff (minute, msdb.dbo.backupset.backup_start_date, msdb.dbo.backupset.backup_finish_date) duration,
	--msdb.dbo.backupset.expiration_date, 
	CASE msdb..backupset.type 
		WHEN 'D' THEN 'Database' 
		WHEN 'L' THEN 'Log' 
		WHEN 'I' THEN 'Differential' 
		WHEN 'F' THEN 'File or filegroup' 
		WHEN 'G' THEN 'Differential file' 
		WHEN 'P' THEN 'Partial' 
		WHEN 'Q' THEN 'Differential partial' 
		ELSE 'Unknown' 
	END AS backup_type, 
	--msdb.dbo.backupset.backup_size, 
	CAST(CAST(msdb.dbo.backupset.backup_size AS BIGINT) / (1024 * 1024) AS VARCHAR(MAX)) + ' MB' [Size MB],
	--msdb.dbo.backupmediafamily.logical_device_name, 
	--msdb.dbo.backupmediafamily.physical_device_name, 
	msdb.dbo.backupset.name AS backupset_name
	--,msdb.dbo.backupset.description 
FROM msdb.dbo.backupmediafamily 
INNER JOIN msdb.dbo.backupset ON msdb.dbo.backupmediafamily.media_set_id = msdb.dbo.backupset.media_set_id 
WHERE msdb.dbo.backupset.database_name not in ('master','msdb','model', 'tempdb')
-- comment these lines if all available history required
	--and (CONVERT(datetime, msdb.dbo.backupset.backup_start_date, 102) >= GETDATE() - @history_days) 
	--and msdb.dbo.backupset.database_name = @database_name
	--and msdb..backupset.type = @backupset_type
ORDER BY 
msdb.dbo.backupset.database_name, 
msdb.dbo.backupset.backup_start_date desc