select 
	'One_call' as number,
	count(*) as PlanCount,
	Sum(size_in_bYtes)/1024/1024 size_in_Mb
From sys.dm_exec_cached_plans
where usecounts = 1 
UNION 
select 
	'Two_calls' as number,
	count(*) as PlanCount,
	Sum(size_in_bYtes)/1024/1024 size_in_Mb
From sys.dm_exec_cached_plans
where usecounts = 2
UNION 
select 
	'More_than_two' as number,
	count(*) as PlanCount,
	Sum(size_in_bYtes)/1024/1024 size_in_Mb
From sys.dm_exec_cached_plans
where usecounts >= 3
