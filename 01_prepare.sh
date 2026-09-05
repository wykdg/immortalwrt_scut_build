#!/usr/bin/env bash
set -euo pipefail

# Keep the old 21.02 build reproducible while replacing only the moving feeds.
KENZO_COMMIT="11660fafed3c3f77cf9c7ce1d0c4d86dc25ec034"
SMALL_COMMIT="49dccb502c9bdfc19770e790d9b1b1af6619c8a1"
GOLANG_COMMIT="17077f28edf4f18be1cb490253e76e7f14876459"
PASSWALL_COMMIT="8347d3034f2ec6ef87dd1eca41a93017ae85fc4e"
PASSWALL_PACKAGES_COMMIT="3e11c458c552aefd348232c627fd1ed9f8f08e41"
OPENCLASH_COMMIT="c3a33c1d3407956fdf8f0e0b7c1a4c52e6ad9593"
FRP_COMMIT="8503943074fb6ae4a06f5cacdb07b577555b0565"

clone_at() {
	local url="$1" ref="$2" destination="$3"
	rm -rf "$destination"
	git clone --filter=blob:none --no-checkout "$url" "$destination"
	git -C "$destination" fetch --depth=1 origin "$ref"
	git -C "$destination" -c advice.detachedHead=false checkout --detach FETCH_HEAD
}

sed_in_place() {
	if sed --version >/dev/null 2>&1; then
		sed -i "$@"
	else
		sed -i '' "$@"
	fi
}

insert_first() {
	local line="$1" file="$2" tmp_file
	tmp_file="$(mktemp)"
	awk -v line="$line" 'BEGIN { print line } { print }' "$file" > "$tmp_file"
	mv "$tmp_file" "$file"
}

insert_before_exit() {
	local file="$1" first="$2" second="${3:-}" tmp_file
	tmp_file="$(mktemp)"
	awk -v first="$first" -v second="$second" '
		$0 == "exit 0" && !inserted {
			print first
			if (second != "") print second
			inserted = 1
		}
		{ print }
	' "$file" > "$tmp_file"
	mv "$tmp_file" "$file"
}

replace_feed() {
	local name="$1" url="$2" ref="$3"
	sed_in_place "/^[[:space:]]*src-git\(-full\)\{0,1\}[[:space:]]${name}[[:space:]]/d" feeds.conf.default
	insert_first "src-git ${name} ${url}^${ref}" feeds.conf.default
}

replace_feed kenzo https://github.com/kenzok8/openwrt-packages.git "$KENZO_COMMIT"
replace_feed small https://github.com/kenzok8/small.git "$SMALL_COMMIT"
./scripts/feeds update -a

# The old feed copies are intentionally replaced by the official Passwall tree.
rm -rf feeds/luci/applications/luci-app-mosdns
rm -rf feeds/packages/net/{alist,adguardhome,mosdns,xray*,v2ray*,sing*,smartdns}
rm -rf feeds/packages/utils/v2dat
rm -rf feeds/small/luci-app-passwall
rm -rf feeds/small/luci-app-openclash package/openclash
rm -rf feeds/small/sing-box
rm -rf feeds/luci/applications/luci-app-scutclient package/frp
git clone --depth=1 https://github.com/wykdg/luci-app-scutclient.git feeds/luci/applications/luci-app-scutclient
clone_at https://github.com/kuoruan/openwrt-frp.git "$FRP_COMMIT" package/frp

if [[ -f feeds/small/dns2tcp/Makefile ]] && ! grep -q '^PKG_USE_MIPS16[[:space:]]*:=' feeds/small/dns2tcp/Makefile; then
	insert_first 'PKG_USE_MIPS16:=0' feeds/small/dns2tcp/Makefile
fi

rm -rf feeds/packages/lang/golang
clone_at https://github.com/kenzok8/golang.git "$GOLANG_COMMIT" feeds/packages/lang/golang

# The feed has an ARM64 bootstrap archive but omits linux_arm64 from its host list.
golang_makefile="feeds/packages/lang/golang/golang/Makefile"
if [[ -f "$golang_makefile" ]] && ! grep -A8 '^BOOTSTRAP_GO_VALID_OS_ARCH:=' "$golang_makefile" | grep -q 'linux_arm64'; then
	sed_in_place 's/linux_386      linux_amd64      linux_arm \\/linux_386      linux_amd64      linux_arm linux_arm64 \\/' "$golang_makefile"
fi

./scripts/feeds install -a

# Follow Passwall's independent-repository integration method.
rm -rf feeds/packages/net/{xray-core,v2ray-geodata,sing-box,chinadns-ng,dns2socks,hysteria,ipt2socks,microsocks,naiveproxy,shadowsocks-rust,shadowsocksr-libev,simple-obfs,tcping,v2ray-plugin,xray-plugin,geoview,shadow-tls}
rm -rf feeds/luci/applications/luci-app-passwall
clone_at https://github.com/Openwrt-Passwall/openwrt-passwall-packages.git "$PASSWALL_PACKAGES_COMMIT" package/passwall-packages
clone_at https://github.com/Openwrt-Passwall/openwrt-passwall.git "$PASSWALL_COMMIT" package/passwall-luci
clone_at https://github.com/vernesong/OpenClash.git "$OPENCLASH_COMMIT" package/openclash

# ImmortalWrt 21.02 does not understand the newer PKG_BUILD_FLAGS variable.
# Disable MIPS16 explicitly so Go's runtime/cgo MIPS assembly is assembled in
# the regular MIPS ABI instead of receiving -mips16 from package.mk.
sing_box_makefile="package/passwall-packages/sing-box/Makefile"
if [[ -f "$sing_box_makefile" ]] && ! grep -q '^PKG_USE_MIPS16[[:space:]]*:=' "$sing_box_makefile"; then
	insert_first 'PKG_USE_MIPS16:=0' "$sing_box_makefile"
fi

# OpenClash calls po2lmo while preparing translations.  Declare LuCI's host
# tool explicitly because package.mk alone does not pull in luci-base/host.
openclash_makefile="package/openclash/luci-app-openclash/Makefile"
if [[ -f "$openclash_makefile" ]] && ! grep -q '^PKG_BUILD_DEPENDS:=luci-base/host$' "$openclash_makefile"; then
	tmp_file="$(mktemp)"
	awk '
		{ print }
		/^PKG_VERSION:=/ && !inserted {
			print "PKG_BUILD_DEPENDS:=luci-base/host"
			inserted = 1
		}
	' "$openclash_makefile" > "$tmp_file"
	mv "$tmp_file" "$openclash_makefile"
fi

./scripts/feeds install -a

# The feed index can recreate removed packages as symlinks. Remove every feed
# provider whose directory name is also supplied by the official Passwall tree,
# so old copies from small/Kenzo/packages cannot override the pinned packages.
while IFS= read -r -d '' passwall_makefile; do
	passwall_package="$(basename "$(dirname "$passwall_makefile")")"
	rm -rf package/feeds/*/"$passwall_package"
done < <(find package/passwall-packages -mindepth 2 -maxdepth 2 -name Makefile -print0)
rm -rf package/feeds/*/luci-app-passwall package/feeds/*/luci-app-openclash

chinadns_makefile="package/passwall-packages/chinadns-ng/Makefile"
chinadns_version="$(sed -n 's/^PKG_VERSION:=//p' "$chinadns_makefile")"
if [[ "$chinadns_version" != "2025.08.09" ]]; then
	echo "Unexpected Passwall chinadns-ng version: ${chinadns_version:-missing}" >&2
	exit 1
fi
echo "Using Passwall chinadns-ng ${chinadns_version}"

# Preserve the original local customizations.
sed_in_place "s#option command '/bin/login'#option command '/bin/login -f root'#" feeds/packages/utils/ttyd/files/ttyd.config
if ! grep -q '/usr/bin/trojan-go' package/emortal/default-settings/files/99-default-settings; then
	insert_before_exit package/emortal/default-settings/files/99-default-settings \
		"[ ! -f '/usr/sbin/trojan' ] && [ -f '/usr/bin/trojan-go' ] && ln -sf /usr/bin/trojan-go /usr/bin/trojan"
fi
