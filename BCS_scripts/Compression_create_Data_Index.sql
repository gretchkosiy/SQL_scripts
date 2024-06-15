-- table data compression
DECLARE @SQLscript VARCHAR(MAX) 
DECLARE db_cursor CURSOR FOR  
SELECT 
        --[t].[name] AS [Table]
  --     , [p].[partition_number] AS [Partition]
  --     , [p].[data_compression_desc] AS [Compression]
       --  , a.used_pages AS UsedPages
       --  , 
--          'ALTER TABLE [' + [ss].[name] + '].[' + [t].[name] + '] REBUILD PARTITION = ' + CAST([p].[partition_number] AS VARCHAR(5)) + ' WITH(DATA_COMPRESSION = PAGE )' AS SCRIPT
          'ALTER TABLE [' + [ss].[name] + '].[' + [t].[name] + '] REBUILD WITH(DATA_COMPRESSION = PAGE )' AS SCRIPT
FROM [sys].[partitions] AS [p]
INNER JOIN sys.tables AS [t] ON [t].[object_id] = [p].[object_id]
INNER JOIN sys.allocation_units a ON a.container_id = p.partition_id
INNER JOIN sys.schemas ss on ss.schema_id = t.schema_id

WHERE [p].[index_id] in (0,1)
--and [t].[name] = 'TBL_AuditLogActivity'
and [p].[data_compression_desc] = 'NONE'

OPEN db_cursor   
FETCH NEXT FROM db_cursor INTO @SQLscript   
WHILE @@FETCH_STATUS = 0   
BEGIN  
          PRINT @SQLscript  
		  PRINT 'GO'
          --EXEC(@SQLscript) 
       FETCH NEXT FROM db_cursor INTO @SQLscript   
END   
CLOSE db_cursor   
DEALLOCATE db_cursor

-- indexes compression
--DECLARE @SQLscript VARCHAR(MAX) 
DECLARE db_cursor CURSOR FOR  
SELECT 
       --[t].[name] AS [Table]
       --, [i].[name] AS [Index]
       --, [p].[partition_number] AS [Partition]
       --, [p].[data_compression_desc] AS [Compression]
       --, 
--       'ALTER INDEX [' + [ss].[name] + '].[' + [i].[name]  + '] ON [' + [t].[name] + '] REBUILD PARTITION = ' + CAST([p].[partition_number] AS VARCHAR(5)) + ' WITH (SORT_IN_TEMPDB = ON, DATA_COMPRESSION = PAGE )' AS SCRIPT
       'ALTER INDEX [' + [i].[name]  + '] ON [' + [ss].[name] + '].[' + [t].[name] + '] REBUILD WITH (SORT_IN_TEMPDB = ON, DATA_COMPRESSION = PAGE )' AS SCRIPT
FROM [sys].[partitions] AS [p]
INNER JOIN sys.tables AS [t] ON [t].[object_id] = [p].[object_id]
INNER JOIN sys.indexes AS [i] ON [i].[object_id] = [p].[object_id] AND [i].[index_id] = [p].[index_id]
INNER JOIN sys.schemas ss on ss.schema_id = t.schema_id
WHERE [p].[index_id] > 1
--and [t].[name] = 'TBL_AuditLogActivity'
and [p].[data_compression_desc] = 'NONE'
--and [p].[partition_number] = 10

OPEN db_cursor   
FETCH NEXT FROM db_cursor INTO @SQLscript   
WHILE @@FETCH_STATUS = 0   
BEGIN   
          PRINT @SQLscript
          --EXEC(@SQLscript) 
		  PRINT 'GO'
       FETCH NEXT FROM db_cursor INTO @SQLscript   
END   
CLOSE db_cursor   
DEALLOCATE db_cursor
