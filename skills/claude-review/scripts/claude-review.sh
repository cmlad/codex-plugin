#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
usage: claude-review.sh [--base <ref>] [--plan-file <path>|--plan <text>] [--max-diff-bytes <bytes>]

Runs an external Claude Code CLI review of the current branch by sending Claude
the implementation plan and branch diff context.

Options:
  --base <ref>              Base ref to diff against. Defaults to origin/HEAD,
                            origin/main, origin/master, main, then master.
  --plan-file <path>        File containing the implementation plan. Use "-" to
                            read the plan from stdin. Defaults to plan.md.
  --plan <text>             Implementation plan text.
  --max-diff-bytes <bytes>  Maximum branch diff bytes to send. Defaults to
                            CLAUDE_REVIEW_MAX_DIFF_BYTES or 250000.
  -h, --help                Show this help.
USAGE
}

die() {
  echo "claude-review: $*" >&2
  exit 1
}

default_base_ref() {
  local candidate

  if candidate="$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null)"; then
    if git rev-parse --verify --quiet "${candidate}^{commit}" >/dev/null; then
      printf '%s\n' "$candidate"
      return 0
    fi
  fi

  for candidate in origin/main origin/master main master; do
    if git rev-parse --verify --quiet "${candidate}^{commit}" >/dev/null; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  return 1
}

BASE_REF=""
PLAN_FILE=""
PLAN_TEXT=""
MAX_DIFF_BYTES="${CLAUDE_REVIEW_MAX_DIFF_BYTES:-250000}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --base)
      [[ $# -ge 2 ]] || die "--base requires a value"
      BASE_REF="$2"
      shift 2
      ;;
    --plan-file)
      [[ $# -ge 2 ]] || die "--plan-file requires a value"
      PLAN_FILE="$2"
      shift 2
      ;;
    --plan)
      [[ $# -ge 2 ]] || die "--plan requires a value"
      PLAN_TEXT="$2"
      shift 2
      ;;
    --max-diff-bytes)
      [[ $# -ge 2 ]] || die "--max-diff-bytes requires a value"
      MAX_DIFF_BYTES="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "unknown argument: $1"
      ;;
  esac
done

[[ "$MAX_DIFF_BYTES" =~ ^[0-9]+$ ]] || die "--max-diff-bytes must be an integer"

command -v claude >/dev/null 2>&1 || die "claude CLI not found on PATH"
command -v git >/dev/null 2>&1 || die "git not found on PATH"

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || die "not inside a git repository"
cd "$REPO_ROOT"

if [[ -n "$PLAN_TEXT" && -n "$PLAN_FILE" ]]; then
  die "use only one of --plan or --plan-file"
fi

if [[ -z "$PLAN_TEXT" ]]; then
  if [[ -n "$PLAN_FILE" ]]; then
    if [[ "$PLAN_FILE" == "-" ]]; then
      if [[ -t 0 ]]; then
        die "--plan-file - requires plan text on stdin; use --plan for inline text"
      fi
      PLAN_TEXT="$(cat)"
    else
      [[ -f "$PLAN_FILE" ]] || die "plan file not found: $PLAN_FILE"
      PLAN_TEXT="$(cat "$PLAN_FILE")"
    fi
  elif [[ -f plan.md ]]; then
    PLAN_TEXT="$(cat plan.md)"
  else
    die "no plan found; pass --plan-file, --plan, or create plan.md"
  fi
fi

[[ -n "${PLAN_TEXT//[[:space:]]/}" ]] || die "plan is empty"

if [[ -z "$BASE_REF" ]]; then
  BASE_REF="$(default_base_ref)" || die "could not infer base ref; pass --base <ref>"
fi

git rev-parse --verify --quiet "${BASE_REF}^{commit}" >/dev/null || die "base ref not found: $BASE_REF"

MERGE_BASE="$(git merge-base "$BASE_REF" HEAD)" || die "could not compute merge-base with $BASE_REF"
HEAD_SHA="$(git rev-parse HEAD)"
BRANCH_NAME="$(git branch --show-current)"
if [[ -z "$BRANCH_NAME" ]]; then
  BRANCH_NAME="detached HEAD"
fi

DIFF_FILE="$(mktemp)"
trap 'rm -f "$DIFF_FILE"' EXIT

git diff --no-ext-diff --find-renames "$MERGE_BASE...HEAD" >"$DIFF_FILE"
DIFF_BYTES="$(wc -c <"$DIFF_FILE" | tr -d '[:space:]')"

DIFF_TRUNCATED="false"
if (( DIFF_BYTES > MAX_DIFF_BYTES )); then
  DIFF_TRUNCATED="true"
fi

CLAUDE_ARGS=(-p --output-format text --tools "" --max-turns 1 --no-session-persistence)
if [[ "${CLAUDE_REVIEW_BARE:-}" == "1" || "${CLAUDE_REVIEW_BARE:-}" == "true" ]]; then
  CLAUDE_ARGS=(--bare "${CLAUDE_ARGS[@]}")
fi

REVIEW_PROMPT="You are an external staff engineer reviewer. Review the branch diff and implementation plan supplied on stdin.

Focus on correctness, regressions, missing tests, maintainability, performance, and whether the branch actually implements the plan without unnecessary scope.

Do not suggest edits unless they are actionable. Do not ask to inspect more files unless the provided diff is insufficient for a specific finding. If the diff is truncated, say which parts of the review are limited by truncation.

Output format:
- Start with the branch name, HEAD SHA, base ref, and merge-base SHA you reviewed.
- List findings first, ordered by severity, with file paths and concrete reasoning.
- If there are no significant findings, say that clearly.
- End with any residual risks or test gaps."

{
  printf '# Branch Metadata\n\n'
  printf 'Repository: %s\n' "$REPO_ROOT"
  printf 'Branch: %s\n' "$BRANCH_NAME"
  printf 'HEAD: %s\n' "$HEAD_SHA"
  printf 'Base ref: %s\n' "$BASE_REF"
  printf 'Merge base: %s\n' "$MERGE_BASE"
  printf 'Diff bytes: %s\n' "$DIFF_BYTES"
  printf 'Diff truncated: %s\n\n' "$DIFF_TRUNCATED"

  printf '# Working Tree Status\n\n'
  git status --short
  printf '\n'

  printf '# Commits In Branch\n\n'
  git log --oneline --decorate "$MERGE_BASE..HEAD" || true
  printf '\n'

  printf '# Diff Stat\n\n'
  git diff --no-ext-diff --find-renames --stat "$MERGE_BASE...HEAD"
  printf '\n'

  printf '# Implementation Plan\n\n'
  printf '%s\n\n' "$PLAN_TEXT"

  printf '# Branch Diff\n\n'
  if [[ "$DIFF_TRUNCATED" == "true" ]]; then
    head -c "$MAX_DIFF_BYTES" "$DIFF_FILE"
    printf '\n\n[Diff truncated after %s of %s bytes.]\n' "$MAX_DIFF_BYTES" "$DIFF_BYTES"
  else
    cat "$DIFF_FILE"
  fi
} | claude "${CLAUDE_ARGS[@]}" "$REVIEW_PROMPT"
