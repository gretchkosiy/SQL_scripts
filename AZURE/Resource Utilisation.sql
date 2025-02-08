-- detailed resource utilisation as percentage of service tier limit for the past 14 days
-- useful for charting utilisation over time in Excel
-- must run on master

USE master
GO
SELECT 
end_time AS UTC_time, 
avg_cpu_percent,
avg_instance_cpu_percent,
avg_data_io_percent, 
avg_log_write_percent, 
avg_instance_memory_percent, 
max_worker_percent, 
max_session_percent,
dtu_limit,
cpu_limit,
allocated_storage_in_megabytes,
storage_in_megabytes
FROM sys.resource_stats


-- resource utilisation for the past hour only
-- results are percentage of service tier limit
-- must run on the database target of your investigation
SELECT
    database_name = DB_NAME()
,   UTC_time = end_time
,   'CPU Utilization In % of Limit'           = rs.avg_cpu_percent
,   'Data IO In % of Limit'                   = rs.avg_data_io_percent
,   'Log Write Utilization In % of Limit'     = rs.avg_log_write_percent
,   'Memory Usage In % of Limit'              = rs.avg_memory_usage_percent 
,   'In-Memory OLTP Storage in % of Limit'    = rs.xtp_storage_percent
,   'Concurrent Worker Threads in % of Limit' = rs.max_worker_percent
,   'Concurrent Sessions in % of Limit'       = rs.max_session_percent
FROM sys.dm_db_resource_stats AS rs  --past hour only
ORDER BY  rs.end_time DESC;


-- summary of resource utilisation as percentage of service tier limit for the past 14 days
-- must run on master
SELECT sku, database_name, 
AVG(avg_cpu_percent) AS avg_cpu_percent, 
MAX(storage_in_megabytes)  max_storage_in_megabytes,
AVG(avg_data_io_percent) AS avg_data_io_percent,
MAX(avg_data_io_percent) AS max_data_io_percent,
AVG(avg_log_write_percent) AS avg_log_write_percent,
MAX(avg_log_write_percent) AS max_log_write_percent,
AVG(avg_instance_cpu_percent) AS avg_instance_cpu_percent,
MAX(avg_instance_cpu_percent) AS max_instance_cpu_percent,
AVG(avg_instance_memory_percent) AS avg_instance_memory_percent,
MAX(avg_instance_memory_percent) AS max_instance_memory_percent,
MAX(max_worker_percent) AS max_worker_percent,
MAX(max_session_percent) AS max_session_percent
FROM sys.resource_stats
GROUP BY sku, database_name  
