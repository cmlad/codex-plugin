---
name: pr-tests
description: Poll GitHub PR checks, classify failures, fix PR-caused breakages, and retry unrelated flakes until the PR tests are green or conclusively blocked.
---

# PR Tests

Stay in the loop until one of these is true:

- all checks are green
- only unrelated failures remain after reasonable retries
- the run is conclusively blocked

## Workflow

1. Identify the PR for the current branch with `gh pr view --json number,url,headRefName`.
2. Push any pending fixes.
3. Wait for checks with `gh pr checks --watch --fail-fast`.
4. If any checks are still pending, keep waiting.
5. When failures exist:
   - inspect failed logs with `gh run view`
   - compare against the PR diff
   - classify each failure as PR-caused or unrelated
6. Fix PR-caused failures directly.
7. Retry unrelated flakes with `gh run rerun <run_id> --failed`.
8. Loop until green or conclusively blocked.

## Exit criteria

Report success only when all checks are green.
