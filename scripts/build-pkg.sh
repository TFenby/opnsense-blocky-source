#!/bin/sh
set -e

PKG_NAME="$1"
PLUGIN_VERSION="$2"
PLUGIN_REVISION="$3"
PKG_FILENAME="$4"
BLOCKY_BIN="$5"

ABI="FreeBSD:14:amd64"
STAGE=$(mktemp -d)
DIST="dist/${ABI}"

mkdir -p "${DIST}"
mkdir -p "${STAGE}/usr/local/bin"
mkdir -p "${STAGE}/usr/local/etc/blocky"
mkdir -p "${STAGE}/usr/local/etc/rc.d"
mkdir -p "${STAGE}/usr/local/etc/inc/plugins.inc.d"
mkdir -p "${STAGE}/usr/local/opnsense/version"
mkdir -p "${STAGE}/usr/local/opnsense/mvc/app/controllers/OPNsense/Blocky/Api"
mkdir -p "${STAGE}/usr/local/opnsense/mvc/app/controllers/OPNsense/Blocky/forms"
mkdir -p "${STAGE}/usr/local/opnsense/mvc/app/models/OPNsense/Blocky/ACL"
mkdir -p "${STAGE}/usr/local/opnsense/mvc/app/models/OPNsense/Blocky/Menu"
mkdir -p "${STAGE}/usr/local/opnsense/mvc/app/views/OPNsense/Blocky"
mkdir -p "${STAGE}/usr/local/opnsense/service/conf/actions.d"
mkdir -p "${STAGE}/usr/local/opnsense/service/templates/OPNsense/Blocky"

cp "${BLOCKY_BIN}" "${STAGE}/usr/local/bin/blocky"
chmod 755 "${STAGE}/usr/local/bin/blocky"

if [ -d "src" ]; then
  cp -R src/opnsense/ "${STAGE}/usr/local/opnsense/" 2>/dev/null || true
  cp -R src/etc/ "${STAGE}/usr/local/etc/" 2>/dev/null || true
fi

cat > "${STAGE}/usr/local/opnsense/version/blocky" <<VEOF
{
  "product_id": "${PKG_NAME}",
  "product_name": "blocky-tfen",
  "product_version": "${PLUGIN_VERSION}",
  "product_revision": "${PLUGIN_REVISION}",
  "product_abi": "25.7"
}
VEOF

cd "${STAGE}"
find usr -type f | sort > /tmp/plist
cd -

FLATSIZE=$(find "${STAGE}" -type f -exec stat -f %z {} + | awk '{s+=$1}END{print s}')

cat > "${STAGE}/+COMPACT_MANIFEST" <<MEOF
{
  "name": "${PKG_NAME}",
  "origin": "opnsense/${PKG_NAME}",
  "version": "${PLUGIN_VERSION}_${PLUGIN_REVISION}",
  "comment": "Blocky DNS plugin for OPNsense",
  "maintainer": "opnsense@gfenby.me",
  "www": "https://0xerr0r.github.io/blocky/",
  "abi": "${ABI}",
  "arch": "freebsd:14:x86:64",
  "prefix": "/usr/local",
  "flatsize": ${FLATSIZE},
  "licenselogic": "single",
  "licenses": ["BSD2CLAUSE"],
  "desc": "Blocky DNS proxy and ad-blocker plugin for OPNsense",
  "categories": ["dns"],
  "annotations": {
    "product_abi": "25.7",
    "product_id": "${PKG_NAME}",
    "product_name": "blocky-tfen",
    "product_tier": "3",
    "product_version": "${PLUGIN_VERSION}"
  }
}
MEOF

cp "${STAGE}/+COMPACT_MANIFEST" "${STAGE}/+MANIFEST"

pkg create -v -m "${STAGE}" -r "${STAGE}" -p /tmp/plist -o "${DIST}"

if [ ! -f "${DIST}/${PKG_FILENAME}" ]; then
  FOUND=$(ls "${DIST}"/*.pkg 2>/dev/null | head -1)
  if [ -n "$FOUND" ]; then
    mv "$FOUND" "${DIST}/${PKG_FILENAME}"
  fi
fi

pkg repo "${DIST}"

ls -la "${DIST}"
echo "Package built: ${PKG_FILENAME}"
