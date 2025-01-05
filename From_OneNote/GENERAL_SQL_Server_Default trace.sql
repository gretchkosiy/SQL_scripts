
-- https://www.databasejournal.com/ms-sql/a-few-cool-things-you-can-identify-using-the-default-trace/


DECLARE @current_tracefilename VARCHAR(500); 

DECLARE @0_tracefilename VARCHAR(500); 

DECLARE @indx INT; 

SELECT @current_tracefilename = path 

FROM sys.traces 

WHERE is_default = 1; 

SET @current_tracefilename = REVERSE(@current_tracefilename); 

SELECT @indx = PATINDEX('%\%', @current_tracefilename); 

SET @current_tracefilename = REVERSE(@current_tracefilename); 

SET @0_tracefilename = LEFT(@current_tracefilename, LEN(@current_tracefilename) - @indx) + '\log.trc'; 

SELECT DatabaseName, 

?????? te.name, 

?????? Filename, 

?????? CONVERT(DECIMAL(10, 3), Duration / 1000000e0) AS TimeTakenSeconds, 

?????? StartTime, 

?????? EndTime, 

?????? (IntegerData * 8.0 / 1024) AS 'ChangeInSize MB', 

?????? ApplicationName, 

?????? HostName, 

?????? LoginName 

FROM ::fn_trace_gettable(@0_tracefilename, DEFAULT) t 

???? INNER JOIN sys.trace_events AS te ON t.EventClass = te.trace_event_id 

WHERE(trace_event_id >= 92 

????? AND trace_event_id <= 95) 

ORDER BY t.StartTime; 

 

 

 

 

 

-- Displaying log location for the default trace definition 

 

DECLARE   @filename nvarchar(1000); 

 -- Get the name of the current default trace 

SELECT   @filename = cast(value as nvarchar(1000)) 

FROM   ::fn_trace_getinfo(default) 

WHERE   traceid = 1 and   property = 2; 

  

-- view current trace file 

SELECT   * 

FROM   ::fn_trace_gettable(@filename, default) AS ftg  

INNER   JOIN sys.trace_events AS te ON ftg.EventClass = te.trace_event_id   

  ORDER BY   ftg.StartTime 

 

 

-- Schema Changes 

 

DECLARE   @filename nvarchar(1000); 

 -- Get the name of the current default trace 

SELECT   @filename = cast(value as nvarchar(1000)) 

FROM   ::fn_trace_getinfo(default) 

WHERE   traceid = 1 and   property = 2; 

  

-- view current trace file 

SELECT   * 

FROM   ::fn_trace_gettable(@filename, default) AS ftg  

INNER   JOIN sys.trace_events AS te ON ftg.EventClass = te.trace_event_id   

WHERE (ftg.EventClass = 46 or ftg.EventClass = 47) 

and   DatabaseName <> 'tempdb'  

and   EventSubClass = 0 

ORDER   BY ftg.StartTime; 

 

 

-- Autogrowth Events 

 

DECLARE   @filename nvarchar(1000); 

 -- Get the name of the current default trace 

SELECT   @filename = cast(value as nvarchar(1000)) 

FROM   ::fn_trace_getinfo(default) 

WHERE   traceid = 1 and   property = 2; 

  

-- Find auto growth events in the current trace file 

SELECT 

    ftg.StartTime 

 ,te.name as EventName 

 ,DB_NAME(ftg.databaseid) AS DatabaseName   

 ,ftg.Filename 

 ,(ftg.IntegerData*8)/1024.0 AS GrowthMB  

 ,(ftg.duration/1000)as DurMS 

FROM   ::fn_trace_gettable(@filename, default) AS ftg  

INNER   JOIN sys.trace_events AS te ON ftg.EventClass = te.trace_event_id   

WHERE (ftg.EventClass = 92  -- Date File Auto-grow 

      OR ftg.EventClass   = 93) -- Log File Auto-grow 

 

 

 

-- Security Changes 

 

DECLARE   @filename nvarchar(1000); 

 -- Get the name of the current default trace 

SELECT   @filename = cast(value as nvarchar(1000)) 

FROM   ::fn_trace_getinfo(default) 

WHERE   traceid = 1 and   property = 2; 

  

-- process all trace files 

SELECT   *   

FROM   ::fn_trace_gettable(@filename, default) AS ftg  

INNER   JOIN sys.trace_events AS te ON ftg.EventClass = te.trace_event_id   

WHERE   ftg.EventClass  

      in (102,103,104,105,106,108,109,110,111) 

  ORDER BY   ftg.StartTime 