cls
Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall `
    | Get-ItemProperty | Sort-Object -Property DisplayName `
    | Select-Object -Property DisplayName, UninstallString `
    | Where-Object {(($_.DisplayName -like "Microsoft SQL Server 20[0-9][0-9] (*)") -and ($_.UninstallString -ne $null)) }| Format-table
    # -and ($_.InstallDate -ne $null)
    # -or ($_.DisplayName -like "Service Pack*SQL*")
    # DisplayVersion, InstallDate,


# Anoter option     

$SetupPath = Get-ChildItem -Recurse -Include setup.exe -Path "$env:ProgramFiles\Microsoft SQL Server" -ErrorAction SilentlyContinue |
	Where-Object { ($_.FullName -match 'Setup Bootstrap\\SQL' -or $_.FullName -match 'Bootstrap\\Release\\Setup.exe' -or $_.FullName -match 'Bootstrap\\Setup.exe') -and ($_.FullName -notlike '*90*') } | 
	Sort-Object FullName -Descending | SELECT Fullname

$SetupPath | SELECT @{Name="Version"; Expression={([string]$_.Fullname).Substring(([string]$_.Fullname).IndexOf("\Setup Bootstrap\")-3,3) }}, Fullname