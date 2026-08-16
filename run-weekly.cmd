powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Projects\eng_loop\daily_loop\daily.ps1" -Mode weekly
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Projects\eng_loop\daily_loop\notify.ps1" -Title "Daily Loop Result" -Message "Weekly run finished"
