
-- Discover and govern Azure SQL Database in Microsoft Purview

-- https://learn.microsoft.com/en-us/purview/register-scan-azure-sql-database?tabs=sql-authentication


CREATE LOGIN pureview WITH PASSWORD = 'Purevi^;"ew1234500000!@#$';
GO

-- in database
CREATE USER pureview FOR LOGIN pureview;

select * from sys.sysusers