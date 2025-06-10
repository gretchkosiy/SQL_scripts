
-- Adaptive Join Internals
--https://www.sqlshack.com/sql-server-2017-adaptive-join-internals/

go
alter database [AdventureWorks2022] set compatibility_level = 140;
go
create nonclustered columnstore index dummy on Sales.SalesOrderHeader(SalesOrderID) where SalesOrderID = -1 and SalesOrderID = -2;
go
declare @TerritoryID int = 1;
select
	sum(soh.SubTotal)
from 
	Sales.SalesOrderHeader soh
	join Sales.SalesOrderDetail sod on soh.SalesOrderID = sod.SalesOrderID
where
	soh.TerritoryID = @TerritoryID
--option (optimize for (@TerritoryID = 0))	
	;
go

-- Adaptive Memory Grant Feedback
-- https://www.sqlshack.com/sql-server-2017-sort-spill-memory-and-adaptive-memory-grant-feedback/
-- https://learn.microsoft.com/en-gb/archive/blogs/sqlserverstorageengine/introducing-batch-mode-adaptive-memory-grant-feedback


-- Batch Mode on Rowstore
-- https://www.sqlshack.com/sql-server-2019-new-features-batch-mode-on-rowstore/

-- Interleaved Execution for mTVF
https://www.sqlshack.com/sql-server-2017-interleaved-execution-for-mtvf/

-- Scalar UDF Inlining
https://www.sqlshack.com/scalar-udf-inlining-in-sql-server-2019/


SET STATISTICS IO ON
SET STATISTICS TIME ON
SELECT
Product.Name AS [Product Name] ,
Product.ProductNumber AS [Product Number],
Sales.UnitPrice AS [Sales UnitPrice]
FROM  Production.Product Product
INNER JOIN Sales.SalesOrderDetail Sales
ON Product.ProductID = Sales.ProductID



ALTER DATABASE SCOPED CONFIGURATION SET TSQL_SCALAR_UDF_INLINING = ON/OFF
GO
--SET STATISTICS IO ON
--SET STATISTICS TIME ON
-- Statistics Parser
--https://statisticsparser.com/about.html
SELECT
Product.Name AS [Product Name] ,
Product.ProductNumber AS [Product Number] ,
Sales.UnitPrice AS [Sales UnitPrice],
dbo.ufnGetStock(Product.ProductID)
FROM  Production.Product Product
INNER JOIN Sales.SalesOrderDetail Sales
ON Product.ProductID = Sales.ProductID


-- Table Variable Deferred Compilation 
https://www.sqlshack.com/sql-table-variable-deferred-compilation-in-sql-server-2019/

--DBCC TRACEON(2453);
--DBCC TRACEOFF(2453);
SET STATISTICS IO ON;
SET STATISTICS TIME ON;
DECLARE @Person TABLE
([BusinessEntityID] INT, 
 [FirstName]        VARCHAR(30), 
 [LastName]         VARCHAR(30)
);
INSERT INTO @Person
       SELECT [BusinessEntityID], 
              [FirstName], 
              [LastName]
       FROM [Person].[Person];
SELECT *
FROM @Person P1
     JOIN [Person].[Person] P2 ON P1.[BusinessEntityID] = P2.[BusinessEntityID];