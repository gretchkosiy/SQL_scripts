SELECT 
	a.name,
	product,
	provider,
	data_source,
	remote_name
	--,*
FROM sys.Servers a
LEFT OUTER JOIN sys.linked_logins b ON b.server_id = a.server_id
LEFT OUTER JOIN sys.server_principals c ON c.principal_id = b.local_principal_id
WHERE a.name <> @@servername