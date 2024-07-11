Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall `
    | Get-ItemProperty | Sort-Object -Property DisplayName `
    | Select-Object -Property DisplayName, DisplayVersion, InstallDate `
    | Where-Object {($_.DisplayName -like "Hotfix*SQL*") -or ($_.DisplayName -like "Service Pack*SQL*")}| Format-List