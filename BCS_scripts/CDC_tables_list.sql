IF EXISTS(select 1 from tempdb.dbo.sysobjects where name = '##T_CDC') 
              DROP TABLE ##T_CDC

CREATE TABLE ##T_CDC(
       ServerName VARCHAR(100),
	   DatabaseName VARCHAR(100),
       [Schema_Name] VARCHAR(100),
       Table_Name VARCHAR(100)
)

EXEC SP_MSFOREACHDB' USE [?] 

DECLARE @database_name VARCHAR(MAX)		= db_name()

INSERT INTO ##T_CDC
SELECT 
       @@SERVERNAME,
	   @database_name AS DatabaseName,
       s.name AS Schema_Name, 
       tb.name AS Table_Name
FROM sys.tables tb
INNER JOIN sys.schemas s on s.schema_id = tb.schema_id
WHERE tb.is_tracked_by_cdc = 1'

SELECT * FROM ##T_CDC

IF EXISTS(select 1 from tempdb.dbo.sysobjects where name = '##T_CDC') 
              DROP TABLE ##T_CDC