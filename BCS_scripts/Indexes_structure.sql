
select 
 IOS.INDEX_ID, 
 IOS.OBJECT_ID, 
SUM(ISNULL(IOS.LEAF_ALLOCATION_COUNT,0) + ISNULL(IOS.NONLEAF_ALLOCATION_COUNT,0)) summary
INTO #OPSTAT
from SYS.DM_DB_INDEX_OPERATIONAL_STATS(DB_ID(),NULL,NULL,NULL) IOS
group by IOS.INDEX_ID, IOS.OBJECT_ID


SELECT 
	@@SERVERNAME as ServerName,
	DB_NAME() AS DBname,
	'[' + sch.name + '].[' + o.name + ']' TableName, 
	ISNULL(i.name, '!! HEAP !!') IndexName,
	ii.is_disabled,
	case 
		when i.indid =1 then 'CL: ' +  

case when i.indid =1 then MIN (CASE ik.keyno WHEN 1 
		THEN 
			CASE syst.name
				WHEN 'nvarchar' THEN syst.name + '(' + CAST(c.length AS VARCHAR(10)) + ')'
				WHEN 'varchar' THEN syst.name + '(' + CAST(c.length AS VARCHAR(10)) + ')'
				WHEN 'char' THEN syst.name + '(' + CAST(c.length AS VARCHAR(10)) + ')'
				WHEN 'nchar' THEN syst.name + '(' + CAST(c.length AS VARCHAR(10)) + ')'
				ELSE syst.name
			END
		END)  else '' end + ' ' +
	case when i.indid =1 then ISNULL(MIN (CASE ik.keyno WHEN 1 THEN ISNULL(dc.definition,CASE  COLUMNPROPERTY(O.id, c.name  , 'IsIdentity') WHEN 1 THEN 'IDENTITY' END) END),'')  ELSE '' end 




		else 'NC' 
	end CL,
	

	i.used*8/1024 [Size MB],
	p.[Rows],
	i.OrigFillFactor,
	--i.indid, o.id,
	--ISNULL(IOS.LEAF_ALLOCATION_COUNT,0) + ISNULL(IOS.NONLEAF_ALLOCATION_COUNT,0) 
	ISNULL(IOS.summary,0) as Counts_Splits,


	col1 = ISNULL(MIN (CASE ik.keyno WHEN 1 THEN c.name END),''),
	col2 = ISNULL(MIN (CASE ik.keyno WHEN 2 THEN c.name END),''),
	col3 = ISNULL(MIN (CASE ik.keyno WHEN 3 THEN c.name END),''),
	col4 = ISNULL(MIN (CASE ik.keyno WHEN 4 THEN c.name END),''),
	col5 = ISNULL(MIN (CASE ik.keyno WHEN 5 THEN c.name END),''),
	col6 = ISNULL(MIN (CASE ik.keyno WHEN 6 THEN c.name END),''),
	col7 = ISNULL(MIN (CASE ik.keyno WHEN 7 THEN c.name END),''),
	col8 = ISNULL(MIN (CASE ik.keyno WHEN 8 THEN c.name END),''),
	col9 = ISNULL(MIN (CASE ik.keyno WHEN 9 THEN c.name END),''),
	col10 = ISNULL(MIN (CASE ik.keyno WHEN 10 THEN c.name END),''),
	col11 = ISNULL(MIN (CASE ik.keyno WHEN 11 THEN c.name END),''),
	col12 = ISNULL(MIN (CASE ik.keyno WHEN 12 THEN c.name END),''),
	col13 = ISNULL(MIN (CASE ik.keyno WHEN 13 THEN c.name END),''),
	col14 = ISNULL(MIN (CASE ik.keyno WHEN 14 THEN c.name END),''),
	col15 = ISNULL(MIN (CASE ik.keyno WHEN 15 THEN c.name END),''),
	col16 = ISNULL(MIN (CASE ik.keyno WHEN 16 THEN c.name END),'')

   , 'ALTER INDEX ' + COALESCE(i.name,'') + ' ON ' + sch.name  + '.' + o.name + ' DISABLE;' AS [Disable]
   , 'ALTER INDEX ' + COALESCE(i.name,'') + ' ON ' + sch.name  + '.' + o.name + ' REBUILD;' AS [Rebuild]

FROM sys.sysobjects o
	LEFT JOIN sys.sysindexes i ON i.id = o.id
	LEFT JOIN sys.indexes ii ON ii.index_id = i.indid AND  o.id = ii.object_id
	LEFT JOIN sys.sysindexkeys ik ON ik.id = i.id AND ik.indid = i.indid
	LEFT JOIN sys.syscolumns c ON c.id = ik.id AND c.colid = ik.colid
	LEFT JOIN sys.tables st on st.object_id = o.id		
	LEFT join sys.schemas sch on st.schema_id = sch.schema_id	
	left join sys.types syst on syst.system_type_id = c.xtype	
	left join sys.default_constraints dc on  o.id = dc.parent_object_id AND c.colid = dc.parent_column_id
	INNER JOIN sys.partitions p ON i.id = p.OBJECT_ID AND i.indid = p.index_id
	--LEFT JOIN SYS.DM_DB_INDEX_OPERATIONAL_STATS(NULL,NULL,NULL,NULL) IOS on IOS.INDEX_ID=I.indid AND IOS.OBJECT_ID = o.id and IOS.database_id = db_ID()
	LEFT JOIN #OPSTAT IOS on IOS.INDEX_ID=I.indid AND IOS.OBJECT_ID = o.id 


WHERE ((i.indid BETWEEN 1 AND 254) OR i.name IS NULL)
	AND indexproperty(o.id, i.name, 'IsStatistics') = 0
	AND indexproperty(o.id, i.name, 'IsHypothetical') = 0
	and o.name not like 'sys%'
	and o.name not like 'filestream_%'
	and o.name not like 'queue_messages_%'
	and o.name not like 'filetable_updates_%'
	and o.name not like 'sqlagent_%'
	and o.xtype = 'U'
	and o.name LIKE '%meter_read_5%'
GROUP BY o.name, i.name, i.indid, i.used, sch.name, p.[Rows], i.OrigFillFactor, IOS.summary, ii.is_disabled
	--,IOS.LEAF_ALLOCATION_COUNT, IOS.NONLEAF_ALLOCATION_COUNT
	--, i.indid, o.id
ORDER BY o.name, i.name, i.indid, i.used 


DROP TABLE #OPSTAT