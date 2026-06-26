---
name: claude-review
description: Run an opt-in external Claude Code CLI review of the current branch against its implementation plan, then display Claude's review output to the user.
---

# Claude Review

Use this skill when the user asks for a Claude review, external Claude review, or cross-check of the current branch.

This skill is a thin orchestrator around the Claude Code CLI. It must run the bundled `scripts/claude-review.sh` wrapper with `bash`, resolving the script relative to this skill directory, and display Claude's review to the user.

## Step 1: Obtain the Plan

Obtain the implementation plan in this order:

1. If `$ARGUMENTS` contains an inline plan, use it directly.
2. If `$ARGUMENTS` names a Linear ticket, read the ticket comments and use the latest comment that starts with `## Implementation Plan`.
3. If `plan.md` exists in the repository root, use `plan.md`.

If no plan is available, tell the user that `claude-review` needs an implementation plan and stop. Do not run Claude without a plan.

## Step 2: Run Claude

Resolve `scripts/claude-review.sh` relative to this skill directory, then run it with `bash` from the repository root being reviewed.

For `plan.md`:

```bash
bash <skill-dir>/scripts/claude-review.sh --plan-file plan.md
```

For an inline or externally fetched plan, pass it as an argument:

```bash
bash <skill-dir>/scripts/claude-review.sh --plan "$PLAN_TEXT"
```

Only use `--plan-file -` when plan text is actually piped into the wrapper.
The wrapper fails fast instead of waiting when `--plan-file -` is run from an
interactive stdin.

If the user specifies a base branch or ref, pass it explicitly:

```bash
bash <skill-dir>/scripts/claude-review.sh --base origin/main --plan-file plan.md
```

The wrapper sends Claude:

- branch name, HEAD SHA, base ref, and merge-base SHA
- working tree status
- branch commit list
- diff stat
- full implementation plan
- branch diff from merge base to `HEAD`

The wrapper calls Claude Code in print mode with text output and no tools:

```bash
claude -p --output-format text --tools "" --max-turns 1 --no-session-persistence
```

This follows Claude Code's documented programmatic CLI pattern while keeping the review read-only by passing all context on stdin.

## Step 3: Display the Review

Show Claude's review output to the user. Preserve its findings and do not rewrite them as your own review.

You may add one short line before the review naming the command/base that was used. If Claude fails, show the error and any obvious remediation, such as installing or authenticating the `claude` CLI.
