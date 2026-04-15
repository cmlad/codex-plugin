---
name: pr-green
description: Get a GitHub PR green by resolving addressed review threads, fixing PR-caused failures, and driving checks to green.
---

# Get PR Green

Stay in the loop until one of these is true:

- all checks are green and outstanding review threads have been triaged
- only unrelated failures remain after reasonable retries
- the run is conclusively blocked

## Workflow

1. Identify the PR for the current branch with `gh pr view --json number,url,headRefName`.
2. Push any pending fixes.
3. Review unresolved PR feedback:
   - fetch unresolved review threads and relevant top-level review summaries
   - for each unresolved thread, inspect the current code and decide conservatively whether the feedback is already addressed
   - for addressed threads, reply with a short explanation and resolve the thread
4. If actionable unresolved feedback remains, fix it directly, push, and repeat Step 3.
5. Wait for checks with `gh pr checks --watch --fail-fast`.
6. If checks are still pending, keep waiting.
7. When failures exist:
   - inspect failed logs with `gh run view`
   - compare against the PR diff
   - classify each failure as PR-caused or unrelated
8. Fix PR-caused failures directly, push, and go back to Step 3.
9. Retry unrelated flakes with `gh run rerun <run_id> --failed`.
10. Loop until green or conclusively blocked.

## Exit criteria

Report success only when checks are green and unresolved review feedback has been triaged (resolved when already addressed, or explicitly reported as still actionable).
