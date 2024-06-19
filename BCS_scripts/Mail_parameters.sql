select 
	servername
	,servertype
	,port
	,username
	,credential_id
	,enable_ssl
	--,* 

from msdb.[dbo].[sysmail_server]

SELECT 
	NAME
	,display_name
	,email_address
	,replyto_address
--,* 

FROM msdb.dbo.sysmail_account