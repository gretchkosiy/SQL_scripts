SELECT 
	s.name AS SchemaName,
    t.NAME AS TableName,
	--i.index_id,
    ISNULL(i.name,'') as indexName,
    p.[Rows],
    sum(a.total_pages) as TotalPages, 
    sum(a.used_pages) as UsedPages, 
    sum(a.data_pages) as DataPages,
    (sum(a.total_pages) * 8) / 1024 as TotalSpaceMB, 
    (sum(a.used_pages) * 8) / 1024 as UsedSpaceMB, 
    (sum(a.data_pages) * 8) / 1024 as DataSpaceMB,
	ISNULL(SUM(z.INDEXsizeMB),0) as IndexesSpaceMB

FROM 
    sys.tables t
INNER JOIN      
    sys.indexes i ON t.OBJECT_ID = i.object_id
INNER JOIN 
    sys.partitions p ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id
INNER JOIN 
    sys.allocation_units a ON p.partition_id = a.container_id
INNER JOIN 
	sys.schemas s ON s.schema_id = t.schema_id

LEFT JOIN (
			SELECT
			OBJECT_SCHEMA_NAME(i.OBJECT_ID) AS SchemaName,
			OBJECT_NAME(i.OBJECT_ID) AS TableName,
			(8 * SUM(a.used_pages))/1024 AS 'INDEXsizeMB'
			FROM sys.indexes AS i
			JOIN sys.partitions AS p ON p.OBJECT_ID = i.OBJECT_ID AND p.index_id = i.index_id
			JOIN sys.allocation_units AS a ON a.container_id = p.partition_id
			WHERE i.index_id > 1
			GROUP BY i.OBJECT_ID) z on z.SchemaName = s.name and z.TableName = t.name
WHERE 
    t.NAME NOT LIKE 'dt%' AND
    i.OBJECT_ID > 255 AND   
    i.index_id <= 1
GROUP BY 
    t.NAME, i.object_id, i.index_id, i.name, p.[Rows] , s.name
ORDER BY 
    s.name, object_name(i.object_id) 