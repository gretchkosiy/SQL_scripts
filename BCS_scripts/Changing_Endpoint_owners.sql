USE [master]; 


SELECT 
	e.name as mirror_endpoint_name, 
	s.name AS login_name, 
	p.permission_name, 
	p.state_desc as permission_state, 
	e.state_desc endpoint_state
FROM sys.server_permissions p
	INNER JOIN sys.endpoints e ON p.major_id = e.endpoint_id
	INNER JOIN sys.server_principals s ON p.grantee_principal_id = s.principal_id
--WHERE p.class_desc = 'ENDPOINT' AND e.type_desc = 'DATABASE_MIRRORING'


SELECT 
	SUSER_NAME(principal_id) AS endpoint_owner, 
	name as endpoint_name 
FROM sys.database_mirroring_endpoints 


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
	--ALTER AUTHORIZATION ON ENDPOINT::Hadr_endpoint TO emrsa; 
	--GRANT CONNECT ON ENDPOINT::Hadr_endpoint TO [HAD\ahoore02admin]; 
COMMIT TRANSACTION 
 
SELECT 
	SUSER_NAME(principal_id) AS endpoint_owner, 
	name as endpoint_name 
FROM sys.database_mirroring_endpoints 