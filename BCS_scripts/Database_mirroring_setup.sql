-- Post emergency failback procedure 
-- For :CONNECT commands to work in SQL Server Management Studio, you MUST Enable SQLCMD Mode via "Query" > "SQLCMD Mode" Menu
-- NOTE: NOT ALL STEPS MAY BE REQUIRED - RUN EACH STEP AS NEEDED, DO NOT EXECUTE ENTIRE SCRIPT IN TOTAL

-- This will prevent entire script from running, but only if SQLCMD Mode not yet set!
RAISERROR('Do not run entire Script!!',16,1);
RETURN;

:CONNECT BCSADLNB26\SQL14
ALTER DATABASE [MirrorTEST] SET PARTNER OFF

:CONNECT BCSADLNB26\SQL141
ALTER DATABASE [MirrorTEST] SET PARTNER OFF  

:CONNECT BCSADLNB26\SQL141
DROP DATABASE [MirrorTEST]


-- 1. Check for existing end points on NCD
:CONNECT BCSADLNB26\SQL14
SELECT [name], role_desc FROM sys.database_mirroring_endpoints;
GO
:CONNECT BCSADLNB26\SQL141
SELECT [name], role_desc FROM sys.database_mirroring_endpoints;
GO

-- 2. If Endpoints Exist: Identify ports used by endpoints
--    (only TSQL Default TCP will show if no Database Mirroring Endpoint created yet
:CONNECT BCSADLNB26\SQL14
SELECT [name], port FROM sys.tcp_endpoints;
GO

:CONNECT BCSADLNB26\SQL141
SELECT [name], port
--, * 
FROM sys.tcp_endpoints;
GO

-- 2a. If Endpoints Don't Exist: Create the endpoint (must be done on each Instance - Primary and Secondary)
-- Not Needed unless NDC Servers Also Rebuilt
:CONNECT BCSADLNB26\SQL14
IF  EXISTS (SELECT * FROM sys.endpoints e WHERE e.name = N'DBMirroringEndPoint') 
 DROP ENDPOINT [DBMirroringEndPoint];
--PRINT 'DBMirroringEndPoint Already Exists'
GO
:CONNECT BCSADLNB26\SQL14
CREATE ENDPOINT DBMirroringEndPoint
    AUTHORIZATION sa
    STATE = STARTED
    AS TCP ( LISTENER_PORT = 7023 )
    FOR DATABASE_MIRRORING (
       AUTHENTICATION = WINDOWS NEGOTIATE,
       ENCRYPTION = DISABLED,
       ROLE=ALL);
GO


:CONNECT BCSADLNB26\SQL141
IF  EXISTS (SELECT * FROM sys.endpoints e WHERE e.name = N'DBMirroringEndPoint') 
DROP ENDPOINT [DBMirroringEndPoint];
--PRINT 'DBMirroringEndPoint Already Exists'
GO
:CONNECT BCSADLNB26\SQL141
CREATE ENDPOINT DBMirroringEndPoint
    AUTHORIZATION sa
    STATE = STARTED
    AS TCP ( LISTENER_PORT = 7022 )
    FOR DATABASE_MIRRORING (
       AUTHENTICATION = WINDOWS NEGOTIATE,
       ENCRYPTION = DISABLED,
       ROLE=ALL);
GO


-- 2c. If servicesql Login Not on Mirror: Create login for Partner (on Mirror)
:CONNECT BCSADLNB26\SQL141
--CREATE LOGIN [BLUECRYSTAL\gennadi.gretchkosiy] FROM WINDOWS ;
CREATE LOGIN [BLUECRYSTAL\BCSADLNB26$] FROM WINDOWS ;
GO
-- 2c. If servicesql Login Not on Mirror: Create login for Partner (on Mirror)
:CONNECT BCSADLNB26\SQL14
CREATE LOGIN [BLUECRYSTAL\gennadi.gretchkosiy] FROM WINDOWS ;
GO
-- Grant connect permissions on endpoint to login account of Principal.
:CONNECT BCSADLNB26\SQL141
--GRANT CONNECT ON ENDPOINT::DBMirroringEndPoint TO [BLUECRYSTAL\gennadi.gretchkosiy];
GRANT CONNECT ON ENDPOINT::DBMirroringEndPoint TO [BLUECRYSTAL\BCSADLNB26$] ;
--GRANT CONNECT ON ENDPOINT::DBMirroringEndPoint TO ALL;
GO

:CONNECT BCSADLNB26\SQL14
GRANT CONNECT ON ENDPOINT::DBMirroringEndPoint TO [BLUECRYSTAL\gennadi.gretchkosiy];
--GRANT CONNECT ON ENDPOINT::DBMirroringEndPoint TO ALL;
GO


-- 2d. Check End Point status
:CONNECT BCSADLNB26\SQL14
SELECT e.name, e.protocol_desc, e.type_desc, e.role_desc, e.state_desc, 
       t.port, e.is_encryption_enabled, e.encryption_algorithm_desc, 
       e.connection_auth_desc 
	   ,e.state, e. state_desc 
FROM   sys.database_mirroring_endpoints e JOIN sys.tcp_endpoints t
ON     e.endpoint_id = t.endpoint_id;
GO

:CONNECT BCSADLNB26\SQL141
SELECT e.name, e.protocol_desc, e.type_desc, e.role_desc, e.state_desc, 
       t.port, e.is_encryption_enabled, e.encryption_algorithm_desc, 
       e.connection_auth_desc 
	   	   ,e.state, e. state_desc 
FROM   sys.database_mirroring_endpoints e JOIN sys.tcp_endpoints t
ON     e.endpoint_id = t.endpoint_id;
GO

-- 2e. Check End Point security
:CONNECT BCSADLNB26\SQL14
SELECT EP.name,
       SP.STATE, 
       CONVERT(nvarchar(38), suser_name(SP.grantor_principal_id)) GRANTOR, 
       SP.TYPE PERMISSION,
       CONVERT(nvarchar(46),suser_name(SP.grantee_principal_id)) GRANTEE 
FROM   sys.server_permissions SP INNER JOIN sys.endpoints EP ON SP.major_id = EP.endpoint_id
ORDER BY
       Permission,grantor, grantee;
GO

:CONNECT BCSADLNB26\SQL141
SELECT EP.name,
       SP.STATE, 
       CONVERT(nvarchar(38), suser_name(SP.grantor_principal_id)) GRANTOR, 
       SP.TYPE PERMISSION,
       CONVERT(nvarchar(46),suser_name(SP.grantee_principal_id)) GRANTEE 
FROM   sys.server_permissions SP INNER JOIN sys.endpoints EP ON SP.major_id = EP.endpoint_id
ORDER BY
       Permission,grantor, grantee;
GO

-- 3. Check Mirrored DB status
:CONNECT BCSADLNB26\SQL14
SELECT d.name, d.database_id, m.mirroring_role_desc, 
       m.mirroring_state_desc, m.mirroring_safety_level_desc, 
       m.mirroring_partner_name, m.mirroring_partner_instance,
       m.mirroring_witness_name, m.mirroring_witness_state_desc
FROM   sys.database_mirroring m JOIN sys.databases d
ON     m.database_id = d.database_id
WHERE  mirroring_state_desc IS NOT NULL;
GO

:CONNECT BCSADLNB26\SQL141
SELECT d.name, d.database_id, m.mirroring_role_desc, 
       m.mirroring_state_desc, m.mirroring_safety_level_desc, 
       m.mirroring_partner_name, m.mirroring_partner_instance,
       m.mirroring_witness_name, m.mirroring_witness_state_desc
FROM   sys.database_mirroring m JOIN sys.databases d
ON     m.database_id = d.database_id
WHERE  mirroring_state_desc IS NOT NULL;
GO

-- 4. If Database Mirroring Not Setup, perform below Steps:

-- On NDC Set DB to Full Recovery mode
:CONNECT BCSADLNB26\SQL14
USE MASTER;
go
ALTER DATABASE [MirrorTEST] SET RECOVERY FULL 
GO




-- DISABLE ANY TRANSACTION LOG BACKUP JOBS ON BCC SERVER


--xp_cmdshell 'del C:\0\MirrorTEST_mirroring.bak|echo Y'
--xp_cmdshell 'del C:\0\MirrorTEST_mirroring.trn|echo Y'

-- Full DB Backups on NDC
:CONNECT BCSADLNB26\SQL14
BACKUP DATABASE MirrorTEST TO DISK = 'C:\0\MirrorTEST_mirroring.bak' WITH INIT, STATS = 10
go


-- Copy the Backups created above to v:\mssql.1\backup\ on the Mirror; or
:CONNECT BCSADLNB26\SQL141
-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! THIS MUST BE CHANGED !!!!!!!!!!!!!!!!!!!!!!!!!!!!!
--xp_cmdshell 'COPY \\HTRDMULTI01\f$\Sql_backup\corpmedepo\Restore\*_mirroring.bak C:\Gennadi\Health_check_tested_20042015\Mirroring\'
GO

-- Restore DB on BCC with NO RECOVERY
-- Mirror
:CONNECT BCSADLNB26\SQL141
restore database MirrorTEST from disk='C:\0\MirrorTEST_mirroring.bak'
with file = 1, norecovery, 
--replace,
MOVE N'MirrorTEST' TO N'C:\Program Files\Microsoft SQL Server\MSSQL12.SQL141\MSSQL\DATA\MirrorTEST.mdf',  
MOVE N'MirrorTEST_log' TO N'C:\Program Files\Microsoft SQL Server\MSSQL12.SQL141\MSSQL\DATA\MirrorTEST_log.ldf',  
stats=10
go



-- Back the trans log on BCC - MUST do even after a Backup
:CONNECT BCSADLNB26\SQL14
BACKUP LOG MirrorTEST TO DISK = 'C:\0\MirrorTEST_mirroring.trn' WITH INIT;
GO

-- Copy the Transaction Log Backups created above to v:\mssql.1\restore\ on the NDC; or
:CONNECT BCSADLNB26\SQL141
--xp_cmdshell 'COPY \\HTRDMULTI01\f$\Sql_backup\corpmedepo\Restore\*_mirroring.trn C:\Gennadi\Health_check_tested_20042015\Mirroring'
GO


-- Restore the trans log backup to the Mirror WITH NORECOVERY
-- Note any other Transaction Log backups that have occurred on Principle before or after above step will need to be
-- restored in Sequence
:CONNECT BCSADLNB26\SQL141
RESTORE LOG MirrorTEST FROM DISK = 'C:\0\MirrorTEST_mirroring.trn' WITH NORECOVERY;
GO


-- Set partner on NDC
:CONNECT BCSADLNB26\SQL14
ALTER DATABASE MirrorTEST SET PARTNER = 'TCP://BCSADLNB26.BlueCrystal.com.au:7022';
GO


-- Set partner on BCC
:CONNECT BCSADLNB26\SQL141
ALTER DATABASE MirrorTEST SET PARTNER = 'TCP://BCSADLNB26:7023';
--ALTER DATABASE MirrorTEST SET PARTNER = 'TCP://BCSADLNB26.BlueCrystal.local:7023';
GO





-- Check the status of the mirroring
:CONNECT BCSADLNB26\SQL141
SELECT d.name, d.database_id, m.mirroring_role_desc, 
       m.mirroring_state_desc, m.mirroring_safety_level_desc, 
       m.mirroring_partner_name, m.mirroring_partner_instance,
       m.mirroring_witness_name, m.mirroring_witness_state_desc
FROM   sys.database_mirroring m JOIN sys.databases d
ON     m.database_id = d.database_id
WHERE  mirroring_state_desc IS NOT NULL;
GO

:CONNECT BCSADLNB26\SQL14
SELECT d.name, d.database_id, m.mirroring_role_desc, 
       m.mirroring_state_desc, m.mirroring_safety_level_desc, 
       m.mirroring_partner_name, m.mirroring_partner_instance,
       m.mirroring_witness_name, m.mirroring_witness_state_desc
FROM   sys.database_mirroring m JOIN sys.databases d
ON     m.database_id = d.database_id
WHERE  mirroring_state_desc IS NOT NULL;
GO



-- On NDC Convert Mirroring from Synchronous to Asynchronous
:CONNECT BCSADLNB26\SQL14
ALTER DATABASE MirrorTEST SET PARTNER SAFETY OFF;
GO

-- Ensure Database Mirroring mirroring_role_desc = PRINCIPLE,
--                           mirroring_state_desc = SYNCHRONIZED
--                           mirroring_safety_level_desc = OFF
-- CORPMEDEPO (NDC)
:CONNECT BCSADLNB26\SQL14
SELECT d.name, d.database_id, m.mirroring_role_desc, 
       m.mirroring_state_desc, m.mirroring_safety_level_desc, 
       m.mirroring_partner_name, m.mirroring_partner_instance,
       m.mirroring_witness_name, m.mirroring_witness_state_desc
FROM   sys.database_mirroring m JOIN sys.databases d
ON     m.database_id = d.database_id
WHERE  mirroring_state_desc IS NOT NULL;
GO

-- Comms Change Content Switch change Services
-- Wintel restart App Servers

-- ** HEALTH CHECKS ** --



