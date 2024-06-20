/* 
-- checking jobs owners - 2008

select s.name,l.name
 from  msdb..sysjobs s 
 left join master.sys.syslogins l on s.owner_sid = l.sid
 where l.name not in ('sa') OR l.name IS NULL
*/ 
 
 
UPDATE msdb..sysjobs
SET owner_sid = 
	(select sid 
	from master.sys.syslogins
	where loginname = 'sa')
from  msdb..sysjobs s 
 left join master.sys.syslogins l on s.owner_sid = l.sid
 where l.name not in ('sa', 'MYBUDGET\svc_sqlserver', 'MYBUDGET\ReportingServices') OR  l.name IS NULL


 /* 
-- checking MPs and DTSs owners - 2008
select S.name, l.name
from [msdb].[dbo].[sysssispackages] S
left join master.sys.syslogins l on s.ownersid = l.sid
where l.name is null

*/

-- updating MPs and DTSs owners
UPDATE	[msdb].[dbo].[sysssispackages] 
SET	[ownersid] = 
	(select sid 
	from master.sys.syslogins
	where loginname = 'sa')
from [msdb].[dbo].[sysssispackages] S
left join master.sys.syslogins l on s.ownersid = l.sid
where l.name is null