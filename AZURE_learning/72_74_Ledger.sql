-- https://learn.microsoft.com/en-us/sql/relational-databases/security/ledger/ledger-overview?view=sql-server-ver16

-- https://learn.microsoft.com/en-us/sql/relational-databases/security/ledger/ledger-how-to-configure-ledger-database?view=sql-server-ver16&tabs=t-sql%2Ct-sql2&pivots=as1-azure-sql-database



-- 01 New table to be created with 

-- WITH (SYSTEM_VERSIONING = ON, LEDGER = ON) 

-- 02 copy data to this table 
INSERT [SalesLT].[ProductDescription_Ledger]
SELECT * FROM [SalesLT].[ProductDescription]


-- 03 cheking list of ledger table and history 
select * from sys.tables where ledger_type <> 0 

-- empty - no permissions 
SELECT * FROM [SalesLT].MSSQL_LedgerHistoryFor_1314103722

-- 04 but can read from view
SELECT TOP (1000) [ProductDescription_LedgerID]
      ,[Description]
      ,[rowguid]
      ,[ModifiedDate]
      ,[ledger_transaction_id]
      ,[ledger_sequence_number]
      ,[ledger_operation_type]
      ,[ledger_operation_type_desc]
  FROM [SalesLT].[ProductDescription_Ledger_Ledger]

-- 05 delete some records 
  DELETE FROM [SalesLT].[ProductDescription_Ledger] WHERE ProductDescription_LedgerID <10 

  SELECT TOP (1000) [ProductDescription_LedgerID]
      ,[Description]
      ,[rowguid]
      ,[ModifiedDate]
      ,[ledger_transaction_id]
      ,[ledger_sequence_number]
      ,[ledger_operation_type]
      ,[ledger_operation_type_desc]
  FROM [SalesLT].[ProductDescription_Ledger_Ledger]
  where [ledger_operation_type_desc] = 'DELETE'


  UPDATE [SalesLT].[ProductDescription_Ledger]
  SET [Description] = 'New Description'
  WHERE ProductDescription_LedgerID = 170


  SELECT TOP (1000) [ProductDescription_LedgerID]
      ,[Description]
      ,[rowguid]
      ,[ModifiedDate]
      ,[ledger_transaction_id]
      ,[ledger_sequence_number]
      ,[ledger_operation_type]
      ,[ledger_operation_type_desc]
  FROM [SalesLT].[ProductDescription_Ledger_Ledger]
    WHERE ProductDescription_LedgerID = 170
	ORDER BY [ledger_transaction_id]