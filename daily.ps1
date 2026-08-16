param(
    [ValidateSet("manual", "weekly", "sabotage")]
    [string]$Mode = "manual"
)

$root = "C:\Projects\eng_loop\daily_loop"
$progressFile = Join-Path $root "progress.md"
$changelogFile = Join-Path $root "CHANGELOG.md"
$doneFile = Join-Path $root "task-done.txt"

$startedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"

$content = Get-Content $progressFile -Raw

# Spine: last_commit
$lastCommit = ""
if ($content -match 'last_commit:\s*(\S*)') {
    $lastCommit = $Matches[1]
}

# Worktree isolation
$wtPath = Join-Path $root "wt-$stamp"
$null = git worktree add $wtPath HEAD 2>&1

$draftOk = $false
$verdict = "FAIL"
$reason = "worktree not created"
$newCount = 0

if (Test-Path $wtPath) {
    Push-Location $wtPath
    try {
        # Write spine state into the worktree so maker reads correctly.
        Set-Content -Path $progressFile -Value $content

        node maker.js

        $draft = Get-Content "draft.txt" -Raw
        if ($Mode -eq "sabotage") {
            Set-Content -Path "draft.txt" -Value "INVALID LINE WITHOUT HASH"
        }

        $reviewOutput = node reviewer.js 2>&1
        $reviewText = ($reviewOutput -join "`n")

        if ($reviewText -match '(?m)^PASS') {
            $verdict = "PASS"
            $reason = "reviewer PASS"

            $draftLines = Get-Content "draft.txt"
            if ($draftLines -notcontains "NO_NEW_COMMITS") {
                Add-Content -Path $changelogFile -Value $draftLines
                $newCount = @($draftLines | Where-Object { $_ -match '^- ' }).Count
            }

            # Update spine with newest commit hash
            $headHash = (git rev-parse HEAD).Trim()
            $newProgress = $content -replace 'last_commit:\s*\S*', "last_commit: $headHash"
            Set-Content -Path $progressFile -Value $newProgress
        } else {
            $reason = ($reviewOutput | Where-Object { $_ -match '^Reason' } | Select-Object -First 1)
        }
    } finally {
        Pop-Location
    }
}

git worktree remove --force $wtPath 2>&1 | Out-Null
git worktree prune 2>&1 | Out-Null

$now = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$doneCount = 0
if (Test-Path $doneFile) {
    $doneCount = (Get-Content $doneFile | Where-Object { $_ -match '^DONE-' }).Count
}
$nextDone = $doneCount + 1

if ($verdict -eq "PASS") {
    "DONE-$nextDone at $now : $Mode : SUCCESS" | Add-Content -Path $doneFile
} else {
    "DONE-$nextDone at $now : $Mode : FAIL" | Add-Content -Path $doneFile
}

$summaryCount = (Get-ChildItem -Path $root -Filter "SUMMARY*.md" -ErrorAction SilentlyContinue).Count
$nextSummary = $summaryCount + 1
$summaryFile = Join-Path $root "SUMMARY$nextSummary.md"

$summaryLines = @(
    "Run: $nextSummary"
    "Started: $startedAt"
    "Finished: $now"
    "Mode: $Mode"
    "Verdict: $verdict"
    "Reason: $reason"
    "New changelog lines: $newCount"
)
Set-Content -Path $summaryFile -Value $summaryLines

Write-Output "===== daily_loop ====="
Write-Output "Run: $nextSummary"
Write-Output "Mode: $Mode"
Write-Output "Verdict: $verdict"
Write-Output "Reason: $reason"
Write-Output "New changelog lines: $newCount"
Write-Output "Wrote task-done.txt -> DONE-$nextDone"
Write-Output "Wrote $summaryFile"
Write-Output "======================"

$popupMessage = "Run: $nextSummary`nMode: $Mode`nVerdict: $verdict`nTime: $now"
& "C:\Projects\eng_loop\daily_loop\notify.ps1" -Title "Daily Loop Result" -Message $popupMessage
