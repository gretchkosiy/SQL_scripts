/*
Run on the database target of your investigation
DO NOT run on master.
*/

-- plan cache memory consumed by single-use plans
SELECT 
    AVG(usecounts) AS Avg_UseCount,
    SUM(refcounts) AS AllRefObjects,
    SUM(CAST(size_in_bytes AS bigint))/1024/1024 AS SizeInMB
FROM sys.dm_exec_cached_plans
WHERE usecounts = 1

-- plan cache memory consumed by reused plans
SELECT 
    AVG(usecounts) AS Avg_UseCount,
    SUM(refcounts) AS AllRefObjects,
    SUM(CAST(size_in_bytes AS bigint))/1024/1024 AS SizeInMB
FROM sys.dm_exec_cached_plans
WHERE usecounts > 1

-- detailed view of plans in the plan cache with respective use counts and sizes
SELECT * FROM sys.dm_exec_cached_plans cp CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle)