USE MSDB 
GO

-- not working for sql 2000


DECLARE @sqlCommand nvarchar(1000)
declare @counts int
IF (substring(convert(char(12),serverproperty('productversion')), 1, 2) = '10' 
	AND substring(convert(char(12),serverproperty('productversion')), 4, 2) = '50')
	OR substring(convert(char(12),serverproperty('productversion')), 1, 2) = '13' 
	SET @sqlCommand = 'SELECT @cnt=count(*) FROM msdb.dbo.sysssislog'
ELSE 
	SET @sqlCommand = 'SELECT @cnt=count(*) FROM msdb.dbo.sysdtslog90'

EXECUTE sp_executesql @sqlCommand, N'@cnt int OUTPUT', @cnt=@counts OUTPUT

;with fs
as
(
    select database_id, type, size * 8 / 1024 size
    from sys.master_files
)
select
@@SERVERNAME [ServerName]
,name
,(select sum(size) from fs where type = 0 and fs.database_id = db.database_id) DataFileSizeMB
,CAST(CAST(FILEPROPERTY('MSDBdata', 'SpaceUsed') AS int)/128 AS varchar) as MSDB_used
,(select sum(size) from fs where type = 1 and fs.database_id = db.database_id) LogFileSizeMB
,(Select count(*) FROM msdb.[dbo].[log_shipping_monitor_history_detail]) LS_history
,(Select count(*) FROM msdb.[dbo].[log_shipping_monitor_error_detail]) LS_errors
,(Select count(*) FROM msdb.[dbo].[sysjobhistory]) Job_History
,(Select count(*) FROM msdb.[dbo].[backupfile]) Backup_Files
,(Select count(*) FROM msdb.[dbo].[backupset]) Backup_Set
,(Select count(*) FROM msdb.[dbo].[backupmediafamily]) [backupmediafamily]
,(Select count(*) FROM msdb.[dbo].[logmarkhistory]) [logmarkhistory]
,(Select count(*) FROM msdb.[dbo].sysmail_attachments) sysmail_attachments
,(Select count(*) FROM msdb.[dbo].sysmail_log) sysmail_log -- "Database mail log"
,(Select count(*) FROM msdb.[dbo].sysmail_send_retries) sysmail_send_retries
,(Select count(*) FROM msdb.[dbo].sysmail_allitems) sysmail_allitems
,(Select count(*) FROM msdb.sys.transmission_queue) transmission_queue  -- service broker 
--,(Select count(*) FROM msdb.dbo.sysdtslog90)  sysdtslog90
, @counts sysdtslog90
,(select count(*)  from msdb.dbo.sysmaintplan_log) sysmaintplan_log
,(select count(*)  from msdb.dbo.sysmaintplan_logdetail) sysmaintplan_logdetail

from sys.databases db
WHERE name in ('msdb')

-- ,(Select count(*) FROM msdb.sys.sysxmitqueue) sysxmitqueue - ????

-- http://blog.devart.com/reduce-msdb-big-size.html

--- 19/06/2023
-- SELECT COUNT(*)  FROM msdb.dbo.syspolicy_policy_execution_history_internal
-- SELECT COUNT(*)  FROM  msdb.dbo.syspolicy_policies 



-- ????? [sys].[sp_cleanup_log_shipping_history]  - is managed by LS itself
-- but [dbo].[log_shipping_monitor_error_detail] 
-- and [dbo].[log_shipping_monitor_history_detail] can be cleaned filtered by date ([log_time_utc] - indexed) or by DBname ([database_name])


-- https://docs.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sysmail-delete-mailitems-sp-transact-sql
-- delete all email information including attachments (except sysmail_log table)
-- [dbo].[sysmail_delete_mailitems_sp] @sent_status = unsent, sent, failed, retrying

-- [dbo].[sysmail_delete_log_sp]   '@event_type', 'success, warning, error, information'
   -- only sysmail_log 

--  [dbo].[sp_purge_jobhistory]
	-- only sysjobhistory

-- [dbo].[sp_delete_database_backuphistory] - @database_name
-- [dbo].[sp_delete_backuphistory] - @oldest_date 
  --BOTH cleaning
	--backupfile
	--backupfilegroup
	--backupset
	--backupmediafamily
	--backupmediaset
	--restorefile
	--restorefilegroup
	--restorehistory

-- [dbo].[sp_maintplan_delete_log]
   --Scenario 1: User wants to delete all logs
   --Scenario 2: User wants to delete all logs older than X date
   --Scenario 3: User wants to delete all logs for a given plan
   --Scenario 4: User wants to delete all logs for a specific subplan
   --Scenario 5: User wants to delete all logs for a given plan older than X date
   --Scenario 6: User wants to delete all logs for a specific subplan older than X date


--SELECT object_name(i.object_id) AS TableName,
--i.[name] AS IndexName,
--(sum(a.total_pages)*8)/1024 AS TotalSpaceMB,
--(sum(a.used_pages)*8)/1024 AS UsedSpaceMB,
--(sum(a.data_pages)*8)/1024 AS DataSpaceMB
--FROM sys.indexes i
--INNER JOIN sys.partitions p
--ON i.object_id = p.object_id
--AND i.index_id = p.index_id
--INNER JOIN sys.allocation_units a
--ON p.partition_id = a.container_id
--WHERE object_name(i.object_id) = 'sysxmitqueue'
--GROUP BY i.object_id, i.[name]