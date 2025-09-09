# Versioning Policy (SemVer)

We use **Semantic Versioning**: `MAJOR.MINOR.PATCH`

- **MAJOR** — Incompatible API changes, large refactors, or user‑visible breaking changes.
- **MINOR** — Backward‑compatible feature additions.
- **PATCH** — Backward‑compatible bug fixes or small tweaks.

Optional:
- **Pre‑release tags**: `-alpha.1`, `-beta.2`, `-rc.1`
- **Build metadata**: `+build.20250908` (not used for precedence)

## Flutter project specifics

Flutter reads the version from `pubspec.yaml` like:
```
version: 1.2.3+45
```
- `1.2.3` is the SemVer visible to users.
- `+45` is the build number (Android `versionCode` / iOS `CFBundleVersion`). Increase it on every release you ship to a store.

## Workflow

1. Make changes and commit using short, descriptive Conventional Commit messages (recommended):
   - `feat(profile): add camera preview`
   - `fix(camera): handle permission denial`
   - `chore(build): bump version to 0.2.1`
2. Update `pubspec.yaml` version.
3. Update `CHANGELOG.md`:
   - Move items from **Unreleased** into a new section for the version.
4. Commit the version bump and changelog:
   ```bash
   git add pubspec.yaml CHANGELOG.md
   git commit -m "chore(release): vX.Y.Z"
   git tag vX.Y.Z
   git push && git push --tags
   ```

## How to bump versions

Use the helper script `bump_version.sh` in the repo root:
```
./bump_version.sh patch
./bump_version.sh minor
./bump_version.sh major
```
It:
- Reads the current `version:` line in `pubspec.yaml`
- Increments MAJOR/MINOR/PATCH accordingly
- Increments the build number by 1 automatically
- Writes the new version back

_If your `pubspec.yaml` stores the version differently, adjust the script's regex near the top._

## Example

- Start at `0.1.0+1` for early development.
- Add a feature (no break): `0.2.0+2`
- Fix a bug: `0.2.1+3`
- Make a breaking change: `1.0.0+4`

