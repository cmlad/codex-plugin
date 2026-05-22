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

## Failure Causality Rule

Only make code, generated-file, dependency, schema, snapshot, fixture, or test changes for failures that were caused by the PR's own diff.

Before editing anything because of a failed check, you MUST establish and state the causal link between the failure and the PR. Use the PR diff as the boundary of responsibility. If the failure cannot be tied to files, behavior, dependencies, configuration, generated outputs, or tests changed by the PR, do not change code to fix it.

Treat these as unrelated unless the PR explicitly changed the relevant area:

- upstream or base-branch drift, including proto drift, generated-code drift, lockfile drift, formatter drift, or schema drift
- failures in crates, packages, services, or workflows untouched by the PR
- test fakes or compile errors caused only by upstream interface changes that the PR did not introduce
- flaky tests, infrastructure failures, network/service outages, rate limits, cache problems, runner capacity, or third-party tool failures
- pre-existing failures reproducible on `main` or visible in recent `main`/base CI
- broad workspace failures where the first failing error is outside the PR's changed surface

For unrelated failures, do not "helpfully" update unrelated files just to make CI green. Instead, report the failure as unrelated, include the evidence, and retry only when it is plausibly flaky. If a required check is red because of an unrelated deterministic failure, stop and call the PR blocked rather than expanding the PR scope.

If you are unsure whether a failure is PR-caused, default to not editing. Gather more evidence first, such as the exact failing line, the owning file, whether the file is in `git diff origin/main...HEAD`, whether the failure reproduces on the base branch, and whether recent base-branch CI already shows it. Ask the user before making any unrelated or scope-expanding change.

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
   - identify the first failing error, owning file/package/workflow, and whether it is inside the PR diff
   - classify each failure as PR-caused, unrelated, flaky, or blocked
   - do not edit code unless the failure is classified as PR-caused with evidence
9. Fix PR-caused failures directly, push, perform Step 2, leave the required PR comment summarizing what failures or feedback that push addressed, and go back to Step 4.
10. Retry unrelated flakes with `gh run rerun <run_id> --failed`.
11. Loop until green or conclusively blocked.

## Exit criteria

Report success only when checks are green and unresolved review feedback has been triaged (resolved when already addressed, or explicitly reported as still actionable).
