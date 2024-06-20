<?xml version="1.0" encoding="utf-8" ?>
<configuration>
<startup useLegacyV2RuntimeActivationPolicy="true"> 
<supportedRuntime version="v4.0"/>     
<supportedRuntime version="v2.0.50727"/>
</startup>
</configuration>

-- https://support.microsoft.com/en-us/help/3186435/fix-sql-server-2016-database-mail-does-not-work-on-a-computer-that-does-not-have-the-.net-framework-3.5-installed
-- Create the DatabaseMail.exe.config and drop it next to the DatabaseMail.exe under the Binn folder.
-- Run a repair setup action of SQL Server 2016 SP1
