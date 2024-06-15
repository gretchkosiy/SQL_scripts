


USE [_CESA_SSIS]

DECLARE @database_name VARCHAR(MAX)		= db_name()

DECLARE @BackupPath VARCHAR(max)		= '\\EN-ADLTDB-20\CommonBackup\'
DECLARE @RestoreDBpath VARCHAR(max)		= 'F:\Program Files\Microsoft SQL Server\BUSINESS\Data\'
DECLARE @RestoreLOGpath VARCHAR(max)	= 'G:\Program Files\Microsoft SQL Server\BUSINESS\Log\'
DECLARE @DeleteBackup VARCHAR(max)

DECLARE @BackupSQL VARCHAR(max)
DECLARE @RestoreSQL VARCHAR(max)

SET @BackupSQL =  'BACKUP DATABASE [' + @database_name  + '] TO DISK=''' + @BackupPath + @database_name  + '.bak'' WITH COMPRESSION, COPY_ONLY'
SET @DeleteBackup = 'EXEC xp_cmdshell ''del ' + @BackupPath + db_name() + '.bak'''


SET @RestoreSQL = '-- START RESTORE DATABAS PART
USE [master];

DECLARE @kill varchar(8000) = '''';  
SELECT @kill = @kill + ''kill '' + CONVERT(varchar(5), session_id) + '';''  
FROM sys.dm_exec_sessions
WHERE database_id  = db_id(''[' + @database_name + ']'')

--Print @kill
EXEC(@kill);

GO
ALTER DATABASE [' + @database_name + '] SET RECOVERY SIMPLE WITH NO_WAIT
GO
ALTER DATABASE [' + @database_name + '] SET OFFLINE WITH ROLLBACK IMMEDIATE
GO

'

SET @RestoreSQL =  @RestoreSQL + 'RESTORE DATABASE [' + @database_name  + '] 
FROM  DISK = ''' + @BackupPath + @database_name  + '.bak'' WITH '

PRINT @BackupSQL

PRINT ''
PRINT ''

DECLARE @partSQL VARCHAR(max)

DECLARE files_cursor CURSOR FOR   
SELECT 
	--name
	CASE
		WHEN groupid != 0 THEN 'MOVE ''' + name + ''' TO ''' + @RestoreDBpath + + reverse(left(reverse(filename), charindex('\',reverse(filename), 1) - 1)) + ''','
		ELSE 'MOVE ''' + name + ''' TO ''' + @RestoreLOGpath + + reverse(left(reverse(filename), charindex('\',reverse(filename), 1) - 1)) +''','
	END
FROM sys.sysfiles f

OPEN files_cursor  

FETCH NEXT FROM files_cursor INTO @partSQL  


WHILE @@FETCH_STATUS = 0  
BEGIN  
	SET @RestoreSQL = @RestoreSQL+ char(13) + @partSQL
 	FETCH NEXT FROM files_cursor INTO @partSQL  
	--SET @RestoreSQL = @RestoreSQL +  char(13) + @partSQL 
END   
CLOSE files_cursor;  
DEALLOCATE files_cursor;  

SET @RestoreSQL = @RestoreSQL+ char(13) + 'NOUNLOAD,  STATS = 5
-- END RESTORE DATABAS PART'

PRINT @RestoreSQL


PRINT ''
PRINT ''


PRINT @DeleteBackup



