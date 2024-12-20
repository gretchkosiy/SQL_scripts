-- ## 1

-- Run from Distribution Database 
USE Distribution 
GO 
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED 
-- Get the publication name based on article 
SELECT DISTINCT  
srv.srvname publication_server  
, a.publisher_db 
, p.publication publication_name 
, a.article 
, a.destination_object 
, ss.srvname subscription_server 
, s.subscriber_db 
, da.name AS distribution_agent_job_name 
FROM MSArticles a WITH (NOLOCK) 
JOIN MSpublications p WITH (NOLOCK) ON a.publication_id = p.publication_id 
JOIN MSsubscriptions s WITH (NOLOCK) ON p.publication_id = s.publication_id 
JOIN master..sysservers ss WITH (NOLOCK) ON s.subscriber_id = ss.srvid 
JOIN master..sysservers srv WITH (NOLOCK) ON srv.srvid = p.publisher_id 
JOIN MSdistribution_agents da WITH (NOLOCK) ON da.publisher_id = p.publisher_id  
     AND da.subscriber_id = s.subscriber_id 
ORDER BY 1,2,3 

-- ## 2

-- Run from Publisher Database  
-- Get information for all databases 
DECLARE @Detail CHAR(1) 
SET @Detail = 'Y' 
CREATE TABLE #tmp_replcationInfo ( 
	PublisherDB VARCHAR(128),  
	PublisherName VARCHAR(128), 
	TableName VARCHAR(128), 
	SubscriberServerName VARCHAR(128)) 

IF DATABASEPROPERTYEX ( db_name() , 'IsPublished' ) = 1 
	insert into #tmp_replcationInfo 
	select  
		db_name() PublisherDB 
		, sp.name as PublisherName 
		, sa.name as TableName 
		, UPPER(srv.srvname) as SubscriberServerName 
	from dbo.syspublications sp  
	join dbo.sysarticles sa on sp.pubid = sa.pubid 
	join dbo.syssubscriptions s on sa.artid = s.artid 
	join master.dbo.sysservers srv on s.srvid = srv.srvid 
 
IF @Detail = 'Y' 
   SELECT * FROM #tmp_replcationInfo 
ELSE 
SELECT DISTINCT  
PublisherDB 
,PublisherName 
,SubscriberServerName  
FROM #tmp_replcationInfo 
DROP TABLE #tmp_replcationInfo 



---- Run from Publisher Database  
---- Get information for all databases 
--DECLARE @Detail CHAR(1) 
--SET @Detail = 'Y' 
--CREATE TABLE #tmp_replcationInfo ( 
--PublisherDB VARCHAR(128),  
--PublisherName VARCHAR(128), 
--TableName VARCHAR(128), 
--SubscriberServerName VARCHAR(128), 
--) 
--EXEC sp_msforeachdb  
--'use ?; 
--IF DATABASEPROPERTYEX ( db_name() , ''IsPublished'' ) = 1 
--insert into #tmp_replcationInfo 
--select  
--db_name() PublisherDB 
--, sp.name as PublisherName 
--, sa.name as TableName 
--, UPPER(srv.srvname) as SubscriberServerName 
--from dbo.syspublications sp  
--join dbo.sysarticles sa on sp.pubid = sa.pubid 
--join dbo.syssubscriptions s on sa.artid = s.artid 
--join master.dbo.sysservers srv on s.srvid = srv.srvid 
--' 
--IF @Detail = 'Y' 
--   SELECT * FROM #tmp_replcationInfo 
--ELSE 
--SELECT DISTINCT  
--PublisherDB 
--,PublisherName 
--,SubscriberServerName  
--FROM #tmp_replcationInfo 
--DROP TABLE #tmp_replcationInfo 

-- ## 3


-- Run from Subscriber Database 
SELECT distinct publisher, publisher_db, publication
FROM dbo.MSreplication_subscriptions
ORDER BY 1,2,3