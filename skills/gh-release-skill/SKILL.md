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
   - Use GitHub Actions for automated release creation (preferred).

## Ecosystem Specifics

### Node.js

- **Version File**: `package.json`
- **Bumping**: Use `npm version patch|minor|major`.
- **CI/CD**: Often uses `Changesets` or `Semantic Release`.

### Python

- **Version File**: `pyproject.toml` or `__init__.py`.
- **Tooling**: Use `uv` or `poetry` for environment management.
- **PyInstaller Multi-Arch Builds**: PyInstaller cannot truly cross-compile. For reliable multi-architecture builds (e.g., `linux-arm64`), use dedicated runners for each target architecture (e.g., `runs-on: ubuntu-latest-arm64`) instead of emulation. **Note**: GitHub Actions automation for this can be unreliable; manual intervention may be required.

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

- **Automation**: Prefer triggering releases via tags to let CI handle binary builds and checksums. However, be prepared for automation failures and manual intervention for specific platforms.
- **Notes**: Use `--generate-notes` to automatically pull in PR titles and contributors.
- **Safety**: Never force-push tags unless absolutely necessary.
- **Troubleshooting Automated Releases**: If automated release creation fails in GitHub Actions (e.g., `release not found`, "tag_name immutable" errors), inspect workflow logs closely. Manual intervention might be necessary:
  1. Ensure all build jobs complete and artifacts are uploaded.
  1. If the release job fails, manually create the release and upload artifacts using `gh release create <tag> ...` and `gh release upload <tag> <file> ...`.
  1. If a tag prevents release creation, try deleting and recreating the tag, or create a new version tag.
