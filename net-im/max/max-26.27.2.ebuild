# Copyright 2026 strategy155
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit optfeature unpacker xdg

DESCRIPTION="MAX messenger desktop client"
HOMEPAGE="https://max.ru"

# Upstream appends a per-release build number to the version in the deb
# filename (apt index Version: is just 26.27.2); not derivable from ${PV},
# so it must be looked up in the repo's Packages index on every bump.
PV_BUILD="76730"
SRC_URI="https://download.max.ru/linux/deb/pool/main/m/max/MAX-${PV}.${PV_BUILD}.deb"
S="${WORKDIR}"

# Proprietary EULA client, no source release (github.com/max-messenger only
# hosts bot-API SDKs); same label ::gentoo uses for net-im/discord.
LICENSE="all-rights-reserved"
SLOT="0"
# Upstream ships amd64 only; -* marks the package as intentionally
# unkeywordable elsewhere (net-im/slack convention for prebuilts).
KEYWORDS="-* ~amd64"

RESTRICT="bindist mirror strip test"

# The app bundles its entire runtime under usr/share/max (Qt 6.11 incl.
# QtWebEngine, libstdc++, plus a private lib64 for its max-service helper),
# so RDEPEND is only the thin native layer the deb itself declares Depends on.
RDEPEND="
	app-misc/ca-certificates
	dev-libs/glib:2
	gnome-base/gsettings-desktop-schemas
	media-libs/libglvnd
	media-libs/libva[X]
	x11-libs/libXScrnSaver
	x11-libs/libnotify
	x11-libs/libvdpau
	x11-libs/libxcb
	x11-libs/libxkbcommon[X]
	x11-libs/xcb-util-cursor
	x11-libs/xcb-util-keysyms
	x11-libs/xcb-util-wm
"

QA_PREBUILT="usr/share/max/*"

src_install() {
	# The deb ships a ready FHS tree (everything under usr/share: the app,
	# max.desktop, hicolor icons). mv preserves the modes data.tar carries,
	# unlike doins -r which would clear exec bits on 572 files.
	mv usr "${ED}"/ || die

	# What the deb postinst did via update-alternatives.
	dosym -r /usr/share/max/bin/max /usr/bin/max
}

pkg_postinst() {
	xdg_pkg_postinst

	optfeature "screen sharing and audio capture" media-video/pipewire
}
