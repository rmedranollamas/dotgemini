---
name: policy-manager
description: Manage and consolidate Gemini CLI run_shell_command policies. Use this skill to merge auto-saved policies into the main shell.toml, deduplicate prefixes, and ensure basenames are allowed for full-path commands.
---

# Policy Manager

This skill provides a reliable way to keep your `run_shell_command` policies clean and consolidated.

## Workflows

### Consolidate Policies
When new commands are added to `policies/auto-saved.toml`, the model should merge them into `policies/shell.toml`.

1. **Extract new prefixes** from `policies/auto-saved.toml`.
2. **Merge** them into the `commandPrefix` list in `policies/shell.toml`.
3. **Ensure Dual Entries**: For every command, include both its basename (e.g., `ls`) and its full path (e.g., `/usr/bin/ls`). Use `which` to resolve paths.
4. **Deduplicate and Sort** the final list.
5. **Verify** that `policies/shell.toml` contains the updated list and preserve other tool rules.
6. **Reset** `policies/auto-saved.toml` to a clean state (usually just the `enter_plan_mode` rule).
