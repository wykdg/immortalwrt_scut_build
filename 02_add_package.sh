#!/usr/bin/env bash
set -euo pipefail

package_file="${PACKAGE_FILE:-../package.conf}"
[[ -f "$package_file" ]] || { echo "Package list not found: $package_file" >&2; exit 1; }

awk '
	/^[[:space:]]*#/ || NF == 0 { next }
	$1 == "luci-app-mosdns" || $1 == "luci-app-openvpn-server" || $1 == "luci-app-passwall_INCLUDE_Xray" { next }
	{ print "CONFIG_PACKAGE_" $1 "=y" }
' "$package_file" >> .config

# Passwall defaults Xray to y on these targets; force the requested single-box setup.
cat >> .config <<'EOF'
CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Xray=n
CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Xray_Plugin=n
CONFIG_PACKAGE_xray-core=n
CONFIG_PACKAGE_xray-plugin=n
CONFIG_PACKAGE_luci-app-mosdns=n
CONFIG_PACKAGE_luci-app-openvpn-server=n
EOF
