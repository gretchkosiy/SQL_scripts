
-- locks
SELECT * FROM sys.dm_tran_locks
--«To view blocking:

SELECT sessionjd, blocking_session_id,
 start_time, status, command,
DB_NAME(database_id) as [database],
wait_type, wait_resource, wait_time,
open_transaction_count
FROM sys.dm_exec_requests
WHERE blocking_session_id > 0;