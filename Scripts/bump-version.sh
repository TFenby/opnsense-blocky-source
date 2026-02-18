#!/usr/bin/env bash

set -euo pipefail

PLUGIN_MAKEFILE="dns/blocky-tfenby/Makefile"

die() { echo "error: $*" >&2; exit 1; }

usage() {
	cat <<-EOF
	Usage: bump-version.sh [options] [VERSION]

	Bump the plugin version or revision, commit, tag, and push.

	Options:
	  -r, --revision    Bump revision only (1.5_2 → 1.5_3)
	  -y, --yes         Skip confirmation prompt
	  -h, --help        Show this help

	Arguments:
	  VERSION           Target version, e.g. 2.0 or v2.0
	                    Auto-increments minor version if omitted

	Examples:
	  bump-version.sh              1.5 → 1.6
	  bump-version.sh 2.0          1.5_2 → 2.0
	  bump-version.sh -r           1.5_2 → 1.5_3
	EOF
	exit 0
}

current_version() {
	grep '^PLUGIN_VERSION=' "$PLUGIN_MAKEFILE" | sed 's/.*=[[:space:]]*//'
}

current_revision() {
	local rev
	rev=$(grep '^PLUGIN_REVISION=' "$PLUGIN_MAKEFILE" | sed 's/.*=[[:space:]]*//' || true)
	echo "${rev:-0}"
}

confirm_push() {
	local tag="$1"
	if [[ "$skip_confirm" != true ]]; then
		read -rp "Push commit and tag ${tag}? [y/N] " answer
		[[ "$answer" =~ ^[Yy]$ ]] || die "cancelled"
	fi
	git push origin main "$tag"
}

display_version() {
	local ver rev
	ver=$(current_version)
	rev=$(current_revision)
	if [[ "$rev" != "0" ]]; then
		echo "${ver}_${rev}"
	else
		echo "$ver"
	fi
}

bump_revision=false
skip_confirm=false
version_arg=""

while [[ $# -gt 0 ]]; do
	case "$1" in
		-r|--revision) bump_revision=true; shift ;;
		-y|--yes)      skip_confirm=true; shift ;;
		-h|--help)     usage ;;
		-*)            die "unknown option: $1" ;;
		*)             version_arg="$1"; shift ;;
	esac
done

[[ -f "$PLUGIN_MAKEFILE" ]] || die "must be run from the repository root"
[[ -z "$(git status --porcelain)" ]] || die "working tree is dirty — commit or stash first"
[[ "$(git branch --show-current)" == "main" ]] || die "not on main branch"

current_ver=$(current_version)
current_rev=$(current_revision)
current_display=$(display_version)

if [[ "$bump_revision" == true ]]; then
	[[ -z "$version_arg" ]] || die "--revision and VERSION are mutually exclusive"

	new_rev=$((current_rev + 1))
	tag_version="${current_ver}_${new_rev}"

	[[ -z "$(git tag -l "plugin-v${tag_version}")" ]] || die "tag plugin-v${tag_version} already exists"

	echo "==> Bumping revision: ${current_display} → ${tag_version}"

	if grep -q '^PLUGIN_REVISION=' "$PLUGIN_MAKEFILE"; then
		sed "s/^PLUGIN_REVISION=.*/PLUGIN_REVISION=    ${new_rev}/" "$PLUGIN_MAKEFILE" > "${PLUGIN_MAKEFILE}.tmp"
	else
		awk -v rev="$new_rev" '
			/^PLUGIN_VERSION=/ { print; print "PLUGIN_REVISION=    " rev; next }
			1' "$PLUGIN_MAKEFILE" > "${PLUGIN_MAKEFILE}.tmp"
	fi
	mv "${PLUGIN_MAKEFILE}.tmp" "$PLUGIN_MAKEFILE"

	git add "$PLUGIN_MAKEFILE"
	git commit -m "Bump plugin revision to ${tag_version}"
	git tag -a "plugin-v${tag_version}" -m "Plugin version ${tag_version}"
	confirm_push "plugin-v${tag_version}"
else
	if [[ -n "$version_arg" ]]; then
		new_version="${version_arg#v}"
	else
		major=$(echo "$current_ver" | cut -d. -f1)
		minor=$(echo "$current_ver" | cut -d. -f2)
		new_version="${major}.$((minor + 1))"
	fi

	[[ "$new_version" =~ ^[0-9]+\.[0-9]+$ ]] || die "version must be X.Y (got: $new_version)"
	[[ "$new_version" != "$current_ver" ]] || die "already at version $current_ver"
	[[ -z "$(git tag -l "plugin-v${new_version}")" ]] || die "tag plugin-v${new_version} already exists"

	echo "==> Bumping version: ${current_display} → ${new_version}"

	sed "s/^PLUGIN_VERSION=.*/PLUGIN_VERSION=     ${new_version}/" "$PLUGIN_MAKEFILE" > "${PLUGIN_MAKEFILE}.tmp"
	mv "${PLUGIN_MAKEFILE}.tmp" "$PLUGIN_MAKEFILE"

	if grep -q '^PLUGIN_REVISION=' "$PLUGIN_MAKEFILE"; then
		sed '/^PLUGIN_REVISION=/d' "$PLUGIN_MAKEFILE" > "${PLUGIN_MAKEFILE}.tmp"
		mv "${PLUGIN_MAKEFILE}.tmp" "$PLUGIN_MAKEFILE"
	fi

	git add "$PLUGIN_MAKEFILE"
	git commit -m "Bump plugin version to ${new_version}"
	git tag -a "plugin-v${new_version}" -m "Plugin version ${new_version}"
	confirm_push "plugin-v${new_version}"
fi

echo "==> Done. CI build will start."
