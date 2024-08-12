# RUN THIS IN 64 and 32 bits mode!!!

Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall `
    | Get-ItemProperty | Sort-Object -Property DisplayName `
    | Select-Object -Property DisplayName, DisplayVersion, InstallDate `
    | Where-Object {($_.DisplayName -like "Hotfix*SQL*") -or ($_.DisplayName -like "Service Pack*SQL*")}| Sort-Object -Property InstallDate -Descending| Format-table

