SELECT
sh.name AS SchemaName,
t.name AS TableName,
c.name AS ColumnName,
s.name AS StatName,
STATS_DATE(s.[object_id], s.stats_id) AS LastUpdated,
s.has_filter,
s.filter_definition,
s.auto_created,
s.user_created,
s.no_recompute
FROM sys.stats s
JOIN sys.stats_columns sc ON sc.[object_id] = s.[object_id] AND sc.stats_id = s.stats_id
JOIN sys.columns c ON c.[object_id] = sc.[object_id] AND c.column_id = sc.column_id
JOIN sys.tables t ON s.[object_id] = t.[object_id]
join sys.schemas sh on sh.schema_id = t.schema_id
WHERE t.is_ms_shipped = 0
	and (auto_created = 1 or user_created = 1)
ORDER BY t.name,s.name,c.name;