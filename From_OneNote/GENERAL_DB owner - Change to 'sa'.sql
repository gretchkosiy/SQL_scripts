SELECT suser_sname( owner_sid ), name FROM sys.databases 
where suser_sname( owner_sid ) !='sa' 
ALTER AUTHORIZATION ON DATABASE::[<database_name>] TO [sa] 