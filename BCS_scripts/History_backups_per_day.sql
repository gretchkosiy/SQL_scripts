--- This scripts collects backups for last day of backups


create function dbo.fn_BCStimes
(
	@date date,
	@db varchar(max),
	@type char(1) 

) Returns VARCHAR(MAX)
BEGIN 
	DECLARE @Times VARCHAR(MAX) = 'Times: '
	SELECT 
		@Times = @Times + Cast(CAST(msdb.dbo.backupset.backup_start_date AS TIME(0)) AS VARCHAR(MAX)) + ' | '
	FROM msdb.dbo.backupmediafamily 
		INNER JOIN msdb.dbo.backupset ON msdb.dbo.backupmediafamily.media_set_id = msdb.dbo.backupset.media_set_id 
	WHERE 
		CAST(msdb.dbo.backupset.backup_start_date AS DATE) = @date -- '2023-07-31'
		AND msdb.dbo.backupset.database_name = @db -- 'PHDCFG'
		AND msdb.dbo.backupset.type = @type -- 'L'

	RETURN @Times
END
GO

;WITH  HistoryLast_Run (database_name, LastDate, type)
AS (
		 SELECT 
			msdb.dbo.backupset.database_name, 
			MAX(CAST(msdb.dbo.backupset.backup_start_date AS DATE)),
			msdb.dbo.backupset.type 
		FROM msdb.dbo.backupmediafamily 
			INNER JOIN msdb.dbo.backupset ON msdb.dbo.backupmediafamily.media_set_id = msdb.dbo.backupset.media_set_id 
		GROUP BY  msdb.dbo.backupset.database_name, msdb..backupset.type 
),
 History_bkp_7_Days AS (
			SELECT 
				DISTINCT 
				msdb.dbo.backupset.database_name, 
				msdb.dbo.backupset.backup_start_date, 
				--msdb.dbo.backupset.backup_finish_date, 
				datediff (minute, msdb.dbo.backupset.backup_start_date, msdb.dbo.backupset.backup_finish_date) duration,
				--msdb.dbo.backupset.expiration_date, 
msdb.dbo.backupset.type,
				CASE msdb.dbo.backupset.type 
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
			WHERE (CONVERT(datetime, msdb.dbo.backupset.backup_start_date, 102) >= GETDATE() - 7) 
)


SELECT 
	CONVERT(CHAR(100), SERVERPROPERTY('Servername')) AS [Instance name], 
	Name AS [Database name], 
	recovery_model_desc AS [Model],
	CASE 
		WHEN backup_type IS NULL THEN 'No Backup'
		ELSE backup_type 
	END AS [Backup Type],
	CASE 
		WHEN backup_type IS NULL THEN ''
		ELSE MAX([Size MB])	
	END [Backup Size (MB)],
	CASE 
		WHEN MAX(duration) IS NULL THEN ''
		ELSE CAST(MAX(duration) AS VARCHAR(MAX))
	END AS [Max duration (min)],
	CASE 
		WHEN backup_type IS NULL THEN ''
		ELSE Cast(COUNT(*) AS VARCHAR(MAX)) 
	END AS 	[Counts For last 7 Days]
	,CASE 
		WHEN backup_type IS NULL THEN ''
		ELSE CAST(HLR.LastDate AS VARCHAR(MAX))
	END AS [Last Date]
	,CASE 
		WHEN backup_type IS NULL THEN ''
		ELSE dbo.fn_BCStimes(HLR.LastDate, Name, H.type)
	END  AS [Times to run at last date]
	--backup_start_date
FROM master.sys.databases AS D 
	LEFT JOIN History_bkp_7_Days H ON H.database_name = D.Name
	LEFT JOIN HistoryLast_Run HLR ON HLR.database_name = D.Name AND H.type = HLR.type
WHERE name not in ('tempdb')
GROUP BY 
	Name, 
	backup_type,
	H.type,
	HLR.LastDate,
	recovery_model_desc

GO
drop function dbo.fn_BCStimes