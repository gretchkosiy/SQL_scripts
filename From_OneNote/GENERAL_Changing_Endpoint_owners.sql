USE [master]; 

SELECT 
	SUSER_NAME(principal_id) AS endpoint_owner, 
	name as endpoint_name 
FROM sys.database_mirroring_endpoints 
 

USE [master]; 

SELECT 
	ep.name, 
	sp.STATE,  
	CONVERT(nvarchar(38),  
	SUSER_NAME(sp.grantor_principal_id)) AS [GRANT BY], 
	sp.TYPE AS PERMISSION, 
	CONvERT(nvarchar(46), 
	SUSER_NAME(sp.grantee_principal_id)) AS [GRANT TO] 
FROM sys.server_permissions sp, sys.endpoints ep 
WHERE sp.major_id = ep.endpoint_id AND [name] = 'Hadr_endpoint' 

BEGIN TRANSACTION 

	USE [master]; 

	ALTER AUTHORIZATION ON ENDPOINT::Hadr_endpoint TO emrsa; 
	GRANT CONNECT ON ENDPOINT::Hadr_endpoint TO [HAD\ahoore02admin]; 

COMMIT TRANSACTION 

SELECT SUSER_NAME(principal_id) AS endpoint_owner, 
name as endpoint_name 
FROM sys.database_mirroring_endpoints 