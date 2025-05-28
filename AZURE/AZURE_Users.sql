-------


SELECT DISTINCT
'Users Roles' as [Description]
,@@Servername as ServerName
,DB_NAME() AS DatabaseName
,d.name AS DatabaseUser
,D.type_desc as DatabaseUserType
,d.authentication_type_desc as DatabaseUserAuthenticationType
,ISNULL(dr.name, '') AS DatabaseRoleUserBelongTo

--,ISNULL(dp.permission_name, '') as AdditionalPermission
--,ISNULL(dp.state_desc,'') AS PermissionState
--,ISNULL(o.type_desc, '')  AS ObjectType
--,ISNULL(o.name, '') AS ObjectName

FROM sys.database_principals d
    LEFT JOIN sys.database_role_members r
        ON d.principal_id = r.member_principal_id 
    LEFT JOIN sys.database_principals dr
        ON r.role_principal_id = dr.principal_id 
    left JOIN   sys.database_permissions dp
        ON d.principal_id = dp.grantee_principal_id
    LEFT JOIN sys.objects o
        ON dp.major_id = o.object_id 
where d.name not in (
		'public'
		,'guest'
		,'dbo'
		,'sys'
		,'db_backupoperator'
		,'db_denydatareader'
		,'db_ddladmin'
		,'db_denydatawriter'
		,'db_owner'
		,'db_datareader'
		,'db_accessadmin'
		,'db_securityadmin'
		,'db_datawriter'
		,'INFORMATION_SCHEMA')
AND ISNULL(dr.name, '') <> ''
Order by 3,6 --,10


--------------------------------------

SELECT DISTINCT
'Additional permissions' as [Description]
,@@Servername as ServerName
,DB_NAME() AS DatabaseName
,d.name AS DatabaseUser
,D.type_desc as DatabaseUserType
--,d.authentication_type_desc as DatabaseUserAuthenticationType
--,ISNULL(dr.name, '') AS DatabaseRoleUserBelongTo

,ISNULL(dp.permission_name, '') as AdditionalPermission
,ISNULL(dp.state_desc,'') AS PermissionState
,ISNULL(o.type_desc, '')  AS ObjectType
,ISNULL('[' + OBJECT_SCHEMA_NAME(o.object_id)  +'].[' + o.name + ']', '') AS ObjectName


FROM sys.database_principals d
    LEFT JOIN sys.database_role_members r
        ON d.principal_id = r.member_principal_id 
    LEFT JOIN sys.database_principals dr
        ON r.role_principal_id = dr.principal_id 
    left JOIN   sys.database_permissions dp
        ON d.principal_id = dp.grantee_principal_id
    LEFT JOIN sys.objects o
        ON dp.major_id = o.object_id 
where d.name not in (
		'public'
		,'guest'
		,'dbo'
		,'sys'
		,'db_backupoperator'
		,'db_denydatareader'
		,'db_ddladmin'
		,'db_denydatawriter'
		,'db_owner'
		,'db_datareader'
		,'db_accessadmin'
		,'db_securityadmin'
		,'db_datawriter'
		,'INFORMATION_SCHEMA')
--AND ISNULL(dr.name, '') <> '' 
AND ISNULL(dp.permission_name, '') <> 'CONNECT' AND ISNULL(dp.permission_name, '')  <> ''
Order by 4


-------------------------------------------------------







-- 01 - List users in Azure SQL database

---- https://dataedo.com/kb/query/azure-sql/list-users-in-database

select @@SERVERNAME AS ServerName, DB_NAME() as DatabaseName,
	name as username,
       --create_date,
       --modify_date,
       type_desc as type,
       authentication_type_desc as authentication_type
	   --,*
from sys.database_principals
where type not in ('A', 'G', 'R', 'X')
      and sid is not null
	 -- and (
		--name like '%alex%'
		--OR 
		--name like '%Geoff%'
		--OR 
		--name like '%Toshio%' 
		--OR 
		--name like '%Aaron%') 
order by username;


-- 02 Roles participants


SELECT  @@SERVERNAME AS ServerName, DB_NAME() as DatabaseName, 
	DP1.name AS DatabaseRoleName,   
   isnull (DP2.name, 'No members') AS DatabaseUserName   
 FROM sys.database_role_members AS DRM  
 RIGHT OUTER JOIN sys.database_principals AS DP1  
   ON DRM.role_principal_id = DP1.principal_id  
 LEFT OUTER JOIN sys.database_principals AS DP2  
   ON DRM.member_principal_id = DP2.principal_id  
WHERE DP1.type = 'R'

ORDER BY DP1.name;

--- roles permissions

--https://dba.stackexchange.com/questions/36618/list-all-permissions-for-a-given-role

 WITH    perms_cte as
(
        select USER_NAME(p.grantee_principal_id) AS principal_name,
                dp.principal_id,
                dp.type_desc AS principal_type_desc,
                p.class_desc,
                OBJECT_NAME(p.major_id) AS object_name,
                p.permission_name,
                p.state_desc AS permission_state_desc
        from    sys.database_permissions p
        inner   JOIN sys.database_principals dp
        on     p.grantee_principal_id = dp.principal_id
)
--role members
SELECT rm.member_principal_name, rm.principal_type_desc, p.class_desc, 
    p.object_name, p.permission_name, p.permission_state_desc,rm.role_name
FROM    perms_cte p
right outer JOIN (
    select role_principal_id, dp.type_desc as principal_type_desc, 
   member_principal_id,user_name(member_principal_id) as member_principal_name,
   user_name(role_principal_id) as role_name--,*
    from    sys.database_role_members rm
    INNER   JOIN sys.database_principals dp
    ON     rm.member_principal_id = dp.principal_id
) rm
ON     rm.role_principal_id = p.principal_id
order by 1

-----

SELECT DISTINCT rp.name, 
                ObjectType = rp.type_desc, 
                PermissionType = pm.class_desc, 
                pm.permission_name, 
                pm.state_desc, 
                ObjectType = CASE 
                               WHEN obj.type_desc IS NULL 
                                     OR obj.type_desc = 'SYSTEM_TABLE' THEN 
                               pm.class_desc 
                               ELSE obj.type_desc 
                             END, 
                s.Name as SchemaName,
                [ObjectName] = Isnull(ss.name, Object_name(pm.major_id)) 
FROM   sys.database_principals rp 
       LEFT JOIN sys.database_permissions pm 
               ON pm.grantee_principal_id = rp.principal_id 
       LEFT JOIN sys.schemas ss 
              ON pm.major_id = ss.schema_id 
       LEFT JOIN sys.objects obj 
              ON pm.[major_id] = obj.[object_id] 
       LEFT JOIN sys.schemas s
              ON s.schema_id = obj.schema_id
WHERE  rp.type_desc = 'DATABASE_ROLE' 
       AND pm.class_desc <> 'DATABASE' 
	   AND rp.name NOT IN ('public')
ORDER  BY rp.name, 
          rp.type_desc, 
          pm.class_desc 



--https://blobeater.blog/2018/10/22/azure-sql-db-failed-to-update-database-because-the-database-is-read-only/