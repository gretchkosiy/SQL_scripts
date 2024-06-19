/*
INTER-SITE FAILOVER - EMERGENCY 
-- IMPORTANT! If SQL is OK at NDC, use SCHEDULED Failover Procedures & Script Instead!!
*/
-- NOTE: For :CONNECT commands to work in SQL Server Management Studio, you MUST Enable SQLCMD Mode via "Query" > "SQLCMD Mode" Menu

-- Wintel shutdown App Servers

-- ** For Emergency Failover, NDC probably not available, but if it is:
-- Disable Application Jobs at NDC
-- CORPMEDEPO (NDC)
-- Run Disable_Application_Jobs_CORPMEDEPO.sql

-- ** For Emergency Failover, NDC probably not available,
--    so Mirroring State should be Disconnected:
-- Confirm BCC Database Mirroring mirroring_role_desc = MIRROR, mirroring_state_desc = DISCONNECTED
-- If Mirroring State is Syncronized, investigate possibility of SCHEDULED Failover!!
-- CORPMEDEPO (BCC)
:CONNECT HTRDMULTI04\CORPMEDEPO
SELECT d.name, d.database_id, m.mirroring_role_desc, 
       m.mirroring_state_desc, m.mirroring_safety_level_desc, 
       m.mirroring_partner_name, m.mirroring_partner_instance,
       m.mirroring_witness_name, m.mirroring_witness_state_desc
FROM   sys.database_mirroring m JOIN sys.databases d
ON     m.database_id = d.database_id
WHERE  mirroring_state_desc IS NOT NULL;
GO

-- ** For Emergency Failover, NDC should not be available, so Instances at NDC should be stopped:
-- Site Role Reversal (need to first take current Principal Offline by stopping services
-- as Mirroring needs to be in Disconnected State or command will not proceed)
-- CORPMEDEPO (BCC)
:CONNECT HTRDMULTI01\CORPMEDEPO
ALTER DATABASE ePO4_HTVAEPO0002 SET PARTNER FORCE_SERVICE_ALLOW_DATA_LOSS;
GO
ALTER DATABASE ePO4_HTVAEPO0003 SET PARTNER FORCE_SERVICE_ALLOW_DATA_LOSS;
GO


-- ** Suspend the mirroring on the BCC so databases become accessible
-- CORPMEDEPO (BCC)
:CONNECT HTRDMULTI01\CORPMEDEPO
ALTER DATABASE ePO4_HTVAEPO0002 SET PARTNER SUSPEND;
GO
ALTER DATABASE ePO4_HTVAEPO0003 SET PARTNER SUSPEND;
GO


/*
Now databases on BCC have become accessible for user activity and it is possible to resume mirroring 
from BCC to NDC once NDC is back up online
*/


-- Confirm BCC Database Mirroring mirroring_role_desc = PRINCIPAL,
--                                mirroring_state_desc = SUSPENDED
:CONNECT HTRDMULTI04\CORPMEDEPO
SELECT d.name, d.database_id, m.mirroring_role_desc, 
       m.mirroring_state_desc, m.mirroring_safety_level_desc, 
       m.mirroring_partner_name, m.mirroring_partner_instance,
       m.mirroring_witness_name, m.mirroring_witness_state_desc
FROM   sys.database_mirroring m JOIN sys.databases d
ON     m.database_id = d.database_id
WHERE  mirroring_state_desc IS NOT NULL;
GO

-- ** HEALTH CHECKS ** --

-- Once Health Checks confirm OK, Enable Application Jobs at BCC
-- CORPMEDEPO (BCC)

-- If NDC Servers come back up before Mirroring is Broken, Disable existing Application Jobs at NDC
-- CORPMEDEPO (NDC)


