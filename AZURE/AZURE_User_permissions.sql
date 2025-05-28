-- https://schottsql.com/2023/07/12/azure-sql-database-get-users-and-role-members-for-all-databases/

SELECT 
	@@ServerName as ServerName,
	DB_NAME() as DatabaseName,
    pr.name AS PrincipalName,
    pr.type_desc AS PrincipalType,
    r.name AS RoleName,
    dp.state_desc AS RoleState,
	NULL as PermissionName,
	NULL as PermissionState,
	NULL as PermissionClass,
	NULL as ObjectName
FROM
    sys.database_role_members drm
    RIGHT JOIN sys.database_principals pr ON drm.member_principal_id = pr.principal_id
    LEFT JOIN sys.database_principals r ON drm.role_principal_id = r.principal_id
    LEFT JOIN sys.database_permissions dp ON pr.principal_id = dp.grantee_principal_id
WHERE
	pr.type_desc IN ('SQL_USER', 'WINDOWS_USER', 'WINDOWS_GROUP', 'EXTERNAL_USER', 'EXTERNAL_GROUP', 'APPLICATION_ROLE') -- Filter for users and groups

UNION

/* Get all db principals and their explicitly granted permissions for Azure SQL */
SELECT 
	@@ServerName as ServerName,
	DB_NAME() as DatabaseName,
    pr.name AS PrincipalName,
    pr.type_desc AS PrincipalType,
	NULL as RoleName,
	NULL as RoleState,
    dp.permission_name AS PermissionName,
    dp.state_desc AS PermissionState,
    dp.class_desc AS PermissionClass,
    OBJECT_NAME(dp.major_id) AS ObjectName
FROM
    sys.database_permissions dp
    JOIN sys.database_principals pr ON dp.grantee_principal_id = pr.principal_id
WHERE
    pr.type_desc IN ('SQL_USER', 'WINDOWS_USER', 'WINDOWS_GROUP', 'EXTERNAL_USER', 'EXTERNAL_GROUP', 'APPLICATION_ROLE') -- Filter for users and groups
	and dp.permission_name NOT IN ('CONNECT')

-- my permissions
-- SELECT * FROM fn_my_permissions(NULL, 'DATABASE');  