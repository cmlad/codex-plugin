# codex-plugin

This repository packages the migrated planning, implementation, review, and CI workflows as a Codex plugin.

## What is included

- Codex plugin manifest: [`.codex-plugin/plugin.json`](/home/zh/src/codex-plugin/.codex-plugin/plugin.json)
- Migrated skills under [`skills/`](/home/zh/src/codex-plugin/skills)
- No bundled MCP servers. This plugin ships skills only.
- Optional external-agent bridge script: [`scripts/claude-print.sh`](/home/zh/src/codex-plugin/scripts/claude-print.sh)

## Install locally

1. Add this repo to your personal plugin marketplace:

```json
{
  "name": "personal",
  "interface": {
    "displayName": "Personal Plugins"
  },
  "plugins": [
    {
      "name": "codex-plugin",
      "source": {
        "source": "local",
        "path": "/home/zh/src/codex-plugin"
      },
      "policy": {
        "installation": "AVAILABLE",
        "authentication": "ON_INSTALL"
      },
      "category": "Developer Tools"
    }
  ]
}
```

Write that to `~/.agents/plugins/marketplace.json`, then open Codex and use `/plugins` to install `codex-plugin`.

2. Keep user-level defaults in `~/.codex/config.toml`.

Suggested pattern:

```toml
model = "gpt-5.4"
approval_policy = "on-request"
sandbox_mode = "workspace-write"

[agents]
max_threads = 6
max_depth = 1
```

Default workflow model policy in this plugin:

- Main coding/planning agent: `gpt-5.3-codex` with `xhigh` reasoning
- Review agent 1: `gpt-5.3-codex` with `xhigh` reasoning
- Review agent 2: `gpt-5.4` with `xhigh` reasoning

3. Put custom agents in `~/.codex/agents/`.

Example reviewer:

```toml
name = "reviewer"
description = "Focused PR reviewer."
model = "gpt-5.4"
model_reasoning_effort = "high"
sandbox_mode = "read-only"
developer_instructions = """
Review for correctness, regressions, and missing tests.
Do not make edits.
"""
```

## Refresh local install

If Codex does not automatically pick up local plugin changes, sync the repo into the
installed cache and restart Codex:

```bash
~/src/codex-plugin/scripts/sync-local-install.sh
```

This mirrors the repo into `~/.codex/plugins/cache/personal/codex-plugin/<version>/`.
Codex reloads plugins on startup, so start a new session after syncing.

## Sharing across machines

- Sync this repo itself via git.
- Sync `~/.codex/config.toml` via dotfiles, but keep secrets out of the file when possible.
- Prefer environment-backed MCP auth instead of hardcoded tokens.
- Sync `~/.codex/agents/` and `~/.agents/plugins/marketplace.json` with the same dotfiles setup.

## Native reviewers

This plugin now assumes review and implementation loops stay entirely inside Codex.

If you ever want an external model cross-check later, keep it behind a narrow wrapper and treat it as an external tool, not a native subagent.
