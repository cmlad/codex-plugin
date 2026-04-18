#!/usr/bin/env bash

set -euo pipefail

SRC_DIR="${1:-$HOME/src/codex-plugin}"
PLUGIN_JSON="$SRC_DIR/.codex-plugin/plugin.json"
CACHE_ROOT="$HOME/.codex/plugins/cache/personal/codex-plugin"

if [[ ! -f "$PLUGIN_JSON" ]]; then
  echo "plugin manifest not found: $PLUGIN_JSON" >&2
  exit 1
fi

VERSION="$(sed -n 's/^[[:space:]]*"version":[[:space:]]*"\([^"]*\)".*/\1/p' "$PLUGIN_JSON" | head -n 1)"

if [[ -z "$VERSION" ]]; then
  echo "failed to read plugin version from $PLUGIN_JSON" >&2
  exit 1
fi

TARGET_DIR="$CACHE_ROOT/$VERSION"

mkdir -p "$CACHE_ROOT"
rm -rf "$TARGET_DIR"
mkdir -p "$TARGET_DIR"

# Mirror the local plugin into the installed-cache shape Codex expects.
rsync -a --delete --exclude .git "$SRC_DIR"/ "$TARGET_DIR"/

echo "synced codex-plugin $VERSION to $TARGET_DIR"
echo "restart Codex and start a new session to load the updated plugin"
