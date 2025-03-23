        Get-WinEvent -FilterHashtable @{logname='System' ; id = 1074}  | ForEach-Object {
        $rv = New-Object PSObject | Select-Object Date, User, Action, Process, Reason, ReasonCode, Comment, Message
        $rv.Date = $_.TimeCreated
        $rv.User = $_.Properties[6].Value
        $rv.Process = $_.Properties[0].Value
        $rv.Action = $_.Properties[4].Value
        $rv.Reason = $_.Properties[2].Value
        $rv.ReasonCode = $_.Properties[3].Value
        $rv.Comment = $_.Properties[5].Value
        $rv.Message = $_.Message
        $rv
        } | Select-Object Date, Action, Reason, User, Comment, Message | format-table 


# https://learn.microsoft.com/en-us/troubleshoot/windows-server/performance/troubleshoot-unexpected-reboots-system-event-logs
# https://teamdynamix.umich.edu/TDClient/30/Portal/KB/ArticleDet?ID=11475#:~:text=Expand%20the%20Windows%20Logs%20section,we%20will%20enter%20ID%201074%20.

# Get-CimInstance -ClassName win32_operatingsystem | select csname, lastbootuptime
# (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime
# systeminfo | find /i "Boot Time"