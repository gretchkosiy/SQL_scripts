with fs
as
(
    select database_id, type, CAST(size AS BIGINT) * 8 / 1024 size
    from sys.master_files
)
select
	@@SERVERNAME [ServerName], 
    db.name,
	S.name DBowner,
	recovery_model_desc,
	CASE
		WHEN is_read_only = 1 THEN 'READ ONLY'
		ELSE ''
	END [RO]	,
    (select sum(CAST(size AS BIGINT)) from fs where type = 0 and fs.database_id = db.database_id) DataFileSizeMB,
	--CAST(CAST(FILEPROPERTY('MSDBdata', 'SpaceUsed') AS int)/128 AS varchar), 
    (select sum(CAST(size AS BIGINT)) from fs where type = 1 and fs.database_id = db.database_id) LogFileSizeMB, 
	sd.version, 
	compatibility_level AS [Compatibility], 
	collation_name AS [Collation], 
	page_verify_option_desc AS [Page Verify],
	CASE is_auto_close_on WHEN 1 THEN 'Y' ELSE 'N' END AS [auto_close],
	CASE is_auto_shrink_on WHEN 1 THEN 'Y' ELSE 'N' END AS [auto_shrink],
	CASE is_db_chaining_on WHEN 1 THEN 'Y' ELSE 'N' END as [db_chaining],
	CASE is_auto_create_stats_on WHEN 1 THEN 'Y' ELSE 'N' END AS [auto_create_stats],
	CASE is_auto_update_stats_on WHEN 1 THEN 'Y' ELSE 'N' END AS [auto_update_stats]
	,'use [' + Db.name + '];exec sp_changedbowner ''sa'''

--select * 
from sys.databases db 
	LEFT JOIN sys.sysdatabases sd ON sd.name = db.name
	LEFT JOIN master.sys.syslogins S on Db.owner_sid = s.sid  
WHERE 
	db.name not in ('master', 'msdb', 'model', 'tempdb')
--and db.name not like 'ReportServer%'


/*

-- The same but splitted by files and available space
-- Can be run in TXT output - for SHINKFILE part

IF OBJECT_ID(N'tempdb.dbo.##temp',N'U') IS NOT NULL
       DROP TABLE ##temp;

EXEC sp_MSforeachdb 'USE [?];

IF OBJECT_ID(N''tempdb.dbo.##temp'',N''U'') IS NULL
CREATE TABLE ##temp (
	   [InstanceName] VARCHAR(500),
       [DBname] VARCHAR(100),
       [File Group] VARCHAR(100),
       [Logical Name] VARCHAR(100),
       [Filename] VARCHAR(8000),
       [Currently Allocated Space (MB)] VARCHAR(100),
       [Space Used (MB)] VARCHAR(100),
       [Available Space (MB)] VARCHAR(100),
	   [Free %] DECIMAL(4,2),
	   [Shrink] VARCHAR(1000));
INSERT INTO ##temp
SELECT 
	   @@SERVERNAME AS [InstanceName],
       DB_NAME() AS [DBname],
       ISNULL(b.groupname, ''Log'') AS [File Group],
       Name as [Logical Name],
       [Filename],
       CONVERT (Decimal(15,2),ROUND(a.Size/128.000,2)) [Currently Allocated Space (MB)],
       CONVERT (Decimal(15,2), ROUND(FILEPROPERTY(a.Name,''SpaceUsed'')/128.000,2)) AS [Space Used (MB)],
       CONVERT (Decimal(15,2),ROUND((a.Size-FILEPROPERTY(a.Name,''SpaceUsed''))/128.000,2)) AS [Available Space (MB)]
	   ,(CONVERT (Decimal(15,2),ROUND((a.Size-FILEPROPERTY(a.Name,''SpaceUsed''))/128.000,2)))*100/CONVERT (Decimal(15,2),ROUND(a.Size/128.000,2)) [Free %]
	   ,''USE ['' + DB_NAME() + ''];'' + CHAR(13)+CHAR(10) + ''GO'' + CHAR(13)+CHAR(10) + ''DBCC SHRINKFILE (N'''''' + Name + '''''', '' + CAST(CONVERT (Decimal(15,0), ROUND(FILEPROPERTY(a.Name,''SpaceUsed'')/128.000,0)+1) AS VARCHAR(20)) + '')''  AS [Shrink]
FROM dbo.sysfiles a (NOLOCK)
LEFT JOIN sysfilegroups b (NOLOCK) ON a.groupid = b.groupid;'
 
IF OBJECT_ID(N'tempdb.dbo.##temp',N'U') IS NOT NULL
SELECT [InstanceName], DBname, [File Group], [Logical Name],[Filename],[Currently Allocated Space (MB)],[Space Used (MB)],[Available Space (MB)],[Free %]  FROM ##temp 
WHERE 
       [DBname] not in ('master','model','msdb', 'tempdb')
       --AND [DBname] in ('SP2013_Content_Intranet')
ORDER BY [DBname],[File Group], [Logical Name]
 
-- this is for SHRINKFILE in SSMS Text mode 
SELECT '--- Start ' + [DBname] + ' ' + [Logical Name] + CHAR(13)+CHAR(10) + [Shrink] + CHAR(13)+CHAR(10) + '--- End ' + [DBname] + ' ' + [Logical Name] + CHAR(13)+CHAR(10) + CHAR(13)+CHAR(10) AS DBCC_SHRINKFILE  FROM ##temp 
--WHERE [DBname] in ('tempdb')
ORDER BY [DBname],[File Group], [Logical Name]
 
IF OBJECT_ID(N'tempdb.dbo.##temp',N'U') IS NOT NULL
       DROP TABLE ##temp;





*/