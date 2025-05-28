-- Section 10 - video 75
-- https://learn.microsoft.com/en-us/sql/t-sql/statements/create-security-policy-transact-sql?view=sql-server-ver16

CREATE USER BOSS WITHOUT LOGIN;
CREATE USER User1 WITHOUT LOGIN;
CREATE USER User2 WITHOUT LOGIN;
GO

Create Schema Customers
GO

Create table Customers.Customers
(Customer nvarchar(10),
Status nvarchar(10),
UserLead nvarchar(10))

INSERT INTO Customers.Customers VALUES
('John1','A','User1'),('Fred','B','User2'),('Mark','A','BOSS'),('Alfred','B','BOSS')
GO

SELECT * FROM Customers.Customers 
GO
Create Schema RLS
GO

CREATE FUNCTION RLS.rls_security(@user as nvarchar(10),@status as nvarchar(10)) RETURNS TABLE
WITH SCHEMABINDING 
AS 
RETURN SELECT 1 as rls_security_result
WHERE @user = USER_NAME() OR (USER_NAME() = 'BOSS' AND @status = 'A');
GO

GRANT SELECT ON RLS.rls_security TO BOSS
GRANT SELECT ON RLS.rls_security TO User1
GRANT SELECT ON RLS.rls_security TO User2

GRANT SELECT ON Customers.Customers TO BOSS
GRANT SELECT ON Customers.Customers TO User1
GRANT SELECT ON Customers.Customers TO User2
GRANT INSERT ON Customers.Customers TO BOSS

GO

CREATE SECURITY POLICY RLSPolicy
ADD FILTER PREDICATE RLS.rls_security(userlead, status)
ON Customers.Customers,
ADD BLOCK PREDICATE RLS.rls_security(userlead, status)
ON Customers.Customers AFTER INSERT
WITH (STATE = ON); -- To enable policy
GO

-- TEST 1 
EXECUTE AS USER = 'User1'
SELECT USER_NAME() 
SELECT * FROM Customers.Customers 
REVERT


-- TEST 2
EXECUTE AS USER = 'BOSS'
SELECT USER_NAME() 
SELECT * FROM Customers.Customers 
-- CAN ADD
INSERT INTO Customers.Customers VALUES ('aaa','A','User1')
-- THROW ERROR
INSERT INTO Customers.Customers VALUES ('bbb','B','User1')

REVERT
GO

ALTER SECURITY POLICY RLSPolicy
WITH (STATE = OFF)
go
SELECT * FROM Customers.Customers 