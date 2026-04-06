#!/usr/bin/env bash
set -euo pipefail

if ! command -v claude >/dev/null 2>&1; then
  echo "claude CLI not found on PATH" >&2
  exit 1
fi

if [ "$#" -lt 1 ]; then
  echo "usage: $0 <prompt...>" >&2
  exit 1
fi

claude -p --output-format text "$*"
