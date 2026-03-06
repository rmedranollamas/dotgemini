---
name: policy-manager
description: Manage and consolidate Gemini CLI run_shell_command policies. Use this skill to merge auto-saved policies into the main shell.toml, deduplicate prefixes, and ensure basenames are allowed for full-path commands.
---

# Policy Manager

This skill provides a reliable way to keep your `run_shell_command` policies clean and consolidated.

## Workflows

### Consolidate Policies
When new commands are added to `policies/auto-saved.toml`, use this workflow to move them to `policies/shell.toml`.

1. Run the consolidation script:
   ```bash
   python3 skills/policy-manager/scripts/consolidate_policies.py
   ```
2. Verify that `policies/shell.toml` contains the updated list.
3. Verify that `policies/auto-saved.toml` has been reset.

## Scripts
- `scripts/consolidate_policies.py`: The core logic for merging and cleaning up policy files.
