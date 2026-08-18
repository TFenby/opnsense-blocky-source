#!/bin/sh

set -eu

# Packages the upstream blocky binary only. Everything we author (rc.d script,
# config sample, plugin glue) lives in os-blocky-tfenby so that it is versioned
# by PLUGIN_VERSION rather than by the upstream blocky release.

VERSION="${1:-$(sed 's/^v//' BLOCKY_VERSION | tr -d '[:space:]')}"
REVISION="${2:-0}"
BLOCKY_BIN="${3:-staging/bin/blocky}"

# Follows the host ABI (FreeBSD:15:amd64 on OPNsense 26.7) unless overridden,
# so the package is never pinned to a base release again.
ABI="${PKG_ABI:-$(pkg config abi)}"

STAGE="$(mktemp -d)"
META="$(mktemp -d)"
OUTDIR="dist/${ABI}"

trap "rm -rf ${STAGE} ${META}" EXIT

mkdir -p "${STAGE}/usr/local/sbin"
mkdir -p "${OUTDIR}"

cp "${BLOCKY_BIN}" "${STAGE}/usr/local/sbin/blocky"
chmod 755 "${STAGE}/usr/local/sbin/blocky"

if [ "${REVISION}" = "0" ]; then
	PKG_VERSION="${VERSION}"
else
	PKG_VERSION="${VERSION}_${REVISION}"
fi

cat > "${META}/+MANIFEST" << EOF
name: "blocky-tfenby"
version: "${PKG_VERSION}"
origin: "dns/blocky-tfenby"
comment: "Fast and lightweight DNS proxy and ad-blocker"
arch: "${ABI}"
prefix: "/usr/local"
www: "https://0xerr0r.github.io/blocky/"
maintainer: "opnsense@fenby.me"
licenselogic: "single"
licenses: [ "Apache-2.0" ]
desc: "Blocky is a DNS proxy and ad-blocker for the local network."
EOF

cat > "${META}/plist" << EOF
sbin/blocky
EOF

cat > "${META}/+DESC" << EOF
Blocky is a DNS proxy and ad-blocker for the local network.
EOF

pkg create -v -m "${META}" -r "${STAGE}" -p "${META}/plist" -o "${OUTDIR}"

echo ">>> Package created: ${OUTDIR}/blocky-tfenby-${PKG_VERSION}.pkg"
