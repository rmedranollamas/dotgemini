______________________________________________________________________

## name: gh-release-skill description: "Universal GitHub release workflow: versioning, tagging, and creating releases using the gh CLI across multiple ecosystems (Node, Python, Go, Rust). Use when cutting new software versions."

# Universal GitHub Release Workflow

This skill provides a standardized workflow for releasing software on GitHub across different programming environments.

## Core Release Steps

Regardless of the language, follow these core steps:

1. **Preparation**:
   - Verify all tests pass: `npm test`, `pytest`, `cargo test`, or `go test`.
   - Ensure the working directory is clean: `git status`.
1. **Version Bump**:
   - Identify the version file (e.g., `package.json`, `pyproject.toml`, `Cargo.toml`).
   - Bump the version according to Semantic Versioning (Major.Minor.Patch).
   - Update any lockfiles (e.g., `npm install`, `uv sync`, `cargo check`).
1. **Source Control**:
   - Stage and commit: `git add . && git commit -m "Chore: release vX.Y.Z"`
   - Push to main: `git push origin main`
1. **Tagging & Release**:
   - Create and push the tag: `git tag vX.Y.Z && git push origin vX.Y.Z`
   - Create the GitHub Release:
     ```bash
     gh release create vX.Y.Z --generate-notes
     ```

## Ecosystem Specifics

### Node.js

- **Version File**: `package.json`
- **Bumping**: Use `npm version patch|minor|major`.
- **CI/CD**: Often uses `Changesets` or `Semantic Release`.

### Python

- **Version File**: `pyproject.toml` or `__init__.py`.
- **Tooling**: Use `uv` or `poetry` for environment management.
- **Patterns**: Ensure entry points (like `run.py` for PyInstaller) are updated if necessary.

### Go

- **Tooling**: `GoReleaser` is the standard.
- **Workflow**: Tagging often triggers a full build/release pipeline.

### Rust

- **Version File**: `Cargo.toml`
- **Tooling**: `cargo-release` or `release-plz`.

## Advanced `gh` CLI Usage

- **Upload Assets**: `gh release create v1.0.0 ./dist/*`
- **Prerelease**: Add `--prerelease` for beta/rc versions.
- **Draft**: Add `--draft` to review before publishing.
- **Discussion**: Use `--discussion-category "Announcements"` to notify the community.

## Best Practices

- **Automation**: Prefer triggering releases via tags to let CI handle binary builds and checksums.
- **Notes**: Use `--generate-notes` to automatically pull in PR titles and contributors.
- **Safety**: Never force-push tags unless absolutely necessary.
