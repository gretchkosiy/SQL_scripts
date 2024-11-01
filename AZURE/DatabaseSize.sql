SELECT @@SERVERNAME AS [ServerName],
       DB_NAME() AS [DBname],
       ISNULL(b.groupname, 'Log') AS 'File Group',
       Name as [Logical Name],
       [Filename],
       CONVERT (Decimal(15,2),ROUND(a.Size/128.000,2)) [Currently Allocated Space (MB)],
       CONVERT (Decimal(15,2), ROUND(FILEPROPERTY(a.Name,'SpaceUsed')/128.000,2)) AS [Space Used (MB)],
       CONVERT (Decimal(15,2),ROUND((a.Size-FILEPROPERTY(a.Name,'SpaceUsed'))/128.000,2)) AS [Available Space (MB)]
FROM dbo.sysfiles a (NOLOCK)
LEFT JOIN sysfilegroups b (NOLOCK) ON a.groupid = b.groupid;