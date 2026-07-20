#!/usr/bin/env bash
#
# bump-release.sh
# Helper to bump and push a semantic-version tag locally.
#
# Consumers of this library pin to a major tag (e.g. @v1). Maintainers move that
# major tag forward as releases are cut. This script:
#   * finds the latest vX.Y.Z tag,
#   * bumps major|minor|patch (default: patch),
#   * creates the new vX.Y.Z tag AND updates the floating major tag (vX),
#   * optionally pushes.
#
# Usage:
#   scripts/bump-release.sh [major|minor|patch] [--push]
#
# Examples:
#   scripts/bump-release.sh minor         # create tag locally only
#   scripts/bump-release.sh patch --push  # create + push tag and floating major
set -euo pipefail

BUMP="${1:-patch}"
PUSH="false"
for arg in "$@"; do
  [ "${arg}" = "--push" ] && PUSH="true"
done

case "${BUMP}" in
  major|minor|patch) ;;
  *) echo "Usage: $0 [major|minor|patch] [--push]" >&2; exit 2 ;;
esac

git fetch --tags --quiet || true

LATEST="$(git tag --list 'v[0-9]*.[0-9]*.[0-9]*' --sort=-v:refname | head -n1)"
if [ -z "${LATEST}" ]; then
  LATEST="v0.0.0"
  echo "No existing semver tag found; starting from ${LATEST}"
fi

VER="${LATEST#v}"
MAJOR="${VER%%.*}"
REST="${VER#*.}"
MINOR="${REST%%.*}"
PATCH="${REST##*.}"

case "${BUMP}" in
  major) MAJOR=$((MAJOR + 1)); MINOR=0; PATCH=0 ;;
  minor) MINOR=$((MINOR + 1)); PATCH=0 ;;
  patch) PATCH=$((PATCH + 1)) ;;
esac

NEW="v${MAJOR}.${MINOR}.${PATCH}"
FLOATING="v${MAJOR}"

echo "Latest: ${LATEST}  ->  New: ${NEW}  (floating major: ${FLOATING})"

git tag -a "${NEW}" -m "Release ${NEW}"
# Move the floating major tag to the new release commit.
git tag -f -a "${FLOATING}" -m "Update floating major tag ${FLOATING} -> ${NEW}"

if [ "${PUSH}" = "true" ]; then
  git push origin "${NEW}"
  git push origin -f "${FLOATING}"
  echo "Pushed ${NEW} and ${FLOATING}."
else
  echo "Created ${NEW} and ${FLOATING} locally. Re-run with --push to publish."
fi
