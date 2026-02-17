#!/bin/sh

set -eu

PLUGIN_MAKEFILE="dns/blocky-tfenby/Makefile"

# --- helpers ---

die() { echo "Error: $*" >&2; exit 1; }

current_version() {
	grep '^PLUGIN_VERSION=' "$PLUGIN_MAKEFILE" | sed 's/.*=[[:space:]]*//'
}

current_revision() {
	REV=$(grep '^PLUGIN_REVISION=' "$PLUGIN_MAKEFILE" | sed 's/.*=[[:space:]]*//' || true)
	echo "${REV:-0}"
}

# --- preflight ---

test -f "$PLUGIN_MAKEFILE" || die "must be run from the repository root"
test -z "$(git status --porcelain)" || die "working tree is dirty — commit or stash first"
test "$(git branch --show-current)" = "main" || die "not on main branch"

# --- resolve target ---

CURRENT_VER=$(current_version)
CURRENT_REV=$(current_revision)

if [ "$CURRENT_REV" != "0" ]; then
	CURRENT_DISPLAY="${CURRENT_VER}_${CURRENT_REV}"
else
	CURRENT_DISPLAY="$CURRENT_VER"
fi

if [ "${1:-}" = "--revision" ]; then
	# --- revision bump: keep version, increment revision ---
	REVISION=$((CURRENT_REV + 1))
	TAG_VERSION="${CURRENT_VER}_${REVISION}"
	git tag -l "plugin-v${TAG_VERSION}" | grep -q . && die "tag plugin-v${TAG_VERSION} already exists"

	echo "==> Bumping plugin revision: ${CURRENT_DISPLAY} -> ${TAG_VERSION}"

	if grep -q '^PLUGIN_REVISION=' "$PLUGIN_MAKEFILE"; then
		sed "s/^PLUGIN_REVISION=.*/PLUGIN_REVISION=    ${REVISION}/" "$PLUGIN_MAKEFILE" > "${PLUGIN_MAKEFILE}.tmp"
	else
		awk -v rev="$REVISION" '
			/^PLUGIN_VERSION=/ { print; print "PLUGIN_REVISION=    " rev; next }
			1' "$PLUGIN_MAKEFILE" > "${PLUGIN_MAKEFILE}.tmp"
	fi
	mv "${PLUGIN_MAKEFILE}.tmp" "$PLUGIN_MAKEFILE"

	git add "$PLUGIN_MAKEFILE"
	git commit -m "Bump plugin revision to ${TAG_VERSION}"
	git tag -a "plugin-v${TAG_VERSION}" -m "Plugin version ${TAG_VERSION}"
	git push origin main "plugin-v${TAG_VERSION}"

	echo "==> Done. Tag plugin-v${TAG_VERSION} pushed — CI build will start."
else
	# --- version bump: bump version, reset revision ---
	if [ -n "${1:-}" ]; then
		VERSION="$1"
	else
		MAJOR=$(echo "$CURRENT_VER" | cut -d. -f1)
		MINOR=$(echo "$CURRENT_VER" | cut -d. -f2)
		VERSION="${MAJOR}.$((MINOR + 1))"
	fi

	echo "$VERSION" | grep -qE '^[0-9]+\.[0-9]+$' || die "VERSION must be X.Y (got: $VERSION)"
	test "$VERSION" != "$CURRENT_VER" || die "version is already $CURRENT_VER"
	git tag -l "plugin-v${VERSION}" | grep -q . && die "tag plugin-v${VERSION} already exists"

	echo "==> Bumping plugin version: ${CURRENT_DISPLAY} -> ${VERSION}"

	sed "s/^PLUGIN_VERSION=.*/PLUGIN_VERSION=     ${VERSION}/" "$PLUGIN_MAKEFILE" > "${PLUGIN_MAKEFILE}.tmp"
	mv "${PLUGIN_MAKEFILE}.tmp" "$PLUGIN_MAKEFILE"

	# Reset revision (remove explicit line; plugins.mk defaults to 0)
	if grep -q '^PLUGIN_REVISION=' "$PLUGIN_MAKEFILE"; then
		sed '/^PLUGIN_REVISION=/d' "$PLUGIN_MAKEFILE" > "${PLUGIN_MAKEFILE}.tmp"
		mv "${PLUGIN_MAKEFILE}.tmp" "$PLUGIN_MAKEFILE"
	fi

	git add "$PLUGIN_MAKEFILE"
	git commit -m "Bump plugin version to ${VERSION}"
	git tag -a "plugin-v${VERSION}" -m "Plugin version ${VERSION}"
	git push origin main "plugin-v${VERSION}"

	echo "==> Done. Tag plugin-v${VERSION} pushed — CI build will start."
fi
