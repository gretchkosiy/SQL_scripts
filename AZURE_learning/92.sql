
-- in master only 
select * from sys.resource_stats

select * from sys.dm_elastic_pool_resource_stats

--select CLOUD_DATABASEPROPERTYEX()

select DATABASEPROPERTYEX('ledgerdb','MaxSizeInBytes')


select * from sys.database_files


DBCC SHRINKFILE(2) 
DBCC SHRINKDATABASE(ledgerdb)