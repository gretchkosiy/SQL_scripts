-- Run on the database target of your investigation
-- DO NOT run on master.

-- When did the logical server last start?
select sqlserver_start_time from sys.dm_os_sys_info

-- service level objective (SLO)
-- with this information you can look at the resource limits
-- depending on whether this is a single database using the vCore or DTU purchasing model, or an elastic pool
-- DTU model for single databases: https://learn.microsoft.com/en-us/azure/azure-sql/database/resource-limits-dtu-single-databases?view=azuresql
-- DTU model for elastic pool: https://learn.microsoft.com/en-us/azure/azure-sql/database/resource-limits-dtu-elastic-pools?view=azuresql
-- vCore model for single database: https://learn.microsoft.com/en-us/azure/azure-sql/database/resource-limits-vcore-single-databases?view=azuresql-db
-- vCore model for elastic pool: https://learn.microsoft.com/en-us/azure/azure-sql/database/resource-limits-vcore-elastic-pools?view=azuresql
select * from sys.database_service_objectives

-- quick way to find out how many vCores are allocated to the database
SELECT 
    COUNT(*) as vCores
FROM sys.dm_os_schedulers
WHERE status = N'VISIBLE ONLINE';
GO

-- resource quotas determined by resource governance for the database
SELECT 
server_name, 
database_name,
slo_name AS service_level_objective, 
user_data_directory_space_quota_mb / 1024 AS max_storage_gb, -- maximum storage allowed by resource governance
user_data_directory_space_usage_mb / 1024 AS current_storage_usage_gb, -- current storage consumption by data files, T-log files and tempdb files
primary_group_max_io AS max_iops, -- maximum IOPS allowed by resource governance
pool_max_io AS pool_max_iops, -- maximum IOPS for a database on elastic pool
primary_group_max_cpu AS max_cpu_percent, -- maximum CPU % limited by resource governance
max_dop, -- will return MAXDOP for the database limited by resource governance, regardless of purchasing model
cpu_limit AS vcore_limit, -- will return NULL or zero if under DTU purchasing model
dtu_limit AS dtu_limit, -- will return NULL or zero if under vCore purchasing model
max_db_memory / 1024 / 1024 AS max_db_memory_gb -- maximum memory allowed for the database
FROM sys.dm_user_db_resource_governance

-- list all settings
select * from sys.configurations order by name

-- database scoped settings
SELECT configuration_id, name, value
FROM sys.database_scoped_configurations
ORDER BY name

-- database files and sizes
select * from sys.database_files

SELECT SUM(CAST(FILEPROPERTY(name, 'SpaceUsed') AS decimal(19,4)) * 8 / 1024.) AS space_used_mb,
       SUM(CAST(size/128.0 - CAST(FILEPROPERTY(name, 'SpaceUsed') AS int)/128.0 AS decimal(19,4))) AS space_unused_mb,
       SUM(CAST(size AS decimal(19,4)) * 8 / 1024.) AS space_allocated_mb,
       SUM(CAST(max_size AS decimal(19,4)) * 8 / 1024.) AS max_size_mb
FROM sys.database_files;

SELECT file_id, type_desc, name,
       CAST(FILEPROPERTY(name, 'SpaceUsed') AS decimal(19,4)) * 8 / 1024. AS space_used_mb,
       CAST(size/128.0 - CAST(FILEPROPERTY(name, 'SpaceUsed') AS int)/128.0 AS decimal(19,4)) AS space_unused_mb,
       CAST(size AS decimal(19,4)) * 8 / 1024. AS space_allocated_mb,
       CAST(max_size AS decimal(19,4)) * 8 / 1024. AS max_size_mb
FROM sys.database_files;

EXEC master.sys.sp_MSforeachdb 'USE [?];
SELECT ''?'' as name, (
SELECT SUM(CAST(FILEPROPERTY(name, ''SpaceUsed'') AS decimal(19,4)) * 8 / 1024.)
FROM sys.database_files
WHERE type_desc = ''ROWS'') as space_used_mb'

-- recent connection failures (this one must be run on master)
DECLARE @s datetime;  
DECLARE @e datetime; 
SET @s= DateAdd(d,-7,GETUTCDATE());  
SET @e= GETUTCDATE();  

SELECT database_name, start_time, end_time, event_category,
event_type, event_subtype, event_subtype_desc, severity,
event_count, description
FROM sys.event_log
WHERE event_type = 'connection_failed'
    AND event_subtype = 4
    AND start_time BETWEEN @s AND @e
	
-- out of memory events
SELECT * FROM sys.dm_os_out_of_memory_events ORDER BY event_time DESC;  

