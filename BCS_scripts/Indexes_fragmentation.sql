IF EXISTS(select 1 from tempdb.dbo.sysobjects where name = '##index_fragmentation_detail')			DROP TABLE ##index_fragmentation_detail


CREATE TABLE ##index_fragmentation_detail(
	ServerName VARCHAR(100),
	DatabaseName VARCHAR(100), 
	SchemaName VARCHAR(100), 
	TableName VARCHAR(100),
	IndexName VARCHAR(100),
	avg_fragmentation_in_percent varchar(20), 
	page_count varchar(20)
)


EXEC SP_MSFOREACHDB' USE [?] 
INSERT INTO ##index_fragmentation_detail 

select 
	@@SERVERNAME AS ServerName,
	DB_NAME() AS DatabaseName,
	dbschemas.[name] as [SchemaName], 
	dbtables.[name] as [TableName], 
	dbindexes.[name] as [IndexName],
	indexstats.avg_fragmentation_in_percent,
	indexstats.page_count
from sys.dm_db_index_physical_stats (DB_ID(), NULL, NULL, NULL, NULL) as indexstats
	INNER JOIN sys.tables dbtables on dbtables.[object_id] = indexstats.[object_id]
	INNER JOIN sys.schemas dbschemas on dbtables.[schema_id] = dbschemas.[schema_id]
	INNER JOIN sys.indexes as dbindexes on dbindexes.[object_id] = indexstats.[object_id]
		AND indexstats.index_id = dbindexes.index_id
where indexstats.database_id = DB_ID()
	AND indexstats.avg_fragmentation_in_percent >0
order by indexstats.avg_fragmentation_in_percent desc'


SELECT 
	*
	 
FROM ##index_fragmentation_detail
WHERE avg_fragmentation_in_percent > 50.00
AND page_count > 100

IF EXISTS(select 1 from tempdb.dbo.sysobjects where name = '##index_fragmentation_detail')			DROP TABLE ##index_fragmentation_detail