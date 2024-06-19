/*
INTER-SITE FAILBACK - SCHEDULED 
*/
-- NOTE: For :CONNECT commands to work in SQL Server Management Studio, you MUST Enable SQLCMD Mode via "Query" > "SQLCMD Mode" Menu

-- Disable Application Jobs at BCC
-- CORPMEDEPO (BCC)

-- Disable "Create DB Snapshots" Jobs for both Instances at NDC
-- CORPMEDEPO (NDC)

-- Confirm BCC Database Mirroring mirroring_role_desc = PRINCIPLE, mirroring_state_desc = SYNCHRONIZED
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

-- Confirm NDC Database Mirroring mirroring_role_desc = MIRROR, mirroring_state_desc = SYNCHRONIZED
-- CORPMEDEPO (NDC)
:CONNECT HTRDMULTI01\CORPMEDEPO
SELECT d.name, d.database_id, m.mirroring_role_desc, 
       m.mirroring_state_desc, m.mirroring_safety_level_desc, 
       m.mirroring_partner_name, m.mirroring_partner_instance,
       m.mirroring_witness_name, m.mirroring_witness_state_desc
FROM   sys.database_mirroring m JOIN sys.databases d
ON     m.database_id = d.database_id
WHERE  mirroring_state_desc IS NOT NULL;
GO

-- On BCC Convert Mirroring from Asynchronous to Synchronous
-- CORPMEDEPO (BCC)
:CONNECT HTRDMULTI01\CORPMEDEPO
ALTER DATABASE ePO4_HTVAEPO0002 SET PARTNER SAFETY FULL;
GO
ALTER DATABASE ePO4_HTVAEPO0003 SET PARTNER SAFETY FULL;
GO

-- Confirm BCC Database Mirroring mirroring_role_desc = PRINCIPAL,
--                                mirroring_state_desc = SYNCHRONIZED
--                                mirroring_safety_level_desc = FULL
-- CORPMEDEPO (BCC)
:CONNECT HTRDMULTI01\CORPMEDEPO
SELECT d.name, d.database_id, m.mirroring_role_desc, 
       m.mirroring_state_desc, m.mirroring_safety_level_desc, 
       m.mirroring_partner_name, m.mirroring_partner_instance,
       m.mirroring_witness_name, m.mirroring_witness_state_desc
FROM   sys.database_mirroring m JOIN sys.databases d
ON     m.database_id = d.database_id
WHERE  mirroring_state_desc IS NOT NULL;
GO

-- On BCC set each Database to now become the Mirror
-- CORPMEDEPO (BCC)
:CONNECT HTRDMULTI01\CORPMEDEPO
use master
GO
ALTER DATABASE ePO4_HTVAEPO0002 SET PARTNER FAILOVER;
GO
ALTER DATABASE ePO4_HTVAEPO0003 SET PARTNER FAILOVER;
GO


-- Switch to NDC and ensure Database Mirroring mirroring_role_desc = PRINCIPAL,
--                                             mirroring_state_desc = SYNCHRONIZED
--                                             mirroring_safety_level_desc = FULL
-- CORPMEDEPO (NDC)
:CONNECT HTRDMULTI04\CORPMEDEPO
SELECT d.name, d.database_id, m.mirroring_role_desc, 
       m.mirroring_state_desc, m.mirroring_safety_level_desc, 
       m.mirroring_partner_name, m.mirroring_partner_instance,
       m.mirroring_witness_name, m.mirroring_witness_state_desc
FROM   sys.database_mirroring m JOIN sys.databases d
ON     m.database_id = d.database_id
WHERE  mirroring_state_desc IS NOT NULL;
GO

-- On NDC Convert Mirroring from Synchronous to Asynchronous
-- CORPMEDEPO (NDC)
:CONNECT HTRDMULTI04\CORPMEDEPO
ALTER DATABASE ePO4_HTVAEPO0002 SET PARTNER SAFETY OFF;
GO
ALTER DATABASE ePO4_HTVAEPO0003 SET PARTNER SAFETY OFF;
GO

-- Ensure Database Mirroring mirroring_role_desc = PRINCIPLE,
--                           mirroring_state_desc = SYNCHRONIZED
--                           mirroring_safety_level_desc = OFF
-- CORPMEDEPO (NDC)
:CONNECT HTRDMULTI04\CORPMEDEPO
SELECT d.name, d.database_id, m.mirroring_role_desc, 
       m.mirroring_state_desc, m.mirroring_safety_level_desc, 
       m.mirroring_partner_name, m.mirroring_partner_instance,
       m.mirroring_witness_name, m.mirroring_witness_state_desc
FROM   sys.database_mirroring m JOIN sys.databases d
ON     m.database_id = d.database_id
WHERE  mirroring_state_desc IS NOT NULL;
GO

-- Comms Change Content Switch change Services
-- Wintel restart App Servers

-- ** HEALTH CHECKS ** --

