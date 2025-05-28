/*

Find slow queries 

To establish that you have query performance issues on your SQL Server instance, 
start by examining queries by their execution time (elapsed time). 
Check if the time exceeds a threshold you have set (in milliseconds) 
based on an established performance baseline. 
For example, in a stress testing environment, you may have established a threshold 
for your workload to be no longer than 300 ms, and you can use this threshold. 
Then, you can identify all queries that exceed that threshold, 
focusing on each individual query and its pre-established performance baseline duration. 
Ultimately, business users care about the overall duration of database queries; 
therefore, the main focus is on execution duration. Other metrics like 
CPU time and logical reads are gathered to help with narrowing down the investigation. 

For currently executing statements, check?total_elapsed_time?and?
cpu_time?columns in?sys.dm_exec_requests. Run the following query to get the data: 

*/
 
 
SELECT req.session_id 
	, DB_NAME(req.database_id) as DatabaseName
	, req.total_elapsed_time ASduration_ms 
    , req.cpu_time AScpu_time_ms 
    , req.total_elapsed_time - req.cpu_time ASwait_time 
    , req.logical_reads 
    , SUBSTRING(REPLACE(REPLACE(SUBSTRING(ST.text, (req.statement_start_offset/2) + 1,  
       ((CASE statement_end_offset 
           WHEN-1 THEN DATALENGTH(ST.text)   
           ELSE req.statement_end_offset 
         END- req.statement_start_offset)/2) + 1) , CHAR(10), ' '), CHAR(13), ' '),  
      1, 8000)  ASstatement_text   
FROM sys.dm_exec_requests AS req 
    CROSS APPLY sys.dm_exec_sql_text(req.sql_handle) AS ST 
ORDER BY total_elapsed_time DESC;  
 

--For past executions of the query, check?last_elapsed_time?and?last_worker_time?columns in?sys.dm_exec_query_stats. Run the following query to get the data: 

 
SELECTt.text, 
     (qs.total_elapsed_time/1000) / qs.execution_count ASavg_elapsed_time, 
     (qs.total_worker_time/1000) / qs.execution_count ASavg_cpu_time, 
     ((qs.total_elapsed_time/1000) / qs.execution_count ) - ((qs.total_worker_time/1000) / qs.execution_count) ASavg_wait_time, 
     qs.total_logical_reads / qs.execution_count ASavg_logical_reads, 
     qs.total_logical_writes / qs.execution_count ASavg_writes, 
     (qs.total_elapsed_time/1000) AScumulative_elapsed_time_all_executions 
FROMsys.dm_exec_query_stats qs 
     CROSSapplysys.Dm_exec_sql_text (sql_handle) t 
WHEREt.text like'<Your Query>%'-- Replace <Your Query> with your query or the beginning part of your query. The special chars like '[','_','%','^' in the query should be escaped.ORDERBY(qs.total_elapsed_time / qs.execution_count) DESC 

 

--From <https://learn.microsoft.com/en-us/troubleshoot/sql/database-engine/performance/troubleshoot-slow-running-queries>  