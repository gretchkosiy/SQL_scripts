declare @db varchar(max)
declare @log varchar(max)
declare @share varchar(max)

declare @Mirror varchar(max)
declare @Principle varchar(max)


--SET @db			= 'L:\DataL\DataFiles\SP2010COLIN\'
--SET @log		= 'L:\LogsL\LogFiles\SP2010COLIN\'
--SET @share		= '\\Dc1cn001\mirroring\'
--SET @Mirror = 'DC1DB031'
--SET @Principle = 'DC1DB250'

--SET @db			= 'M:\DataM\DataFiles\SP2010\'
--SET @log		= 'M:\LogsM\LogFiles\SP2010\'
--SET @share		= '\\Dc1cn001\mirroring\'
--SET @Mirror		= 'DC1DB034'
--SET @Principle	= 'DC1DB007'

--SET @db			= 'G:\DataG\DataFiles\MARCIS\'
--SET @log		= 'G:\LogsG\LogFiles\MARCIS\'
--SET @share		= '\\Dc1cn001\mirroring\'
--SET @Mirror		= 'DC1DB037'
--SET @Principle	= 'DC2DB009'



--SET @db			= 'S:\DataS\DataFiles\DB012\'
--SET @log		= 'S:\LogsS\LogFiles\DB012\'
--SET @share		= '\\Dc1cn001\mirroring\'
--SET @Mirror		= 'DC1DB035'
--SET @Principle	= 'DC1DB012'


--SET @db			= 'Z:\DataZ\DataFiles\SP2010COLINPRE\'
--SET @log		= 'Z:\LogsZ\LogFiles\SP2010COLINPRE\'
--SET @share		= '\\Dc1cn001\mirroring\'
--SET @Mirror		= 'DC2DB255'
--SET @Principle	= 'DC2DB253'


SET @db			= 'A:\DataA\DataFiles\SP2010\'
SET @log		= 'A:\LogsA\LogFiles\SP2010\'
SET @share		= '\\DC1DB044\Mirroring\'
SET @Mirror		= 'DC1DB044'
SET @Principle	= 'DC1DB034'


select 
	db.name AS DatabaseName,
	MFr.size,
	'MKDIR ' + @db + replace(db.name,' ','_') AS MkDir,
	'MKDIR ' + @log + replace(db.name,' ','_') AS MkDir1,
	'BACKUP DATABASE [' + db.name + '] TO DISK = ''' + @share + replace(db.name,' ','_') + '_mirroring.bak'' WITH COMPRESSION' AS [BACKUP],
	'restore database [' + db.name + '] from disk=''' + @share + replace(db.name,' ','_') + '_mirroring.bak'' with NORECOVERY, ' +
	'MOVE N''' + MFr.name + ''' TO N''' + @db + replace(db.name,' ','_') + '\'  + reverse(left(reverse(mfr.physical_name), charindex('\', reverse(mfr.physical_name)) -1)) + ''', ' +
    'MOVE N''' + MFl.name + ''' TO N''' + @log + replace(db.name,' ','_') + '\'   + reverse(left(reverse(MFl.physical_name), charindex('\', reverse(MFl.physical_name)) -1)) + ''''  AS [RESTORE],
	'BACKUP LOG [' + db.name + '] TO DISK = ''' + @share + replace(db.name,' ','_') + '_mirroring.trn'' WITH INIT' AS [BACKUP_LOG],
	'RESTORE LOG [' + db.name + ']  FROM DISK = ''' + @share + replace(db.name,' ','_') + '_mirroring.trn'' WITH NORECOVERY;' AS [RESTORE_LOG],
	'ALTER DATABASE [' + db.name + ']  SET PARTNER = ''TCP://' + @Principle + '.pipelinetrust.com.au:5022''' AS [Mirror],
    'ALTER DATABASE [' + db.name + ']  SET PARTNER = ''TCP://' + @Mirror + '.pipelinetrust.com.au:5023''' AS [Principal],
	'ALTER DATABASE [' + db.name + ']  SET PARTNER OFF' AS [Mirror_OFF]
from master.dbo.sysdatabases db
	LEFT JOIN master.sys.master_files MFr ON db.dbid = MFr.database_id AND MFr.type_desc = 'ROWS'
	LEFT JOIN master.sys.master_files MFl ON db.dbid = MFl.database_id AND MFl.type_desc = 'LOG'
where db.name not in ('master','msdb','tempdb','model'
	--,'ReportServer','ReportServerTempDB'
	)
	AND db.name not in (
					SELECT d.name
					FROM   sys.database_mirroring m JOIN sys.databases d
					ON     m.database_id = d.database_id
					WHERE  mirroring_state_desc IS NOT NULL)
--- only DB with 1 MDF
    AND db.dbid IN (
					select database_id 
					FROM master.sys.master_files
					GROUP BY database_id
					HAVING count(*) = 2) 
-- only small databases
    --AND db.dbid IN (select Database_id from sys.master_files where size < 33164192 and type = 0) 
	AND db.name != 'Application_Registry_Service_DB_0008fc2b10994b3eb57b988d89bd74d8'
	AND db.name IN (
'MOSS_NINTEX2007DB',
'MOSS_Photos_Content_01',
'MOSS_Teams_Content_02',
'NintexForms',
'NintexWorkflow_Config',
'NintexWorkflow_Content',
'NintexWorkflow_Content_02',
'PerformancePoint Service Application_b2bb3ff0c00b4129b039a403ab7913ed',
'ProjectServer_Archive',
'ProjectServer_Draft',
'ProjectServer_Extension',
'ProjectServer_Published',
'ProjectServer_Reporting',
'ReportServer',
'ReportServerTempDB',
'Search_Service_Application_CrawlStoreDB_d54261c19b61417fa237f85dadba746f',
'Search_Service_Application_DB_287ec9aeaa2e4a49b5810330638db7de',
'Search_Service_Application_PropertyStoreDB_c5a69e0b3d9d46a4aa7f220fa8ef7b53',
'Secure_Store_Service_DB_241c02a7af724030a498cac0dedd228a',
'SessionStateService_09a9d0ba289544d5afaf7b4103f60512',
'SharePoint2010_AdminContent',
'SharePoint2010_Config',
'SP_FoundationSearch',
'SP_PS_Content_01',
'SP_PS_PWA_Content_01',
'SP_PS_PWS_Content_01',
'StateService_a1823baf90cc409ba6d8cc2c005ce97a',
'UserProfileDB',
'UserSocialDB',
'UserSyncDB',
'WebAnalyticsServiceApplication_StagingDB_d0b6bf33-6cdc-4345-90d3-bbc06a5d8d05',
'WordAutomationServices_d6529ef9ba234f0ea070f671b5ed532a',
'WSS_Content_APAGridPortal',
'WSS_Content_Integration_01',
'WSS_Content_SPApps_01',
'WSS_Logging'	
	
	
	)
ORDER BY MFr.size