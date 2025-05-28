

-- in master only 
select database_name, start_time, storage_in_megabytes 
from sys.resource_stats
order by  database_name, start_time  desc