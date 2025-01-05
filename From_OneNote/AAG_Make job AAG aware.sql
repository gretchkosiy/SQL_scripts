


  

DECLARE @jobName nvarchar(max)  = 'BCS SQL Server Errorlog Cycle (12am daily)' 

DECLARE @AAGname nvarchar(max) = '<AG NAME>' 

DECLARE @job_ID nvarchar(max)  

DECLARE @TSQL nvarchar(max)  

  

SET @TSQL =  

'DECLARE @AAGname VARCHAR(20) 

SET @AAGname = ''' + @AAGname + ''' 

  

IF (SUBSTRING(CAST(SERVERPROPERTY(''ProductVersion'') AS VARCHAR(20)),1,CHARINDEX(''.'',CAST(SERVERPROPERTY(''ProductVersion'') AS VARCHAR(20)))-1) > 10) 

BEGIN  

-- SQL 2012 or later 

IF (SELECT COUNT(*) FROM sys.dm_hadr_availability_replica_states) > 0  

BEGIN 

--- AAG exists 

IF (SUBSTRING(CAST(SERVERPROPERTY(''Edition'') AS VARCHAR(MAX)),1,LEN(''Enterprise'')) = ''Enterprise'') 

OR (SUBSTRING(CAST(SERVERPROPERTY(''Edition'') AS VARCHAR(MAX)),1,LEN(''Developer'')) = ''Developer'') 

BEGIN  

-- full AAG 

IF (SELECT LOWER(RS.role_desc) 

FROM sys.dm_hadr_availability_replica_states RS 

JOIN sys.availability_groups AG ON RS.group_id = AG.group_id AND RS.is_local = 1 

WHERE AG.Name = @AAGname 

) <> ''primary'' 

BEGIN 

-- Secondary node, exit here! 

PRINT ''is NOT Primary Replica''; 

RAISERROR(''NOT Primary Replica'', 16,1)  

END 

END 

ELSE  

BEGIN 

--BAG only  

IF (SELECT TOP 1 LOWER(RS.role_desc) 

FROM sys.dm_hadr_availability_replica_states RS 

JOIN sys.availability_groups AG ON RS.group_id = AG.group_id AND RS.is_local = 1 

) <> ''primary'' 

BEGIN 

-- Secondary node, exit here! 

PRINT ''is NOT Primary Replica''; 

RAISERROR(''NOT Primary Replica'', 16,1)  

END 

END 

END 

END' 

  

  

  

  

-- Get job_id 

SELECT @job_ID = job_id 

FROM msdb.dbo.sysjobs 

where name = @jobName 

  

-- Add new AAG check step as first step  

DECLARE @step_id INT = 1  

IF NOT EXISTS (SELECT 1 FROM msdb.dbo.sysjobsteps WHERE job_id = @job_ID AND step_id = 1 AND [step_name] = N'Check AG Replica Status') 

EXEC msdb.dbo.sp_add_jobstep  

  @job_id= @job_ID,  

  @step_name=N'Check AG Replica Status',  

  @step_id=@step_id,  

  @cmdexec_success_code=0,  

  @on_success_action=3,       -- ON SUCCESS – go to the next step  

  @on_fail_action=1,          -- ON FAILURE – quit the job reporting success 

  @retry_attempts=0,  

  @retry_interval=0,  

  @os_run_priority=0,  

  @subsystem=N'TSQL',  

  @command=@TSQL,  

  @database_name=N'master',  

  @flags=0 

  

-- REVERT 

/* 

  

GO 

DECLARE @jobName nvarchar(max)  = 'BCS SQL Server Errorlog Cycle (12am daily)' 

DECLARE @job_ID nvarchar(max)  

DECLARE @step_id INT = 1  

  

-- Get job_id 

SELECT @job_ID = job_id 

FROM msdb.dbo.sysjobs 

where name = @jobName 

  

IF EXISTS (SELECT 1 FROM msdb.dbo.sysjobsteps WHERE job_id = @job_ID AND step_id = 1 AND [step_name] = N'Check AG Replica Status') 

EXEC msdb.dbo.sp_delete_jobstep  @job_name = @jobName, @step_id = @step_id 

  

*/ 

  