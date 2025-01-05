
-- From <https://portal.bd.bluecrystal.com.au/cms/display/SAHEALTH/Tips+n+Tricks#TipsnTricks-ASE>  


--Kills sessions in sleeping state that have not run a batch in the last 2 minutes and have open transactions. 


DECLARE @session_id int = 0 

DECLARE @kill_cmd VARCHAR(50) 

WHILE 1=1 

BEGIN 

SELECT TOP 1 @session_id = spid FROM sys.sysprocesses WHERE spid > 50 AND status = 'sleeping' AND open_tran > 0 AND last_batch < DATEADD(SECOND, -120, GETDATE()) 

IF (@session_id > 0) 

BEGIN 

SET @kill_cmd = 'KILL ' + CAST(@session_id AS VARCHAR(20)) 

EXEC (@kill_cmd) 

PRINT 'Killed ' + CAST(@session_id AS VARCHAR(20)) + ' ' + CAST(CURRENT_TIMESTAMP AS VARCHAR(255)) 

END 

WAITFOR DELAY '00:00:05' 

END 