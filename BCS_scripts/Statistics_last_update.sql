IF EXISTS(select 1 from tempdb.dbo.sysobjects where name = '##last_updatestatistic')	DROP TABLE ##last_updatestatistic


CREATE TABLE ##last_updatestatistic (
	rowid int IDENTITY(1, 1),
	db_name sysname,
	last_date Varchar(255)
)

EXEC sp_MSforeachdb 'USE [?] 
INSERT INTO ##last_updatestatistic 
SELECT DB_NAME(), MIN(STATS_DATE(al.object_id, stats_id))
FROM sys.stats st
INNER JOIN sys.all_objects al
ON (st.object_id = al.object_id) AND al.type_desc= ''USER_TABLE''
'

select 
	db_name,
	last_date

from ##last_updatestatistic
where last_date < DATEADD(dd,-30, GETDATE())

IF EXISTS(select 1 from tempdb.dbo.sysobjects where name = '##last_updatestatistic')	DROP TABLE ##last_updatestatistic