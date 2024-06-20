  declare @strtSQL datetime
   declare @currmem int
   declare @smaxmem int
   declare @osmaxmm int
   declare @osavlmm int 

declare @installationSQL datetime 

SELECT 
	@installationSQL = create_date 
FROM sys.server_principals
WHERE sid = 0x010100000000000512000000

   -- SQL memory
   SELECT 
      @strtSQL = sqlserver_start_time,
      @currmem = (committed_kb/1024)
	  --,@smaxmem = (committed_target_kb/1024)           
   FROM sys.dm_os_sys_info;
   
   --OS memory
   --SELECT 
   --   --@osmaxmm = (total_physical_memory_kb/1024),
   --   @osavlmm = (available_physical_memory_kb/1024) 
   --FROM sys.dm_os_sys_memory;


declare @Instant_file_initialization VARCHAR(MAX)
SELECT  
        @instant_file_initialization = CASE WHEN instant_file_initialization_enabled = 'Y' THEN 'Yes'ELSE 'No' END
FROM    sys.dm_server_services
WHERE   servicename LIKE 'SQL Server (%'


declare @Lock_pages_in_memory VARCHAR(MAX)
SELECT @Lock_pages_in_memory = CASE WHEN sql_memory_model = 2 THEN 'Yes' ELSE 'No' END
FROM sys.dm_os_sys_info;

----


DECLARE	@DatabaseMailUserRole VARCHAR(50)

IF EXISTS (SELECT 1 FROM msdb.[INFORMATION_SCHEMA].[SCHEMATA] where schema_name = 'DatabaseMailUserRole' and schema_owner <> 'DatabaseMailUserRole') 
	SET @DatabaseMailUserRole = 'Not'
ELSE 
	SET @DatabaseMailUserRole = 'Ok'



DECLARE	@DAC VARCHAR(50)
DECLARE @MV INT
DECLARE @LV INT

SELECT @MV = SUBSTRING(CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(20)),1,CHARINDEX('.',CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(20)))-1)
SELECT @LV = SUBSTRING(CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(20)),CHARINDEX('.',CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(20)))+1,CHARINDEX('.',CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(20)),CHARINDEX('.',CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(20)))+1) - CHARINDEX('.',CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(20))) -1)


if exists (select 1 from tempdb..sysobjects where name = '##Globals')
	DROP TABLE ##Globals

CREATE TABLE ##Globals
(
  net_transport VARCHAR(20) NULL,
  protocol_type VARCHAR(20) NULL,
  auth_scheme VARCHAR(20) NULL,
  client_net_address VARCHAR(20) NULL,
  local_net_address VARCHAR(20) NULL,
  local_tcp_port VARCHAR(20) NULL
)


IF @MV >=10
	EXEC(' INSERT INTO ##Globals (net_transport, protocol_type, auth_scheme, client_net_address, local_net_address, local_tcp_port) 
	VALUES(
	CAST(CONNECTIONPROPERTY(''net_transport'') AS VARCHAR(20)) , 
	CAST(CONNECTIONPROPERTY(''protocol_type'') AS VARCHAR(20)) , 
	CAST(CONNECTIONPROPERTY(''auth_scheme'') AS VARCHAR(20)) ,
	CAST(CONNECTIONPROPERTY(''client_net_address'') AS VARCHAR(20)) ,
	CAST(CONNECTIONPROPERTY(''local_net_address'') AS VARCHAR(20)) ,
	CAST(CONNECTIONPROPERTY(''local_tcp_port'') AS VARCHAR(20))  )')
ELSE 
	EXEC(' INSERT INTO ##Globals (net_transport, protocol_type, auth_scheme, client_net_address, local_net_address, local_tcp_port)	VALUES('''','''','''','''','''','''')')

SELECT 
	@DAC = 
	CASE 
		WHEN value_in_use = 1 THEN 'Enabled'
		ELSE 'Disabled'
	END 
FROM sys.configurations
WHERE name = 'remote admin connections'

declare 
        @dirArg3 nvarchar(4000),
        @dirArg4 nvarchar(4000),
        @dirArg5 nvarchar(4000),
        @dirArg6 nvarchar(4000),
		@StartUp nvarchar(4000)

exec master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE',N'Software\Microsoft\MSSQLServer\MSSQLServer\Parameters',N'SQLArg3', @dirArg3 output, 'no_output'
exec master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE',N'Software\Microsoft\MSSQLServer\MSSQLServer\Parameters',N'SQLArg4', @dirArg4 output, 'no_output'
exec master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE',N'Software\Microsoft\MSSQLServer\MSSQLServer\Parameters',N'SQLArg5', @dirArg5 output, 'no_output'
exec master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE',N'Software\Microsoft\MSSQLServer\MSSQLServer\Parameters',N'SQLArg6', @dirArg6 output, 'no_output'


SET @StartUp = ISNULL(@dirArg3,'') + ISNULL(', ' +@dirArg4,'') + ISNULL(', ' +@dirArg5,'') + ISNULL(', ' +@dirArg6,'')

DECLARE
	@TempDBdata         VARCHAR(1000),
	@TempDBlog			VARCHAR(1000)

SET @TempDBdata = ''
SET @TempDBlog = ''


SELECT @TempDBlog = @TempDBlog + ', ' + CAST(CAST(Size*1.0/128 as int) as varchar(50))
	--,case
	--	when data_space_id = 0 then 'log'
	--	else 'data'
	--end as type
FROM tempdb.sys.database_files
WHERE data_space_id = 0
--GROUP BY data_space_id

SELECT @TempDBdata = @TempDBdata + ', ' + CAST(CAST(Size*1.0/128 as int) as varchar(50))
	--,case
	--	when data_space_id = 0 then 'log'
	--	else 'data'
	--end as type
FROM tempdb.sys.database_files
WHERE data_space_id <> 0
--GROUP BY data_space_id

SET @TempDBdata = SUBSTRING(@TempDBdata,3,LEN(@TempDBdata)-2)
SET @TempDBlog = SUBSTRING(@TempDBlog,3,LEN(@TempDBlog)-2)


DECLARE
@OSEdition            VARCHAR(100)
,@OSVersion            VARCHAR(100)
,@OSName            VARCHAR(100)
,@OSPatchLevel        VARCHAR(100)

EXEC   master.dbo.xp_regread
@rootkey      = N'HKEY_LOCAL_MACHINE',
@key          = N'SOFTWARE\Microsoft\Windows NT\CurrentVersion',
@value_name   = N'ProductName',
@value        = @OSName output

if exists (select 1 from tempdb..sysobjects where name = '##OSEdition')
                DROP TABLE ##OSEdition

--create table ##OSEdition (VALUe varchar(255),OSEdition varchar(255), data varchar(100))
--insert into ##OSEdition
--EXEC   master.dbo.xp_regread
--@rootkey      = N'HKEY_LOCAL_MACHINE',
--@key          = N'SYSTEM\CurrentControlSet\Control\ProductOptions',
--@value_name   = N'ProductSuite'
--SET @OSEdition = (SELECT TOP 1 OSEdition  FROM ##OSEdition)

EXEC   master.dbo.xp_regread
@rootkey      = N'HKEY_LOCAL_MACHINE',
@key          = N'SOFTWARE\Microsoft\Windows NT\CurrentVersion',
@value_name   = N'CSDVersion',
@value        = @OSPatchLevel output

create table ##OSEdition (VALUe varchar(255),OSEdition varchar(255), data varchar(100))
insert into ##OSEdition
EXEC   master.dbo.xp_regread
@rootkey      = N'HKEY_LOCAL_MACHINE',
@key          = N'SYSTEM\CurrentControlSet\Control\ProductOptions',
@value_name   = N'ProductSuite'
SET @OSEdition = (SELECT TOP 1 OSEdition  FROM ##OSEdition)


DECLARE @valueMSX VARCHAR(20)
declare @dirBIN1 nvarchar(4000)
declare @InstanceID nvarchar(4000)
DECLARE @key VARCHAR(100)

exec master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE',N'Software\Microsoft\MSSQLServer\Setup',N'SQLBinRoot', @dirBIN1 output, 'no_output'
Select @InstanceID = SUBSTRING(@dirBIN1,CHARINDEX('SQL Server\', @dirBIN1)+11,CHARINDEX('\MSSQL\Binn', @dirBIN1) -  CHARINDEX('SQL Server\', @dirBIN1)-11) 

SET @key = 'SOFTWARE\Microsoft\Microsoft SQL Server\' + @InstanceID + '\SQLServerAgent'

EXEC master..xp_regread
   @rootkey = 'HKEY_LOCAL_MACHINE',
   @key = @key,
   @value_name = 'MsxEncryptChannelOptions',
   @value = @valueMSX OUTPUT



DECLARE @errorlog_file NVARCHAR(255)
EXECUTE master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE',
                                       N'SOFTWARE\Microsoft\MSSQLServer\SQLServerAgent',
                                       N'ErrorLogFile',
                                        @errorlog_file OUTPUT,
                                       N'no_output'

Declare @ErrorLogLocation VARCHAR(max)
SELECT @ErrorLogLocation = CAST(SERVERPROPERTY('ErrorLogFileName') AS VARCHAR(max))



Declare @SharedDriveNames VARCHAR(max)
SET @SharedDriveNames = ''

SELECT @SharedDriveNames = @SharedDriveNames + ',' + DriveName FROM sys.dm_io_cluster_shared_drives

Declare @GrowthFileMaster VARCHAR(max)
Declare @GrowthFileMsdb VARCHAR(max)
Declare @GrowthFileModel VARCHAR(max)

select  TOP 1
       @GrowthFileMaster = 
       CASE is_percent_growth
              WHEN 1 THEN CAST(growth as VARCHAR(MAX)) + ' percent(s)'
              ELSE CAST(growth/128 as VARCHAR(MAX)) + ' MB(s)'
       END
from master.sys.database_files where type = 0

select TOP 1
       @GrowthFileMsdb = 
       CASE is_percent_growth
              WHEN 1 THEN CAST(growth as VARCHAR(MAX)) + ' percent(s)'
              ELSE CAST(growth/128 as VARCHAR(MAX)) + ' MB(s)'
       END 
from msdb.sys.database_files where type = 0

select TOP 1
       @GrowthFileModel = 
       CASE is_percent_growth
              WHEN 1 THEN CAST(growth as VARCHAR(MAX)) + ' percent(s)'
              ELSE CAST(growth/128 as VARCHAR(MAX)) + ' MB(s)'
       END
from model.sys.database_files where type = 0






Declare @SystemDatabases varchar(max)
Declare @SystemDatabasesMODEL varchar(max)
Declare @SystemDatabasesMSDB varchar(max)


SELECT @SystemDatabases = physical_name 
FROM master.sys.master_files
WHERE NAME = 'master'

SELECT @SystemDatabasesMODEL = physical_name 
FROM model.sys.master_files
WHERE NAME = 'modeldev'

SELECT @SystemDatabasesMSDB = physical_name 
FROM msdb.sys.master_files
WHERE NAME = 'MSDBData'

Declare @Jobs int

select @Jobs = Count(*)
 from  msdb..sysjobs s 
 left join master.sys.syslogins l on s.owner_sid = l.sid
 where l.name not in ('sa') OR l.name IS NULL


Declare @MPs int
IF @MV <= 9
	select @MPs = Count(*)
	from  msdb.dbo.sysdtspackages90 S
	left join master.sys.syslogins l on s.ownersid = l.sid
	where S.name like '%Maintenance%' and l.name <> 'sa'
ELSE 
	select @MPs = Count(*)
	from [msdb].[dbo].[sysssispackages] S
	left join master.sys.syslogins l on S.ownersid = l.sid
	where S.name like '%Maintenance%' and l.name <> 'sa'

Declare @DOP int

SELECT @DOP = CAST(value_in_use AS INT)
  FROM sys.configurations 
  WHERE name = 'max degree of parallelism'

Declare @MIN int

SELECT @MIN = CAST(value_in_use AS INT)
  FROM sys.configurations 
  WHERE name = 'min server memory (MB)'

Declare @MAX int

SELECT @MAX = CAST(value_in_use AS INT)
  FROM sys.configurations 
  WHERE name = 'max server memory (MB)'

declare @mail varchar(150)
select @mail = servername from msdb.dbo.sysmail_server

Declare @a varchar(max)
SET @a = ''
SELECT @a = @a + NodeName + ','   FROM sys.dm_os_cluster_nodes

Declare @NumberTempDB int
Declare @InitialSizeTempDB varchar(max)
Declare @GrowthFileTempDB varchar(max)
Declare @LocationFileTempDB varchar(max)
Declare @LocationLogTempDB varchar(max)

select  TOP 1
       @InitialSizeTempDB = 
       CASE is_percent_growth
              WHEN 1 THEN CAST(growth as VARCHAR(MAX)) + ' percent(s)'
              ELSE CAST(growth/128 as VARCHAR(MAX)) + ' MB(s)'
       END
from tempdb.sys.database_files  where type = 1


select 
       @NumberTempDB = COUNT(*), 
       --@InitialSizeTempDB = MIN(size)/ 128, 
       --@GrowthFileTempDB = 
       ----MIN(growth),

       --MIN(CASE is_percent_growth
       --     WHEN 1 THEN CAST(growth as VARCHAR(MAX)) + ' percent(s)'
       --     ELSE CAST(growth/128 as VARCHAR(MAX)) + ' MB(s)'
       --END),

       @LocationFileTempDB = MIN(FileName)  
from tempdb.sys.sysfiles where groupid <>0


select  TOP 1
       @GrowthFileTempDB = 
       CASE is_percent_growth
              WHEN 1 THEN CAST(growth as VARCHAR(MAX)) + ' percent(s)'
              ELSE CAST(growth/128 as VARCHAR(MAX)) + ' MB(s)'
       END
from tempdb.sys.database_files where type = 0

select 
       @LocationLogTempDB = MIN(FileName)  
from tempdb.sys.sysfiles where groupid =0



Declare @ServiceAccount varchar(max)
Declare @ServiceAccountStatus varchar(max)
Declare @ServiceAccountStartup varchar(max)

If Exists (select 1 from master.sys.sysobjects where name = 'dm_server_services')
       SELECT  
        @ServiceAccount = DSS.service_account,
              @ServiceAccountStatus = status_desc, 
              @ServiceAccountStartup = startup_type_desc 
       FROM    master.sys.dm_server_services AS DSS
       where servicename like 'SQL Server%' and servicename not like 'SQL Server Agent%'


Declare @AgentAccount varchar(max)
Declare @AgentAccountStatus varchar(max)
Declare @AgentAccountStartup varchar(max)
If Exists (select 1 from master.sys.sysobjects where name = 'dm_server_services')
       SELECT  
        @AgentAccount = DSS.service_account,
              @AgentAccountStatus = status_desc, 
              @AgentAccountStartup = startup_type_desc 
       FROM    master.sys.dm_server_services AS DSS
       where servicename like 'SQL Server Agent%'

declare @memoryOSgb int
--select name from sysobjects where name like 'dm%' -- = 'dm_os_sys_memory'

--if exists (select 1 from sysobjects where name = 'dm_os_sys_memory')
select 
       @memoryOSgb = (total_physical_memory_kb / 1024 + 1) /1024
	   ,@osavlmm = (available_physical_memory_kb/1024) 
from sys.dm_os_sys_memory 

DECLARE @AuthenticationMode INT  
DECLARE @Authentication VARCHAR(max)  

EXEC master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer',   
       N'LoginMode', @AuthenticationMode OUTPUT  
SELECT  @Authentication = CASE @AuthenticationMode    
       WHEN 1 THEN 'Windows Authentication'   
       WHEN 2 THEN 'Windows and SQL Server Authentication'   
ELSE 'Unknown'  END 


declare @dirDATA nvarchar(4000), 
              @dirLOG nvarchar(4000),
              @dirBACKUP nvarchar(4000),
              @dirBIN nvarchar(4000)

exec master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE',N'Software\Microsoft\MSSQLServer\MSSQLServer',N'DefaultData', @dirDATA output, 'no_output'
if (@dirDATA is null) 
begin 
       exec master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE',N'Software\Microsoft\MSSQLServer\Setup',N'SQLDataRoot', @dirDATA output, 'no_output' 
       select @dirDATA = @dirDATA + N'\Data' 
end

exec master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE',N'Software\Microsoft\MSSQLServer\MSSQLServer',N'DefaultLog', @dirLOG output, 'no_output'
if (@dirLOG is null) 
begin 
       SET @dirLOG = @dirDATA
       --exec master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE',N'Software\Microsoft\MSSQLServer\Setup',N'SQLDataRoot', @dirLOG output, 'no_output' 
       --select @dirLOG = @dirLOG + N'\LOG' 
end

exec master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE',N'Software\Microsoft\MSSQLServer\MSSQLServer',N'BackupDirectory', @dirBACKUP output, 'no_output'
exec master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE',N'Software\Microsoft\MSSQLServer\Setup',N'SQLBinRoot', @dirBIN output, 'no_output'


declare @CPUs int
select 
       @CPUs = count(*)
--scheduler_id, cpu_id, status, is_online 
from sys.dm_os_schedulers 
where status = 'VISIBLE ONLINE'


declare @compression varchar(max)

select 
       @compression = 
       CASE value 
              WHEN 1 THEN 'Enabled'
              ELSE 'No'
       END
from sys.configurations 
where name = 'backup compression default'

declare @erronum int 


-- for any version but less than 2019
--exec master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', N'NumErrorLogs', @erronum output

DECLARE @FileList AS TABLE (
     subdirectory NVARCHAR(4000) NOT NULL 
     ,DEPTH BIGINT NOT NULL
     ,[FILE] BIGINT NOT NULL
    );
    
    DECLARE @ErrorLog NVARCHAR(4000), @ErrorLogPath NVARCHAR(4000);
    SELECT @ErrorLog = CAST(SERVERPROPERTY(N'errorlogfilename') AS NVARCHAR(4000));
    SELECT @ErrorLogPath = SUBSTRING(@ErrorLog, 1, LEN(@ErrorLog) - CHARINDEX(N'\', REVERSE(@ErrorLog))) + N'\';
    
    INSERT INTO @FileList
    EXEC xp_dirtree @ErrorLogPath, 0, 1;

	
    SET @erronum = (SELECT COUNT(*) FROM @FileList WHERE [@FileList].subdirectory LIKE N'ERRORLOG%');
 
------------------------------------------------------------------------------------

USE msdb

SELECT

--SERVERPROPERTY('ServerName') as ServerName,
       SERVERPROPERTY('MachineName') AS HostName,
       ISNULL(SERVERPROPERTY('InstanceName'),'defailt') as InstanceName,
	   @installationSQL AS [Installation date],
	   @strtSQL AS [Start time],

	   @StartUp AS StartUpFlags,
	   @Instant_file_initialization AS [InstantFileInitialisation],
	   @Lock_pages_in_memory AS [LockPagesInMemory],
	   @DAC AS DAC,

		CAST((SELECT net_transport from ##Globals) AS VARCHAR(20)) AS net_transport,
		CAST((SELECT protocol_type from ##Globals) AS VARCHAR(20))  AS protocol_type,
		CAST((SELECT auth_scheme from ##Globals) AS VARCHAR(20)) AS auth_scheme,
		SERVERPROPERTY('ComputerNamePhysicalNetBIOS') AS ActiveNode,
	CASE 
                WHEN @a is NULL OR LTRIM(RTRIM(@a)) = '' THEN ''
                ELSE SUBSTRING(@a,1,len(@a)-1) 
	END 
AS ListNodes,
       (SELECT client_net_address from ##Globals) AS client_net_address,  
		(SELECT local_net_address from ##Globals) AS local_net_address,
       CASE
              WHEN  (SELECT local_tcp_port from ##Globals) > 0  THEN CAST((SELECT local_tcp_port from ##Globals) as int)
              ELSE 65536+CAST((SELECT local_tcp_port from ##Globals) as int) 
       END AS local_tcp_port,
       @ServiceAccount AS ServiceAccount,
       @ServiceAccountStatus AS ServiceAccountStatus,
       @ServiceAccountStartup AS ServiceAccountStartup,
       @AgentAccount AS AgentAccount,
       @AgentAccountStatus AS AgentAccountStatus,
       @AgentAccountStartup AS AgentAccountStartup,
       @Authentication AS AuthentificationMode,


@compression as BackupCompression,
@DOP as DOP,
@memoryOSgb as OSmemoryGB,
@MIN as [MinRAM (mb)],
@MAX as [MaxRAM (mb)],
@currmem AS [SQL used Mb],
@osavlmm AS [OS free Mb],
@CPUs  AS CPUs,
@GrowthFileMaster AS GrowthFile_Master,
@GrowthFileMsdb AS GrowthFile_Msdb,
@GrowthFileModel AS GrowthFile_Model,
@NumberTempDB as NumberTempDB, 
--SUBSTRING(@dirDATA,1,2) Drive_Location,

CASE 
                WHEN @SharedDriveNames is NULL OR LTRIM(RTRIM(@SharedDriveNames)) = '' THEN ''
                ELSE SUBSTRING(@SharedDriveNames,2,len(@SharedDriveNames)-1)
END

AS ListSharedDrives,
(select size/128 from msdb.sys.master_files where name = 'MSDBData') DataFileSizeMB,
CAST(CAST(FILEPROPERTY('MSDBdata', 'SpaceUsed') AS int)/128 AS varchar) as MSDB_used,
@SystemDatabases AS MASTER_file_location,
@SystemDatabasesMODEL AS MODEL_file_location,
@SystemDatabasesMSDB AS MSDB_file_location, 
@InitialSizeTempDB as InitialSizeTempDB, 
@GrowthFileTempDB AS GrowthFileTempDB,
@TempDBdata AS SizeDataTempDB,
@TempDBlog AS SizeLogTempDB,
@LocationFileTempDB AS TempDB_fileLocation,
@LocationLogTempDB AS TempDB_LogLocation,

@dirDATA AS DB_FileLocation,
@dirLOG       AS DB_LogLocation,   
@dirBACKUP AS DB_BackupLocation,
@dirBIN AS BIN_Location,

              [MailServer] = @mail,


SERVERPROPERTY('ProductLevel') AS ProductLevel,
SERVERPROPERTY('ProductUpdateLevel') AS ProductUpdateLevel,
SERVERPROPERTY('ProductBuildType') AS ProductBuildType,
SERVERPROPERTY('ProductUpdateReference') AS ProductUpdateReference,
SERVERPROPERTY('ProductVersion') AS ProductVersion,
SERVERPROPERTY('ProductMajorVersion') AS ProductMajorVersion,
SERVERPROPERTY('ProductMinorVersion') AS ProductMinorVersion,
SERVERPROPERTY('ProductBuild') AS ProductBuild,
SERVERPROPERTY('Collation') AS ProductCollation,
SERVERPROPERTY('Edition') AS Edition,
@MPs as MaintenancePlansWith_no_SA,
@Jobs AS JobsWith_no_SA,
@ErrorLogLocation As ErrorLogLocation,
@errorlog_file As AgentErrorLogLocation,
CASE WHEN @valueMSX = 0x0 THEN 'MSX ready' ELSE '' END AS MultiServerJobs
--,@OSEdition AS OsEdition
--,@OSVersion AS OsVersion
,@OSName AS OsName
--,@OSPatchLevel AS PatchLevel
,@erronum NumberErrorLog_files
, @DatabaseMailUserRole AS [MSDB_DatabaseMailUserRole]
GO
