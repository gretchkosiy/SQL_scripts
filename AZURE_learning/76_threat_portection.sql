Declare @txt varchar(max)
set  @txt = 'select * from [SalesLT].[Product]'
EXEC (@txt)
set  @txt = @txt + ';drop table sss.ddd'
EXEC (@txt)