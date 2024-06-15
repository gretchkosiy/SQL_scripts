-- https://www.sqlservercentral.com/articles/find-invalid-objects-in-sql-server


SET NOCOUNT ON;
IF OBJECT_ID('tempdb.dbo.#invalid_db_objects') IS NOT NULL
DROP TABLE #invalid_db_objects
 
CREATE TABLE #invalid_db_objects (
  invalid_object_id INT --PRIMARY KEY
, [database_name]  NVARCHAR(3000) NOT NULL
, invalid_obj_name NVARCHAR(1000)
, missed_obj_name NVARCHAR(3000) NOT NULL
, invalid_obj_type VARCHAR(3000) NOT NULL
)
 
INSERT INTO #invalid_db_objects (invalid_object_id, [database_name], invalid_obj_name, missed_obj_name, invalid_obj_type)
SELECT
  cte.referencing_id
, DB_NAME() AS [database_name]
, obj_name = QUOTENAME(SCHEMA_NAME(all_object.[schema_id])) + '.' + QUOTENAME(all_object.name) ,
   --'Invalid object name ''' + 
   cte.obj_name 
   --+ ''''   
, all_object.[type_desc]
FROM ( SELECT
      sed.referencing_id
    , obj_name = COALESCE(sed.referenced_schema_name + '.', '') + sed.referenced_entity_name
FROM sys.sql_expression_dependencies sed
WHERE sed.is_ambiguous = 0    AND sed.referenced_id IS NULL

) cte
JOIN sys.objects all_object ON cte.referencing_id = all_object.[object_id]
WHERE
	-- ignore some triggers 
	NOT (all_object.[type_desc] = 'SQL_TRIGGER' and cte.obj_name in ('inserted', 'deleted'))

SELECT 
	*
FROM #invalid_db_objects






