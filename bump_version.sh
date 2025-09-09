#!/usr/bin/env bash
set -euo pipefail

# Simple SemVer bumper for Flutter pubspec.yaml
# Usage: ./bump_version.sh [major|minor|patch]
# Increments the build number by 1 automatically.
# Requires: bash, grep, sed, awk

LEVEL="${1:-patch}"
PUBSPEC="pubspec.yaml"

if [[ ! -f "$PUBSPEC" ]]; then
  echo "pubspec.yaml not found in current directory."
  exit 1
fi

# Extract the version line: version: X.Y.Z+N
VERSION_LINE=$(grep -E '^version:\s*[0-9]+\.[0-9]+\.[0-9]+(\+[0-9]+)?\s*$' "$PUBSPEC" || true)
if [[ -z "$VERSION_LINE" ]]; then
  echo "Could not find a 'version: X.Y.Z+N' line in pubspec.yaml"
  exit 1
fi

CURRENT=$(echo "$VERSION_LINE" | awk '{print $2}')
BASE="${CURRENT%%+*}"           # X.Y.Z
BUILD="${CURRENT##*+}"          # N or same as CURRENT if no '+'
if [[ "$BUILD" == "$BASE" ]]; then
  BUILD=0
fi

IFS='.' read -r MAJOR MINOR PATCH <<< "$BASE"

case "$LEVEL" in
  major)
    MAJOR=$((MAJOR+1))
    MINOR=0
    PATCH=0
    ;;
  minor)
    MINOR=$((MINOR+1))
    PATCH=0
    ;;
  patch)
    PATCH=$((PATCH+1))
    ;;
  *)
    echo "Unknown level '$LEVEL' (use major|minor|patch)"
    exit 1
    ;;
esac

BUILD=$((BUILD+1))

NEW_VERSION="${MAJOR}.${MINOR}.${PATCH}+${BUILD}"

# Replace in pubspec.yaml
# Works by replacing the entire version line with the new value.
sed -i.bak -E "s/^version:\s*[0-9]+\.[0-9]+\.[0-9]+(\+[0-9]+)?\s*$/version: ${NEW_VERSION}/" "$PUBSPEC"

echo "Bumped version: ${CURRENT} -> ${NEW_VERSION}"
echo "Don't forget to update CHANGELOG.md and tag the release:"
echo "  git add pubspec.yaml CHANGELOG.md"
echo "  git commit -m \"chore(release): v${MAJOR}.${MINOR}.${PATCH}\""
echo "  git tag v${MAJOR}.${MINOR}.${PATCH}"
echo "  git push && git push --tags"
