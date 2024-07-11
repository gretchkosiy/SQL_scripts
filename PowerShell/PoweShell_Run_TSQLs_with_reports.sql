


------------------------------------------------------
cls 

$Instance = "PRTDBCR04\SHIELDREPLICA"
$SQLDatabasename = "NicheRMS_SAT"

$RunTime = Get-Date  
$RunTime

# Get current Location
$MyPath = split-path -parent $MyInvocation.MyCommand.Definition 

$ScriptsPath = "$MyPath\SQL\"
$CSVPath = "$MyPath\Reports\"

$Path = $MyPath

# ADD !!!  delete all *.txt and  *.xml in $CSVPath

Get-ChildItem -Path $CSVPath -Include *.txt -Recurse | foreach { $_.Delete()}
Get-ChildItem -Path $CSVPath -Include *.xml -Recurse | foreach { $_.Delete()}


Write-Host "Scripts location: $ScriptsPath" -fore Green
Write-Host "Reports location: $CSVPath" -fore Green

$LogFile = "$ScriptsPath\Report_log_" `
+ $RunTime.Year.ToString() `
+ ("0"+$RunTime.Month.ToString()).SUBSTRING(("0"+$RunTime.Month.ToString()).Length-2) `
+ ("0"+$RunTime.Day.ToString()).SUBSTRING(("0"+$RunTime.Day.ToString()).Length-2) + "_" `
+ ("0"+$RunTime.Hour.ToString()).SUBSTRING(("0"+$RunTime.Hour.ToString()).Length-2) `
+ ("0"+$RunTime.Minute.ToString()).SUBSTRING(("0"+$RunTime.Minute.ToString()).Length-2) `
+ ("0"+$RunTime.Second.ToString()).SUBSTRING(("0"+$RunTime.Second.ToString()).Length-2) `
+ ".txt"

"$RunTime - Start " | Out-File -append $LogFile 

[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | Out-Null

Function Invoke-Sqlcmd2 
{ 
    [CmdletBinding()] 
    param ( 
        [Parameter(Position=0, Mandatory=$true)] [string]$ServerInstance, 
        [Parameter(Position=1, Mandatory=$false)] [string]$Database, 
        [Parameter(Position=2, Mandatory=$false)] [string]$Query, 
        [Parameter(Position=3, Mandatory=$false)] [string]$Username, 
        [Parameter(Position=4, Mandatory=$false)] [string]$Password, 
        [Parameter(Position=5, Mandatory=$false)] [Int32]$QueryTimeout=600, 
        [Parameter(Position=6, Mandatory=$false)] [Int32]$ConnectionTimeout=15, 
        [Parameter(Position=7, Mandatory=$false)] [ValidateScript({test-path $_})] [string]$InputFile, 
        [Parameter(Position=8, Mandatory=$false)] [ValidateSet("DataSet", "DataTable", "DataRow", "DataValue")] [string]$As="DataRow" 
    )

    if ($InputFile) { 
        $filePath = $(resolve-path $InputFile).path 
        $Query =  [System.IO.File]::ReadAllText("$filePath") 
    } 
 
    $conn=new-object System.Data.SqlClient.SQLConnection 
      
    if ($Username) { 
        $ConnectionString = "Server={0};Database={1};User ID={2};Password={3};Trusted_Connection=False;Connect Timeout={4}" -f $ServerInstance,$Database,$Username,$Password,$ConnectionTimeout 
    } else { 
        $ConnectionString = "Server={0};Database={1};Integrated Security=True;Connect Timeout={2}" -f $ServerInstance,$Database,$ConnectionTimeout 
    }
    $conn.ConnectionString=$ConnectionString 
     
    #Following EventHandler is used for PRINT and RAISERROR T-SQL statements. Executed when -Verbose parameter specified by caller 
    if ($PSBoundParameters.Verbose) { 
        $conn.FireInfoMessageEventOnUserErrors=$true 
        $handler = [System.Data.SqlClient.SqlInfoMessageEventHandler] { 
            #Write-Verbose "$($_)"
        } 
        $conn.add_InfoMessage($handler) 
    } 

    try {      
        $conn.Open() 
        $cmd=new-object system.Data.SqlClient.SqlCommand($Query,$conn) 
        $cmd.CommandTimeout=$QueryTimeout 
        $ds=New-Object system.Data.DataSet 
        $da=New-Object system.Data.SqlClient.SqlDataAdapter($cmd) 
        [void]$da.fill($ds) 
        $conn.Close() 
        } catch { 
            throw $_.Exception
            continue 
        } 

        switch ($As) 
        { 
            'DataSet'   { Write-Output ($ds) } 
            'DataTable' { Write-Output ($ds.Tables) } 
            'DataRow'   { Write-Output ($ds.Tables[0]) } 
            'DataValue' { Write-Output ($ds.Tables[0].Rows[0].Column1) } 
        }

}  

Function Write-DataTable 
{ 
    [CmdletBinding()] 
    param ( 
    [Parameter(Position=0, Mandatory=$true)] [string]$ServerInstance, 
    [Parameter(Position=1, Mandatory=$true)] [string]$Database, 
    [Parameter(Position=2, Mandatory=$true)] [string]$TableName, 
    [Parameter(Position=3, Mandatory=$true)] $Data, 
    [Parameter(Position=4, Mandatory=$false)] [string]$Username, 
    [Parameter(Position=5, Mandatory=$false)] [string]$Password, 
    [Parameter(Position=6, Mandatory=$false)] [Int32]$BatchSize=50000, 
    [Parameter(Position=7, Mandatory=$false)] [Int32]$QueryTimeout=0, 
    [Parameter(Position=8, Mandatory=$false)] [Int32]$ConnectionTimeout=15 
    ) 
     
    $conn=new-object System.Data.SqlClient.SQLConnection 
 
    if ($Username) { 
        $ConnectionString = "Server={0};Database={1};User ID={2};Password={3};Trusted_Connection=False;Connect Timeout={4}" -f $ServerInstance,$Database,$Username,$Password,$ConnectionTimeout 
    } else { 
        $ConnectionString = "Server={0};Database={1};Integrated Security=True;Connect Timeout={2}" -f $ServerInstance,$Database,$ConnectionTimeout 
    } 
    $conn.ConnectionString=$ConnectionString 
 
    try {  
        $conn.Open() 
        $bulkCopy = new-object ("Data.SqlClient.SqlBulkCopy") $connectionString 
        $bulkCopy.DestinationTableName = $tableName 
        $bulkCopy.BatchSize = $BatchSize 
        $bulkCopy.BulkCopyTimeout = $QueryTimeOut 
        $bulkCopy.WriteToServer($Data) 
        $conn.Close() 
    } catch { 
        throw $_.Exception
        #Write-Error $_.Exception
        continue 
    } 
 
} 

###  START #########################################################

$STR = "Instance: '$Instance'  Database: $SQLDatabasename"
Write-Host $STR  -fore Gray
$STR | Out-File -append $LogFile 

$STR = "$newRunTime - Start Queries loop"
Write-Host $STR  -fore Green
$STR | Out-File -append $LogFile 

# getting list of scripts
$ScriptsList = Get-ChildItem -Path $ScriptsPath | where {$_.Extension -eq '.sql' } | Select Name, BaseName

    # Loop through all scripts
    foreach ($Script in $ScriptsList) {
        $ScriptFullName = $ScriptsPath + $Script.Name
        
        $Query = Get-Content -Path $ScriptFullName -Raw
        $ResultS = $null

        $QN = $Script.BaseName 

            $ConnectionCFG = New-Object System.Data.SQLClient.SQLConnection("server='$Instance';Integrated Security=SSPI;Initial Catalog='$SQLDatabasename';");
            $ConnectionCFG.Open()
            $CommandCFG = New-Object System.Data.SQLClient.SQLCommand
            $CommandCFG.Connection = $ConnectionCFG
            $CommandCFG.CommandTimeout = 0
            $adapter = New-Object System.Data.SqlClient.SqlDataAdapter $CommandCFG
            $dataset = New-Object System.Data.DataSet

            $CommandCFG.CommandText = $Query 
               $adapter.Fill($dataset) | out-null 
               $Result = $dataset.Tables[0]
            if ($Result.Count -ne 0) { $ResultS += $Result } 

        $D = $Query.Replace("  "," ").Replace("  "," ").Replace("  "," ").Replace("  "," ")

        if ($D.IndexOf("FOR XML") -gt 0) { 
                 $STR = " Query processed as XML : '$QN' "
                 $CSVFileName = $CSVPath + $Script.BaseName + ".xml" 
                 $oneline =""
                 
                 foreach ($Rline in $ResultS ) { $oneline += $Rline[0].Replace("><",">`r`n <") }
                    #$Rline[0].Replace("><",">`r`n <")  | Out-File -append $CSVFileName -NoNewline 
                $oneline | Out-File $CSVFileName 
            }
            else { 
                $STR = " Query processed as Text: '$QN' "
                $CSVFileName = $CSVPath + $Script.BaseName +  ".xml"  # ".txt"
                foreach ($Rline in $ResultS ) { $Rline[0] | Out-File -append $CSVFileName }
            }     
            Write-Host  $STR -fore Gray
            $STR | Out-File -append $LogFile 

    }

$STR = "$newRunTime - End Queries loop" 
$STR | Out-File -append $LogFile 
Write-Host  $STR  -fore green
"$newRunTime - END" | Out-File -append $LogFile   
Get-Date  
