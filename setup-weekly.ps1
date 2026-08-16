$taskName = "DailyLoopCapstone"
$cmdPath = "C:\Projects\eng_loop\daily_loop\run-weekly.cmd"
$time = "13:00"

schtasks /Delete /TN $taskName /F 2>$null | Out-Null
schtasks /Create /TN $taskName /TR $cmdPath /SC WEEKLY /D SUN /ST $time /F | Out-Null

$xml = schtasks /Query /TN $taskName /XML

# Set battery allowance and catch-up.
$xml = $xml -replace '<DisallowStartIfOnBatteries>true</DisallowStartIfOnBatteries>', '<DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>'

# Insert StartWhenAvailable into Settings, after DisallowStartIfOnBatteries.
$xml = $xml -replace '(<DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>)', '$1<StartWhenAvailable>true</StartWhenAvailable>'

$tmpFile = Join-Path $env:TEMP "daily_loop_task.xml"
$xml | Set-Content -Path $tmpFile -Encoding UTF8

schtasks /Create /TN $taskName /XML $tmpFile /F | Out-Null

Write-Output "Weekly task '$taskName' created for Sunday at $time with catch-up enabled."
