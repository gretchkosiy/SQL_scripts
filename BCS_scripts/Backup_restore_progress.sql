SELECT 
	session_id as SPID, 
	percent_complete, 
	command, a.text AS Query, 
	start_time, 
	dateadd(second,estimated_completion_time/1000, getdate()) as estimated_completion_time 
FROM sys.dm_exec_requests r CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) a 
WHERE session_id <> @@SPID
and r.command in ('DbccFilesCompact','DBCC','BACKUP LOG' ,'BACKUP DATABASE',
				'RESTORE DATABASE','RESTORE HEADERONLY', 'DBCC TABLE CHECK', 
				'DBCC TABLE REPAIR', 'UPDATE STATISTICS', 'CREATE INDEX', 'ALTER TABLE')