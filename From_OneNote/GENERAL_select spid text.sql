


SELECT 
	spid, 
	t.* 
FROM sysprocesses AS r 
	CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) AS t 
WHERE spid = 271  

--From <https://portal.bd.bluecrystal.com.au/cms/display/SAHEALTH/Tips+n+Tricks#TipsnTricks-ASE>  