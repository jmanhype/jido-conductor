# Contributing to JIDO Conductor

## Commit Message Format

This repository enforces **Conventional Commits** for automatic semantic versioning and changelog generation.

### Format
```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types
- **feat**: A new feature (triggers MINOR version bump)
- **fix**: A bug fix (triggers PATCH version bump)
- **docs**: Documentation only changes
- **style**: Changes that don't affect code meaning (white-space, formatting)
- **refactor**: Code change that neither fixes a bug nor adds a feature
- **perf**: Performance improvements (triggers PATCH version bump)
- **test**: Adding or updating tests
- **build**: Changes to build system or dependencies
- **ci**: Changes to CI configuration files
- **chore**: Other changes that don't modify src or test files
- **revert**: Reverts a previous commit (triggers PATCH version bump)

### Breaking Changes
Add `BREAKING CHANGE:` in the footer or `!` after the type to trigger a MAJOR version bump:
```
feat!: remove support for Node 16

BREAKING CHANGE: Node 16 is no longer supported. Minimum version is now Node 18.
```

### Examples

#### Feature
```
feat(auth): add OAuth2 integration

Implemented Google and GitHub OAuth providers
with automatic token refresh
```

#### Fix
```
fix(ui): correct button alignment on mobile

Buttons were overlapping on screens < 400px
```

#### Breaking Change
```
feat(api)!: change response format to JSON

BREAKING CHANGE: API now returns JSON instead of XML.
Update all client applications to handle JSON responses.
```

## Version Bumping

Based on your commits:
- `fix:`, `perf:`, `revert:` → Patch release (0.0.X)
- `feat:` → Minor release (0.X.0)
- `BREAKING CHANGE:` or `!` → Major release (X.0.0)

## Automated Releases

When commits are pushed to `main`, semantic-release will:
1. Analyze commit messages
2. Determine version bump type
3. Update version in package.json and other files
4. Generate CHANGELOG.md
5. Create GitHub release with notes
6. Tag the release

## Pre-commit Hooks

This repository uses husky and commitlint to validate commit messages.
If your commit message doesn't follow the convention, it will be rejected.

To bypass hooks in emergency (not recommended):
```bash
git commit --no-verify -m "your message"
```