--USE master
--GO

SELECT database_name, start_time, end_time, event_category,
	event_type, event_subtype, event_subtype_desc, severity,
	event_count, description
FROM master.sys.event_log
WHERE 
	database_name = 'RETAIL'
	AND description NOT LIKE '%Connected%'
	--AND event_category <> 'connectivity'
	--event_type = 'connection_failed'
--    AND event_subtype = 4
--    AND start_time >= '2022-03-25 10:00:00'
--    AND end_time <= '2022-03-25 11:00:00';  
ORDER BY start_time ASC