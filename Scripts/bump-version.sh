#!/bin/sh

set -eu

PLUGIN_MAKEFILE="dns/blocky-tfenby/Makefile"

# --- helpers ---

die() { echo "Error: $*" >&2; exit 1; }

current_version() {
	grep '^PLUGIN_VERSION=' "$PLUGIN_MAKEFILE" | sed 's/.*=[[:space:]]*//'
}

# --- preflight ---

test -f "$PLUGIN_MAKEFILE" || die "must be run from the repository root"
test -z "$(git status --porcelain)" || die "working tree is dirty — commit or stash first"
test "$(git branch --show-current)" = "main" || die "not on main branch"

# --- resolve version ---

CURRENT=$(current_version)

if [ -n "${1:-}" ]; then
	VERSION="$1"
else
	MAJOR=$(echo "$CURRENT" | cut -d. -f1)
	MINOR=$(echo "$CURRENT" | cut -d. -f2)
	VERSION="${MAJOR}.$((MINOR + 1))"
fi

echo "$VERSION" | grep -qE '^[0-9]+\.[0-9]+$' || die "VERSION must be X.Y (got: $VERSION)"
test "$VERSION" != "$CURRENT" || die "version is already $CURRENT"
git tag -l "plugin-v${VERSION}" | grep -q . && die "tag plugin-v${VERSION} already exists"

# --- apply ---

echo "==> Bumping plugin version: ${CURRENT} -> ${VERSION}"

sed "s/^PLUGIN_VERSION=.*/PLUGIN_VERSION=     ${VERSION}/" "$PLUGIN_MAKEFILE" > "${PLUGIN_MAKEFILE}.tmp"
mv "${PLUGIN_MAKEFILE}.tmp" "$PLUGIN_MAKEFILE"

git add "$PLUGIN_MAKEFILE"
git commit -m "Bump plugin version to ${VERSION}"
git tag -a "plugin-v${VERSION}" -m "Plugin version ${VERSION}"
git push origin main "plugin-v${VERSION}"

echo "==> Done. Tag plugin-v${VERSION} pushed — CI build will start."
