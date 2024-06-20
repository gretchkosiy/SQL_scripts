-- https://docs.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/always-on-availability-groups-dynamic-management-views-functions?source=recommendations&view=sql-server-ver16


-- shows everyting on PRIMARY only and NULL for secondary
SELECT  
	   AG.name						AS [AAG name]
	   ,ADC.[database_name]			AS [DB name]
	   ,HARCS.[replica_server_name]	AS [Replica name]
	   ,HARS.role_desc				AS [Role]
		,ISNULL(AGL.dns_name,'')	AS [Ls DNS name]
		,ISNULL(AGL.port,'')		AS [Ls PORT]
		,CASE WHEN AGL.dns_name IS NOT NULL THEN ISNULL(AGL.[ip_configuration_string_from_cluster],'no virtual IP addresses') ELSE '' END
									AS [Cluster IP configuration string]
		,HARS.synchronization_health_desc AS [Health]
		,AARP.endpoint_url			AS [Endpoint]
		,AARP.availability_mode_desc AS [Availability Mode]
		,AARP.failover_mode_desc	AS [Failover Mode]
		,AARP.seeding_mode_desc		AS [Seeding Mode]
		,DRS.connected_state_desc	AS [Connected State]

  FROM [master].[sys].[dm_hadr_database_replica_cluster_states] AS HDRCS  WITH (NOLOCK) 
	LEFT JOIN [sys].[dm_hadr_availability_replica_cluster_states] AS HARCS WITH (NOLOCK) 
		ON HDRCS.replica_id = HARCS.replica_id
	LEFT JOIN [sys].[availability_databases_cluster] AS ADC WITH (NOLOCK)
		ON ADC.group_id = HARCS.group_id AND ADC.group_database_id = HDRCS.group_database_id
	LEFT JOIN [sys].[availability_groups] AS AG WITH (NOLOCK) 
		ON AG.group_id = ADC.group_id 
	LEFT JOIN sys.dm_hadr_availability_replica_states AS HARS WITH (NOLOCK)
		ON HARS.group_id = HARCS.group_id AND HARS.replica_id = HARCS.replica_id
	LEFT JOIN sys.availability_group_listeners AGL WITH (NOLOCK)
		ON HARCS.group_id = AGL.group_id
	LEFT JOIN sys.availability_replicas AARP WITH (NOLOCK)
		ON HARS.replica_id = AARP.replica_id
	LEFT JOIN SYS.DM_HADR_AVAILABILITY_REPLICA_STATES DRS WITH (NOLOCK)
		ON HARS.replica_id = DRS.replica_id 

WHERE AG.name IS NOT NULL 
--AND AG.name = 'PS_DB_19'
  ORDER BY AG.name, HDRCS.[database_name], HDRCS.[group_database_id],HARCS.replica_server_name


  /*

SELECT 
	HARS.role_desc
	,HARCS.replica_server_name
	--,HARS.operational_state_desc
	--,HARS.connected_state_desc
	,HARS.synchronization_health_desc
	,AG.name
	,ISNULL(AGL.dns_name,'')	AS [Listener DNS name]
	, ISNULL(AGL.port,'')		AS [Listener PORT]
	,CASE WHEN AGL.dns_name IS NOT NULL THEN ISNULL(AGL.[ip_configuration_string_from_cluster],'no virtual IP addresses') ELSE '' END
								AS [Cluster IP configuration string]
	,AARP.endpoint_url			AS [Endpoint]
	,AARP.availability_mode_desc AS [Availability Mode]
	,AARP.failover_mode_desc	AS [Failover Mode]
	,AARP.seeding_mode_desc		AS [Seeding Mode]
	,DRS.operational_state_desc AS [Operational State]
	,DRS.connected_state_desc	AS [Connected State]
	,DRS.synchronization_health_desc AS [Health]


	 
FROM sys.dm_hadr_availability_replica_states AS HARS WITH (NOLOCK) 
	LEFT JOIN sys.availability_groups AS AG WITH (NOLOCK)
		ON HARS.group_id = AG.group_id --AND HARS.role = 2
	LEFT JOIN sys.availability_group_listeners AGL
		ON AG.group_id = AGL.group_id
	LEFT JOIN sys.dm_hadr_availability_replica_cluster_states AS HARCS 
		ON HARCS.replica_id = HARS.replica_id
	INNER JOIN sys.availability_replicas AARP WITH (NOLOCK)
		ON HARS.replica_id = AARP.replica_id
	INNER JOIN SYS.DM_HADR_AVAILABILITY_REPLICA_STATES DRS WITH (NOLOCK)
		ON HARS.replica_id = DRS.replica_id 
ORDER BY AGL.dns_name DESC, name, HARS.role_desc





==================================================================
Script: HADR Local Replica Overview.sql
Description: This script will display a utilisation overview
of the local Availability Group Replica Server.
The overview will contain amount of databases as
well as total size of databases (DATA, LOG, FILESTREAM)
and is group by ...
1) ... Replica role (PRIMARY / SECONDARY)
2) ... Availability Group
Date created: 05.09.2018 (Dominic Wirth)
Last change: -
Script Version: 1.0
SQL Version: SQL Server 2014 or higher
====================================================================
-- Load size of databases which are part of an Availability Group
DECLARE @dbSizes TABLE (DatabaseId INT, DbTotalSizeMB INT, DbTotalSizeGB DECIMAL(10,2));
DECLARE @dbId INT, @stmt NVARCHAR(MAX);
SELECT @dbId = MIN(database_id) FROM sys.databases WHERE group_database_id IS NOT NULL;
WHILE @dbId IS NOT NULL
BEGIN
SELECT @stmt = 'USE [' + DB_NAME(@dbId) + ']; SELECT ' + CAST(@dbId AS NVARCHAR) + ', (SUM([size]) / 128.0), (SUM([size]) / 128.0 / 1024.0) FROM sys.database_files;';
INSERT INTO @dbSizes (DatabaseId, DbTotalSizeMB, DbTotalSizeGB) EXEC (@stmt);
SELECT @dbId = MIN(database_id) FROM sys.databases WHERE group_database_id IS NOT NULL AND database_id > @dbId;
END;
-- Show utilisation overview grouped by replica role
SELECT AR.replica_server_name, DRS.is_primary_replica AS IsPrimaryReplica, COUNT(DB.database_id) AS [Databases]
,SUM(DBS.DbTotalSizeMB) AS SizeOfAllDatabasesMB, SUM(DBS.DbTotalSizeGB) AS SizeOfAllDatabasesGB
FROM sys.dm_hadr_database_replica_states AS DRS
INNER JOIN sys.availability_replicas AS AR ON DRS.replica_id = AR.replica_id
LEFT JOIN sys.databases AS DB ON DRS.group_database_id = DB.group_database_id
LEFT JOIN @dbSizes AS DBS ON DB.database_id = DBS.DatabaseId
WHERE DRS.is_local = 1
GROUP BY DRS.is_primary_replica, AR.replica_server_name
ORDER BY AR.replica_server_name ASC, DRS.is_primary_replica DESC;
-- Show utilisation overview grouped by Availability Group
SELECT AR.replica_server_name, DRS.is_primary_replica AS IsPrimaryReplica, AG.[name] AS AvailabilityGroup, COUNT(DB.database_id) AS [Databases]
,SUM(DBS.DbTotalSizeMB) AS SizeOfAllDatabasesMB, SUM(DBS.DbTotalSizeGB) AS SizeOfAllDatabasesGB
FROM sys.dm_hadr_database_replica_states AS DRS
INNER JOIN sys.availability_groups AS AG ON DRS.group_id = AG.group_id
INNER JOIN sys.availability_replicas AS AR ON DRS.replica_id = AR.replica_id
LEFT JOIN sys.databases AS DB ON DRS.group_database_id = DB.group_database_id
LEFT JOIN @dbSizes AS DBS ON DB.database_id = DBS.DatabaseId
WHERE DRS.is_local = 1
GROUP BY AG.[name], DRS.is_primary_replica, AR.replica_server_name
ORDER BY AG.[name] ASC, AR.replica_server_name ASC;
GO




*/


/*

SELECT
AG.name AS [AvailabilityGroupName],
ISNULL(agstates.primary_replica, '') AS [PrimaryReplicaServerName],
ISNULL(arstates.role, 3) AS [LocalReplicaRole],
dbcs.database_name AS [DatabaseName],
ISNULL(dbrs.synchronization_state, 0) AS [SynchronizationState],
ISNULL(dbrs.is_suspended, 0) AS [IsSuspended],
ISNULL(dbcs.is_database_joined, 0) AS [IsJoined]
FROM master.sys.availability_groups AS AG
LEFT OUTER JOIN master.sys.dm_hadr_availability_group_states as agstates
   ON AG.group_id = agstates.group_id
INNER JOIN master.sys.availability_replicas AS AR
   ON AG.group_id = AR.group_id
INNER JOIN master.sys.dm_hadr_availability_replica_states AS arstates
   ON AR.replica_id = arstates.replica_id AND arstates.is_local = 1
INNER JOIN master.sys.dm_hadr_database_replica_cluster_states AS dbcs
   ON arstates.replica_id = dbcs.replica_id
LEFT OUTER JOIN master.sys.dm_hadr_database_replica_states AS dbrs
   ON dbcs.replica_id = dbrs.replica_id AND dbcs.group_database_id = dbrs.group_database_id
ORDER BY AG.name ASC
--, dbcs.database_name


*/