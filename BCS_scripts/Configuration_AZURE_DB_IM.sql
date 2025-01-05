  -- Last update 2/01/2025
  -- AZURE enabled - IM and DB


  -- MSDB used space is not working for MI!!!! Need to add

  -- need to add - number of database sWHERE not sa owner
  --   -- SSRS, SSIS, SSAS, FTS - sys.dm_server_services since 2016

  -- different collations for databases !!!
  -- AAG
  -- Replication
  -- most recent backup - type and locations
   --BTSQLPROD02.reddog.microsoft.com - SQL Service account WRONG!!!!
 

-- https://dba.stackexchange.com/questions/81352/physical-server-or-a-virtual-machine-sql-server

-- https://learn.microsoft.com/en-us/dotnet/api/microsoft.sqlserver.management.common.databaseengineedition?view=sql-smo-160

SET NOCOUNT ON

DECLARE @MV INT = CAST(SUBSTRING(CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(20)),1,CHARINDEX('.',CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(20)))-1) AS int)
DECLARE @LV INT = SUBSTRING(CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(20)),CHARINDEX('.',CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(20)))+1,CHARINDEX('.',CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(20)),CHARINDEX('.',CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(20)))+1) - CHARINDEX('.',CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(20))) -1)

--SELECT @MV = CAST(SUBSTRING(CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(20)),1,CHARINDEX('.',CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(20)))-1) AS int)
--SELECT @LV = SUBSTRING(CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(20)),CHARINDEX('.',CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(20)))+1,CHARINDEX('.',CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(20)),CHARINDEX('.',CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(20)))+1) - CHARINDEX('.',CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(20))) -1)


DECLARE @isAZURE VARCHAR(MAX) =	CASE	WHEN SERVERPROPERTY('Edition') =  'SQL Azure' THEN 
										CASE 
											WHEN SERVERPROPERTY('EngineEdition') = 5 THEN 'SQL Azure - SQL Database'
											WHEN SERVERPROPERTY('EngineEdition') = 6 THEN 'SQL Azure - Microsoft Azure Synapse Analytics'
											WHEN SERVERPROPERTY('EngineEdition') = 7 THEN 'SQL Azure - Stretch Database'
											WHEN SERVERPROPERTY('EngineEdition') = 8 THEN 'SQL Azure - Managed Instance'
											WHEN SERVERPROPERTY('EngineEdition') = 9 THEN 'SQL Azure - Don''t know'
											WHEN SERVERPROPERTY('EngineEdition') = 10 THEN 'SQL Azure - Don''t know'
											WHEN SERVERPROPERTY('EngineEdition') = 11 THEN 'SQL Azure - Azure Synapse serverless SQL pool'
											WHEN SERVERPROPERTY('EngineEdition') = 12 THEN 'SQL Azure - Don''t know'
											ELSE ''
								END	ELSE ''	END

--SELECT @isAZURE,@MV,@LV

DECLARE @GrowthFileMsdb VARCHAR(MAX) = ''
DECLARE @GrowthFileModel VARCHAR(MAX) =  ''
DECLARE	@DatabaseMailUserRole VARCHAR(MAX) = ''
DECLARE @SystemDatabasesMODEL VARCHAR(MAX) =''
DECLARE @SystemDatabasesMSDB VARCHAR(MAX) =''l
DECLARE @mail VARCHAR(MAX) = ''
DECLARE @Jobs INT = 0
DECLARE @MPs INT = 0
DECLARE @allnodes VARCHAR(MAX) = ''
DECLARE @StartUp NVARCHAR(MAX) = ''
DECLARE @Authentication VARCHAR(MAX)  =''
DECLARE @memoryOSgb INT =0
DECLARE @osavlmm INT = 0
DECLARE @SharedDriveNames VARCHAR(MAX) = ''
DECLARE @SystemDatabases VARCHAR(MAX) =''
DECLARE @erronum INT =0
DECLARE @dirDATA NVARCHAR(MAX) ='', 
        @dirLOG NVARCHAR(MAX) ='',
        @dirBACKUP NVARCHAR(MAX) ='',
        @dirBIN NVARCHAR(MAX) =''
DECLARE @OSName VARCHAR(MAX) = ''
DECLARE @DataFileSizeMB INT = 0
DECLARE @errorlog_file VARCHAR(MAX) = ''
DECLARE @OlaVer VARCHAR(MAX) = '' 
DECLARE @MSDB_used INT = 0 

IF (@isAZURE != 'SQL Azure - SQL Database') 
BEGIN 
	--PRINT 'Not for SQL Azure - SQL Database'

	IF EXISTS (SELECT 1 FROM tempdb.dbo.sysobjects WHERE name = '##GlobalsNoAzureDb') DROP TABLE ##GlobalsNoAzureDb

	CREATE TABLE ##GlobalsNoAzureDb
			 (GrowthFileMsdb VARCHAR(MAX) NULL
			  ,GrowthFileModel VARCHAR(MAX) NULL
			  ,DatabaseMailUserRole VARCHAR(MAX) NULL
			  ,SystemDatabasesMODEL VARCHAR(MAX) NULL
			  ,SystemDatabasesMSDB VARCHAR(MAX) NULL
			  ,mail VARCHAR(MAX) NULL
			  ,Jobs INT NULL
			  ,MPs INT NULL
			  ,allnodes VARCHAR(MAX) NULL
			  ,StartUp VARCHAR(MAX) NULL
			  ,Authentication VARCHAR(MAX) NULL
			  ,memoryOSgb INT NULL
			  ,osavlmm INT NULL
			  ,SharedDriveNames VARCHAR(MAX) NULL
			  ,SystemDatabases VARCHAR(MAX) NULL
			  ,erronum INT NULL
			  ,dirDATA VARCHAR(MAX) NULL
			  ,dirLOG VARCHAR(MAX) NULL
			  ,dirBACKUP VARCHAR(MAX) NULL
			  ,dirBIN VARCHAR(MAX) NULL
			  ,OSName VARCHAR(MAX) NULL
			  ,DataFileSizeMB INT NULL
			  ,errorlog_file VARCHAR(MAX) NULL
			  ,MSDB_used INT NULL
			  ,OlaVer VARCHAR(MAX) NULL)

	
	EXEC('INSERT INTO ##GlobalsNoAzureDb (GrowthFileMsdb) SELECT TOP 1 CASE is_percent_growth WHEN 1 THEN CAST(growth AS VARCHAR(MAX)) + '' percent(s)'' ELSE CAST(growth/128 AS VARCHAR(MAX)) + '' MB(s)'' END FROM msdb.sys.database_files WHERE type = 0')
	EXEC('UPDATE ##GlobalsNoAzureDb SET GrowthFileModel = (SELECT TOP 1 CASE is_percent_growth WHEN 1 THEN CAST(growth AS VARCHAR(MAX)) + '' percent(s)'' ELSE CAST(growth/128 AS VARCHAR(MAX)) + '' MB(s)'' END FROM model.sys.database_files WHERE type = 0)')
	EXEC('UPDATE ##GlobalsNoAzureDb  SET DatabaseMailUserRole = (SELECT CASE WHEN COUNT(*) = 0 THEN ''Not'' ELSE ''Ok'' END FROM msdb.[INFORMATION_SCHEMA].[SCHEMATA] where schema_name = ''DatabaseMailUserRole'' and schema_owner <> ''DatabaseMailUserRole'')')
	EXEC('UPDATE ##GlobalsNoAzureDb SET SystemDatabasesMODEL = (SELECT  ISNULL(physical_name,'''') FROM model.sys.master_files WHERE database_id = 3 and file_id = 1)')
	EXEC('UPDATE ##GlobalsNoAzureDb SET SystemDatabasesMSDB = (SELECT ISNULL(physical_name,'''') FROM msdb.sys.master_files WHERE database_id = 4 and file_id = 1)')
	EXEC('UPDATE ##GlobalsNoAzureDb  SET mail  = (SELECT TOP 1 servername FROM msdb.dbo.sysmail_server)')
	EXEC('UPDATE ##GlobalsNoAzureDb SET Jobs = (SELECT Count(*) FROM  msdb.dbo.sysjobs s  LEFT JOIN master.sys.syslogins l on s.owner_sid = l.sid WHERE l.name NOT IN (''sa'') OR l.name IS NULL)')

	EXEC('DECLARE @allnodes VARCHAR(MAX); SET @allnodes = ''''; SELECT @allnodes = @allnodes + NodeName + '',''   FROM sys.dm_os_cluster_nodes; SET @allnodes = CASE WHEN @allnodes is NULL OR LTRIM(RTRIM(@allnodes)) = '''' THEN '''' ELSE SUBSTRING(@allnodes,1,len(@allnodes)-1) END;
	      UPDATE ##GlobalsNoAzureDb 
		  SET allnodes = allnodes ')

	EXEC('DECLARE @dirArg3 NVARCHAR(MAX), @dirArg4 NVARCHAR(MAX), @dirArg5 NVARCHAR(MAX), @dirArg6 NVARCHAR(MAX), @StartUp NVARCHAR(MAX)
		  exec master.dbo.xp_instance_regread N''HKEY_LOCAL_MACHINE'',N''Software\Microsoft\MSSQLServer\MSSQLServer\Parameters'',N''SQLArg3'', @dirArg3 output, ''no_output''
		  exec master.dbo.xp_instance_regread N''HKEY_LOCAL_MACHINE'',N''Software\Microsoft\MSSQLServer\MSSQLServer\Parameters'',N''SQLArg4'', @dirArg4 output, ''no_output''
		  exec master.dbo.xp_instance_regread N''HKEY_LOCAL_MACHINE'',N''Software\Microsoft\MSSQLServer\MSSQLServer\Parameters'',N''SQLArg5'', @dirArg5 output, ''no_output''
		  exec master.dbo.xp_instance_regread N''HKEY_LOCAL_MACHINE'',N''Software\Microsoft\MSSQLServer\MSSQLServer\Parameters'',N''SQLArg6'', @dirArg6 output, ''no_output''
		  SET @StartUp = ISNULL(@dirArg3,'''') + ISNULL('', '' +@dirArg4,'''') + ISNULL('', '' +@dirArg5,'''') + ISNULL('', '' +@dirArg6,'''')
		 UPDATE ##GlobalsNoAzureDb 
		 SET StartUp = @StartUp')

	IF @MV <= 9 EXEC('UPDATE ##GlobalsNoAzureDb SET MPs = (SELECT Count(*) FROM  msdb.dbo.sysdtspackages90 S LEFT JOIN master.sys.syslogins l on s.ownersid = l.sid WHERE S.name like ''%Maintenance%'' and l.name <> ''sa'')')
		ELSE EXEC('UPDATE ##GlobalsNoAzureDb SET MPs = (SELECT Count(*) FROM [msdb].[dbo].[sysssispackages] S left JOIN master.sys.syslogins l on S.ownersid = l.sid WHERE S.name like ''%Maintenance%'' and l.name <> ''sa'')')

	EXEC('DECLARE @AuthenticationMode INT  
		DECLARE @Authentication VARCHAR(MAX)  
		EXEC master.dbo.xp_instance_regread N''HKEY_LOCAL_MACHINE'', N''Software\Microsoft\MSSQLServer\MSSQLServer'',   
			   N''LoginMode'', @AuthenticationMode OUTPUT  
		SELECT  @Authentication = CASE @AuthenticationMode    
			   WHEN 1 THEN ''Windows Authentication''   
			   WHEN 2 THEN ''Windows and SQL Server Authentication''   
		ELSE ''Unknown''  END 
	
		UPDATE ##GlobalsNoAzureDb 
			 SET Authentication = @Authentication')

	EXEC('UPDATE ##GlobalsNoAzureDb SET memoryOSgb = (SELECT (total_physical_memory_kb / 1024 + 1) /1024 FROM sys.dm_os_sys_memory )')
	EXEC('UPDATE ##GlobalsNoAzureDb SET osavlmm = (SELECT (available_physical_memory_kb/1024) FROM sys.dm_os_sys_memory )')

	EXEC('DECLARE @SharedDriveNames VARCHAR(MAX); 
		   SET @SharedDriveNames = ''''; 
		   SELECT @SharedDriveNames = @SharedDriveNames + '','' + DriveName FROM sys.dm_io_cluster_shared_drives;
		   UPDATE ##GlobalsNoAzureDb
		   SET SharedDriveNames = @SharedDriveNames')

	EXEC('UPDATE ##GlobalsNoAzureDb SET SystemDatabases = (SELECT ISNULL(physical_name,'''') FROM master.sys.master_files WHERE database_id = 1 and file_id = 1)')

	EXEC('DECLARE @erronum INT = 0;
		  DECLARE @FileList AS TABLE (
			 subdirectory NVARCHAR(4000) NOT NULL 
			 ,DEPTH BIGINT NOT NULL
			 ,[FILE] BIGINT NOT NULL);
    
		DECLARE @ErrorLog NVARCHAR(4000), @ErrorLogPath NVARCHAR(4000);
		SELECT @ErrorLog = CAST(SERVERPROPERTY(N''errorlogfilename'') AS NVARCHAR(4000));
		SELECT @ErrorLogPath = SUBSTRING(@ErrorLog, 1, LEN(@ErrorLog) - CHARINDEX(N''\'', REVERSE(@ErrorLog))) + N''\'';
    
		INSERT INTO @FileList
		EXEC xp_dirtree @ErrorLogPath, 0, 1;
	
		SET @erronum = (SELECT COUNT(*) FROM @FileList WHERE [@FileList].subdirectory LIKE N''ERRORLOG%'');
	
		UPDATE ##GlobalsNoAzureDb 
		 SET erronum  = @erronum ')

	EXEC('declare @dirDATA nvarchar(4000), 
				  @dirLOG nvarchar(4000),
				  @dirBACKUP nvarchar(4000),
				  @dirBIN nvarchar(4000)

		exec master.dbo.xp_instance_regread N''HKEY_LOCAL_MACHINE'',N''Software\Microsoft\MSSQLServer\MSSQLServer'',N''DefaultData'', @dirDATA output, ''no_output''
		if (@dirDATA is null) 
		begin 
			   exec master.dbo.xp_instance_regread N''HKEY_LOCAL_MACHINE'',N''Software\Microsoft\MSSQLServer\Setup'',N''SQLDataRoot'', @dirDATA output, ''no_output'' 
			   select @dirDATA = @dirDATA + N''\Data'' 
		end

		exec master.dbo.xp_instance_regread N''HKEY_LOCAL_MACHINE'',N''Software\Microsoft\MSSQLServer\MSSQLServer'',N''DefaultLog'', @dirLOG output, ''no_output''
		if (@dirLOG is null) 
		begin 
			   SET @dirLOG = @dirDATA
			   --exec master.dbo.xp_instance_regread N''HKEY_LOCAL_MACHINE'',N''Software\Microsoft\MSSQLServer\Setup'',N''SQLDataRoot'', @dirLOG output, ''no_output'' 
			   --select @dirLOG = @dirLOG + N''\LOG'' 
		end

		exec master.dbo.xp_instance_regread N''HKEY_LOCAL_MACHINE'',N''Software\Microsoft\MSSQLServer\MSSQLServer'',N''BackupDirectory'', @dirBACKUP output, ''no_output''
		exec master.dbo.xp_instance_regread N''HKEY_LOCAL_MACHINE'',N''Software\Microsoft\MSSQLServer\Setup'',N''SQLBinRoot'', @dirBIN output, ''no_output''

		UPDATE ##GlobalsNoAzureDb SET dirDATA =  @dirDATA 
		UPDATE ##GlobalsNoAzureDb SET dirLOG = @dirLOG 
		UPDATE ##GlobalsNoAzureDb SET dirBACKUP = @dirBACKUP
		UPDATE ##GlobalsNoAzureDb SET dirBIN = @dirBIN')

	EXEC('DECLARE @OSName VARCHAR(100);
			EXEC   master.dbo.xp_regread
				@rootkey      = N''HKEY_LOCAL_MACHINE'',
				@key          = N''SOFTWARE\Microsoft\Windows NT\CurrentVersion'',
				@value_name   = N''ProductName'',
				@value        = @OSName output;
		 UPDATE ##GlobalsNoAzureDb 
		 SET OSName = @OSName')

	EXEC('UPDATE ##GlobalsNoAzureDb  SET DataFileSizeMB = (select size/128 from msdb.sys.master_files where database_id = 4 and file_id = 1)')

	EXEC('DECLARE @errorlog_file NVARCHAR(255)
		EXECUTE master.dbo.xp_instance_regread N''HKEY_LOCAL_MACHINE'',
											   N''SOFTWARE\Microsoft\MSSQLServer\SQLServerAgent'',
											   N''ErrorLogFile'',
												@errorlog_file OUTPUT,
											   N''no_output''
		 UPDATE ##GlobalsNoAzureDb 
		 SET errorlog_file = @errorlog_file')

-- not working for MI!!!! Need to add
	EXEC('USE msdb
		 UPDATE ##GlobalsNoAzureDb 
		 SET MSDB_used = CAST(CAST(FILEPROPERTY(''MSDBdata'', ''SpaceUsed'') AS int)/128 AS varchar) ')

	EXEC('USE msdb

			DECLARE @OlaVer VARCHAR(MAX)
			IF EXISTS (SELECT 1 FROM master.dbo.sysdatabases WHERE name = ''msdb'')
			BEGIN 
				IF EXISTS(SELECT 1 FROM [msdb].sys.objects WHERE name = ''DatabaseBackup'')  
				BEGIN  
					DECLARE @t TABLE (txt VARCHAR(2000) NULL)
					INSERT INTO @t EXEC sp_helptext ''MSDB.[dbo].[DatabaseBackup]''; 
					IF EXISTS(SELECT 1 FROM @t WHERE txt like ''%//%BCS: Ver%'' and  txt not like ''%SET%'')  
						SELECT @OlaVer = SUBSTRING(txt, CHARINDEX(''Ver'',txt,1) + LEN(''Ver'') + 1,LEN(''1.0 2019-02-05'')+1)  
						FROM @t WHERE txt like ''%//%BCS: Ver%'' and  txt not like ''%SET%''
					ELSE 
						SELECT @OlaVer = ''Installed, but BCS verssion N/A'' 
				END 
				ELSE SELECT @OlaVer = ''BCS OLA Maintenace Plan is missing'' 
			END 
			UPDATE ##GlobalsNoAzureDb 
			SET OlaVer = @OlaVer')
	
	SET @GrowthFileMsdb = (SELECT GrowthFileMsdb FROM ##GlobalsNoAzureDb)			
	SET @GrowthFileModel = (SELECT GrowthFileModel FROM ##GlobalsNoAzureDb)	
	SET @DatabaseMailUserRole = ISNULL((SELECT DatabaseMailUserRole FROM ##GlobalsNoAzureDb),'Not')
	SET @SystemDatabasesMODEL = (SELECT SystemDatabasesMODEL FROM ##GlobalsNoAzureDb)	
	SET @SystemDatabasesMSDB = (SELECT SystemDatabasesMSDB FROM ##GlobalsNoAzureDb)	
	SET @mail = (SELECT mail FROM ##GlobalsNoAzureDb)	
	SET @Jobs = (SELECT Jobs FROM ##GlobalsNoAzureDb)	
	SET @MPs = (SELECT MPs FROM ##GlobalsNoAzureDb)	
	SET @allnodes = ISNULL((SELECT allnodes FROM ##GlobalsNoAzureDb),'')	
	SET @StartUp = (SELECT StartUp FROM ##GlobalsNoAzureDb)	
	SET @Authentication = (SELECT Authentication FROM ##GlobalsNoAzureDb)	
	SET @memoryOSgb = (SELECT memoryOSgb FROM ##GlobalsNoAzureDb)	
	SET @osavlmm = (SELECT osavlmm FROM ##GlobalsNoAzureDb)	
	SET @SharedDriveNames = (SELECT SharedDriveNames FROM ##GlobalsNoAzureDb)	
	SET @SystemDatabases = (SELECT SystemDatabases FROM ##GlobalsNoAzureDb)	
	SET @erronum = (SELECT erronum FROM ##GlobalsNoAzureDb)	
	SET @dirDATA = (SELECT dirDATA FROM ##GlobalsNoAzureDb)	
	SET @dirLOG = (SELECT dirLOG FROM ##GlobalsNoAzureDb)	
	SET @dirBACKUP = (SELECT dirBACKUP FROM ##GlobalsNoAzureDb)	
	SET @dirBIN = (SELECT dirBIN FROM ##GlobalsNoAzureDb)	
	SET @OSName = (SELECT OSName FROM ##GlobalsNoAzureDb)	
	SET @DataFileSizeMB = (SELECT DataFileSizeMB FROM ##GlobalsNoAzureDb)	
	SET @errorlog_file = (SELECT errorlog_file FROM ##GlobalsNoAzureDb)	
	SET @MSDB_used = (SELECT MSDB_used FROM ##GlobalsNoAzureDb)	
	SET @OlaVer = (SELECT OlaVer FROM ##GlobalsNoAzureDb)	

	--SELECT * FROM ##GlobalsNoAzureDb

	IF EXISTS (SELECT 1 FROM tempdb.dbo.sysobjects WHERE name = '##GlobalsNoAzureDb') DROP TABLE ##GlobalsNoAzureDb
END
ELSE SET @OlaVer = 'AZURE BD Maintenace Plan is not required' 


DECLARE	@DAC VARCHAR(MAX) = (SELECT CASE  WHEN value_in_use = 1 THEN 'Enabled' ELSE 'Disabled' END FROM sys.configurations WHERE name = 'remote admin connections' )

IF EXISTS (SELECT 1 FROM tempdb.dbo.sysobjects WHERE name = '##Globals') DROP TABLE ##Globals

CREATE TABLE ##Globals
		 (net_transport VARCHAR(20) NULL,
		  protocol_type VARCHAR(20) NULL,
		  auth_scheme VARCHAR(20) NULL,
		  client_net_address VARCHAR(20) NULL,
		  local_net_address VARCHAR(20) NULL,
		  local_tcp_port VARCHAR(20) NULL,

		  Instant_file_initialization VARCHAR(20) NULL,
		  Lock_pages_in_memory VARCHAR(20) NULL,
		  Virtual VARCHAR(20) NULL,
		  strtSQL DATETIME NULL,
		  currmem INT NULL)

IF @MV >=10
	IF @MV >= 13
		BEGIN 
			EXEC(' INSERT INTO ##Globals (net_transport, protocol_type, auth_scheme, client_net_address, local_net_address, local_tcp_port,Instant_file_initialization,Lock_pages_in_memory,Virtual,strtSQL,currmem) 
			VALUES(
			CAST(CONNECTIONPROPERTY(''net_transport'') AS VARCHAR(20)) , 
			CAST(CONNECTIONPROPERTY(''protocol_type'') AS VARCHAR(20)) , 
			CAST(CONNECTIONPROPERTY(''auth_scheme'') AS VARCHAR(20)) ,
			CAST(CONNECTIONPROPERTY(''client_net_address'') AS VARCHAR(20)) ,
			CAST(CONNECTIONPROPERTY(''local_net_address'') AS VARCHAR(20)) ,
			CAST(CONNECTIONPROPERTY(''local_tcp_port'') AS VARCHAR(20))  

			, (SELECT  CASE WHEN instant_file_initialization_enabled = ''Y'' THEN ''Yes'' ELSE ''No'' END FROM sys.dm_server_services WHERE servicename LIKE ''SQL Server (%'')  
			, (SELECT CASE WHEN sql_memory_model = 2 THEN ''Yes'' ELSE ''No'' END FROM sys.dm_os_sys_info)
			, (SELECT CASE 
					WHEN dosi.virtual_machine_type = 2
					THEN ''Virtual'' 
					ELSE ''Physical''
					END
				FROM sys.dm_os_sys_info dosi)
			, (SELECT sqlserver_start_time FROM sys.dm_os_sys_info)
			, (SELECT (committed_kb/1024) FROM sys.dm_os_sys_info)

			--,''''
			--,'''','''',NULL,NULL

			)')
		END 	
	ELSE
		EXEC(' INSERT INTO ##Globals (net_transport, protocol_type, auth_scheme, client_net_address, local_net_address, local_tcp_port,Instant_file_initialization,Lock_pages_in_memory,Virtual,strtSQL,currmem) 
		VALUES(
		CAST(CONNECTIONPROPERTY(''net_transport'') AS VARCHAR(20)) , 
		CAST(CONNECTIONPROPERTY(''protocol_type'') AS VARCHAR(20)) , 
		CAST(CONNECTIONPROPERTY(''auth_scheme'') AS VARCHAR(20)) ,
		CAST(CONNECTIONPROPERTY(''client_net_address'') AS VARCHAR(20)) ,
		CAST(CONNECTIONPROPERTY(''local_net_address'') AS VARCHAR(20)) ,
		CAST(CONNECTIONPROPERTY(''local_tcp_port'') AS VARCHAR(20))  
		,'''','''','''',(SELECT create_Date FROM MASTER.sys.databases WHERE name = ''tempdb''),0
		)')
ELSE 
	EXEC(' INSERT INTO ##Globals (net_transport, protocol_type, auth_scheme, client_net_address, local_net_address, local_tcp_port)	VALUES('''','''','''','''','''','''','''','''','''',(SELECT create_Date FROM MASTER.sys.databases WHERE name = ''tempdb''),0)')



DECLARE @installationSQL DATETIME = (SELECT create_date FROM sys.server_principals WHERE sid = 0x010100000000000512000000)
DECLARE @ServiceAccount VARCHAR(MAX)
DECLARE @ServiceAccountStatus VARCHAR(MAX)
DECLARE @ServiceAccountStartup VARCHAR(MAX)

IF EXISTS (SELECT 1 FROM master.sys.sysobjects WHERE name = 'dm_server_services')
       SELECT @ServiceAccount = DSS.service_account,
              @ServiceAccountStatus = status_desc, 
              @ServiceAccountStartup = startup_type_desc 
       FROM    master.sys.dm_server_services AS DSS
       WHERE servicename like 'SQL Server%' and servicename not like 'SQL Server Agent%'  and servicename not like 'SQL Server Launchpad%'

DECLARE @AgentAccount VARCHAR(MAX)
DECLARE @AgentAccountStatus VARCHAR(MAX)
DECLARE @AgentAccountStartup VARCHAR(MAX)
IF EXISTS (SELECT 1 FROM master.sys.sysobjects WHERE name = 'dm_server_services')
       SELECT  
        @AgentAccount = DSS.service_account,
              @AgentAccountStatus = status_desc, 
              @AgentAccountStartup = startup_type_desc 
       FROM    master.sys.dm_server_services AS DSS
       WHERE servicename like 'SQL Server Agent%'

-- not required for express
DECLARE @compression VARCHAR(MAX) =  ISNULL((SELECT CASE value  WHEN 1 THEN 'Enabled' ELSE 'No' END FROM sys.configurations  WHERE name = 'backup compression default'),'')
DECLARE @DOP INT =(SELECT CAST(value_in_use AS INT) FROM sys.configurations WHERE name = 'max degree of parallelism')
DECLARE @MIN INT =(SELECT CAST(value_in_use AS INT) FROM sys.configurations WHERE name = 'min server memory (MB)')
DECLARE @MAX INT =(SELECT CAST(value_in_use AS INT) FROM sys.configurations  WHERE name = 'max server memory (MB)')
DECLARE @CPUs INT = (SELECT count(*) FROM sys.dm_os_schedulers  WHERE status = 'VISIBLE ONLINE')
DECLARE @GrowthFileMaster VARCHAR(MAX) = (SELECT  TOP 1 CASE is_percent_growth WHEN 1 THEN CAST(growth AS VARCHAR(MAX)) + ' percent(s)' ELSE CAST(growth/128 AS VARCHAR(MAX)) + ' MB(s)' END FROM master.sys.database_files WHERE type = 0)
DECLARE @NumberTempDB INT =(SELECT COUNT(*) FROM tempdb.sys.sysfiles WHERE groupid <>0)
DECLARE @InitialSizeTempDB VARCHAR(MAX) = (SELECT  TOP 1 CASE is_percent_growth WHEN 1 THEN CAST(growth AS VARCHAR(MAX)) + ' percent(s)' ELSE CAST(growth/128 AS VARCHAR(MAX)) + ' MB(s)' END FROM tempdb.sys.database_files  WHERE type = 1)
DECLARE @GrowthFileTempDB VARCHAR(MAX) =(SELECT  TOP 1 CASE is_percent_growth WHEN 1 THEN CAST(growth AS VARCHAR(MAX)) + ' percent(s)' ELSE CAST(growth/128 AS VARCHAR(MAX)) + ' MB(s)' END FROM tempdb.sys.database_files  WHERE type = 1)
DECLARE @LocationFileTempDB VARCHAR(MAX) = (SELECT TOP 1 MIN(FileName) FROM tempdb.sys.sysfiles WHERE groupid <>0)
DECLARE @LocationLogTempDB VARCHAR(MAX) = (SELECT MIN(FileName)  FROM tempdb.sys.sysfiles WHERE groupid =0)
DECLARE @TempDBdata VARCHAR(MAX); SET @TempDBdata = ''; SELECT @TempDBdata = @TempDBdata + ', ' + CAST(CAST(Size*1.0/128 AS int) AS VARCHAR(50)) FROM tempdb.sys.database_files WHERE data_space_id <> 0; SET @TempDBdata = SUBSTRING(@TempDBdata,3,LEN(@TempDBdata)-2)
DECLARE @TempDBlog VARCHAR(MAX); SET @TempDBlog = ''; SELECT @TempDBlog = @TempDBlog + ', ' + CAST(CAST(Size*1.0/128 AS int) AS VARCHAR(50)) FROM tempdb.sys.database_files WHERE data_space_id = 0; SET @TempDBlog = SUBSTRING(@TempDBlog,3,LEN(@TempDBlog)-2)
DECLARE @ErrorLogLocation VARCHAR(MAX) =(SELECT CAST(SERVERPROPERTY('ErrorLogFileName') AS VARCHAR(MAX)))
DECLARE @valueMSX VARCHAR(MAX)
DECLARE @InstanceID NVARCHAR(MAX) = ''

--SELECT @InstanceID = SUBSTRING(@dirBIN1,CHARINDEX('SQL Server\', @dirBIN1)+11,CHARINDEX('\MSSQL\Binn', @dirBIN1) -  CHARINDEX('SQL Server\', @dirBIN1)-11) 
DECLARE @key VARCHAR(MAX) = 'SOFTWARE\Microsoft\Microsoft SQL Server\' + @InstanceID + '\SQLServerAgent'

--EXEC   master.dbo.xp_regread
--	@rootkey      = N'HKEY_LOCAL_MACHINE',
--	@key          = N'SOFTWARE\Microsoft\Windows NT\CurrentVersion',
--	@value_name   = N'CSDVersion',
--	@value        = @OSPatchLevel output


--EXEC master..xp_regread
--   @rootkey = 'HKEY_LOCAL_MACHINE',
--   @key = @key,
--   @value_name = 'MsxEncryptChannelOptions',
--   @value = @valueMSX OUTPUT

-------------------------


SELECT
		CAST((SELECT CASE WHEN Virtual<>'' THEN Virtual ELSE @isAZURE END FROM ##Globals) AS VARCHAR(MAX))  AS [P/V],
	--SERVERPROPERTY('ServerName') AS ServerName,
		ISNULL(SERVERPROPERTY('MachineName'),'') AS HostName,
		ISNULL(SERVERPROPERTY('InstanceName'),'defailt') AS InstanceName,
		ISNULL(@installationSQL,'') AS [Installation date],
		CAST(ISNULL((SELECT strtSQL   FROM ##Globals),'') AS DATETIME) AS [Start time],
		CASE WHEN LEN (@StartUp) <> 0 THEN  '="' + @StartUp + '"' ELSE '' END AS StartUpFlags,
		CAST((SELECT Instant_file_initialization   FROM ##Globals) AS VARCHAR(20)) AS [InstantFileInitialisation],
		CAST((SELECT Lock_pages_in_memory    FROM ##Globals) AS VARCHAR(20)) AS [LockPagesInMemory],
		@DAC AS DAC,
		CAST((SELECT net_transport FROM ##Globals) AS VARCHAR(20)) AS net_transport,
		CAST((SELECT protocol_type FROM ##Globals) AS VARCHAR(20))  AS protocol_type,
		CAST((SELECT auth_scheme FROM ##Globals) AS VARCHAR(20)) AS auth_scheme,
		ISNULL(SERVERPROPERTY('ComputerNamePhysicalNetBIOS'),'') AS ActiveNode,
		@allnodes AS ListNodes,
		(SELECT client_net_address FROM ##Globals) AS client_net_address,  
		ISNULL((SELECT local_net_address FROM ##Globals),'') AS local_net_address,
		ISNULL(CASE
				WHEN  (SELECT local_tcp_port FROM ##Globals) > 0  THEN CAST((SELECT local_tcp_port FROM ##Globals) AS int)
				ELSE 65536+CAST((SELECT local_tcp_port FROM ##Globals) AS int) 
		END,'') AS local_tcp_port,
		ISNULL(@ServiceAccount,'') AS ServiceAccount,
		ISNULL(@ServiceAccountStatus,'') AS ServiceAccountStatus,
		ISNULL(@ServiceAccountStartup,'') AS ServiceAccountStartup,
		ISNULL(@AgentAccount,'') AS AgentAccount,
		ISNULL(@AgentAccountStatus,'') AS AgentAccountStatus,
		ISNULL(@AgentAccountStartup,'') AS AgentAccountStartup,
		@Authentication AS AuthentificationMode,
		@compression AS BackupCompression,
		@DOP AS DOP,
		@memoryOSgb AS OSmemoryGB,
		@MIN AS [MinRAM (mb)],
		@MAX AS [MaxRAM (mb)],
		CAST((SELECT currmem   FROM ##Globals) AS int) AS [SQL used Mb],
		@osavlmm AS [OS free Mb],
		@CPUs  AS CPUs,
		@GrowthFileMaster AS GrowthFile_Master,
		@GrowthFileMsdb AS GrowthFile_Msdb,
		@GrowthFileModel AS GrowthFile_Model,
		@NumberTempDB AS NumberTempDB, 
----SUBSTRING(@dirDATA,1,2) Drive_Location,
		CASE WHEN @SharedDriveNames is NULL OR LTRIM(RTRIM(@SharedDriveNames)) = '' THEN '' ELSE SUBSTRING(@SharedDriveNames,2,len(@SharedDriveNames)-1)
		END AS SharedDrivesOnCluster,
		@DataFileSizeMB AS DataFileSizeMB,
		ISNULL(@MSDB_used,'') AS MSDB_used,
		ISNULL(@SystemDatabases,'') AS MASTER_file_location,
		ISNULL(@SystemDatabasesMODEL,'') AS MODEL_file_location,
		ISNULL(@SystemDatabasesMSDB,'') AS MSDB_file_location, 
		ISNULL(@InitialSizeTempDB,'') AS InitialSizeTempDB, 
		@GrowthFileTempDB AS GrowthFileTempDB,
		@TempDBdata AS SizeDataTempDB,
		@TempDBlog AS SizeLogTempDB,
		@LocationFileTempDB AS TempDB_fileLocation,
		@LocationLogTempDB AS TempDB_LogLocation,
		@dirDATA AS DB_FileLocation,
		@dirLOG       AS DB_LogLocation,   
		@dirBACKUP AS DB_BackupLocation,
		@dirBIN AS BIN_Location,
        ISNULL(@mail,'') AS [MailServer],
		ISNULL(SERVERPROPERTY('ProductLevel'),'') AS ProductLevel,
		ISNULL(SERVERPROPERTY('ProductUpdateLevel'),'') AS ProductUpdateLevel,
		ISNULL(SERVERPROPERTY('ProductBuildType'),'') AS ProductBuildType,
		ISNULL(SERVERPROPERTY('ProductUpdateReference'),'') AS ProductUpdateReference,
		SERVERPROPERTY('ProductVersion') AS ProductVersion,
		ISNULL(SERVERPROPERTY('ProductMajorVersion'),'') AS ProductMajorVersion,
		ISNULL(SERVERPROPERTY('ProductMinorVersion'),'') AS ProductMinorVersion,
		ISNULL(SERVERPROPERTY('ProductBuild'),'') AS ProductBuild,
		SERVERPROPERTY('Collation') AS ProductCollation,
		SERVERPROPERTY('Edition') AS Edition,
		@MPs AS MaintenancePlansWith_no_SA,
		@Jobs AS JobsWith_no_SA,
		ISNULL(@ErrorLogLocation,'') AS ErrorLogLocation,
		@errorlog_file AS AgentErrorLogLocation,
		CASE WHEN @valueMSX = 0x0 THEN 'MSX ready' ELSE '' END AS MultiServerJobs,
----,@OSEdition AS OsEdition
----,@OSVersion AS OsVersion
		ISNULL(@OSName,'') AS OsName,
----,@OSPatchLevel AS PatchLevel
		@erronum NumberErrorLog_files,
		ISNULL(@DatabaseMailUserRole,'Not') AS [MSDB_DatabaseMailUserRole],
		@OlaVer AS [BCS installed Ola MP]


