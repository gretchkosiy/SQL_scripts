/*
Run on the database target of your investigation
DO NOT run on master.
*/

-- disk latency introduced by Resource Governance and by normal operations since SQL Server last start up
SELECT
    [ReadLatencyByGovernance] =
        CASE WHEN [num_of_reads] = 0
            THEN 0 ELSE ([io_stall_queued_read_ms] / [num_of_reads]) END,
    [WriteLatencyByGovernance] =
        CASE WHEN [num_of_writes] = 0
            THEN 0 ELSE ([io_stall_queued_write_ms] / [num_of_writes]) END,
    [ReadLatency] =
        CASE WHEN [num_of_reads] = 0
            THEN 0 ELSE ([io_stall_read_ms] / [num_of_reads]) END,
    [WriteLatency] =
        CASE WHEN [num_of_writes] = 0
            THEN 0 ELSE ([io_stall_write_ms] / [num_of_writes]) END,
    [Latency] =
        CASE WHEN ([num_of_reads] = 0 AND [num_of_writes] = 0)
            THEN 0 ELSE ([io_stall] / ([num_of_reads] + [num_of_writes])) END,
    [AvgBPerRead] =
        CASE WHEN [num_of_reads] = 0
            THEN 0 ELSE ([num_of_bytes_read] / [num_of_reads]) END,
    [AvgBPerWrite] =
        CASE WHEN [num_of_writes] = 0
            THEN 0 ELSE ([num_of_bytes_written] / [num_of_writes]) END,
    [AvgBPerTransfer] =
        CASE WHEN ([num_of_reads] = 0 AND [num_of_writes] = 0)
            THEN 0 ELSE
                (([num_of_bytes_read] + [num_of_bytes_written]) /
                ([num_of_reads] + [num_of_writes])) END,
    DB_NAME ([vfs].[database_id]) AS [DB],
[vfs].file_id

FROM
    sys.dm_io_virtual_file_stats (NULL,NULL) AS [vfs]
-- WHERE [vfs].[file_id] = 2 -- log files
-- ORDER BY [Latency] DESC
-- ORDER BY [ReadLatency] DESC
ORDER BY [WriteLatency] DESC;