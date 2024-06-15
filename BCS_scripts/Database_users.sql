IF EXISTS(select 1 from tempdb.dbo.sysobjects where name = '##dbinfo')					
	DROP TABLE ##dbinfo

CREATE TABLE ##dbinfo(
	DBname varchar(255),
	LoginName varchar(255),
	OwnSchema varchar(255))

EXEC sp_MSforeachdb 'USE [?]; 
INSERT INTO ##dbinfo
SELECT ''?'' as DBname, p.name as LoginName, ISNULL(o.schemanames,'''') OwnSchema
FROM sys.database_principals p
LEFT JOIN (select schema_name(schema_id) as schemanames,
	user_name(s.principal_id) as usernames
	from sys.schemas As s) AS o ON P.name = o.usernames
where (p.type=''S'' or p.type = ''U'')
and p.name not in (''dbo'', ''guest'', ''sys'', ''INFORMATION_SCHEMA'')'

SELECT @@Servername as ServerName, * FROM ##dbinfo
where LoginName not in ('##MS_PolicyEventProcessingLogin##',
'MS_DataCollectorInternalUser'
,'##MS_PolicyTsqlExecutionLogin##'
--,''
--,''

) and DBname not in ('master', 'msdb', 'tempdb', 'model', 'ReportServer', 'ReportServerTempDB')