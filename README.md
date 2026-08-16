# daily_loop

Project 8 capstone: the full six-part loop.

## Run manual test

```powershell
.\daily.ps1 -Mode manual
```

## Run sabotage test

```powershell
.\daily.ps1 -Mode sabotage
```

## Register weekly Task Scheduler trigger (01:00 PM, catch-up on)

```powershell
.\setup-weekly.ps1
```

## Parts

- Heartbeat: manual or Task Scheduler weekly
- Worktree: fresh git worktree per beat
- Skill: skill.md
- Maker-checker: maker.js drafts, reviewer.js grades
- Connector: appends to CHANGELOG.md
- Spine: progress.md (last_commit)
