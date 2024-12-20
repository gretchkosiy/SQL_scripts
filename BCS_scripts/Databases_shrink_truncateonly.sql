EXEC sp_MSforeachdb 'USE [?];

	DECLARE @partSQL VARCHAR(max)
	DECLARE files_cursor CURSOR FOR 
		SELECT ''DBCC SHRINKFILE ('''''' + a.Name + '''''' , 0, TRUNCATEONLY)'' 
		FROM dbo.sysfiles a (NOLOCK) LEFT JOIN sysfilegroups b (NOLOCK) ON a.groupid = b.groupid;

	OPEN files_cursor  
	FETCH NEXT FROM files_cursor INTO @partSQL  
	WHILE @@FETCH_STATUS = 0  
	BEGIN  
	    PRINT  ''USE [?]''
		PRINT @partSQL
		--EXEC(@partSQL)
 		FETCH NEXT FROM files_cursor INTO @partSQL  
	END   
	CLOSE files_cursor;  
	DEALLOCATE files_cursor; 
'





EXEC sp_MSforeachdb 'USE [master];
IF ''?'' not in (''tempdb'' ,''master'',''model'', ''msdb'')
BEGIN 
	DECLARE @partSQL VARCHAR(max)
	SET @partSQL =''ALTER DATABASE [?] SET RECOVERY SIMPLE WITH NO_WAIT''
	PRINT @partSQL
	--EXEC @partSQL
END'