---
name: pr-comments
description: Review unresolved GitHub PR comments, reply to the ones already addressed by current code, and resolve those threads.
---

# PR Comments

## Workflow

1. Find the PR for the current branch.
2. Fetch unresolved review comments and relevant top-level review summaries.
3. For each unresolved thread:
   - inspect the current code
   - decide conservatively whether the feedback is already addressed
4. For addressed comments:
   - reply with a short explanation
   - resolve the thread
5. Report resolved versus still-open threads.
