# Daily Changelog Skill

## Goal
Draft changelog lines for every commit after the last processed commit.

## Steps
1. Read `progress.md` to find `last_commit`.
2. Run `git log last_commit..HEAD --pretty=format:"%h|%s"`.
3. For each commit, draft one changelog line: `- <hash> <message>`.
4. Write the draft to `draft.txt`.
5. Do not modify CHANGELOG.md directly.

## Done when
The reviewer reads `draft.txt` and replies PASS.
