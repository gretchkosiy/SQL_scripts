SELECT '[' + SCHEMA_NAME(t.schema_id) + '].[' + [t].[name] + ']' AS [Table]
	, [p].[partition_number] AS [Partition]
	, [p].[data_compression_desc] AS [Compression]
FROM [sys].[partitions] AS [p]
INNER JOIN sys.tables AS [t] ON [t].[object_id] = [p].[object_id]
WHERE [p].[index_id] in (0,1)
ORDER BY 1,2

SELECT 
	'[' + SCHEMA_NAME(t.schema_id) + '].[' + [t].[name] + ']' AS [Table],
	[i].[name] AS [Index],  
    [p].[partition_number] AS [Partition],
    [p].[data_compression_desc] AS [Compression]
FROM [sys].[partitions] AS [p]
INNER JOIN sys.tables AS [t] ON [t].[object_id] = [p].[object_id]
INNER JOIN sys.indexes AS [i] ON [i].[object_id] = [p].[object_id] AND [i].[index_id] = [p].[index_id]
WHERE [p].[index_id] > 1
ORDER BY 1,2,3