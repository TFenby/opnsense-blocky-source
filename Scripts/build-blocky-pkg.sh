#!/bin/sh

set -eu

VERSION="${1:-0.28.2}"
REVISION="${2:-0}"
BLOCKY_BIN="${3:-staging/bin/blocky}"

SCRIPTSDIR="$(dirname "$0")"
PORTSDIR="$(cd "${SCRIPTSDIR}/.." && pwd)"

STAGE="$(mktemp -d)"
META="$(mktemp -d)"
OUTDIR="dist/FreeBSD:14:amd64"

trap "rm -rf ${STAGE} ${META}" EXIT

mkdir -p "${STAGE}/usr/local/bin"
mkdir -p "${STAGE}/usr/local/etc/rc.d"
mkdir -p "${STAGE}/usr/local/etc/blocky"
mkdir -p "${OUTDIR}"

cp "${BLOCKY_BIN}" "${STAGE}/usr/local/bin/blocky"
cp blocky/etc/rc.d/blocky "${STAGE}/usr/local/etc/rc.d/blocky"
cp blocky/etc/blocky/config.yml.sample "${STAGE}/usr/local/etc/blocky/config.yml.sample"

chmod 755 "${STAGE}/usr/local/bin/blocky"
chmod 755 "${STAGE}/usr/local/etc/rc.d/blocky"

if [ "${REVISION}" = "0" ]; then
	PKG_VERSION="${VERSION}"
else
	PKG_VERSION="${VERSION}_${REVISION}"
fi

cat > "${META}/+MANIFEST" << EOF
name: "blocky"
version: "${PKG_VERSION}"
origin: "dns/blocky"
comment: "Fast and lightweight DNS proxy and ad-blocker"
arch: "freebsd:14:amd64"
prefix: "/usr/local"
www: "https://0xerr0r.github.io/blocky/"
maintainer: "opnsense@gfenby.me"
licenselogic: "single"
licenses: [ "Apache-2.0" ]
desc: "Blocky is a DNS proxy and ad-blocker for the local network."
EOF

cat > "${META}/plist" << EOF
/usr/local/bin/blocky
/usr/local/etc/rc.d/blocky
@sample /usr/local/etc/blocky/config.yml.sample
@dir /usr/local/etc/blocky
EOF

cat > "${META}/+DESC" << EOF
Blocky is a DNS proxy and ad-blocker for the local network.
EOF

PORTSDIR="${PORTSDIR}" pkg create -v -m "${META}" -r "${STAGE}" -p "${META}/plist" -o "${OUTDIR}"

echo ">>> Package created: ${OUTDIR}/blocky-${PKG_VERSION}.pkg"
