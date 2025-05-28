/*
Run the script on the database target of your investigation
DO NOT RUN ON master
*/

DECLARE @EngineEdition INT = CAST(SERVERPROPERTY(N'EngineEdition') AS INT)
;WITH XMLNAMESPACES (DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/showplan')
,planCache
AS(
    SELECT 
        *
    FROM sys.dm_exec_query_stats as qs WITH(NOLOCK)
    CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) as qp
    WHERE qp.query_plan.exist('/ShowPlanXML/BatchSequence/Batch/Statements/StmtSimple/QueryPlan/MissingIndexes/MissingIndexGroup/MissingIndex')=1
), analyzedPlanCache
AS(
    SELECT 
        sql_text = T.C.value('(@StatementText)[1]', 'nvarchar(max)')
        ,[impact %] = T.C.value('(./QueryPlan/MissingIndexes/MissingIndexGroup/@Impact)[1]', 'float')
        ,[cachedPlanSize (KB)] = T.C.value('(./QueryPlan/@CachedPlanSize)[1]', 'int')
        ,[compileTime (ms)] = T.C.value('(./QueryPlan/@CompileTime)[1]', 'int')
        ,[compileCPU (ms)] = T.C.value('(./QueryPlan/@CompileCPU)[1]', 'int')
        ,[compileMemory (KB)] = T.C.value('(./QueryPlan/@CompileMemory)[1]', 'int')
        ,database_name = T.C.value('(./QueryPlan/MissingIndexes/MissingIndexGroup/MissingIndex/@Database)[1]','varchar(128)')
        ,schema_name = T.C.value('(./QueryPlan/MissingIndexes/MissingIndexGroup/MissingIndex/@Schema)[1]','varchar(128)')
        ,object_name = T.C.value('(./QueryPlan/MissingIndexes/MissingIndexGroup/MissingIndex/@Table)[1]','varchar(128)')
        ,equality_columns = (
            SELECT 
                DISTINCT tb.col.value('(@Name)[1]', 'sysname') + ','
            FROM T.c.nodes('./QueryPlan/MissingIndexes/MissingIndexGroup/MissingIndex/ColumnGroup') AS T(cg)
                CROSS APPLY T.cg.nodes('./Column') AS tb(col)
            WHERE T.cg.value('(@Usage)[1]', 'varchar(128)') = 'EQUALITY'
            FOR  XML PATH('')
        )
        ,inequality_columns = (
            SELECT 
                DISTINCT tb.col.value('(@Name)[1]', 'sysname') + ','
            FROM T.c.nodes('./QueryPlan/MissingIndexes/MissingIndexGroup/MissingIndex/ColumnGroup') AS T(cg)
                CROSS APPLY T.cg.nodes('./Column') AS tb(col)
            WHERE T.cg.value('(@Usage)[1]', 'varchar(128)') = 'INEQUALITY'
            FOR  XML PATH('')
        )
        ,include_columns = (
            SELECT 
                DISTINCT tb.col.value('(@Name)[1]', 'sysname') + ','
            FROM T.c.nodes('./QueryPlan/MissingIndexes/MissingIndexGroup/MissingIndex/ColumnGroup') AS T(cg)
                CROSS APPLY T.cg.nodes('./Column') AS tb(col)
            WHERE T.cg.value('(@Usage)[1]', 'varchar(128)') = 'INCLUDE'
            FOR  XML PATH('')
        )
        ,pc.*
    FROM planCache AS pc
        CROSS APPLY query_plan.nodes('/ShowPlanXML/BatchSequence/Batch/Statements/StmtSimple') AS T(C)
    WHERE C.exist('./QueryPlan/MissingIndexes/MissingIndexGroup/MissingIndex') = 1
)
SELECT 
    plan_handle
    ,query_plan
    ,query_hash
    ,query_plan_hash
    ,sql_text
    ,[impact %]
    ,[cachedPlanSize (KB)]
    ,[compileTime (ms)]
    ,[compileCPU (ms)]
    ,[compileMemory (KB)]
    ,object = database_name + '.' + schema_name + '.' + object_name
	--,equality_columns
	--,inequality_columns
	--,include_columns
    ,missing_index_creation = 
            N'CREATE NONCLUSTERED INDEX ' 
			+ QUOTENAME(N'IX'
			+ CASE WHEN equality_columns is not null THEN N'_' + REPLACE(REPLACE(REPLACE(LEFT(equality_columns, len(equality_columns) - 1), N',', N'_'), N'[', N''), N']', N'') ELSE N'' END
			+ CASE WHEN inequality_columns is not null THEN N'_' + REPLACE(REPLACE(REPLACE(LEFT(inequality_columns, len(inequality_columns) - 1), N',', N'_'), N'[', N''), N']', N'') ELSE N'' END
			+ CASE WHEN include_columns is not null THEN N'_' + REPLACE(REPLACE(REPLACE(LEFT(include_columns, len(include_columns) - 1), N',', N'_'), N'[', N''), N']', N'') ELSE N'' END
			+ N'')
            + N' ON ' + database_name + '.' + schema_name + '.' + object_name 
            + QUOTENAME(
                CASE 
                    WHEN equality_columns is not null and inequality_columns is not null 
                        THEN equality_columns + LEFT(inequality_columns, len(inequality_columns) - 1)
                    WHEN equality_columns is not null and inequality_columns is null 
                        THEN LEFT(equality_columns, len(equality_columns) - 1)
                    WHEN inequality_columns is not null 
                        THEN LEFT(inequality_columns, len(inequality_columns) - 1)
                END
                , N'()')
            + CASE 
                    WHEN include_columns is not null 
                    THEN N' INCLUDE ' + QUOTENAME(REPLACE(LEFT(include_columns, len(include_columns) - 1), N'@', N''), N'()')
                    ELSE N''
                END
            + CASE @EngineEdition 
                    WHEN 3 THEN N' WITH (ONLINE = ON)' 
                    ELSE N''
                END 
			+ N';'
    ,creation_time
    ,last_execution_time
    ,execution_count
    ,(total_worker_time / 1000.0) AS [total_worker_time (ms)]
    ,(last_worker_time / 1000.0) AS [last_worker_time (ms)]
    ,(min_worker_time / 1000.0) AS [min_worker_time (ms)]
    ,(max_worker_time / 1000.0) AS [max_worker_time (ms)]
    ,total_physical_reads
    ,last_physical_reads
    ,min_physical_reads
    ,max_physical_reads
    ,total_logical_writes
    ,last_logical_writes
    ,min_logical_writes
    ,max_logical_writes
    ,total_logical_reads
    ,last_logical_reads
    ,min_logical_reads
    ,max_logical_reads
    ,(total_clr_time / 1000.0) AS [total_clr_time (ms)]
    ,(last_clr_time / 1000.0) AS [last_clr_time (ms)]
    ,(min_clr_time / 1000.0) AS [min_clr_time (ms)]
    ,(max_clr_time / 1000.0) AS [max_clr_time (ms)]
    ,(total_elapsed_time / 1000.0) AS [total_elapsed_time (ms)]
    ,(last_elapsed_time / 1000.0) AS [last_elapsed_time (ms)]
    ,(min_elapsed_time / 1000.0) AS [min_elapsed_time (ms)]
    ,(max_elapsed_time / 1000.0) AS [max_elapsed_time (ms)]
    ,total_rows
    ,last_rows
    ,min_rows
    ,max_rows
FROM analyzedPlanCache
WHERE dbid = DB_ID()