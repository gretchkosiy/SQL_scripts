USE [SSISDB]
GO

EXEC [SSISDB].[catalog].[configure_catalog] @property_name=N'MAX_PROJECT_VERSIONS', @property_value=5
EXEC [SSISDB].[catalog].[configure_catalog] @property_name=N'RETENTION_WINDOW', @property_value=30

GO

IF EXISTS (SELECT * FROM sys.sysobjects WHERE id = OBJECT_ID('[dbo].[sp_SSIS_structure]'))
	DROP PROCEDURE [dbo].[sp_SSIS_structure] 
GO

IF EXISTS (SELECT * FROM sys.sysobjects WHERE id = OBJECT_ID('[dbo].[sp_SSIS_Errors]'))
	DROP PROCEDURE [dbo].[sp_SSIS_Errors]
GO


/*
--- test runs 
 
EXEC [SSISDB].dbo.sp_SSIS_structure
EXEC [SSISDB].dbo.sp_SSIS_structure 'CDWH-Student'
EXEC [SSISDB].dbo.sp_SSIS_structure 'CDWH-Student', 'NAPLAN'
EXEC [SSISDB].dbo.sp_SSIS_structure 'CDWH-Student', 'NAPLAN', '02_NAPLAN_BandCutoff.dtsx'
EXEC [SSISDB].dbo.sp_SSIS_structure 'CDWH-Student', 'NAPLAN', '02_NAPLAN_BandCutoff.dtsx', 'TEST'
EXEC [SSISDB].dbo.sp_SSIS_structure 'CDWH-Student', '', '', 'TEST'
EXEC [SSISDB].dbo.sp_SSIS_structure 'CDWH-DataCollection'

*/
CREATE PROCEDURE [dbo].[sp_SSIS_structure] 
	 @folder varchar(max) = ''
	,@project varchar(max) = ''
	,@package varchar(max) = ''
	--,@environment varchar(max) = ''
AS
BEGIN 
SET NOCOUNT ON
	DECLARE @txtStructure VARCHAR(MAX)
	DECLARE @txtEnvironment VARCHAR(MAX)
	DECLARE @txtVariables VARCHAR(MAX)
	DECLARE @txtPermissions VARCHAR(MAX)

	DECLARE @P VARCHAR(max) = ''

	-- List of packages/projects/folders
	SET @txtStructure = 'IF OBJECT_ID(''tempdb..##Structure'') IS NOT NULL DROP TABLE ##Structure;
			SELECT 
				''Structure'' AS [Resultset]
			,@@SERVERNAME AS [SSIS instance]
			  ,F.name AS [Folder Name]
			  --,P.[project_id]
		   --   ,P.[folder_id]
			  ,P.[name] AS [Project Name]
			  ,PA.[name] AS [Package name]
			  --,P.[description]
			  --,P.[project_format_version]
			  --,P.[deployed_by_sid]
			  ,P.[deployed_by_name] AS [Project deployed by]
			  ,P.[last_deployed_time]
			  --,P.[created_time]
			  --,P.[object_version_lsn]
			  --,[validation_status]
			  --,[last_validation_time]	
		INTO ##Structure
		FROM [SSISDB].[internal].[packages] PA 
			INNER JOIN [SSISDB].[internal].[projects] P 
				ON PA.[project_id] = P.[project_id] 
				AND PA.[project_version_lsn] = P.[object_version_lsn]
			INNER JOIN [SSISDB].[internal].[folders] F ON 
				P.[folder_id] = F.[folder_id] '

	SET @txtEnvironment = 'IF OBJECT_ID(''tempdb..##Environments'') IS NOT NULL DROP TABLE ##Environments;
		SELECT 
			''Environments'' AS [Resultset]
			,@@SERVERNAME AS [SSIS instance]
			,F.name AS [Folder Name]
			--,E.[environment_id]
			,E.[environment_name]
			,EV.[name] AS [Variable Name]
			,EV.[type] AS [Variable type]
			,CASE WHEN EV.[sensitive_value] IS NOT NULL THEN ''Yes'' ELSE '''' END AS [Encrypted ENV]
			,CASE WHEN EV.[sensitive_value] IS NOT NULL THEN 
					ISNULL([SSISDB].[internal].[get_value_by_data_type](DECRYPTBYKEYAUTOCERT(CERT_ID(N''MS_Cert_Env_'' + CONVERT(nvarchar(20), EV.[environment_id])), NULL, EV.[sensitive_value]), EV.[type]),'''') 
				ELSE EV.[value] END AS [value]
			--,E.[folder_id]
			,E.[description]
			--,E.[created_by_sid]
			,E.[created_by_name]
			,E.[created_time]
		INTO ##Environments
		FROM [SSISDB].[internal].[environment_variables] EV
			INNER JOIN [SSISDB].[internal].[environments] E on E.[environment_id] = EV.[environment_id]
			INNER JOIN [SSISDB].[internal].[folders] F ON E.[folder_id] = F.[folder_id] 
		where E.[environment_name] IN (SELECT DISTINCT [Environment name] from ##UserModified)'

SET @txtVariables ='IF OBJECT_ID(''tempdb..##UserModified'') IS NOT NULL DROP TABLE ##UserModified;
SELECT
	''Variables-Environments'' AS [Resultset]
	,@@SERVERNAME				AS [SSIS instance]
    ,FL.name					AS [Folder name]
	,PR.[name]					AS [Project name]
	,PP.[object_name]			AS [Object name]
	,CASE 
				WHEN PP.[object_type] = 20 THEN ''project parameter''
				WHEN PP.[object_type] = 30 THEN ''package parameter''
				ELSE ''''
	END							AS [parameter type]
	,PP.[parameter_name]		AS [Parameter name] 
    ,PP.[parameter_data_type]	AS [type]
	,ISNULL(EV.[type],'''')		AS [type ENV]
	,CASE WHEN PP.[sensitive] = 1 AND PP.sensitive_default_value IS NOT NULL THEN ''Yes'' ELSE '''' END AS [Encrypted]
	--,PP.sensitive_default_value
	,CASE WHEN EV.[sensitive_value] IS NOT NULL THEN ''Yes'' ELSE '''' END AS [Encrypted ENV] 
	,CASE 
		WHEN PP.[value_set] = 1 AND PP.[value_type] =''R'' THEN 
		     ISNULL([SSISDB].[internal].[get_value_by_data_type](DECRYPTBYKEYAUTOCERT(CERT_ID(N''MS_Cert_Env_'' + CONVERT(nvarchar(20), EV.[environment_id])), NULL, EV.[sensitive_value]), EV.[type]),'''')
		ELSE ISNULL([SSISDB].[internal].[get_value_by_data_type](DECRYPTBYKEYAUTOCERT(CERT_ID(N''MS_Cert_Proj_'' + CONVERT(nvarchar(20), PP.project_id)), NULL, PP.sensitive_default_value), PP.parameter_data_type),'''')
	END AS [Decrypted value]
	,CASE WHEN PP.[value_set] = 1 THEN ''Yes'' ELSE '''' END AS [Modified]
	--,PP.[value_type]
	,ISNULL(ER.[environment_name],'''') [Environment name]

	,ISNULL(EV.[name],'''') AS [Environment Variable Name]
	--,EV.[value]
	,ISNULL(PP.[design_default_value],'''') AS [Design value]
	,ISNULL(CASE 
		WHEN PP.[value_set] = 0 AND PP.[value_type] =''V'' THEN ''''										-- Not modified
		WHEN PP.[value_set] = 1 AND PP.[value_type] =''V'' THEN PP.[default_value]						-- Mofified in SSIS catalogue
		WHEN PP.[value_set] = 1 AND PP.[value_type] =''R'' THEN EV.[value]								-- Environment
		ELSE ''''
	END,'''') AS [Modified value]
  INTO ##UserModified
  FROM [SSISDB].[internal].[object_parameters] PP
	LEFT JOIN [SSISDB].[internal].[projects] PR ON PP.[project_id] = PR.[project_id]
	LEFT JOIN [SSISDB].[internal].[folders] FL ON FL.[folder_id] = PR.[folder_id]
	LEFT JOIN [SSISDB].[internal].[environment_references] ER ON ER.[project_id] = PP.[project_id]
	LEFT JOIN [SSISDB].[internal].[environments] E ON E.[folder_id] = PR.[folder_id] AND E.[environment_name] = ER.[environment_name]
	LEFT JOIN [SSISDB].[internal].[environment_variables] EV ON EV.[environment_id] = E.[environment_id] AND EV.[name] = PP.[referenced_variable_name]

	-- Get last configuration
	INNER JOIN (SELECT [project_id], MAX([project_version_lsn]) AS [project_version_lsn]   
				FROM [SSISDB].[internal].[object_parameters]
				GROUP BY [project_id]) LSN ON PP.[project_id] =LSN.[project_id] AND PP.[project_version_lsn] =LSN.[project_version_lsn]
WHERE (PP.[value_set] = 1 OR PP.[sensitive] = 1 OR EV.[sensitive] = 1) 
-- AND EV.[type] IS NOT NULL
'

	SET @txtPermissions = 'IF OBJECT_ID(''tempdb..##Permissions'') IS NOT NULL DROP TABLE ##Permissions;
		select 
			''Permissions'' AS [Resultset]
			,@@SERVERNAME AS [SSIS instance]
			,''Database role'' as [object_type],
			rdp.name as [path],
			mdp.name as [user] ,
			'''' as permission_type,
			'''' as [Permission]
		INTO ##Permissions
		from [SSISDB].sys.database_role_members drm
		inner join[SSISDB].sys.database_principals rdp on drm.role_principal_id = rdp.principal_id
		inner join [SSISDB].sys.database_principals mdp on drm.member_principal_id = mdp.principal_id
		union 
		/* folders */
		SELECT 
			''Permissions'' AS [Resultset]
			,@@SERVERNAME AS [SSIS instance]
			,''folder'' as [object_type],
			f.name as [path],
			pri.name as [user],
			permission_type,
			CASE
				WHEN [obj].permission_type=1 THEN ''Read''
				WHEN [obj].permission_type=2 THEN ''Modify''
				WHEN [obj].permission_type=3 THEN ''Execution''
				WHEN [obj].permission_type=4 THEN ''Manage permissions''
				WHEN [obj].permission_type=100 THEN ''Create Objects''
				WHEN [obj].permission_type=102 THEN ''Modify Objects''
				WHEN [obj].permission_type=103 THEN ''Execute Objects''
				WHEN [obj].permission_type=101 THEN ''Read Objects''
				WHEN [obj].permission_type=104 THEN ''Manage Object Permissions''
			END AS [Permission]
		FROM [SSISDB].[internal].[object_permissions] AS obj
			INNER JOIN [SSISDB].[sys].[database_principals] AS pri ON obj.[sid] = pri.[sid]
			INNER JOIN [SSISDB].[internal].[folders] as f ON f.folder_id=obj.object_id
		UNION 
		/* projects */
		SELECT
			''Permissions'' AS [Resultset]
			,@@SERVERNAME AS [SSIS instance]
			,''project'' as [object_type],
			f.name + ''/'' + p.name as [path],
			pri.name as [user],
			permission_type,
			CASE
				WHEN [obj].permission_type=1 THEN ''Read''
				WHEN [obj].permission_type=2 THEN ''Modify''
				WHEN [obj].permission_type=3 THEN ''Execution''
				WHEN [obj].permission_type=4 THEN ''Manage permissions''
				WHEN [obj].permission_type=100 THEN ''Create Objects''
				WHEN [obj].permission_type=102 THEN ''Modify Objects''
				WHEN [obj].permission_type=103 THEN ''Execute Objects''
				WHEN [obj].permission_type=101 THEN ''Read Objects''
				WHEN [obj].permission_type=104 THEN ''Manage Object Permissions''
			END AS [Permission]
		FROM [SSISDB].[internal].[project_permissions] AS obj
			INNER JOIN [SSISDB].[sys].[database_principals] AS pri ON obj.[sid] = pri.[sid]
			INNER JOIN [SSISDB].[internal].[projects] as p ON p.project_id=obj.object_id
			INNER JOIN [SSISDB].[internal].[folders] as f ON p.folder_id=f.folder_id
		UNION 
		/* environments */
		SELECT
			''Permissions'' AS [Resultset]
			,@@SERVERNAME AS [SSIS instance]
			,''environment'' as [object_type],
			f.name + ''/'' + e.environment_name as [path],
			pri.name as [user],
			permission_type,
			CASE
				WHEN [obj].permission_type=1 THEN ''Read''
				WHEN [obj].permission_type=2 THEN ''Modify''
				WHEN [obj].permission_type=3 THEN ''Execution''
				WHEN [obj].permission_type=4 THEN ''Manage permissions''
				WHEN [obj].permission_type=100 THEN ''Create Objects''
				WHEN [obj].permission_type=102 THEN ''Modify Objects''
				WHEN [obj].permission_type=103 THEN ''Execute Objects''
				WHEN [obj].permission_type=101 THEN ''Read Objects''
				WHEN [obj].permission_type=104 THEN ''Manage Object Permissions''
			END AS [Permission]
		FROM [SSISDB].[internal].[project_permissions] AS obj
			INNER JOIN [SSISDB].[sys].[database_principals] AS pri ON obj.[sid] = pri.[sid]
			INNER JOIN [SSISDB].[internal].[environments] as e ON e.environment_id=obj.object_id
			INNER JOIN [SSISDB].[internal].[folders] as f ON e.folder_id=f.folder_id 
			'

	--- Only folder parameter
	IF (@folder != '' AND @project = '' AND @package = '')    
	BEGIN 
		--PRINT '1 *** (@folder != '' AND @project = '' AND @package = '')'
		SET @txtVariables = @txtVariables + ' AND FL.name = ''' + @folder + ''' '
		SET @txtStructure = @txtStructure + ' AND F.name = ''' + @folder + ''' '
	END

	IF (@folder != '' AND @project != '' AND @package = '')   
	BEGIN
		--PRINT '2 *** (@folder != '' AND @project != '' AND @package = '')   '
		SET @txtVariables = @txtVariables + ' and Fl.name = ''' + @folder + ''' AND Pr.[name] = ''' + @project + ''' '
		SET @txtStructure = @txtStructure + ' where F.name = ''' + @folder + ''' AND P.[name] = ''' + @project + ''' '

	END

	IF (@folder != '' AND @project != '' AND @package != '')  
	BEGIN 
		PRINT '3 *** (@folder != '' AND @project != '' AND @package != '') '
		SET @txtVariables = @txtVariables + ' and Fl.name = ''' + @folder + ''' AND Pr.[name] = ''' + @project + ''' AND  PP.[object_name] = ''' + @package + ''' '
		SET @txtStructure = @txtStructure + ' WHERE F.name = ''' + @folder + ''' AND P.[name] = ''' + @project + ''' AND PA.[name] = ''' + @package + ''' '

	END

	EXEC (@txtStructure); IF (@@ROWCOUNT <> 0) 
		BEGIN 
			SELECT * FROM ##Structure ORDER BY [Folder Name], [Project Name], [Package name]; 
			SELECT DISTINCT [Folder Name], [Project Name] INTO #US FROM ##Structure WHERE [Folder Name] <>''
			DROP TABLE ##Structure
		END
	EXEC (@txtVariables); IF (@@ROWCOUNT <> 0) SELECT * FROM ##UserModified ORDER BY 2,3,4,5,6,7  -- 2,3,12,4,5

	EXEC (@txtPermissions); 
	DELETE FROM ##Permissions WHERE LTRIM(RTRIM(CAST([user] AS VARCHAR(MAX)))) = 'dbo'
	set @P = @folder + '%'
	IF OBJECT_ID('tempdb..##Permissions') IS NOT NULL DELETE FROM ##Permissions WHERE [path] NOT LIKE @P and OBJECT_TYPE <>  'Database role'
	IF EXISTS(SELECT DISTINCT 1 FROM ##Permissions) SELECT * FROM ##Permissions; DROP TABLE ##Permissions


	EXEC (@txtEnvironment); IF (@@ROWCOUNT <> 0) SELECT * FROM ##Environments; IF OBJECT_ID('tempdb..##Environments') IS NOT NULL DROP TABLE ##Environments;
	DROP TABLE ##UserModified


IF EXISTS (SELECT 1 FROM #US)
	BEGIN

		SELECT DISTINCT 
			'EXEC msdb.dbo.sp_JOBs_structure ''' + J.NAME + '''' AS [Jobs structure]
			--,CASE 
			--	WHEN CHARINDEX ('\', JS.command, CHARINDEX ('\', JS.command, CHARINDEX('"\"\SSISDB\', JS.command) + 1) + CHARINDEX ('"\"\SSISDB\', JS.command)) - CHARINDEX('"\"\SSISDB\', JS.command) - LEN('"\"\SSISDB\') > 0 
			--	THEN SUBSTRING(JS.command,
			--			CHARINDEX ('\', JS.command, CHARINDEX('"\"\SSISDB\', JS.command) +1 ) + CHARINDEX ('"\"\SSISDB\', JS.command) - 1,  -- START
			--			CHARINDEX ('\', JS.command, CHARINDEX ('\', JS.command, CHARINDEX('"\"\SSISDB\', JS.command) + 1) + CHARINDEX ('"\"\SSISDB\', JS.command)) - CHARINDEX('"\"\SSISDB\', JS.command) - LEN('"\"\SSISDB\') )
			--	ELSE ''
			--END as [SSIS Folder]

			--,CASE 
			--	WHEN CHARINDEX ('\', JS.command, CHARINDEX ('\', JS.command, CHARINDEX('"\"\SSISDB\', JS.command) + 1) + CHARINDEX ('"\"\SSISDB\', JS.command)) - CHARINDEX('"\"\SSISDB\', JS.command) - LEN('"\"\SSISDB\') > 0 
			--	THEN SUBSTRING(JS.command,
			--			CHARINDEX ('\', JS.command, CHARINDEX ('\', JS.command, CHARINDEX('"\"\SSISDB\', JS.command) + 1) + CHARINDEX ('"\"\SSISDB\', JS.command) + 1)+ 1,  -- START
			--			CHARINDEX ('\', JS.command, CHARINDEX ('\', JS.command, CHARINDEX ('\', JS.command, CHARINDEX('"\"\SSISDB\', JS.command) + 1) + CHARINDEX ('"\"\SSISDB\', JS.command) + 1)+ 1) 
			--			- CHARINDEX ('\', JS.command, CHARINDEX ('\', JS.command, CHARINDEX('"\"\SSISDB\', JS.command) + 1) + CHARINDEX ('"\"\SSISDB\', JS.command) + 1)- 1)
			--	ELSE ''
			--END as [SSIS Project]
		FROM msdb.dbo.sysjobsteps JS 
			LEFT JOIN msdb.dbo.sysjobs J ON J.job_id = JS.job_id
			INNER JOIN #US U 
				ON U.[Folder name] COLLATE Latin1_General_CI_AS = CASE 
				WHEN CHARINDEX ('\', JS.command, CHARINDEX ('\', JS.command, CHARINDEX('"\"\SSISDB\', JS.command) + 1) + CHARINDEX ('"\"\SSISDB\', JS.command)) - CHARINDEX('"\"\SSISDB\', JS.command) - LEN('"\"\SSISDB\') > 0 
				THEN SUBSTRING(JS.command,
						CHARINDEX ('\', JS.command, CHARINDEX('"\"\SSISDB\', JS.command) +1 ) + CHARINDEX ('"\"\SSISDB\', JS.command) - 1,  -- START
						CHARINDEX ('\', JS.command, CHARINDEX ('\', JS.command, CHARINDEX('"\"\SSISDB\', JS.command) + 1) + CHARINDEX ('"\"\SSISDB\', JS.command)) - CHARINDEX('"\"\SSISDB\', JS.command) - LEN('"\"\SSISDB\') )
				ELSE ''
			END
				AND U.[Project name] COLLATE Latin1_General_CI_AS = CASE 
				WHEN CHARINDEX ('\', JS.command, CHARINDEX ('\', JS.command, CHARINDEX('"\"\SSISDB\', JS.command) + 1) + CHARINDEX ('"\"\SSISDB\', JS.command)) - CHARINDEX('"\"\SSISDB\', JS.command) - LEN('"\"\SSISDB\') > 0 
				THEN SUBSTRING(JS.command,
						CHARINDEX ('\', JS.command, CHARINDEX ('\', JS.command, CHARINDEX('"\"\SSISDB\', JS.command) + 1) + CHARINDEX ('"\"\SSISDB\', JS.command) + 1)+ 1,  -- START
						CHARINDEX ('\', JS.command, CHARINDEX ('\', JS.command, CHARINDEX ('\', JS.command, CHARINDEX('"\"\SSISDB\', JS.command) + 1) + CHARINDEX ('"\"\SSISDB\', JS.command) + 1)+ 1) 
						- CHARINDEX ('\', JS.command, CHARINDEX ('\', JS.command, CHARINDEX('"\"\SSISDB\', JS.command) + 1) + CHARINDEX ('"\"\SSISDB\', JS.command) + 1)- 1)
				ELSE ''
			END	
		WHERE j.category_id <> 100 --PowerBI
		AND  CHARINDEX ('/ISSERVER', JS.command) <> 0 
			AND [NAME] NOT LIKE 'BCS%' AND [NAME] NOT IN ('syspolicy_purge_history', 'SSIS Server Maintenance Job') 
			--AND CASE 
			--		WHEN CHARINDEX ('\', JS.command, CHARINDEX ('\', JS.command, CHARINDEX('"\"\SSISDB\', JS.command) + 1) + CHARINDEX ('"\"\SSISDB\', JS.command)) - CHARINDEX('"\"\SSISDB\', JS.command) - LEN('"\"\SSISDB\') > 0 
			--		THEN SUBSTRING(JS.command,
			--				CHARINDEX ('\', JS.command, CHARINDEX('"\"\SSISDB\', JS.command) +1 ) + CHARINDEX ('"\"\SSISDB\', JS.command) - 1,  -- START
			--				CHARINDEX ('\', JS.command, CHARINDEX ('\', JS.command, CHARINDEX('"\"\SSISDB\', JS.command) + 1) + CHARINDEX ('"\"\SSISDB\', JS.command)) - CHARINDEX('"\"\SSISDB\', JS.command) - LEN('"\"\SSISDB\') )
			--		ELSE ''
			--	END <> ''



		--SELECT * FROM #US
		DROP TABLE #US
	END
END
GO



CREATE PROCEDURE [dbo].[sp_SSIS_Errors] 
	@days INT = 2	
AS 
-- check existance and availability of SSISDB
--IF EXISTS(SELECT 1 FROM master.dbo.sysdatabases where name = 'SSISDB' AND sys.fn_hadr_is_primary_replica('SSISDB')=1)
BEGIN 
	DECLARE @d AS DATETIME 
	SET @d = DATEADD(day, -@days, GETDATE())

	SELECT DISTINCT
			@@SERVERNAME AS ServerName
			,'/' +execs.[folder_name] +'/' + execs.[project_name] + '/' + execs.[package_name] AS [Object]
			,JobStep.[Job/Step] AS [SQL Agent Job name]
			,OM.[message] AS [ErrorMessage],
			   --execs.[executed_as_name],
			   opers.[start_time] AS [ErrorTime]
	FROM [SSISDB].[internal].[executions] execs
		INNER JOIN [SSISDB].[internal].[operations] opers ON execs.[execution_id]= opers.[operation_id]
		LEFT JOIN [SSISDB].[internal].[operation_messages] OM ON OM.operation_id = opers.operation_id
		LEFT JOIN (
						SELECT 
							J.NAME + ' (Step ' + CAST(JS.step_id AS VARCHAR(3)) + ')' [Job/Step]
							,CASE 
									WHEN CHARINDEX ('\', JS.command, CHARINDEX ('\', JS.command, CHARINDEX('"\"\SSISDB\', JS.command) + 1) + CHARINDEX ('"\"\SSISDB\', JS.command)) - CHARINDEX('"\"\SSISDB\', JS.command) - LEN('"\"\SSISDB\') > 0 
									THEN SUBSTRING(JS.command,
											CHARINDEX ('\', JS.command, CHARINDEX ('\', JS.command, CHARINDEX ('\', JS.command, CHARINDEX('"\"\SSISDB\', JS.command) + 1) + CHARINDEX ('"\"\SSISDB\', JS.command) + 1)+ 1) +1,
											--CHARINDEX ('\', JS.command, CHARINDEX('"\"\SSISDB\', JS.command) + 1) + CHARINDEX ('"\"\SSISDB\', JS.command),  -- START
											CHARINDEX ('\', JS.command, CHARINDEX ('\', JS.command, CHARINDEX ('\', JS.command, CHARINDEX ('\', JS.command, CHARINDEX('"\"\SSISDB\', JS.command) + 1) + CHARINDEX ('"\"\SSISDB\', JS.command) + 1)+ 1) +1) 
											- CHARINDEX ('\', JS.command, CHARINDEX ('\', JS.command, CHARINDEX ('\', JS.command, CHARINDEX('"\"\SSISDB\', JS.command) + 1) + CHARINDEX ('"\"\SSISDB\', JS.command) + 1)+ 1) -1
											)
									ELSE ''
								END as [SSISpackageName]
						FROM msdb.dbo.sysjobsteps JS 
								LEFT JOIN msdb.dbo.sysjobs J ON J.job_id = JS.job_id
						where JS.subsystem = 'SSIS' AND  CHARINDEX ('/ISSERVER', JS.command) <> 0 ) AS JobStep ON JobStep.[SSISpackageName] = execs.[package_name] COLLATE SQL_Latin1_General_CP1_CI_AS
	WHERE      (opers.[operation_id] in (SELECT id FROM [SSISDB].[internal].[current_user_readable_operations])
			   OR (IS_MEMBER('ssis_admin') = 1)
			   OR (IS_SRVROLEMEMBER('sysadmin') = 1))
			   AND opers.status = 4
			   AND opers.start_time >= @d
			   AND OM.[message_type] =  120
	ORDER BY opers.[start_time] DESC
END 
GO

