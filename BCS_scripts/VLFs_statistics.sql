declare @dirBACKUP nvarchar(4000)
declare @DateBACKUP nvarchar(4000)
exec master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE',N'Software\Microsoft\MSSQLServer\MSSQLServer',N'BackupDirectory', @dirBACKUP output, 'no_output'
SELECT @DateBACKUP = CONVERT(VARCHAR(10), GETDATE(), 112)

SELECT 
	name AS NotProcessedDatabasesMoreThan1log
	, 'BACKUP LOG [' + name + '] to disk=''' + @dirBACKUP + '\' +  REPLACE(name,' ','') + '_' + @DateBACKUP + '.trn''' AS BackupTranLog
	--, 'Shrink'
FROM master.sys.databases
where database_id in ((select database_id from master.sys.master_files where data_space_id = 0 group by database_id hAVing COUNT(*) > 1))


       /* declare variables required */
       DECLARE @DatabaseId INT;
       DECLARE @TSQL varchar(MAX);
       DECLARE cur_DBs CURSOR FOR
              SELECT database_id FROM sys.databases WHERE state <> 6 AND name not in ('tempdb'); -- exclude offline databases
       OPEN cur_DBs;
       FETCH NEXT FROM cur_DBs INTO @DatabaseId
       
       --These table variables will be used to store the data
       DECLARE @tblAllDBs Table (DBName sysname
              , FileId INT
              , FileSize BIGINT
              , StartOffset BIGINT
              , FSeqNo INT
              , Status TinyInt
              , Parity INT
              , CreateLSN NUMERIC(25,0)
       )
       IF  '11' = substring(convert(char(12),serverproperty('productversion')), 1, 2)
       OR '12' = substring(convert(char(12),serverproperty('productversion')), 1, 2)
       OR '13' = substring(convert(char(12),serverproperty('productversion')), 1, 2)
       OR '14' = substring(convert(char(12),serverproperty('productversion')), 1, 2)
       OR '15' = substring(convert(char(12),serverproperty('productversion')), 1, 2)
       BEGIN
              DECLARE @tblVLFs2012 Table (RecoveryUnitId BIGINT
                     , FileId INT
                     , FileSize BIGINT
                     , StartOffset BIGINT
                     , FSeqNo INT
                     , Status TinyInt
                     , Parity INT
                     , CreateLSN NUMERIC(25,0)
              );
       END
       ELSE
       BEGIN
              DECLARE @tblVLFs Table (
                     FileId INT
                     , FileSize BIGINT
                     , StartOffset BIGINT
                     , FSeqNo INT
                     , Status TinyInt
                     , Parity INT
                     , CreateLSN NUMERIC(25,0)
              );
       END
       
       --loop through each database and get the info
       WHILE @@FETCH_STATUS = 0
       BEGIN
             
              PRINT 'DB: ' + CONVERT(varchar(200), DB_NAME(@DatabaseId));
              SET @TSQL = 'dbcc loginfo('+CONVERT(varchar(12), @DatabaseId)+');';
       
              IF  '11' = substring(convert(char(12),serverproperty('productversion')), 1, 2)
                  OR '12' = substring(convert(char(12),serverproperty('productversion')), 1, 2)
                     OR '13' = substring(convert(char(12),serverproperty('productversion')), 1, 2)
						 OR '14' = substring(convert(char(12),serverproperty('productversion')), 1, 2)
							 OR '15' = substring(convert(char(12),serverproperty('productversion')), 1, 2)
              BEGIN
                     DELETE FROM @tblVLFs2012;
                     INSERT INTO @tblVLFs2012
                     EXEC(@TSQL);
                     INSERT INTO @tblAllDBs
                     SELECT DB_NAME(@DatabaseId)
                            , FileId
                            , FileSize
                            , StartOffset
                            , FSeqNo
                            , Status
                            , Parity
                            , CreateLSN
                     FROM @tblVLFs2012;
              END
              ELSE
              BEGIN
                     DELETE FROM @tblVLFs;
                     INSERT INTO @tblVLFs
                     EXEC(@TSQL);
                     INSERT INTO @tblAllDBs
                     SELECT DB_NAME(@DatabaseId)
                            , FileId
                            , FileSize
                            , StartOffset
                            , FSeqNo
                            , Status
                            , Parity
                            , CreateLSN
                     FROM @tblVLFs;
              END
       
              FETCH NEXT FROM cur_DBs INTO @DatabaseId
       END
       CLOSE cur_DBs;
       DEALLOCATE cur_DBs;
       
      
       --Return the data based on what we have found
                   --DEClare @r int 

       SELECT 
                   --RANK() OVER (ORDER BY @@servername,  a.DBName, msmf.name) ,
                                @@servername 
										AS ServerName
								, SERVERPROPERTY('ComputerNamePhysicalNetBIOS') 
										AS ActiveNode
								, a.DBName 
										AS DatabaseName
                                --, msmf.name LogName
                                , msdbs.recovery_model_desc [Model]
                                , CASE WHEN msmf.growth = 0 THEN 'N/A' WHEN msmf.growth <> 0 AND msmf.is_percent_growth = 1 AND msmf.max_size <> -1 THEN CAST(msmf.growth AS varchar) + ' percent max of ' + CAST(msmf.max_size/128 AS varchar) + ' mb' WHEN msmf.growth <> 0 AND msmf.is_percent_growth = 1 AND msmf.max_size = -1 THEN CAST(msmf.growth AS varchar) + ' percent unrestricted' WHEN msmf.growth <> 0 AND msmf.is_percent_growth = 0 AND msmf.max_size <> -1 THEN CAST(msmf.growth/128 AS varchar) + ' mb max of ' + CAST(msmf.max_size/128 AS varchar) + ' mb' WHEN msmf.growth <> 0 AND msmf.is_percent_growth = 0 AND msmf.max_size = -1 THEN CAST(msmf.growth/128 AS varchar) + ' mb unrestricted' END 
										AS [AutoGrow]
								, CASE WHEN msmf.is_percent_growth = 1 THEN 'USE [master];ALTER DATABASE [' + a.DBName + '] MODIFY FILE ( NAME = N''' + msmf.name + ''',FILEGROWTH = 64MB);' ELSE '' END 
										AS AlterGrow					
                                , COUNT(a.FileId) AS [TotalVLFs]
                                , MAX(b.[ActiveVLFs]) AS [ActiveVLFs]
                                --, (SUM(a.FileSize) / COUNT(a.FileId) / 1024) AS [AvgFileSizeKb]
                                , SUM(a.FileSize) / 1024 / 1024 SumLogSizeMB
                                --,'USE [' + a.DBName + '];DBCC SHRINKFILE (N''' + msmf.name + ''' , 0);' AS Shrink
                                --,'USE [master]; ALTER DATABASE [' + a.DBName + '] MODIFY FILE (NAME =''' + msmf.name + ''', SIZE = ' + CAST(SUM(a.FileSize) / 1024 / 1024 + 8 AS VARCHAR(100)) + 'MB)' AS [Expand]


                                , CASE 
									WHEN msdbs.recovery_model_desc = 'FULL' THEN 
								'SET NOCOUNT ON;USE [' + a.DBName + '];'
								+ 'Declare @vlfs' +  REPLACE(REPLACE(a.DBName,' ',''),'-','') + ' INT;'
								
								+ 'IF  CAST(substring(convert(char(12),serverproperty(''productversion'')), 1, 2) AS INT) >=11 EXEC ('''
								+ 'Create Table ##stage' +  REPLACE(REPLACE(a.DBName,' ',''),'-','') + '(RecoveryUnintID INT,FileID int,FileSize bigint,StartOffset bigint,FSeqNo bigint,[Status] bigint,Parity bigint,CreateLSN numeric(38));'
								+ '''); ELSE EXEC (''' 
								+ 'Create Table ##stage' +  REPLACE(REPLACE(a.DBName,' ',''),'-','') + '(FileID int,FileSize bigint,StartOffset bigint,FSeqNo bigint,[Status] bigint,Parity bigint,CreateLSN numeric(38));'
								+ ''');'

								+ 'SET @vlfs' +  REPLACE(REPLACE(a.DBName,' ',''),'-','') + ' = 1000;WHILE @vlfs' +  REPLACE(REPLACE(a.DBName,' ',''),'-','') + ' > 50 BEGIN '
                                + 'declare @logBACKUP' +  REPLACE(REPLACE(a.DBName,' ',''),'-','') + ' nvarchar(4000),@logBACKUPorig' +  REPLACE(REPLACE(a.DBName,' ',''),'-','') + ' nvarchar(4000),@isExists' +  REPLACE(REPLACE(a.DBName,' ',''),'-','') + ' INT, @cnt' +  REPLACE(REPLACE(a.DBName,' ',''),'-','') + ' INT;SET @logBACKUPorig' +  REPLACE(REPLACE(a.DBName,' ',''),'-','') + '=''' + @dirBACKUP+'\' + a.DBName + '_'+@DateBACKUP+'.trn'';SET @isExists' +  REPLACE(REPLACE(a.DBName,' ',''),'-','') + '=1;SET @cnt' +  REPLACE(REPLACE(a.DBName,' ',''),'-','') + '=1;WHILE @isExists' +  REPLACE(REPLACE(a.DBName,' ',''),'-','') + ' = 1 BEGIN;SET @logBACKUP' +  REPLACE(REPLACE(a.DBName,' ',''),'-','') + ' = SUBSTRING(@logBACKUPorig' +  REPLACE(REPLACE(a.DBName,' ',''),'-','') + ',1,LEN(@logBACKUPorig' +  REPLACE(REPLACE(a.DBName,' ',''),'-','') + ')-4) + CAST(@cnt' +  REPLACE(REPLACE(a.DBName,' ',''),'-','') + ' AS VARCHAR(3)) + SUBSTRING(@logBACKUPorig' +  REPLACE(REPLACE(a.DBName,' ',''),'-','') + ',LEN(@logBACKUPorig' +  REPLACE(REPLACE(a.DBName,' ',''),'-','') + ')-3,4);exec master.dbo.xp_fileexist @logBACKUP' +  REPLACE(REPLACE(a.DBName,' ',''),'-','') + ', @isExists' +  REPLACE(REPLACE(a.DBName,' ',''),'-','') + ' OUTPUT;SET @cnt' +  REPLACE(REPLACE(a.DBName,' ',''),'-','') + ' = @cnt' +  REPLACE(REPLACE(a.DBName,' ',''),'-','') + ' + 1;END;SET @logBACKUP' +  REPLACE(REPLACE(a.DBName,' ',''),'-','') + ' = ''backup log [' + a.DBName  + '] to disk = '''''' + @logBACKUP' +  REPLACE(REPLACE(a.DBName,' ',''),'-','') + ' + '''''''';EXEC(@logBACKUP' +  REPLACE(REPLACE(a.DBName,' ',''),'-','') + ');'
									ELSE ''
								 END	
								+ 'USE [' + a.DBName + '];'
								+ 'DBCC SHRINKFILE (N''' + msmf.name + ''' , 0) WITH NO_INFOMSGS;' 
								+
								CASE 
									WHEN msdbs.recovery_model_desc = 'FULL' THEN 
                                 'truncate table ##stage' +  REPLACE(REPLACE(a.DBName,' ',''),'-','') + ';Insert Into ##stage' +  REPLACE(REPLACE(a.DBName,' ',''),'-','') + ' Exec sp_executesql N''DBCC LogInfo([' + a.DBName + ']) WITH NO_INFOMSGS'';Select @vlfs' +  REPLACE(REPLACE(a.DBName,' ',''),'-','') + ' = Count(*) From ##stage' +  REPLACE(REPLACE(a.DBName,' ',''),'-','') + '; IF @vlfs' +  REPLACE(REPLACE(a.DBName,' ',''),'-','') + ' >= 10 BEGIN PRINT ''Still VLFs: '' + CAST(@vlfs' +  REPLACE(REPLACE(a.DBName,' ',''),'-','') + ' AS VARCHAR(10));PRINT ''wait 10 sec for next tran log backup for datbase [' + a.DBName + ']'';WAITFOR DELAY ''00:00:10'';END;END;Drop Table ##stage' +  REPLACE(REPLACE(a.DBName,' ',''),'-','') + ';'
									ELSE ''
								END	
								+ 'PRINT ''Expanding LOG'';USE [master]; ALTER DATABASE [' + a.DBName + '] MODIFY FILE (NAME =''' + msmf.name + ''', SIZE = ' + CAST(SUM(a.FileSize) / 1024 / 1024 + 8 AS VARCHAR(100)) + 'MB);'
                                                AS FullLoopScript

--, 'backup log [' + a.DBName + '] to disk = ''' + @dirBACKUP + '\' + a.DBName + '_' + @DateBACKUP + '.trn''' AS [BackupLogOnes] 
--, 'declare @logBACKUP nvarchar(4000),@logBACKUPorig nvarchar(4000),@isExists INT, @cnt INT;SET @logBACKUPorig=''' + @dirBACKUP+'\' + a.DBName + '_'+@DateBACKUP+'.trn'';SET @isExists=1;SET @cnt=1;WHILE @isExists = 1 BEGIN;SET @logBACKUP = SUBSTRING(@logBACKUPorig,1,LEN(@logBACKUPorig)-4) + CAST(@cnt AS VARCHAR(3)) + SUBSTRING(@logBACKUPorig,LEN(@logBACKUPorig)-3,4);exec master.dbo.xp_fileexist @logBACKUP, @isExists OUTPUT;SET @cnt = @cnt + 1;END;SET @logBACKUP = ''backup log [' + a.DBName  + '] to disk = '''''' + @logBACKUP + '''''''';EXEC(@logBACKUP)'
--AS [BackupLogLoops]                                    

       FROM @tblAllDBs a
       INNER JOIN (
              SELECT DBName
                     , COUNT(FileId) [ActiveVLFs]
              FROM @tblAllDBs
              WHERE Status = 2
              GROUP BY DBName
              ) b
              ON b.DBName = a.DBName
       INNER JOIN  master.sys.master_files msmf on msmf.file_id = a.FileId and a.DBName = DB_name(msmf.database_id) 
                   INNER JOIN master.sys.databases msdbs on msmf.database_id = msdbs.database_id
                   where a.DBname not in ('master', 'msdb', 'model', 'tempdb')
                   -- single logs only !!!!!!
                   AND msmf.database_id in (select database_id from master.sys.master_files where data_space_id = 0 group by database_id hAVing COUNT(*) = 1)
       --and a.DBname = 'PQSecure'
       GROUP BY a.DBName , msmf.name, msdbs.recovery_model_desc,
                CASE 
                                 WHEN msmf.growth = 0 THEN 'N/A'
                                WHEN msmf.growth <> 0 AND msmf.is_percent_growth = 1 AND msmf.max_size <> -1 THEN CAST(msmf.growth AS varchar) + ' percent max of ' + CAST(msmf.max_size/128 AS varchar) + ' mb'
                                WHEN msmf.growth <> 0 AND msmf.is_percent_growth = 1 AND msmf.max_size = -1 THEN CAST(msmf.growth AS varchar) + ' percent unrestricted'
                                WHEN msmf.growth <> 0 AND msmf.is_percent_growth = 0 AND msmf.max_size <> -1 THEN CAST(msmf.growth/128 AS varchar) + ' mb max of ' + CAST(msmf.max_size/128 AS varchar) + ' mb'
                                WHEN msmf.growth <> 0 AND msmf.is_percent_growth = 0 AND msmf.max_size = -1 THEN CAST(msmf.growth/128 AS varchar) + ' mb unrestricted'
                END
				,msmf.is_percent_growth 

       --HAVING COUNT(a.FileId) >=50
       ORDER BY a.DBName, TotalVLFs DESC;
       
       
       SET NOCOUNT OFF;



/*
--Original
-- http://adventuresinsql.com/2009/12/a-busyaccidental-dbas-guide-to-managing-vlfs/

DECLARE @query varchar(1000),
 @dbname varchar(1000),
 @count int

SET NOCOUNT ON

DECLARE csr CURSOR FAST_FORWARD READ_ONLY
FOR
SELECT name
FROM sys.databases

CREATE TABLE ##loginfo
(
 dbname varchar(100),
 num_of_rows int)

OPEN csr

FETCH NEXT FROM csr INTO @dbname

WHILE (@@fetch_status <> -1)
BEGIN

CREATE TABLE #log_info
(
 RecoveryUnitId tinyint,
 fileid tinyint,
 file_size bigint,
 start_offset bigint,
 FSeqNo int,
[status] tinyint,
 parity tinyint,
 create_lsn numeric(25,0)
)

SET @query = 'DBCC loginfo (' + '''' + @dbname + ''') '

INSERT INTO #log_info
EXEC (@query)

SET @count = @@rowcount

DROP TABLE #log_info

INSERT ##loginfo
VALUES(@dbname, @count)

FETCH NEXT FROM csr INTO @dbname

END

CLOSE csr
DEALLOCATE csr

SELECT dbname,
 num_of_rows
FROM ##loginfo
WHERE num_of_rows >= 50 --My rule of thumb is 50 VLFs. Your mileage may vary.
ORDER BY dbname

DROP TABLE ##loginfo



*/