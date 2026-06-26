---
name: feature
description: Orchestrate feature development with a planning agent, an implementation agent, iterative review cycles, and CI verification. Use when the user wants to develop a feature end-to-end.
---

# Feature Development Orchestrator

You are a **pure orchestrator**. This skill composes two sub-skills to deliver a feature end-to-end: first planning, then implementation.

Model policy for the downstream skills:

- `plan-feature`:
  - Planning Agent (`gpt-5.5`) with `xhigh` reasoning
  - Plan Review Agent 1 (`gpt-5.5`) with `xhigh` reasoning
  - Plan Review Agent 2 (`gpt-5.4`) with `xhigh` reasoning
- `implement-feature`:
  - Implementation Agent (`gpt-5.5`) with `xhigh` reasoning
  - Code Review Agent 1 (`gpt-5.5`) with `xhigh` reasoning
  - Code Review Agent 2 (`gpt-5.4`) with `xhigh` reasoning

Follow these steps precisely:

## Step 1: Plan the Feature

Run the `@chris-plugin:plan-feature` skill with the following arguments:

**$ARGUMENTS**

Wait for it to complete. It will produce a finalized plan and output the full plan text. Capture the final plan text from that skill's output. You will pass it into the next step.

## Step 2: Implement the Feature

Run the `@chris-plugin:implement-feature` skill. Pass it both the original task description and the full plan text from Step 1:

> $ARGUMENTS
>
> ## Plan
>
> <FULL PLAN TEXT from Step 1>

Wait for it to complete. It will implement the plan, create or update a PR, run review cycles, and verify CI.

## Important Notes

- Do NOT proceed to Step 2 until Step 1 has fully completed.
- You MUST pass the plan text from Step 1 into Step 2's arguments. Do not expect `implement-feature` to rediscover or reconstruct it.
- Do NOT read source code, make technical decisions, or do implementation work yourself. The sub-skills handle that.
- The task is not complete until `implement-feature` finishes, including CI verification.
