param(
    [ValidateSet("manual", "weekly", "sabotage")]
    [string]$Mode = "manual"
)

$root = "C:\Projects\eng_loop\daily_loop"
$doneFile = Join-Path $root "task-done.txt"
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$startedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# Worktree isolation
$wtPath = Join-Path $root "wt-$stamp"
$null = git worktree add $wtPath HEAD 2>&1

$wtProgress = Join-Path $wtPath "progress.md"
$wtChangelog = Join-Path $wtPath "CHANGELOG.md"
$wtDraft = Join-Path $wtPath "draft.txt"

$verdict = "FAIL"
$reason = "worktree not created"
$newCount = 0

if (Test-Path $wtPath) {
    Push-Location $wtPath
    try {
        Copy-Item (Join-Path $root "progress.md") $wtProgress -Force
        Copy-Item (Join-Path $root "CHANGELOG.md") $wtChangelog -Force

        node maker.js

        if ($Mode -eq "sabotage") {
            Set-Content -Path $wtDraft -Value "INVALID LINE WITHOUT HASH"
        }

        $reviewOutput = node reviewer.js 2>&1
        $reviewText = ($reviewOutput -join "`n")

        if ($reviewText -match '(?m)^PASS') {
            $verdict = "PASS"
            $reason = "reviewer PASS"

            $draftLines = Get-Content $wtDraft -ErrorAction SilentlyContinue
            if ($draftLines -and ($draftLines -notcontains "NO_NEW_COMMITS")) {
                Add-Content -Path $wtChangelog -Value $draftLines
                $newCount = @($draftLines | Where-Object { $_ -match '^- ' }).Count
            }

            $headHash = (git rev-parse HEAD).Trim()
            $progressContent = Get-Content $wtProgress -Raw
            $newProgress = $progressContent -replace '(?m)^last_commit:.*$', "last_commit: $headHash"
            Set-Content -Path $wtProgress -Value $newProgress

            Copy-Item $wtProgress (Join-Path $root "progress.md") -Force
            Copy-Item $wtChangelog (Join-Path $root "CHANGELOG.md") -Force
        } else {
            $reason = ($reviewOutput | Where-Object { $_ -match '^Reason' } | Select-Object -First 1)
            if (-not $reason) { $reason = ($reviewOutput -join " ") }
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
