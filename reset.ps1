Set-Content -Path "progress.md" -Value "# daily_loop progress`r`n`r`nlast_commit:`r`n`r`n## History`r`n"
Set-Content -Path "CHANGELOG.md" -Value "# Changelog`r`n"
if (Test-Path "task-done.txt") { Remove-Item "task-done.txt" }
Get-ChildItem -Filter "SUMMARY*.md" -ErrorAction SilentlyContinue | Remove-Item
Write-Output "Reset daily_loop."
