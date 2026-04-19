---
name: pr-green
description: Get a GitHub PR green by resolving addressed review threads, fixing PR-caused failures, and driving checks to green.
---

# Get PR Green

Stay in the loop until one of these is true:

- all checks are green and outstanding review threads have been triaged
- only unrelated failures remain after reasonable retries
- the run is conclusively blocked

Whenever you push code in this workflow, you MUST immediately update the PR description so it reflects the current state of the patch, validation, and remaining follow-ups. You MUST also leave a top-level PR comment summarizing what feedback, review threads, or failing checks that push addressed. This is in addition to any thread-specific replies used to resolve comments.

## Workflow

1. Identify the PR for the current branch with `gh pr view --json number,url,headRefName`.
2. After every push in this workflow, immediately refresh the PR description before continuing. Keep it aligned with the current scope, validation, and any remaining follow-ups.
3. Push any pending fixes. If you push code, immediately perform Step 2 and leave the required PR comment summarizing what feedback or failures that push addressed.
4. Review unresolved PR feedback:
   - fetch unresolved review threads and relevant top-level review summaries
   - for each unresolved thread, inspect the current code and decide conservatively whether the feedback is already addressed
   - for addressed threads, reply with a short explanation and resolve the thread
5. If actionable unresolved feedback remains, fix it directly, push, perform Step 2, leave the required PR comment summarizing what feedback that push addressed, and repeat Step 4.
6. Wait for checks with `gh pr checks --watch --fail-fast`.
7. If checks are still pending, keep waiting.
8. When failures exist:
   - inspect failed logs with `gh run view`
   - compare against the PR diff
   - classify each failure as PR-caused or unrelated
9. Fix PR-caused failures directly, push, perform Step 2, leave the required PR comment summarizing what failures or feedback that push addressed, and go back to Step 4.
10. Retry unrelated flakes with `gh run rerun <run_id> --failed`.
11. Loop until green or conclusively blocked.

## Exit criteria

Report success only when checks are green and unresolved review feedback has been triaged (resolved when already addressed, or explicitly reported as still actionable).
