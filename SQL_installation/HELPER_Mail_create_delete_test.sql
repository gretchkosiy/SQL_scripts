--------------------------------------------------------------------------
-- Create of mail profile:
--------------------------------------------------------------------------


-- https://sqlwithmanoj.com/tag/sysmail_profile/

-- https://docs.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sysmail-add-account-sp-transact-sql

sp_configure 'show advanced options', 1;  
GO  
RECONFIGURE;  
GO  
sp_configure 'Database Mail XPs', 1;  
GO  
RECONFIGURE  
GO  



if not exists (SELECT * FROM msdb.dbo.sysmail_profile)
Begin

	--// Create a Database Mail account
	EXECUTE msdb.dbo.sysmail_add_account_sp
		@account_name = 'SQL Notifications',
		@description = 'Mail account for administrative e-mail.',
		@email_address = 'gennadi.gretchkosiy@bluecrystal.com.au',
		@replyto_address = 'gennadi.gretchkosiy@bluecrystal.com.au',
		@display_name = 'SQL Server',
		@mailserver_name = 'smtp.office365.com',
		@port = 587,
		@enable_ssl = 1,
		@username = 'gennadi.gretchkosiy@bluecrystal.com.au',
		@password = 'XXX'


 
	-- Create a Database Mail profile
	EXECUTE msdb.dbo.sysmail_add_profile_sp
		@profile_name = 'SQL Notifications',
		@description = 'Profile used for administrative mail.'
 
	-- Add the account to the profile
	EXECUTE msdb.dbo.sysmail_add_profileaccount_sp
		@profile_name = 'SQL Notifications',
		@account_name = 'SQL Notifications',
		@sequence_number =1
 
	-- Grant access to the profile to the DBMailUsers role
	EXECUTE msdb.dbo.sysmail_add_principalprofile_sp
		@profile_name = 'SQL Notifications',
		@principal_name = 'public',
		@is_default = 1

END

USE [msdb]
GO

IF NOT EXISTS (select * from msdb.[dbo].[sysoperators] where name = 'SQL Admin')
/****** Object:  Operator [SQL Admin]    Script Date: 7/12/2016 2:02:39 PM ******/
EXEC msdb.dbo.sp_add_operator @name=N'SQL Admin', 
		@enabled=1, 
		@weekday_pager_start_time=90000, 
		@weekday_pager_end_time=180000, 
		@saturday_pager_start_time=90000, 
		@saturday_pager_end_time=180000, 
		@sunday_pager_start_time=90000, 
		@sunday_pager_end_time=180000, 
		@pager_days=0, 
		@email_address=N'gennadi.gretchkosiy@bluecrystal.com.au', 
		@category_name=N'[Uncategorized]'
GO



--------------------------------------------------------------------------
-- Test of mail profile:
--------------------------------------------------------------------------

declare @profile_name  varchar(100)
select top 1 @profile_name = name from msdb.dbo.sysmail_profile

declare @subj  varchar(100)
SET @subj = 'Test E-mail from ' + @@SERVERNAME + ' SQL Server'

--EXEC msdb.dbo.sp_send_dbmail  
--    @profile_name = @profile_name,  
--    @recipients = 'gennadi.gretchkosiy@bluecrystal.com.au',
--    @query = 'SELECT ''Test email from '' + @@SERVERNAME '' SQL Server''' ,  
--    @subject = @subj

-- https://gallery.technet.microsoft.com/scriptcenter/Script-to-Scipt-out-14a19eda
Declare @TheResults varchar(max)
SELECT @TheResults = 'Test email from ' + @@SERVERNAME + ' SQL Server'  + CHAR(13) + CHAR(10) 

SELECT @TheResults = @TheResults  + '
Profile Name                       =  ''' + p.name + '''
Profile Description             =  ''' + ISNULL(p.description,'') + '''
Account Name			= ' + CASE WHEN a.name                IS NULL THEN ' NULL ' ELSE + '''' + a.name                  + '''' END + ' 
Email Address			= ' + CASE WHEN a.email_address       IS NULL THEN ' NULL ' ELSE + '''' + a.email_address         + '''' END + ' 
Display Name                      =  ' + CASE WHEN a.display_name        IS NULL THEN ' NULL ' ELSE + '''' + a.display_name          + '''' END + ' 
Replyto Address                 =  ' + CASE WHEN a.replyto_address     IS NULL THEN ' NULL ' ELSE + '''' + a.replyto_address       + '''' END + ' 
Description                         =  ' + CASE WHEN a.description         IS NULL THEN ' NULL ' ELSE + '''' + a.description           + '''' END + ' 
Mailserver Name         = ' + CASE WHEN s.servername          IS NULL THEN ' NULL ' ELSE + '''' + s.servername            + '''' END + ' 
Mailserver Type         = ' + CASE WHEN s.servertype          IS NULL THEN ' NULL ' ELSE + '''' + s.servertype            + '''' END + ' 
Port                    = ' + CASE WHEN s.port                IS NULL THEN ' NULL ' ELSE + '''' + CONVERT(VARCHAR,s.port) + '''' END + ' 
Username                = ' + CASE WHEN c.credential_identity IS NULL THEN ' NULL ' ELSE + '''' + c.credential_identity   + '''' END + ' 
Password                = ' + CASE WHEN c.credential_identity IS NULL THEN ' NULL ' ELSE + '''NotTheRealPassword''' END + '  
Use_default_credentials = ' + CASE WHEN s.use_default_credentials = 1 THEN ' 1 ' ELSE ' 0 ' END + ' 
Enable_ssl              = ' + CASE WHEN s.enable_ssl = 1              THEN ' 1 ' ELSE ' 0 ' END  
FROM msdb.dbo.sysmail_profile p 
INNER JOIN msdb.dbo.sysmail_profileaccount pa ON  p.profile_id = pa.profile_id 
INNER JOIN msdb.dbo.sysmail_account a         ON pa.account_id = a.account_id  
LEFT OUTER JOIN msdb.dbo.sysmail_server s     ON a.account_id = s.account_id 
LEFT OUTER JOIN msdb.sys.credentials c    ON s.credential_id = c.credential_id



EXEC msdb.dbo.sp_send_dbmail  
    @profile_name = @profile_name,  
    @recipients = 'gennadi.gretchkosiy@bluecrystal.com.au',
    @body = @TheResults ,  
    @subject = @subj



--------------------------------------------------------------------------
-- Delete of mail profile:
--------------------------------------------------------------------------

	
--    SELECT * FROM msdb.dbo.sysmail_profile
USE msdb


declare @ProfileName varchar(max)
declare @AccountName varchar(max)

SET @ProfileName = 'SQL Notifications'
SET @AccountName = 'SQL Notifications'

IF EXISTS(
SELECT * FROM msdb.dbo.sysmail_profileaccount pa
      JOIN msdb.dbo.sysmail_profile p ON pa.profile_id = p.profile_id
      JOIN msdb.dbo.sysmail_account a ON pa.account_id = a.account_id
WHERE
      p.name = @ProfileName AND
      a.name = @AccountName)
BEGIN
      PRINT 'Deleting Profile Account'
      EXECUTE sysmail_delete_profileaccount_sp
      @profile_name = @ProfileName,
      @account_name = @AccountName
END
 
IF EXISTS(
SELECT * FROM msdb.dbo.sysmail_profile p
WHERE p.name = @ProfileName)
BEGIN
      PRINT 'Deleting Profile.'
      EXECUTE sysmail_delete_profile_sp
      @profile_name = @ProfileName
END
 
IF EXISTS(
SELECT * FROM msdb.dbo.sysmail_account a
WHERE a.name = @AccountName)
BEGIN
      PRINT 'Deleting Account.'
      EXECUTE sysmail_delete_account_sp
      @account_name = @AccountName
END
 
-- delete operator
IF EXISTS(
	SELECT * 
	FROM msdb.dbo.sysoperators 
	where name = 'SQL Admin') 
BEGIN
	 PRINT 'Deleting Operator.'
	EXEC msdb.dbo.sp_delete_operator @name=N'SQL Admin'
END
GO