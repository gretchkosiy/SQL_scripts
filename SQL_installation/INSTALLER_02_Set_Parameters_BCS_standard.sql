
USE [master]
GO
/* 0 = Allow Local Connection, 1 = Allow Remote Connections*/ 
sp_configure 'remote admin connections', 1 
GO
RECONFIGURE
GO

ALTER DATABASE [master] MODIFY FILE ( NAME = N'master', FILEGROWTH = 16384KB )
GO
ALTER DATABASE [model] MODIFY FILE ( NAME = N'modeldev', FILEGROWTH = 262144KB )
GO
ALTER DATABASE [msdb] MODIFY FILE ( NAME = N'MSDBData', FILEGROWTH = 32768KB )
GO
EXEC sys.sp_configure N'backup compression default', N'1'
GO
RECONFIGURE WITH OVERRIDE
GO

-- Set number of error logs to 40
EXEC xp_instance_regwrite N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', N'NumErrorLogs', REG_DWORD, 40
GO

-- MultiServer administration

declare @dirBIN nvarchar(4000)
declare @InstanceID nvarchar(4000)
DECLARE @value VARCHAR(20)
DECLARE @key VARCHAR(100)

exec master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE',N'Software\Microsoft\MSSQLServer\Setup',N'SQLBinRoot', @dirBIN output, 'no_output'
Select @InstanceID = SUBSTRING(@dirBIN,CHARINDEX('SQL Server\', @dirBIN)+11,CHARINDEX('\MSSQL\Binn', @dirBIN) -  CHARINDEX('SQL Server\', @dirBIN)-11) 

SET @key = 'SOFTWARE\Microsoft\Microsoft SQL Server\' + @InstanceID + '\SQLServerAgent'

EXEC master..xp_regread
   @rootkey = 'HKEY_LOCAL_MACHINE',
   @key = @key,
   @value_name = 'MsxEncryptChannelOptions',
   @value = @value OUTPUT

--SELECT @InstanceID, CASE WHEN @value = 0x0 THEN 'MSX ready' ELSE '' END


EXEC xp_regwrite N'HKEY_LOCAL_MACHINE', @key, 'MsxEncryptChannelOptions', REG_DWORD, 0
GO

USE [msdb]
GO
-- set job hisory unlimited
EXEC msdb.dbo.sp_set_sqlagent_properties @jobhistory_max_rows=-1, @jobhistory_max_rows_per_job=-1
GO

-- Create MSDB Optimization Indexes
-- Reduces Backup History Cleanup Duration Massively
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE OBJECT_ID = OBJECT_ID('[dbo].[backupset]') AND name = 'BCS_BackupSet_FinDate_MediaSet')
	CREATE NONCLUSTERED INDEX BCS_BackupSet_FinDate_MediaSet ON backupset(backup_finish_date) include (media_set_id)
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE OBJECT_ID = OBJECT_ID('[dbo].[sysssislog]') AND name = 'BCS_sysssislog_endtime')
	CREATE NONCLUSTERED INDEX BCS_sysssislog_endtime ON sysssislog(endtime) 
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE OBJECT_ID = OBJECT_ID('dbo.sysmaintplan_log') AND name = 'BCS_sysmaintplan_log_endtime')
	CREATE NONCLUSTERED INDEX BCS_sysmaintplan_log_endtime ON sysmaintplan_log(end_time) 
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE OBJECT_ID = OBJECT_ID('dbo.sysmaintplan_logdetail') AND name = 'BCS_sysmaintplan_logdetail_end_time')
	CREATE NONCLUSTERED INDEX BCS_sysmaintplan_logdetail_end_time ON sysmaintplan_logdetail(end_time) 
GO

IF EXISTS (SELECT * FROM sys.sysobjects WHERE id = OBJECT_ID('[dbo].[sp_JOBs_structure]'))
	DROP PROCEDURE [dbo].[sp_JOBs_structure] 
GO

-- START
CREATE PROCEDURE [dbo].[sp_JOBs_structure] 
	 @JobName varchar(max) = ''
	,@Structure varchar(max) = 'all'
	--,@package varchar(max) = ''
	--,@environment varchar(max) = ''
--WITH EXECUTE AS 'AD\ggretchkosiy'
AS
BEGIN
-- EXEC msdb.dbo.sp_JOBs_structure 'CDWH-NAPLAN Daily'
-- EXEC msdb.dbo.sp_JOBs_structure 'CDWH-Student-SEQTA-Daily-Yury'

	SET NOCOUNT ON
	DECLARE @txtJobStructure VARCHAR(MAX)

	--DROP TABLE IF EXISTS ##Structure

IF EXISTS (SELECT 1 FROM master.dbo.sysdatabases WHERE name  = 'SSISDB')
	SET @txtJobStructure= '
			SELECT 
					@@SERVERNAME AS [Instance Name]

					,J.NAME [Job name]
					,JS.step_id as [step]
					,JS.subsystem as [type]
					,CASE 
						WHEN JS.on_success_action = 1 THEN ''Quit with success'' 
						WHEN JS.on_success_action = 2 THEN ''Quit with failure'' 
						WHEN JS.on_success_action = 3 THEN ''Next step'' 
						WHEN JS.on_success_action = 4 THEN ''Go to step on_success_step_id'' 
					 END as [On success]
					,CASE 
						WHEN JS.on_fail_action = 1 THEN ''Quit with success'' 
						WHEN JS.on_fail_action = 2 THEN ''Quit with failure'' 
						WHEN JS.on_fail_action = 3 THEN ''Next step'' 
						WHEN JS.on_fail_action = 4 THEN ''Go to step on_success_step_id'' 
					 END [On error]
					,JS.step_name
	

			--/ISSERVER			-- SSIS catalogue
			--/FILE				-- SSIS package on file system
			--/Server			-- SQL Maintenance plan

					, CASE WHEN CHARINDEX (''/FILE'', JS.command) <> 0 AND  JS.subsystem = ''SSIS'' THEN 
							-- File system
								SUBSTRING(JS.command, CHARINDEX (''/FILE'', JS.command)  + LEN(''/FILE "\"''), CHARINDEX (''""'', JS.command,1 ) - LEN(''/FILE "\"'') - LEN(REVERSE(SUBSTRING(REVERSE(JS.command), CHARINDEX (''""\xstd.'',REVERSE(JS.command)) + 3, CHARINDEX (''\'',REVERSE(JS.command), CHARINDEX (''""\xstd.'',REVERSE(JS.command))+7) - CHARINDEX (''""\xstd.'',REVERSE(JS.command))-3))) -2)
							WHEN CHARINDEX (''/ISSERVER'', JS.command) <> 0 AND  JS.subsystem = ''SSIS'' THEN 
							-- SSIS catalogue
								CASE 
						--			WHEN CHARINDEX (''\'', JS.command, CHARINDEX (''\'', JS.command, CHARINDEX(''"\"\SSISDB\'', JS.command)) + CHARINDEX (''"\"\SSISDB\'', JS.command)) - CHARINDEX(''"\"\SSISDB\'', JS.command) - LEN(''"\"\SSISDB\'') > 0 
									WHEN CHARINDEX (''\'', JS.command, CHARINDEX (''\'', JS.command, CHARINDEX(''"\"\SSISDB\'', JS.command) + 1) + CHARINDEX (''"\"\SSISDB\'', JS.command)) - CHARINDEX(''"\"\SSISDB\'', JS.command) - LEN(''"\"\SSISDB\'') > 0 
									THEN SUBSTRING(JS.command,
											CHARINDEX (''\'', JS.command, CHARINDEX(''"\"\SSISDB\'', JS.command) +1 ) + CHARINDEX (''"\"\SSISDB\'', JS.command) - 1,  -- START
											CHARINDEX (''\'', JS.command, CHARINDEX (''\'', JS.command, CHARINDEX(''"\"\SSISDB\'', JS.command) + 1) + CHARINDEX (''"\"\SSISDB\'', JS.command)) - CHARINDEX(''"\"\SSISDB\'', JS.command) - LEN(''"\"\SSISDB\'') )
									ELSE ''''
								END
							WHEN CHARINDEX (''/SQL'', JS.command) <> 0 AND  JS.subsystem = ''SSIS'' THEN 
							-- Maintenance Plan
								SUBSTRING(JS.command, CHARINDEX (''/SQL'', JS.command,1) +6, CHARINDEX(''"'', JS.command, CHARINDEX (''/SQL'', JS.command,1) +7) - CHARINDEX (''/SQL'', JS.command,1) - 6)
							ELSE ''''
					  END AS [SSIS Folder]	

					,CASE WHEN CHARINDEX (''/ISSERVER'', JS.command) <> 0 AND  JS.subsystem = ''SSIS'' THEN 
							CASE 
								WHEN CHARINDEX (''\'', JS.command, CHARINDEX (''\'', JS.command, CHARINDEX(''"\"\SSISDB\'', JS.command) + 1) + CHARINDEX (''"\"\SSISDB\'', JS.command)) - CHARINDEX(''"\"\SSISDB\'', JS.command) - LEN(''"\"\SSISDB\'') > 0 
								THEN SUBSTRING(JS.command,
										CHARINDEX (''\'', JS.command, CHARINDEX (''\'', JS.command, CHARINDEX(''"\"\SSISDB\'', JS.command) + 1) + CHARINDEX (''"\"\SSISDB\'', JS.command) + 1)+ 1,  -- START
										CHARINDEX (''\'', JS.command, CHARINDEX (''\'', JS.command, CHARINDEX (''\'', JS.command, CHARINDEX(''"\"\SSISDB\'', JS.command) + 1) + CHARINDEX (''"\"\SSISDB\'', JS.command) + 1)+ 1) 
										- CHARINDEX (''\'', JS.command, CHARINDEX (''\'', JS.command, CHARINDEX(''"\"\SSISDB\'', JS.command) + 1) + CHARINDEX (''"\"\SSISDB\'', JS.command) + 1)- 1)
								ELSE ''''
							END 
						 ELSE ''''
					 END as [SSIS Project]

					,CASE WHEN CHARINDEX (''/FILE'', JS.command) <> 0 AND  JS.subsystem = ''SSIS'' THEN 
							-- File system
								REVERSE(SUBSTRING(REVERSE(JS.command), CHARINDEX (''""\xstd.'',REVERSE(JS.command)) + 3, CHARINDEX (''\'',REVERSE(JS.command), CHARINDEX (''""\xstd.'',REVERSE(JS.command))+7) - CHARINDEX (''""\xstd.'',REVERSE(JS.command))-3))
							WHEN CHARINDEX (''/ISSERVER'', JS.command) <> 0 AND  JS.subsystem = ''SSIS'' THEN 
							-- SSIS catalogue
								CASE 
									WHEN CHARINDEX (''\'', JS.command, CHARINDEX (''\'', JS.command, CHARINDEX(''"\"\SSISDB\'', JS.command) + 1) + CHARINDEX (''"\"\SSISDB\'', JS.command)) - CHARINDEX(''"\"\SSISDB\'', JS.command) - LEN(''"\"\SSISDB\'') > 0 
									THEN SUBSTRING(JS.command,
											CHARINDEX (''\'', JS.command, CHARINDEX (''\'', JS.command, CHARINDEX (''\'', JS.command, CHARINDEX(''"\"\SSISDB\'', JS.command) + 1) + CHARINDEX (''"\"\SSISDB\'', JS.command) + 1)+ 1) +1,
											--CHARINDEX (''\'', JS.command, CHARINDEX(''"\"\SSISDB\'', JS.command) + 1) + CHARINDEX (''"\"\SSISDB\'', JS.command),  -- START
											CHARINDEX (''\'', JS.command, CHARINDEX (''\'', JS.command, CHARINDEX (''\'', JS.command, CHARINDEX (''\'', JS.command, CHARINDEX(''"\"\SSISDB\'', JS.command) + 1) + CHARINDEX (''"\"\SSISDB\'', JS.command) + 1)+ 1) +1) 
											- CHARINDEX (''\'', JS.command, CHARINDEX (''\'', JS.command, CHARINDEX (''\'', JS.command, CHARINDEX(''"\"\SSISDB\'', JS.command) + 1) + CHARINDEX (''"\"\SSISDB\'', JS.command) + 1)+ 1) -1
											)
									ELSE ''''
								END	
							WHEN CHARINDEX (''/SQL'', JS.command) <> 0 AND  JS.subsystem = ''SSIS'' THEN 
							-- Maintenance Plan
								SUBSTRING(JS.command, CHARINDEX(''/set'', JS.command, CHARINDEX (''/SQL'', JS.command,1) +6) + 6 , LEN (JS.command) - CHARINDEX(''/set'', JS.command, CHARINDEX (''/SQL'', JS.command,1) +6) - 6)
						  ELSE ''''
					  END AS [SSIS Package]

					,

					CASE WHEN CHARINDEX (''/ISSERVER'', JS.command) <> 0  AND JS.subsystem = ''SSIS'' THEN
						ISNULL((SELECT TOP 1 environment_name FROM [SSISDB].[internal].[environment_references] WHERE [reference_id] = 
						 CASE 
							WHEN CHARINDEX (''/'', JS.command, CHARINDEX(''/ENVREFERENCE'', JS.command) + 1) 	- CHARINDEX (''/ENVREFERENCE'', JS.command) -LEN(''/ENVREFERENCE'') > 0 
							THEN  
							LTRIM(RTRIM(SUBSTRING(JS.command,
									CHARINDEX(''/ENVREFERENCE'', JS.command) + LEN(''/ENVREFERENCE''), 
									CHARINDEX (''/'', JS.command, CHARINDEX(''/ENVREFERENCE'', JS.command) + 1) 
							- CHARINDEX (''/ENVREFERENCE'', JS.command) -LEN(''/ENVREFERENCE''))))
							ELSE -1
						END	),'''') 
					ELSE '''' 
					END
					as [ENVIRONMENT]

					,CASE WHEN CHARINDEX (''/FILE'', JS.command) <> 0 AND  JS.subsystem = ''SSIS'' THEN 
							-- File system
								REVERSE(SUBSTRING(REVERSE(JS.command), CHARINDEX (''""\xstd.'',REVERSE(JS.command)) + 3, CHARINDEX (''\'',REVERSE(JS.command), CHARINDEX (''""\xstd.'',REVERSE(JS.command))+7) - CHARINDEX (''""\xstd.'',REVERSE(JS.command))-3))
						  WHEN CHARINDEX (''/ISSERVER'', JS.command) <> 0 AND  JS.subsystem = ''SSIS'' THEN 
						  -- SSIS catalogue
								CASE 
									WHEN CHARINDEX (''\'', JS.command, CHARINDEX (''\'', JS.command, CHARINDEX(''"\"\SSISDB\'', JS.command) + 1) + CHARINDEX (''"\"\SSISDB\'', JS.command)) - CHARINDEX(''"\"\SSISDB\'', JS.command) - LEN(''"\"\SSISDB\'') > 0 
									THEN SUBSTRING(JS.command,
											CHARINDEX (''\'', JS.command, CHARINDEX(''/SERVER "\"'', JS.command) + 1) +2  ,  -- START
											CHARINDEX (''\'', JS.command, CHARINDEX (''\'', JS.command, CHARINDEX(''/SERVER "\"'', JS.command) + 1) +2) - CHARINDEX (''\'', JS.command, CHARINDEX(''/SERVER "\"'', JS.command) + 1) -2)
									ELSE ''''
								END				
						 WHEN CHARINDEX (''/SQL'', JS.command) <> 0 AND  JS.subsystem = ''SSIS'' THEN 
						 -- Maintenance Plan
							SUBSTRING(JS.command, LEN(''/Server "'') + 1, CHARINDEX(''"'', JS.command, LEN(''/Server "'') + 1) - LEN(''/Server "'')-1) 
						ELSE ''''
					END AS [Server]

					, CASE 
						WHEN CHARINDEX(''/X86'',JS.command) >0  THEN ''Yes''
						ELSE '''' 
					  END [32bit on]
					,CASE 
						WHEN JS.subsystem = ''SSIS'' THEN 
															CASE 
																WHEN (CHARINDEX (''"\"$ServerOption::LOGGING_LEVEL(Int16)\""'', JS.command) - CHARINDEX (''/Par'', JS.command) - 10) > 0 
																THEN -- ''Ok''
																	SUBSTRING(JS.command, 
																	CHARINDEX (''/Par'', JS.command) + 5,
																	CHARINDEX (''"\"$ServerOption::LOGGING_LEVEL(Int16)\""'', JS.command) - CHARINDEX (''/Par'', JS.command) - 10) 
																ELSE ''''
															END 
						ELSE ''''
					END AS [User changed Paramaters(Job)] 

					,JS.command
					,j.category_id
				INTO ##Structure
				FROM msdb.dbo.sysjobsteps JS 
					LEFT JOIN msdb.dbo.sysjobs J ON J.job_id = JS.job_id
				WHERE j.category_id <> 100 --PowerBI
					AND [NAME] NOT LIKE ''BCS%'' AND [NAME] NOT IN (''syspolicy_purge_history'', ''SSIS Server Maintenance Job'')'
ELSE
	SET @txtJobStructure= '
			SELECT 
					@@SERVERNAME AS [Instance Name]

					,J.NAME [Job name]
					,JS.step_id as [step]
					,JS.subsystem as [type]
					,CASE 
						WHEN JS.on_success_action = 1 THEN ''Quit with success'' 
						WHEN JS.on_success_action = 2 THEN ''Quit with failure'' 
						WHEN JS.on_success_action = 3 THEN ''Next step'' 
						WHEN JS.on_success_action = 4 THEN ''Go to step on_success_step_id'' 
					 END as [On success]
					,CASE 
						WHEN JS.on_fail_action = 1 THEN ''Quit with success'' 
						WHEN JS.on_fail_action = 2 THEN ''Quit with failure'' 
						WHEN JS.on_fail_action = 3 THEN ''Next step'' 
						WHEN JS.on_fail_action = 4 THEN ''Go to step on_success_step_id'' 
					 END [On error]
					,JS.step_name
	

			--/ISSERVER			-- SSIS catalogue
			--/FILE				-- SSIS package on file system
			--/Server			-- SQL Maintenance plan

					, CASE WHEN CHARINDEX (''/FILE'', JS.command) <> 0 AND  JS.subsystem = ''SSIS'' THEN 
							-- File system
								SUBSTRING(JS.command, CHARINDEX (''/FILE'', JS.command)  + LEN(''/FILE "\"''), CHARINDEX (''""'', JS.command,1 ) - LEN(''/FILE "\"'') - LEN(REVERSE(SUBSTRING(REVERSE(JS.command), CHARINDEX (''""\xstd.'',REVERSE(JS.command)) + 3, CHARINDEX (''\'',REVERSE(JS.command), CHARINDEX (''""\xstd.'',REVERSE(JS.command))+7) - CHARINDEX (''""\xstd.'',REVERSE(JS.command))-3))) -2)
							WHEN CHARINDEX (''/ISSERVER'', JS.command) <> 0 AND  JS.subsystem = ''SSIS'' THEN 
							-- SSIS catalogue
								CASE 
						--			WHEN CHARINDEX (''\'', JS.command, CHARINDEX (''\'', JS.command, CHARINDEX(''"\"\SSISDB\'', JS.command)) + CHARINDEX (''"\"\SSISDB\'', JS.command)) - CHARINDEX(''"\"\SSISDB\'', JS.command) - LEN(''"\"\SSISDB\'') > 0 
									WHEN CHARINDEX (''\'', JS.command, CHARINDEX (''\'', JS.command, CHARINDEX(''"\"\SSISDB\'', JS.command) + 1) + CHARINDEX (''"\"\SSISDB\'', JS.command)) - CHARINDEX(''"\"\SSISDB\'', JS.command) - LEN(''"\"\SSISDB\'') > 0 
									THEN SUBSTRING(JS.command,
											CHARINDEX (''\'', JS.command, CHARINDEX(''"\"\SSISDB\'', JS.command) +1 ) + CHARINDEX (''"\"\SSISDB\'', JS.command) - 1,  -- START
											CHARINDEX (''\'', JS.command, CHARINDEX (''\'', JS.command, CHARINDEX(''"\"\SSISDB\'', JS.command) + 1) + CHARINDEX (''"\"\SSISDB\'', JS.command)) - CHARINDEX(''"\"\SSISDB\'', JS.command) - LEN(''"\"\SSISDB\'') )
									ELSE ''''
								END
							WHEN CHARINDEX (''/SQL'', JS.command) <> 0 AND  JS.subsystem = ''SSIS'' THEN 
							-- Maintenance Plan
								SUBSTRING(JS.command, CHARINDEX (''/SQL'', JS.command,1) +6, CHARINDEX(''"'', JS.command, CHARINDEX (''/SQL'', JS.command,1) +7) - CHARINDEX (''/SQL'', JS.command,1) - 6)
							ELSE ''''
					  END AS [SSIS Folder]	

					,CASE WHEN CHARINDEX (''/ISSERVER'', JS.command) <> 0 AND  JS.subsystem = ''SSIS'' THEN 
							CASE 
								WHEN CHARINDEX (''\'', JS.command, CHARINDEX (''\'', JS.command, CHARINDEX(''"\"\SSISDB\'', JS.command) + 1) + CHARINDEX (''"\"\SSISDB\'', JS.command)) - CHARINDEX(''"\"\SSISDB\'', JS.command) - LEN(''"\"\SSISDB\'') > 0 
								THEN SUBSTRING(JS.command,
										CHARINDEX (''\'', JS.command, CHARINDEX (''\'', JS.command, CHARINDEX(''"\"\SSISDB\'', JS.command) + 1) + CHARINDEX (''"\"\SSISDB\'', JS.command) + 1)+ 1,  -- START
										CHARINDEX (''\'', JS.command, CHARINDEX (''\'', JS.command, CHARINDEX (''\'', JS.command, CHARINDEX(''"\"\SSISDB\'', JS.command) + 1) + CHARINDEX (''"\"\SSISDB\'', JS.command) + 1)+ 1) 
										- CHARINDEX (''\'', JS.command, CHARINDEX (''\'', JS.command, CHARINDEX(''"\"\SSISDB\'', JS.command) + 1) + CHARINDEX (''"\"\SSISDB\'', JS.command) + 1)- 1)
								ELSE ''''
							END 
						 ELSE ''''
					 END as [SSIS Project]

					,CASE WHEN CHARINDEX (''/FILE'', JS.command) <> 0 AND  JS.subsystem = ''SSIS'' THEN 
							-- File system
								REVERSE(SUBSTRING(REVERSE(JS.command), CHARINDEX (''""\xstd.'',REVERSE(JS.command)) + 3, CHARINDEX (''\'',REVERSE(JS.command), CHARINDEX (''""\xstd.'',REVERSE(JS.command))+7) - CHARINDEX (''""\xstd.'',REVERSE(JS.command))-3))
							WHEN CHARINDEX (''/ISSERVER'', JS.command) <> 0 AND  JS.subsystem = ''SSIS'' THEN 
							-- SSIS catalogue
								CASE 
									WHEN CHARINDEX (''\'', JS.command, CHARINDEX (''\'', JS.command, CHARINDEX(''"\"\SSISDB\'', JS.command) + 1) + CHARINDEX (''"\"\SSISDB\'', JS.command)) - CHARINDEX(''"\"\SSISDB\'', JS.command) - LEN(''"\"\SSISDB\'') > 0 
									THEN SUBSTRING(JS.command,
											CHARINDEX (''\'', JS.command, CHARINDEX (''\'', JS.command, CHARINDEX (''\'', JS.command, CHARINDEX(''"\"\SSISDB\'', JS.command) + 1) + CHARINDEX (''"\"\SSISDB\'', JS.command) + 1)+ 1) +1,
											--CHARINDEX (''\'', JS.command, CHARINDEX(''"\"\SSISDB\'', JS.command) + 1) + CHARINDEX (''"\"\SSISDB\'', JS.command),  -- START
											CHARINDEX (''\'', JS.command, CHARINDEX (''\'', JS.command, CHARINDEX (''\'', JS.command, CHARINDEX (''\'', JS.command, CHARINDEX(''"\"\SSISDB\'', JS.command) + 1) + CHARINDEX (''"\"\SSISDB\'', JS.command) + 1)+ 1) +1) 
											- CHARINDEX (''\'', JS.command, CHARINDEX (''\'', JS.command, CHARINDEX (''\'', JS.command, CHARINDEX(''"\"\SSISDB\'', JS.command) + 1) + CHARINDEX (''"\"\SSISDB\'', JS.command) + 1)+ 1) -1
											)
									ELSE ''''
								END	
							WHEN CHARINDEX (''/SQL'', JS.command) <> 0 AND  JS.subsystem = ''SSIS'' THEN 
							-- Maintenance Plan
								SUBSTRING(JS.command, CHARINDEX(''/set'', JS.command, CHARINDEX (''/SQL'', JS.command,1) +6) + 6 , LEN (JS.command) - CHARINDEX(''/set'', JS.command, CHARINDEX (''/SQL'', JS.command,1) +6) - 6)
						  ELSE ''''
					  END AS [SSIS Package]

					, '''' as [ENVIRONMENT]

					,CASE WHEN CHARINDEX (''/FILE'', JS.command) <> 0 AND  JS.subsystem = ''SSIS'' THEN 
							-- File system
								REVERSE(SUBSTRING(REVERSE(JS.command), CHARINDEX (''""\xstd.'',REVERSE(JS.command)) + 3, CHARINDEX (''\'',REVERSE(JS.command), CHARINDEX (''""\xstd.'',REVERSE(JS.command))+7) - CHARINDEX (''""\xstd.'',REVERSE(JS.command))-3))
						  WHEN CHARINDEX (''/ISSERVER'', JS.command) <> 0 AND  JS.subsystem = ''SSIS'' THEN 
						  -- SSIS catalogue
								CASE 
									WHEN CHARINDEX (''\'', JS.command, CHARINDEX (''\'', JS.command, CHARINDEX(''"\"\SSISDB\'', JS.command) + 1) + CHARINDEX (''"\"\SSISDB\'', JS.command)) - CHARINDEX(''"\"\SSISDB\'', JS.command) - LEN(''"\"\SSISDB\'') > 0 
									THEN SUBSTRING(JS.command,
											CHARINDEX (''\'', JS.command, CHARINDEX(''/SERVER "\"'', JS.command) + 1) +2  ,  -- START
											CHARINDEX (''\'', JS.command, CHARINDEX (''\'', JS.command, CHARINDEX(''/SERVER "\"'', JS.command) + 1) +2) - CHARINDEX (''\'', JS.command, CHARINDEX(''/SERVER "\"'', JS.command) + 1) -2)
									ELSE ''''
								END				
						 WHEN CHARINDEX (''/SQL'', JS.command) <> 0 AND  JS.subsystem = ''SSIS'' THEN 
						 -- Maintenance Plan
							SUBSTRING(JS.command, LEN(''/Server "'') + 1, CHARINDEX(''"'', JS.command, LEN(''/Server "'') + 1) - LEN(''/Server "'')-1) 
						ELSE ''''
					END AS [Server]

					, CASE 
						WHEN CHARINDEX(''/X86'',JS.command) >0  THEN ''Yes''
						ELSE '''' 
					  END [32bit on]
					,CASE 
						WHEN JS.subsystem = ''SSIS'' THEN 
															CASE 
																WHEN (CHARINDEX (''"\"$ServerOption::LOGGING_LEVEL(Int16)\""'', JS.command) - CHARINDEX (''/Par'', JS.command) - 10) > 0 
																THEN -- ''Ok''
																	SUBSTRING(JS.command, 
																	CHARINDEX (''/Par'', JS.command) + 5,
																	CHARINDEX (''"\"$ServerOption::LOGGING_LEVEL(Int16)\""'', JS.command) - CHARINDEX (''/Par'', JS.command) - 10) 
																ELSE ''''
															END 
						ELSE ''''
					END AS [User changed Paramaters(Job)] 

					,JS.command
					,j.category_id
				INTO ##Structure
				FROM msdb.dbo.sysjobsteps JS 
					LEFT JOIN msdb.dbo.sysjobs J ON J.job_id = JS.job_id
				WHERE j.category_id <> 100 --PowerBI
					AND [NAME] NOT LIKE ''BCS%'' AND [NAME] NOT IN (''syspolicy_purge_history'', ''SSIS Server Maintenance Job'')'

	IF (@JobName != '') SET @txtJobStructure = @txtJobStructure + ' AND J.NAME = ''' + @JobName + ''' '
	SET @txtJobStructure = @txtJobStructure + ' ORDER BY 1,2,3'

	--PRINT @txtJobStructure
	IF (@Structure <> 'ScheduleOnly') EXEC (@txtJobStructure)
	IF (@@ROWCOUNT <> 0) 
		BEGIN 
			-- replresent JOB structure itself 

			--DROP TABLE IF EXISTS #US
			SELECT * FROM ##Structure ORDER BY 1,2,3
			IF EXISTS (SELECT 1 FROM master.dbo.sysdatabases WHERE name  = 'SSISDB')
				SELECT DISTINCT 'EXEC [SSISDB].dbo.sp_SSIS_structure @folder=''' + [SSIS Folder] + ''', @project=''' + [SSIS Project] + '''' AS [Usefull scripts ;)] 
			INTO #US 
			FROM ##Structure WHERE [SSIS Folder] <> ''
			
		END
   DROP TABLE ##Structure

DECLARE @TimeZone VARCHAR(50)
EXEC master.dbo.xp_regread 'HKEY_LOCAL_MACHINE',
'SYSTEM\CurrentControlSet\Control\TimeZoneInformation',
'TimeZoneKeyName',@TimeZone OUT


IF (@Structure <> 'StructureOnly') 
SELECT
	@@SERVERNAME as [Instance Name]
   ,msdb.dbo.sysjobs.name as [JobName]
   ,master.sys.syslogins.name AS JobOwner
   , msdb.dbo.sysschedules.schedule_id
   , msdb.dbo.sysschedules.name AS [Schedule Name]
   ,CASE
		WHEN msdb.dbo.sysschedules.enabled = 0 THEN 'Disabled'
        WHEN msdb.dbo.sysschedules.enabled = 1 THEN 'Enabled'
		WHEN msdb.dbo.sysschedules.enabled IS NULL THEN 'Unscheduled'
     END
  As [Schedule Enabled]
  ,CASE
       WHEN msdb.dbo.sysjobs.enabled = 0 THEN 'Job is disabled'
       WHEN msdb.dbo.sysschedules.enabled IS NULL THEN 'Unscheduled'
       WHEN msdb.dbo.sysschedules.freq_type = 0x1 -- OneTime
           THEN
               'Once on '
             + CONVERT(
                          CHAR(10)
                        , CAST( CAST( msdb.dbo.sysschedules.active_start_date AS VARCHAR ) AS DATETIME )
                        , 102 -- yyyy.mm.dd
                       )
       WHEN msdb.dbo.sysschedules.freq_type = 0x4 -- Daily
           THEN 'Daily'
       WHEN msdb.dbo.sysschedules.freq_type = 0x8 -- weekly
           THEN
               CASE
                   WHEN msdb.dbo.sysschedules.freq_recurrence_factor = 1
                       THEN 'Weekly on '
                   WHEN msdb.dbo.sysschedules.freq_recurrence_factor > 1
                       THEN 'Every '
                          + CAST( msdb.dbo.sysschedules.freq_recurrence_factor AS VARCHAR )
                          + ' weeks on '
               END
             + LEFT(
                         CASE WHEN msdb.dbo.sysschedules.freq_interval &  1 =  1 THEN 'Sunday, '    ELSE '' END
                       + CASE WHEN msdb.dbo.sysschedules.freq_interval &  2 =  2 THEN 'Monday, '    ELSE '' END
                       + CASE WHEN msdb.dbo.sysschedules.freq_interval &  4 =  4 THEN 'Tuesday, '   ELSE '' END
                       + CASE WHEN msdb.dbo.sysschedules.freq_interval &  8 =  8 THEN 'Wednesday, ' ELSE '' END
                       + CASE WHEN msdb.dbo.sysschedules.freq_interval & 16 = 16 THEN 'Thursday, '  ELSE '' END
                       + CASE WHEN msdb.dbo.sysschedules.freq_interval & 32 = 32 THEN 'Friday, '    ELSE '' END
                       + CASE WHEN msdb.dbo.sysschedules.freq_interval & 64 = 64 THEN 'Saturday, '  ELSE '' END
                     , LEN(
                                CASE WHEN msdb.dbo.sysschedules.freq_interval &  1 =  1 THEN 'Sunday, '    ELSE '' END
                              + CASE WHEN msdb.dbo.sysschedules.freq_interval &  2 =  2 THEN 'Monday, '    ELSE '' END
                              + CASE WHEN msdb.dbo.sysschedules.freq_interval &  4 =  4 THEN 'Tuesday, '   ELSE '' END
                              + CASE WHEN msdb.dbo.sysschedules.freq_interval &  8 =  8 THEN 'Wednesday, ' ELSE '' END
                              + CASE WHEN msdb.dbo.sysschedules.freq_interval & 16 = 16 THEN 'Thursday, '  ELSE '' END
                              + CASE WHEN msdb.dbo.sysschedules.freq_interval & 32 = 32 THEN 'Friday, '    ELSE '' END
                              + CASE WHEN msdb.dbo.sysschedules.freq_interval & 64 = 64 THEN 'Saturday, '  ELSE '' END
                           )  - 1  -- LEN() ignores trailing spaces
                   )
       WHEN msdb.dbo.sysschedules.freq_type = 0x10 -- monthly
           THEN
               CASE
                   WHEN msdb.dbo.sysschedules.freq_recurrence_factor = 1
                       THEN 'Monthly on the '
                   WHEN msdb.dbo.sysschedules.freq_recurrence_factor > 1
                       THEN 'Every '
                          + CAST( msdb.dbo.sysschedules.freq_recurrence_factor AS VARCHAR )
                          + ' months on the '
               END
             + CAST( msdb.dbo.sysschedules.freq_interval AS VARCHAR )
             + CASE
                   WHEN msdb.dbo.sysschedules.freq_interval IN ( 1, 21, 31 ) THEN 'st'
                   WHEN msdb.dbo.sysschedules.freq_interval IN ( 2, 22     ) THEN 'nd'
                   WHEN msdb.dbo.sysschedules.freq_interval IN ( 3, 23     ) THEN 'rd'
                   ELSE 'th'
               END
       WHEN msdb.dbo.sysschedules.freq_type = 0x20 -- monthly relative
           THEN
               CASE
                   WHEN msdb.dbo.sysschedules.freq_recurrence_factor = 1
                       THEN 'Monthly on the '
                   WHEN msdb.dbo.sysschedules.freq_recurrence_factor > 1
                       THEN 'Every '
                          + CAST( msdb.dbo.sysschedules.freq_recurrence_factor AS VARCHAR )
                          + ' months on the '
               END
             + CASE msdb.dbo.sysschedules.freq_relative_interval
                   WHEN 0x01 THEN 'first '
                   WHEN 0x02 THEN 'second '
                   WHEN 0x04 THEN 'third '
                   WHEN 0x08 THEN 'fourth '
                   WHEN 0x10 THEN 'last '
               END
             + CASE msdb.dbo.sysschedules.freq_interval
                   WHEN  1 THEN 'Sunday'
                   WHEN  2 THEN 'Monday'
                   WHEN  3 THEN 'Tuesday'
                   WHEN  4 THEN 'Wednesday'
                   WHEN  5 THEN 'Thursday'
                   WHEN  6 THEN 'Friday'
                   WHEN  7 THEN 'Saturday'
                   WHEN  8 THEN 'day'
                   WHEN  9 THEN 'week day'
                   WHEN 10 THEN 'weekend day'
               END
       WHEN msdb.dbo.sysschedules.freq_type = 0x40
           THEN 'Automatically starts when SQLServerAgent starts.'
       WHEN msdb.dbo.sysschedules.freq_type = 0x80
           THEN 'Starts whenever the CPUs become idle'
       ELSE ''
   END
+ CASE
       WHEN msdb.dbo.sysjobs.enabled = 0 THEN ''
       WHEN msdb.dbo.sysjobs.job_id IS NULL THEN ''
       WHEN msdb.dbo.sysschedules.freq_subday_type = 0x1 OR msdb.dbo.sysschedules.freq_type = 0x1
           THEN ' at '
                        + Case  -- Depends on time being integer to drop right-side digits
                                when(msdb.dbo.sysschedules.active_start_time % 1000000)/10000 = 0 then 
                                                  '12'
                                                + ':'  
                                                +Replicate('0',2 - len(convert(char(2),(msdb.dbo.sysschedules.active_start_time % 10000)/100)))
                                                + convert(char(2),(msdb.dbo.sysschedules.active_start_time % 10000)/100) 
                                                + ' AM'
                                when (msdb.dbo.sysschedules.active_start_time % 1000000)/10000< 10 then
                                                convert(char(1),(msdb.dbo.sysschedules.active_start_time % 1000000)/10000) 
                                                + ':'  
                                                +Replicate('0',2 - len(convert(char(2),(msdb.dbo.sysschedules.active_start_time % 10000)/100))) 
                                                + convert(char(2),(msdb.dbo.sysschedules.active_start_time % 10000)/100) 
                                                + ' AM'
                                when (msdb.dbo.sysschedules.active_start_time % 1000000)/10000 < 12 then
                                                convert(char(2),(msdb.dbo.sysschedules.active_start_time % 1000000)/10000) 
                                                + ':'  
                                                +Replicate('0',2 - len(convert(char(2),(msdb.dbo.sysschedules.active_start_time % 10000)/100))) 
                                                + convert(char(2),(msdb.dbo.sysschedules.active_start_time % 10000)/100) 
                                                + ' AM'
                                when (msdb.dbo.sysschedules.active_start_time % 1000000)/10000< 22 then
                                                convert(char(1),((msdb.dbo.sysschedules.active_start_time % 1000000)/10000) - 12) 
                                                + ':'  
                                                +Replicate('0',2 - len(convert(char(2),(msdb.dbo.sysschedules.active_start_time % 10000)/100))) 
                                                + convert(char(2),(msdb.dbo.sysschedules.active_start_time % 10000)/100) 
                                                + ' PM'
                                else        convert(char(2),((msdb.dbo.sysschedules.active_start_time % 1000000)/10000) - 12)
                                                + ':'  
                                                +Replicate('0',2 - len(convert(char(2),(msdb.dbo.sysschedules.active_start_time % 10000)/100))) 
                                                + convert(char(2),(msdb.dbo.sysschedules.active_start_time % 10000)/100) 
                                                + ' PM'
                        end
       WHEN msdb.dbo.sysschedules.freq_subday_type IN ( 0x2, 0x4, 0x8 )
           THEN ' every '
             + CAST( msdb.dbo.sysschedules.freq_subday_interval AS VARCHAR )
             + CASE freq_subday_type
                   WHEN 0x2 THEN ' second'
                   WHEN 0x4 THEN ' minute'
                   WHEN 0x8 THEN ' hour'
               END
             + CASE
                   WHEN msdb.dbo.sysschedules.freq_subday_interval > 1 THEN 's'
                                   ELSE '' -- Added default 3/21/08; John Arnott
               END
       ELSE ''
   END
+ CASE
       WHEN msdb.dbo.sysjobs.enabled = 0 THEN ''
       WHEN msdb.dbo.sysjobs.job_id IS NULL THEN ''
       WHEN msdb.dbo.sysschedules.freq_subday_type IN ( 0x2, 0x4, 0x8 )
           THEN ' between '
                        + Case  -- Depends on time being integer to drop right-side digits
                                when(msdb.dbo.sysschedules.active_start_time % 1000000)/10000 = 0 then 
                                                  '12'
                                                + ':'  
                                                +Replicate('0',2 - len(convert(char(2),(msdb.dbo.sysschedules.active_start_time % 10000)/100)))
                                                + rtrim(convert(char(2),(msdb.dbo.sysschedules.active_start_time % 10000)/100))
                                                + ' AM'
                                when (msdb.dbo.sysschedules.active_start_time % 1000000)/10000< 10 then
                                                convert(char(1),(msdb.dbo.sysschedules.active_start_time % 1000000)/10000) 
                                                + ':'  
                                                +Replicate('0',2 - len(convert(char(2),(msdb.dbo.sysschedules.active_start_time % 10000)/100))) 
                                                + rtrim(convert(char(2),(msdb.dbo.sysschedules.active_start_time % 10000)/100))
                                                + ' AM'
                                when (msdb.dbo.sysschedules.active_start_time % 1000000)/10000 < 12 then
                                                convert(char(2),(msdb.dbo.sysschedules.active_start_time % 1000000)/10000) 
                                                + ':'  
                                                +Replicate('0',2 - len(convert(char(2),(msdb.dbo.sysschedules.active_start_time % 10000)/100))) 
                                                + rtrim(convert(char(2),(msdb.dbo.sysschedules.active_start_time % 10000)/100)) 
                                                + ' AM'
                                when (msdb.dbo.sysschedules.active_start_time % 1000000)/10000< 22 then
                                                convert(char(1),((msdb.dbo.sysschedules.active_start_time % 1000000)/10000) - 12) 
                                                + ':'  
                                                +Replicate('0',2 - len(convert(char(2),(msdb.dbo.sysschedules.active_start_time % 10000)/100))) 
                                                + rtrim(convert(char(2),(msdb.dbo.sysschedules.active_start_time % 10000)/100)) 
                                                + ' PM'
                                else        convert(char(2),((msdb.dbo.sysschedules.active_start_time % 1000000)/10000) - 12)
                                                + ':'  
                                                +Replicate('0',2 - len(convert(char(2),(msdb.dbo.sysschedules.active_start_time % 10000)/100))) 
                                                + rtrim(convert(char(2),(msdb.dbo.sysschedules.active_start_time % 10000)/100))
                                                + ' PM'
                        end
             + ' and '
                        + Case  -- Depends on time being integer to drop right-side digits
                                when(msdb.dbo.sysschedules.active_end_time % 1000000)/10000 = 0 then 
                                                '12'
                                                + ':'  
                                                +Replicate('0',2 - len(convert(char(2),(msdb.dbo.sysschedules.active_end_time % 10000)/100)))
                                                + rtrim(convert(char(2),(msdb.dbo.sysschedules.active_end_time % 10000)/100))
                                                + ' AM'
                                when (msdb.dbo.sysschedules.active_end_time % 1000000)/10000< 10 then
                                                convert(char(1),(msdb.dbo.sysschedules.active_end_time % 1000000)/10000) 
                                                + ':'  
                                                +Replicate('0',2 - len(convert(char(2),(msdb.dbo.sysschedules.active_end_time % 10000)/100))) 
                                                + rtrim(convert(char(2),(msdb.dbo.sysschedules.active_end_time % 10000)/100))
                                                + ' AM'
                                when (msdb.dbo.sysschedules.active_end_time % 1000000)/10000 < 12 then
                                                convert(char(2),(msdb.dbo.sysschedules.active_end_time % 1000000)/10000) 
                                                + ':'  
                                                +Replicate('0',2 - len(convert(char(2),(msdb.dbo.sysschedules.active_end_time % 10000)/100))) 
                                                + rtrim(convert(char(2),(msdb.dbo.sysschedules.active_end_time % 10000)/100))
                                                + ' AM'
                                when (msdb.dbo.sysschedules.active_end_time % 1000000)/10000< 22 then
                                                convert(char(1),((msdb.dbo.sysschedules.active_end_time % 1000000)/10000) - 12)
                                                + ':'  
                                                +Replicate('0',2 - len(convert(char(2),(msdb.dbo.sysschedules.active_end_time % 10000)/100))) 
                                                + rtrim(convert(char(2),(msdb.dbo.sysschedules.active_end_time % 10000)/100)) 
                                                + ' PM'
                                else        convert(char(2),((msdb.dbo.sysschedules.active_end_time % 1000000)/10000) - 12)
                                                + ':'  
                                                +Replicate('0',2 - len(convert(char(2),(msdb.dbo.sysschedules.active_end_time % 10000)/100))) 
                                                + rtrim(convert(char(2),(msdb.dbo.sysschedules.active_end_time % 10000)/100)) 
                                                + ' PM'
                        end
       ELSE ''
   END AS Schedule

   , @TimeZone AS [TimeZone]

	,CONVERT(CHAR(10), CAST( CAST( msdb.dbo.sysschedules.active_start_date AS VARCHAR ) AS DATETIME ), 103) + ' ' + 
	Case  -- Depends on time being integer to drop right-side digits
		when(msdb.dbo.sysschedules.active_start_time % 1000000)/10000 = 0 then 
							'12'
						+ ':'  
						+Replicate('0',2 - len(convert(char(2),(msdb.dbo.sysschedules.active_start_time % 10000)/100)))
						+ rtrim(convert(char(2),(msdb.dbo.sysschedules.active_start_time % 10000)/100))
						+ ' AM'
		when (msdb.dbo.sysschedules.active_start_time % 1000000)/10000< 10 then
						convert(char(1),(msdb.dbo.sysschedules.active_start_time % 1000000)/10000) 
						+ ':'  
						+Replicate('0',2 - len(convert(char(2),(msdb.dbo.sysschedules.active_start_time % 10000)/100))) 
						+ rtrim(convert(char(2),(msdb.dbo.sysschedules.active_start_time % 10000)/100))
						+ ' AM'
		when (msdb.dbo.sysschedules.active_start_time % 1000000)/10000 < 12 then
						convert(char(2),(msdb.dbo.sysschedules.active_start_time % 1000000)/10000) 
						+ ':'  
						+Replicate('0',2 - len(convert(char(2),(msdb.dbo.sysschedules.active_start_time % 10000)/100))) 
						+ rtrim(convert(char(2),(msdb.dbo.sysschedules.active_start_time % 10000)/100)) 
						+ ' AM'
		when (msdb.dbo.sysschedules.active_start_time % 1000000)/10000< 22 then
						convert(char(1),((msdb.dbo.sysschedules.active_start_time % 1000000)/10000) - 12) 
						+ ':'  
						+Replicate('0',2 - len(convert(char(2),(msdb.dbo.sysschedules.active_start_time % 10000)/100))) 
						+ rtrim(convert(char(2),(msdb.dbo.sysschedules.active_start_time % 10000)/100)) 
						+ ' PM'
		else        convert(char(2),((msdb.dbo.sysschedules.active_start_time % 1000000)/10000) - 12)
						+ ':'  
						+Replicate('0',2 - len(convert(char(2),(msdb.dbo.sysschedules.active_start_time % 10000)/100))) 
						+ rtrim(convert(char(2),(msdb.dbo.sysschedules.active_start_time % 10000)/100))
						+ ' PM'
	end AS [Start date]

	,
	CASE when msdb.dbo.sysschedules.active_end_date = 99991231 then 'No end date'
		ELSE CONVERT(CHAR(10), CAST( CAST( msdb.dbo.sysschedules.active_end_date AS VARCHAR ) AS DATETIME ), 103) + ' ' 
	END	+ 
	Case  -- Depends on time being integer to drop right-side digits
		when msdb.dbo.sysschedules.active_end_date = 99991231 then ''
		when(msdb.dbo.sysschedules.active_end_time % 1000000)/10000 = 0 then 
							'12'
						+ ':'  
						+Replicate('0',2 - len(convert(char(2),(msdb.dbo.sysschedules.active_end_time % 10000)/100)))
						+ rtrim(convert(char(2),(msdb.dbo.sysschedules.active_end_time % 10000)/100))
						+ ' AM'
		when (msdb.dbo.sysschedules.active_end_time % 1000000)/10000< 10 then
						convert(char(1),(msdb.dbo.sysschedules.active_end_time % 1000000)/10000) 
						+ ':'  
						+Replicate('0',2 - len(convert(char(2),(msdb.dbo.sysschedules.active_end_time % 10000)/100))) 
						+ rtrim(convert(char(2),(msdb.dbo.sysschedules.active_end_time % 10000)/100))
						+ ' AM'
		when (msdb.dbo.sysschedules.active_end_time % 1000000)/10000 < 12 then
						convert(char(2),(msdb.dbo.sysschedules.active_end_time % 1000000)/10000) 
						+ ':'  
						+Replicate('0',2 - len(convert(char(2),(msdb.dbo.sysschedules.active_end_time % 10000)/100))) 
						+ rtrim(convert(char(2),(msdb.dbo.sysschedules.active_end_time % 10000)/100)) 
						+ ' AM'
		when (msdb.dbo.sysschedules.active_end_time % 1000000)/10000< 22 then
						convert(char(1),((msdb.dbo.sysschedules.active_end_time % 1000000)/10000) - 12) 
						+ ':'  
						+Replicate('0',2 - len(convert(char(2),(msdb.dbo.sysschedules.active_end_time % 10000)/100))) 
						+ rtrim(convert(char(2),(msdb.dbo.sysschedules.active_end_time % 10000)/100)) 
						+ ' PM'
		else        convert(char(2),((msdb.dbo.sysschedules.active_end_time % 1000000)/10000) - 12)
						+ ':'  
						+Replicate('0',2 - len(convert(char(2),(msdb.dbo.sysschedules.active_end_time % 10000)/100))) 
						+ rtrim(convert(char(2),(msdb.dbo.sysschedules.active_end_time % 10000)/100))
						+ ' PM'
	end AS [End date]

--,active_end_date
--,active_end_time

FROM         msdb.dbo.sysjobs 
				LEFT OUTER JOIN msdb.dbo.sysjobschedules ON msdb.dbo.sysjobs.job_id = msdb.dbo.sysjobschedules.job_id 
				LEFT OUTER JOIN msdb.dbo.sysschedules ON msdb.dbo.sysjobschedules.schedule_id = msdb.dbo.sysschedules.schedule_id
				LEFT OUTER JOIN master.sys.syslogins on msdb.dbo.sysjobs.owner_sid = master.sys.syslogins.sid
WHERE msdb.dbo.sysjobs.category_id <> 100 --PowerBI, SSRS
	AND msdb.dbo.sysjobs.name NOT LIKE 'BCS%' 
	AND msdb.dbo.sysjobs.name NOT IN ('syspolicy_purge_history', 'SSIS Server Maintenance Job')
	AND msdb.dbo.sysjobs.name LIKE	CASE 
										WHEN @JobName = '' THEN '%'
										ELSE @JobName
									END 

--SELECT name FROM tempdb.SYS.OBJECTS WHERE name LIKE '%' ORDER BY NAME
IF EXISTS (SELECT * FROM tempdb.SYS.OBJECTS WHERE name LIKE '#US%')
IF EXISTS (SELECT 1 FROM #US)
	BEGIN
		SELECT * FROM #US
		DROP TABLE #US
	END
END 
--- END PROCEDURE [dbo].[sp_JOBs_structure] 

GO


USE [master]
GO

IF EXISTS (SELECT * FROM sys.sysobjects WHERE id = OBJECT_ID('[dbo].[sp_lock2]'))
	DROP PROCEDURE [dbo].[sp_lock2] 
GO

CREATE   procedure [dbo].[sp_lock2] 
@spid1 int = NULL,      /* server process id to check for locks */ 
@spid2 int = NULL       /* other process id to check for locks */ 
as

set nocount on
/*
** Show the locks for both parameters.
*/ 
declare @objid int,
   @dbid int,
   @string Nvarchar(2000)

CREATE TABLE #locktable
   (
   spid       smallint
   ,loginname nvarchar(20)
   ,hostname  nvarchar(30)
   ,dbid      int
   ,dbname    nvarchar(120)
   ,objId     int
   ,ObjName   nvarchar(128)
   ,IndId     int
   ,IndexName nvarchar(250)
   ,Type      nvarchar(4)
   ,Resource  nvarchar(160)
   ,Mode      nvarchar(8)
   ,Status    nvarchar(5)
   )
   
if @spid1 is not NULL
begin
   INSERT #locktable
      (
      spid
      ,loginname
      ,hostname
      ,dbid
      ,dbname
      ,objId
      ,ObjName
      ,IndId
	  ,IndexName
      ,Type
      ,Resource
      ,Mode
      ,Status
      )
   select convert (smallint, l.req_spid) 
      --,coalesce(substring (user_name(req_spid), 1, 20),'')
      ,coalesce(substring (s.loginame, 1, 20),'')
      ,coalesce(substring (s.hostname, 1, 30),'')
      ,l.rsc_dbid
      ,'[' + substring (db_name(l.rsc_dbid), 1, 120) + ']'
      ,l.rsc_objid
      ,''
      ,l.rsc_indid
	  ,'' AS IndexName
      ,substring (v.name, 1, 4)
      ,substring (l.rsc_text, 1, 16)
      ,substring (u.name, 1, 8)
      ,substring (x.name, 1, 5)
   from master.dbo.syslockinfo l with(nolock),
      master.dbo.spt_values v with(nolock),
      master.dbo.spt_values x with(nolock),
      master.dbo.spt_values u with(nolock),
      master.dbo.sysprocesses s with(nolock)
   where l.rsc_type = v.number
   and   v.type = 'LR'
   and   l.req_status = x.number
   and   x.type = 'LS'
   and   l.req_mode + 1 = u.number
   and   u.type = 'L'
   and   req_spid in (@spid1, @spid2)
   and   req_spid = s.spid
end
/*
** No parameters, so show all the locks.
*/ 
else
begin
   INSERT #locktable
      (
      spid
      ,loginname
      ,hostname
      ,dbid
      ,dbname
      ,objId
      ,ObjName
      ,IndId
	  ,IndexName
      ,Type
      ,Resource
      ,Mode
      ,Status
      )
   select convert (smallint, l.req_spid) 
      --,coalesce(substring (user_name(req_spid), 1, 20),'')
      ,coalesce(substring (s.loginame, 1, 20),'')
      ,coalesce(substring (s.hostname, 1, 30),'')
      ,l.rsc_dbid
      ,'[' + substring (db_name(l.rsc_dbid), 1, 120) + ']'
      ,l.rsc_objid
      ,''
      ,l.rsc_indid
	  ,'' AS IndexName
      ,substring (v.name, 1, 4)
      ,substring (l.rsc_text, 1, 160)
      ,substring (u.name, 1, 8)
      ,substring (x.name, 1, 5)
   from master.dbo.syslockinfo l with(nolock),
      master.dbo.spt_values v with(nolock),
      master.dbo.spt_values x with(nolock),
      master.dbo.spt_values u with(nolock),
      master.dbo.sysprocesses s with(nolock)
   where l.rsc_type = v.number
   and   v.type = 'LR'
   and   l.req_status = x.number
   and   x.type = 'LS'
   and   l.req_mode + 1 = u.number
   and   u.type = 'L'
   and   req_spid = s.spid
   order by spID
END

DECLARE @dbidtxt VARCHAR(120)
DECLARE @ObjIdtxt VARCHAR(120)
DECLARE @dbname VARCHAR(120)
DECLARE @OBJname VARCHAR(120)
DECLARE @IndId varchar(10)
DECLARE @IndexName VARCHAR(120)
DECLARE @TBLname VARCHAR(120)
DECLARE @SchemaName VARCHAR(120) 

DECLARE lock_cursor CURSOR
FOR 
SELECT
	convert(varchar(32),dbid) as dbid, 
	convert(varchar(32),ObjId) as ObjId, 
	'[' + db_name(dbid) + ']', 
	'[' + OBJECT_SCHEMA_NAME(objId,dbid) + '].[' + object_name(objId,dbid) + ']',
	CAST(IndId AS VARCHAR(3)) AS IndId,
	object_name(objId,dbid),
	OBJECT_SCHEMA_NAME(objId,dbid) 
FROM #locktable with(nolock) WHERE Type IN ('TAB', 'PAG', 'KEY')

OPEN lock_cursor
FETCH NEXT FROM lock_cursor INTO @dbidtxt, @ObjIdtxt, @dbname, @OBJname, @IndId, @TBLname, @SchemaName
WHILE @@FETCH_STATUS = 0
   BEGIN
   --SELECT @string = 
   --   'USE ' + @dbname + ';' + 
	  --'DECLARE @IN VARCHAR(150);SET @IN = (SELECT i.name FROM sysobjects o with(nolock), sysindexes i with(nolock) WHERE (o.id = i.id) and (o.name = ''' +  @TBLname + ''') and (i.indid = ' + @IndId + ')); IF @@ROWCOUNT = 0 SET @IN = ''''; ' 
   --   + 'UPDATE #locktable SET ObjName = ''' + @OBJname + ''', dbname = ''' + @dbname + ''', IndexName = @IN ' 
	  --+ ' WHERE dbid = ' + @dbidtxt 
   --   + ' AND objid = ' + @ObjIdtxt
	  --+ ' AND IndId = ' + @IndId

-- 	  + 'DECLARE @IN VARCHAR(150);SET @IN = (SELECT ISNULL(i.name,'''') FROM sysobjects o, sysindexes i WHERE (o.id = i.id) and (o.name = ''' +  @TBLname + ''') and (i.indid = ' + @IndId + ')); IF @@ROWCOUNT = 0 SET @IN = ''''; ' 

   SELECT @string = 
      'USE ' + @dbname + char(13)  + ';'
	  + 'DECLARE @IN VARCHAR(150);SET @IN = (SELECT ISNULL(i.name,'''') FROM sys.objects o with(nolock), sys.sysindexes i with(nolock), sys.schemas s with(nolock) WHERE (o.schema_id = s.schema_id) and (o.object_id = i.id) and (o.name = ''' +  @TBLname + ''') and (i.indid = ' + @IndId + ') and (s.name = ''' + @SchemaName + ''')); IF @@ROWCOUNT = 0 SET @IN = ''''; ' 
      + 'UPDATE #locktable SET ObjName = ''' + @OBJname + ''', dbname = ''' + @dbname + ''''
	  + ', IndexName = ISNULL(@IN,'''') '
	  + ' WHERE dbid = ' + @dbidtxt 
      + ' AND objid = ' + @ObjIdtxt
	  + ' AND IndId = ' + @IndId

   --PRINT @string
   EXECUTE (@string) 
   FETCH NEXT FROM lock_cursor INTO @dbidtxt, @ObjIdtxt, @dbname, @OBJname, @IndId, @TBLname, @SchemaName  
   END
CLOSE lock_cursor
DEALLOCATE lock_cursor
 
DECLARE @D Datetime = GETDATE()

SELECT COUNT(*) as [Count]
	  ,spid
      ,loginname
      ,hostname
      ,dbid
      ,dbname
      ,objId
      ,ObjName
      ,IndId
	  ,IndexName
      ,Type
      ,Resource
      ,Mode
      ,Status 
	  ,@D As [Time]
FROM #locktable with(nolock)
GROUP BY spid
      ,loginname
      ,hostname
      ,dbid
      ,dbname
      ,objId
      ,ObjName
      ,IndId
	  ,IndexName
      ,Type
      ,Resource
      ,Mode
      ,Status
ORDER BY spid, loginname, ObjName, Type, Mode 
return (0) 
-- END sp_lock2
GO


