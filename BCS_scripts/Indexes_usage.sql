SELECT  
				OBJECT_NAME(sis.OBJECT_ID) TableName
				,si.name AS IndexName
				--,COUNT(*) cnt
				, MAX(sis.last_user_seek)	last_user_seek
				, MAX(sis.last_user_scan)	last_user_scan
				, MAX(sis.last_user_lookup)	last_user_lookup
				, MAX(sis.last_user_update)	last_user_update
		FROM sys.dm_db_index_usage_stats sis
			INNER JOIN sys.indexes si ON sis.OBJECT_ID = si.OBJECT_ID AND sis.Index_ID = si.Index_ID
			INNER JOIN sys.index_columns sic ON sis.OBJECT_ID = sic.OBJECT_ID AND sic.Index_ID = si.Index_ID
			INNER JOIN sys.columns sc ON sis.OBJECT_ID = sc.OBJECT_ID AND sic.Column_ID = sc.Column_ID
			WHERE  DB_NAME(sis.Database_ID) NOT IN ('master', 'msdb', 'model', 'tempdb')	-- don't care about system
			AND OBJECT_NAME(sis.OBJECT_ID) like '%EC_CONTRACT_ACCOUNT'
			GROUP BY sis.OBJECT_ID, si.name