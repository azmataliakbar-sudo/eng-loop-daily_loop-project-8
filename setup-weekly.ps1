$taskName = "DailyLoopCapstone"
$scriptPath = "C:\Projects\eng_loop\daily_loop\daily.ps1"
$notifyPath = "C:\Projects\eng_loop\daily_loop\notify.ps1"
$time = "13:00"

$action = "powershell.exe -NoProfile -ExecutionPolicy Bypass -Command `"& '$scriptPath' -Mode weekly; & '$notifyPath' -Title 'Daily Loop' -Message ('Weekly run finished at ' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))`""

# Remove existing task with same name, then create.
schtasks /Delete /TN $taskName /F 2>$null | Out-Null

schtasks /Create `
    /TN $taskName `
    /TR $action `
    /SC WEEKLY `
    /D SUN `
    /ST $time `
    /F

# Enable catch-up: run as soon as possible after a missed start.
schtasks /Change /TN $taskName /Z

Write-Output "Weekly task '$taskName' created for Sunday at $time with catch-up enabled."
