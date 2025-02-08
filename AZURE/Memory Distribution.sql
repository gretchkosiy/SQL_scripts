-- run on the database target of your investigation
-- DO NOT run on master

-- captures memory allocated to the 3 main memory areas
-- Buffer Pool
-- Plan Cache
-- Stolen Memory (Sorting, hashing etc)

SELECT 
(SELECT cntr_value /1024 FROM sys.dm_os_performance_counters WHERE counter_name = 'Stolen Server Memory (KB)') stolen_mb,
(SELECT SUM(pages_kb) / 1024 FROM sys.dm_os_memory_cache_counters WHERE TYPE in ('CACHESTORE_OBJCP', 'CACHESTORE_SQLCP', 'CACHESTORE_PHDR')) plan_cache_mb,
(SELECT COUNT (*) * 8 / 1024 FROM sys.dm_os_buffer_descriptors) buffer_pool_mb
GO

-- plan cache memory allocation

SELECT 
    SUM(CAST(size_in_bytes AS bigint))/1024/1024 AS SizeInMB
FROM sys.dm_exec_cached_plans

-- you can also look at how much memory is allocated to other memory areas

select * from sys.dm_os_memory_clerks order by pages_kb desc

-- detailed view of memory distribution for the Plan Cache

select * from sys.dm_os_memory_cache_counters order by pages_kb desc