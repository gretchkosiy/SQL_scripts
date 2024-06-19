DECLARE @database_name VARCHAR(MAX)		= db_name()



DECLARE @RestoreDBpath VARCHAR(max)		= 'F:\Program Files\Microsoft SQL Server\BUSINESS\Data\'
DECLARE @RestoreLOGpath VARCHAR(max)	= 'G:\Program Files\Microsoft SQL Server\BUSINESS\Log\'
DECLARE @RestoreSQL VARCHAR(max)
DECLARE @MoveDBfiles VARCHAR(max)

PRINT 'ALTER DATABASE [' + @database_name + '] SET  SINGLE_USER WITH ROLLBACK IMMEDIATE;EXEC master.dbo.sp_detach_db @dbname = N''' + @database_name  + ''''

SET @MoveDBfiles = char(13) 
SET @RestoreSQL =  char(13)  + 'CREATE DATABASE [' + @database_name + '] ON ' + char(13)
SELECT 
	 @RestoreSQL  = @RestoreSQL + '(FILENAME = N''' +  
	CASE
		WHEN groupid != 0 THEN @RestoreDBpath + reverse(left(reverse(filename), charindex('\',reverse(filename), 1) - 1)) + '''),'
		ELSE  @RestoreLOGpath + + reverse(left(reverse(filename), charindex('\',reverse(filename), 1) - 1)) +'''),'
	END + char(13),

	@MoveDBfiles = @MoveDBfiles + 'MOVE "' + 
	CASE
		WHEN groupid != 0 THEN SUBSTRING([filename], 1, LEN([filename]) - 	charindex('\',reverse([filename]), 1)+1) + reverse(left(reverse([filename]), charindex('\',reverse([filename]), 1) - 1)) + '" "' + @RestoreDBpath + reverse(SUBSTRING(reverse([filename]),1,charindex('\',reverse([filename]), 1)-1)) + char(13)
		ELSE  SUBSTRING([filename], 1, LEN([filename]) - 	charindex('\',reverse([filename]), 1)+1) + reverse(left(reverse([filename]), charindex('\',reverse([filename]), 1) - 1)) + '" "' + @RestoreLOGpath + reverse(SUBSTRING(reverse([filename]),1,charindex('\',reverse([filename]), 1)-1)) + char(13)
	END 
	 
FROM sys.sysfiles f
order by groupid DESC
SET @RestoreSQL = SUBSTRING(@RestoreSQL, 1, LEN(@RestoreSQL)-2)+ char(13) + ' FOR ATTACH'

PRINT @MoveDBfiles
PRINT @RestoreSQL
