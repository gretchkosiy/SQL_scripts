SELECT database_name, type, backup_finish_date INTO #T1 FROM msdb.dbo.backupset WITH (NOLOCK)

CREATE NONCLUSTERED INDEX [<Name of Missing Index, sysname,>]
ON [dbo].[#T1] ([type])
INCLUDE ([database_name],[backup_finish_date])

SELECT 
	t1.name, 
	t1.recovery_model_desc
	,MAX(bus1.backup_finish_date) AS LastBackUpTime_FULL
	,MAX(bus2.backup_finish_date) AS LastBackUpTime_DIFF
	,MAX(bus.backup_finish_date)  AS LastBackUpTime_LOG
	,GETDATE() AS [Run]
FROM sys.databases t1 WITH (NOLOCK)
	LEFT OUTER JOIN #T1 bus WITH (NOLOCK) ON bus.database_name = T1.name AND bus.type= 'L' 
	LEFT OUTER JOIN #T1 bus1 WITH (NOLOCK) ON bus1.database_name = T1.name AND bus1.type= 'D' 
	LEFT OUTER JOIN #T1 bus2 WITH (NOLOCK) ON bus2.database_name = T1.name AND bus2.type= 'I'
WHERE T1.name not in ('master','msdb','tempdb','model')
GROUP BY t1.name,  t1.recovery_model_desc

--select count(*) from #T1

DROP TABLE #T1
