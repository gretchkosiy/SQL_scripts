# https://www.powershellgallery.com/packages/dbatools/0.9.332/Content/functions%5CGet-DbaSqlFeature.ps1

cls

$setup = Get-ChildItem -Recurse -Include setup.exe -Path "$env:ProgramFiles\Microsoft SQL Server" -ErrorAction SilentlyContinue |
            Where-Object { ($_.FullName -match 'Setup Bootstrap\\SQL' -or $_.FullName -match 'Bootstrap\\Release\\Setup.exe' -or $_.FullName -match 'Bootstrap\\Setup.exe') -and ($_.FullName -notlike '*90*') } |
            Sort-Object FullName -Descending | Select-Object -First 1
$null = Start-Process -FilePath $setup.FullName -ArgumentList "/Action=RunDiscovery /q" -Wait
$parent = Split-Path (Split-Path $setup.Fullname)

$xmlfile = Get-ChildItem -Recurse -Include SqlDiscoveryReport.xml -Path $parent | Sort-Object LastWriteTime -Descending | Select-Object -First 1
#$xmlfile.FullName
    if ($xmlfile) { $InstalledFeatures = ([xml](Get-Content -Path $xmlfile)).ArrayOfDiscoveryInformation.DiscoveryInformation | 
        #select product, Instance, Feature , *
     
        select @{Name="product"; Expression={$_.product `
                    -replace "Microsoft SQL Server 2022","160" `
                    -replace "Microsoft SQL Server 2019","150" `
                    -replace "Microsoft SQL Server 2017","140" `
                    -replace "Microsoft SQL Server 2016","130" `
                    -replace "Microsoft SQL Server 2014","120" `
                    -replace "Microsoft SQL Server 2012","110" `
                    -replace "Microsoft SQL Server 2008","100" `
                    -replace "Microsoft SQL Server 2008R2","100" `
                    }}, 
                Instance, 
                @{Name="FeatureFullName"; Expression={$_.Feature}},
                @{Name="Feature"; Expression={$_.Feature -replace "Database Engine Services","SQLENGINE" `
                    -replace "Full-Text and Semantic Extractions for Search","FULLTEXT" `
                    -replace "SQL Server Replication","REPLICATION" `
                    -replace "Data Quality Services","DQ" `
                    -replace "Machine Learning Services and Language Extensions","ADVANCEDANALYTICS" `
                    -replace "Analysis Services","AS" `
                    -replace "PolyBase Query Service for External Data","POLYBASECORE" `
                    -replace "Data Quality Client","DQC" `
                    -replace "Integration Services","IS" `
                    -replace "Scale Out Master","IS_Master" `
                    -replace "Scale Out Worker","IS_Worker" `
                    -replace "Master Data Services","MDS" `
                    -replace "",""  
					# PolyBase PolyBaseCore PolyBaseCore SQL_INST_MR SQL_INST_MPY SQL_INST_JAVA BC Conn DREPLAY_CTLR DREPLAY_CLT SNAC_SDK LocalDB**
					# RS_SHP RS_SHPWFE SQL_SHARED_MPY SQL_SHARED_MR
                    }}
        }

$InstalledFeatures | Format-table

$InstanceFeatures = $InstalledFeatures |Group-Object Instance, Product |ForEach-Object {
  [pscustomobject]@{
    Version = $_.name.substring($_.name.indexof(',')+2)
    Instance  = $_.name.substring(0,$_.name.indexof(','))
    Features = ([string]($_.Group | % Feature)).Replace(" ",",")
  }
}


$SetupPath = Get-ChildItem -Recurse -Include setup.exe -Path "$env:ProgramFiles\Microsoft SQL Server" -ErrorAction SilentlyContinue |
	Where-Object { ($_.FullName -match 'Setup Bootstrap\\SQL' -or $_.FullName -match 'Bootstrap\\Release\\Setup.exe' -or $_.FullName -match 'Bootstrap\\Setup.exe') -and ($_.FullName -notlike '*90*') } | 
	Sort-Object FullName -Descending | SELECT Fullname

$SP = $SetupPath | SELECT @{Name="Version"; Expression={([string]$_.Fullname).Substring(([string]$_.Fullname).IndexOf("\Setup Bootstrap\")-3,3) }}, Fullname


#$InstanceFeatures
#$SP

$JoinedObject = Foreach ($row in $InstanceFeatures)
{
    $Instance = $row.Instance
    $Features = $row.Features
    $Version  = $row.Version
    $EXEpath = $SP | Where-Object {$_.Version -eq $Version} | Select-Object -ExpandProperty FullName
    $Uninstall = '"' + $EXEpath + '" /ACTION="unInstall" /INDICATEPROGRESS="FALSE" /QUIETSIMPLE="TRUE" /FEATURES=' + $Features # + ' /INSTANCENAME="' + $Instance + '"'  
    if ($Instance -ne "" ) {$Uninstall +=  ' /INSTANCENAME="' + $Instance + '"'}

    [pscustomobject]@{Instance = $Instance; Version = $Version; Features = $Features; EXEpath = $EXEpath; Uninstall = $Uninstall } | Write-Output
}

$JoinedObject | Select Uninstall | Format-list