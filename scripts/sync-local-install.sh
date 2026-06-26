#!/usr/bin/env bash

set -euo pipefail

SRC_DIR="${1:-$HOME/src/codex-plugin}"
PLUGIN_JSON="$SRC_DIR/.codex-plugin/plugin.json"

if [[ ! -f "$PLUGIN_JSON" ]]; then
  echo "plugin manifest not found: $PLUGIN_JSON" >&2
  exit 1
fi

PLUGIN_NAME="$(sed -n 's/^[[:space:]]*"name":[[:space:]]*"\([^"]*\)".*/\1/p' "$PLUGIN_JSON" | head -n 1)"
VERSION="$(sed -n 's/^[[:space:]]*"version":[[:space:]]*"\([^"]*\)".*/\1/p' "$PLUGIN_JSON" | head -n 1)"

if [[ -z "$PLUGIN_NAME" ]]; then
  echo "failed to read plugin name from $PLUGIN_JSON" >&2
  exit 1
fi

if [[ -z "$VERSION" ]]; then
  echo "failed to read plugin version from $PLUGIN_JSON" >&2
  exit 1
fi

CACHE_ROOT="$HOME/.codex/plugins/cache/personal/$PLUGIN_NAME"
TARGET_DIR="$CACHE_ROOT/$VERSION"

mkdir -p "$CACHE_ROOT"
rm -rf "$TARGET_DIR"
mkdir -p "$TARGET_DIR"

# Mirror the local plugin into the installed-cache shape Codex expects.
rsync -a --delete --exclude .git "$SRC_DIR"/ "$TARGET_DIR"/

echo "synced $PLUGIN_NAME $VERSION to $TARGET_DIR"
echo "restart Codex and start a new session to load the updated plugin"
