select sp.name as login,
       sp.type_desc as login_type,
       --sl.password_hash,
       --sp.create_date,
       --sp.modify_date,
       case when sp.is_disabled = 1 then 'Disabled'
            else 'Enabled' end as status
	 ,case when ss.sysadmin = 1 then 'sysadmin'
            else '' end as [sysadmin]
	 ,case when ss.serveradmin = 1 then 'serveradmin'
            else '' end as [serveradmin]			
	 ,case when ss.securityadmin = 1 then 'securityadmin'
            else '' end as [securityadmin]	
	 ,case when ss.denylogin = 1 then 'denylogin'
            else '' end as [denylogin]	

from sys.server_principals sp
left join sys.sql_logins sl
          on sp.principal_id = sl.principal_id
left join sys.syslogins ss on ss.loginname = sp.name 
where sp.type not in ('G', 'R')
order by sp.name;