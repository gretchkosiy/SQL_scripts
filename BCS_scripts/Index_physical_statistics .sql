SELECT  
    DB_NAME() [DatabaseName],
	dbschemas.[name] as [SchemaName], 
	OBJECT_NAME(sd.OBJECT_ID) [TableName], 
	sd.index_id,
	si.name [IndexName],
	index_type_desc,
	alloc_unit_type_desc,
	index_level,
	avg_fragmentation_in_percent,
	avg_page_space_used_in_percent,
	page_count,
	fill_factor
	--,sd.*
FROM sys.dm_db_index_physical_stats (DB_ID(), NULL, NULL, NULL , 'SAMPLED') sd
	inner join sys.indexes si on si.object_id = sd.object_id and si.index_id = sd.index_id
	INNER JOIN sys.tables dbtables on dbtables.[object_id] = sd.[object_id]
	INNER JOIN sys.schemas dbschemas on dbtables.[schema_id] = dbschemas.[schema_id]
--WHERE OBJECT_NAME(sd.OBJECT_ID)  = 'Segment'
ORDER BY sd.avg_fragmentation_in_percent DESC