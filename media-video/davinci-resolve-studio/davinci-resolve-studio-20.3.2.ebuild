# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# Derived from inode64-overlay's davinci-resolve-studio-19.1.3, reworked for the
# 20.x payload. Every deviation from that ebuild is commented where it happens.

EAPI=8

inherit check-reqs desktop udev xdg

PKG_NAME="DaVinci_Resolve_Studio_${PV}_Linux"
PKG_HOME="/opt/resolve"

DESCRIPTION="Professional A/V post-production software suite from Blackmagic Design"
HOMEPAGE="https://www.blackmagicdesign.com/support/family/davinci-resolve-and-fusion"
# Blackmagic serves a login-gated .zip wrapping this .run. We take the .run
# itself so the build never holds a second 9 GB copy of it (see src_unpack).
SRC_URI="${PKG_NAME}.run"
S="${WORKDIR}/squashfs-root"

LICENSE="Blackmagic"
SLOT="0"
KEYWORDS="-* ~amd64"
IUSE="developer video_cards_amdgpu video_cards_nvidia"
# fetch: the download is login-gated (pkg_nofetch explains where to get it).
# bindist: proprietary; built packages must not be redistributed.
RESTRICT="bindist fetch mirror strip test"

# The payload bundles OpenSSL 1.1 (gone from ::gentoo) and ABI-pinned graphviz
# (libcgraph.so.6) and TBB (libtbb.so.2), where the system ships .so.8/.so.12.
# So unlike 19.1.3's USE=-bundled-libs path, the crypto/network stack (curl,
# libpq, libsrtp2, xmlsec) and graphviz/TBB/APR/orc/soxr/libusb stay bundled;
# only what actively breaks is unbundled in src_prepare. RDEPEND is the set of
# sonames the remaining ELFs NEED that nothing in the payload provides
# (derived with scanelf against the 20.3.2 tree).
RDEPEND="
	app-arch/bzip2
	app-arch/xz-utils
	dev-libs/expat
	dev-libs/glib:2
	gnome-base/librsvg:2
	media-libs/alsa-lib
	media-libs/fontconfig
	media-libs/freetype:2
	media-libs/glu
	media-libs/libglvnd
	media-libs/libpng-compat:1.2
	media-libs/libpulse
	sys-apps/dbus
	sys-apps/util-linux
	sys-devel/gcc:*[openmp]
	sys-libs/mtdev
	virtual/libcrypt
	virtual/libudev
	virtual/opencl
	virtual/zlib
	x11-libs/libICE
	x11-libs/libSM
	x11-libs/libX11
	x11-libs/libXcursor
	x11-libs/libXext
	x11-libs/libXfixes
	x11-libs/libXi
	x11-libs/libXinerama
	x11-libs/libXrandr
	x11-libs/libXrender
	x11-libs/libXt
	x11-libs/libXtst
	x11-libs/libXxf86vm
	x11-libs/libxcb
	x11-libs/libxkbcommon[X]
	x11-libs/xcb-util
	x11-libs/xcb-util-image
	x11-libs/xcb-util-keysyms
	x11-libs/xcb-util-renderutil
	x11-libs/xcb-util-wm
	video_cards_amdgpu? ( dev-libs/rocm-opencl-runtime )
	video_cards_nvidia? ( x11-drivers/nvidia-drivers )
"
BDEPEND="sys-fs/squashfs-tools"

QA_PREBUILT="opt/resolve/*"

# Extracted payload is 13 GB; src_install renames it into the image on the same
# filesystem, so the build directory never holds a second copy.
CHECKREQS_DISK_BUILD="14G"

pkg_nofetch() {
	einfo "Download DaVinci Resolve Studio ${PV} for Linux from"
	einfo "  ${HOMEPAGE}"
	einfo "(requires registration), unzip it and place"
	einfo "  ${PKG_NAME}.run"
	einfo "into your DISTDIR (usually /var/cache/distfiles)."
}

src_unpack() {
	# The .run is an AppImage: a small ELF runtime with a squashfs appended.
	# Read the squashfs straight from DISTDIR instead of running the vendor
	# self-extractor, so the build executes no downloaded code and never copies
	# the 9 GB .run into WORKDIR. The payload starts where the ELF image ends:
	# e_shoff (0x28) + e_shentsize (0x3A) * e_shnum (0x3C).
	local run="${DISTDIR}/${PKG_NAME}.run"
	local shoff shentsize shnum offset
	shoff=$(od -An -t u8 -j 40 -N 8 "${run}") || die
	shentsize=$(od -An -t u2 -j 58 -N 2 "${run}") || die
	shnum=$(od -An -t u2 -j 60 -N 2 "${run}") || die
	offset=$(( shoff + shentsize * shnum ))
	[[ $(od -An -c -j "${offset}" -N 4 "${run}" | tr -d ' \n') == hsqs ]] \
		|| die "no squashfs payload at offset ${offset}: installer layout changed"

	unsquashfs -q -no-progress -o "${offset}" -d "${S}" "${run}" || die
}

src_prepare() {
	default

	sed -i -e "s|RESOLVE_INSTALL_LOCATION|${PKG_HOME}|g" share/*.desktop share/*.directory || die
	# Categories=Video is an additional category that requires a main one.
	sed -i -e "s|=Video|=AudioVideo|g" share/*.desktop || die

	# Bundled glib 2.68 is older than what the system pango needs (undefined
	# symbol g_once_init_leave_pointer / g_string_free_and_steal): use system glib.
	rm libs/lib{gio,glib,gmodule,gobject}-2.0.so* || die

	# Clashes with system MIT krb5 (undefined symbol krb5int_c_deprecated_enctype).
	rm "DaVinci Control Panels Setup/libk5crypto.so.3" || die

	# Debug CLI needing ncurses 5 / readline 6, both gone from ::gentoo.
	rm bin/sqlite3 || die

	# 32-bit LUT generators, developer pkg-config files, and the vendor
	# installer/uninstaller hooks: portage owns installation and removal, and
	# src_install ports what post_install.sh sets up (writable Apple Immersive,
	# dongle udev rule, merged menu).
	rm LUT/GenOutputLut LUT/GenLut || die
	rm -r libs/pkgconfig || die
	rm scripts/{pre_install,post_install,uninstall}.sh || die

	rm "BlackmagicRAWSpeedTest/Third Party Licenses.rtf" \
		"BlackmagicRAWPlayer/Third Party Licenses.rtf" || die
}

src_install() {
	# Icons first: the payload move below takes graphics/ out of ${S}.
	# Versus 19.1.3: the MIME-type icons carry the .png extension, without which
	# icon-theme lookup (iconname.png/.svg/.xpm) never finds them, and the .braw
	# sidecar type gets its icon too, as in vendor post_install.sh.
	local res
	for res in 64 128; do
		newicon -s ${res} graphics/DV_Resolve.png DaVinci-Resolve.png
		newicon -s ${res} graphics/DV_ResolveProj.png DaVinci-ResolveProj.png
		newicon -s ${res} graphics/DV_ServerAccess.png DaVinci-ResolveDbKey.png
		newicon -s ${res} -c mimetypes graphics/DV_ResolveBin.png application-x-resolvebin.png
		newicon -s ${res} -c mimetypes graphics/DV_ResolveProj.png application-x-resolveproj.png
		newicon -s ${res} -c mimetypes graphics/DV_ResolveTimeline.png application-x-resolvetimeline.png
		newicon -s ${res} -c mimetypes graphics/DV_ServerAccess.png application-x-resolvedbkey.png
		newicon -s ${res} -c mimetypes graphics/DV_TemplateBundle.png application-x-resolvetemplatebundle.png
	done

	for res in 48 256; do
		newicon -s ${res} graphics/blackmagicraw-speedtest_${res}x${res}_apps.png blackmagicraw-speedtest.png
		newicon -s ${res} graphics/blackmagicraw-player_${res}x${res}_apps.png blackmagicraw-player.png
		newicon -s ${res} -c mimetypes \
			graphics/application-x-braw-clip_${res}x${res}_mimetypes.png application-x-braw-clip.png
		newicon -s ${res} -c mimetypes \
			graphics/application-x-braw-sidecar_${res}x${res}_mimetypes.png application-x-braw-sidecar.png
	done

	# Rename (not copy) the payload into the image: same filesystem, so the 13 GB
	# tree never exists twice, and file modes come straight from the squashfs.
	# This empties the listed dirs out of ${S}: install anything sourced from
	# them above this point.
	# Versus 19.1.3: Onboarding (the Welcome app) and Apple Immersive are new
	# in 20; scripts/ backs the Capture Logs menu entry (script.getlogs.v4).
	local -a dirs=(
		"Apple Immersive" bin BlackmagicRAWPlayer BlackmagicRAWSpeedTest Certificates
		Control "DaVinci Control Panels Setup" "Fairlight Studio Utility" Fusion
		graphics libs LUT Onboarding plugins scripts UI_Resource
	)
	use developer && dirs+=( Developer )

	dodir "${PKG_HOME}"
	local dir
	for dir in "${dirs[@]}"; do
		mv "${dir}" "${ED}${PKG_HOME}/" || die
	done

	# Vendor post_install.sh (set_folder_permissions) makes this writable for all
	# users; without it Resolve 20 exits at startup with "Failed to create
	# application support directories".
	fperms a+w "${PKG_HOME}/Apple Immersive"

	insinto "${PKG_HOME}"/share
	doins share/{default-config.dat,default_cm_config.bin,log-conf.xml,remote-monitor-log-conf.xml}

	dodoc docs/{DaVinci_Resolve_Manual.pdf,ReadMe.html,Welcome.txt}
	dodoc "Technical Documentation"/{"DaVinci Remote Panel.txt","User Configuration folders and customization.txt"}

	# Plus the license-dongle rule vendor post_install.sh writes (75-sdx.rules).
	# Not carried: its catch-all hidraw MODE="0777" rule, which would expose
	# every HID device (keyboards included) to all users; Blackmagic's own 1edb
	# devices are already covered by the shipped rules.
	udev_dorules share/etc/udev/rules.d/*.rules "${FILESDIR}"/75-sdx.rules

	# The Resolve launchers carry no Categories=, so only this merged menu lists
	# them: it goes to applications-merged under the names it references, as
	# vendor post_install.sh installs it.
	insinto /usr/share/desktop-directories
	newins share/DaVinciResolve.directory com.blackmagicdesign.resolve.directory
	insinto /etc/xdg/menus/applications-merged
	newins share/DaVinciResolve.menu com.blackmagicdesign.resolve.menu

	insinto /usr/share/mime/packages
	doins share/{blackmagicraw,resolve}.xml

	# Resolve writes its runtime state here as the desktop user.
	diropts -m 0777
	keepdir "${PKG_HOME}"/{configs,DolbyVision,easyDCP,Fairlight,GPUCache,logs,Media} \
		"${PKG_HOME}"/{"Resolve Disk Database",.crashreport,.license,.LUT}
	keepdir "/var/BlackmagicDesign/DaVinci Resolve"
	diropts -m 0755

	# DaVinciResolveInstaller.desktop is skipped: it launches the vendor uninstaller.
	newmenu share/DaVinciResolve.desktop com.blackmagicdesign.resolve.desktop
	newmenu share/DaVinciControlPanelsSetup.desktop com.blackmagicdesign.resolve-Panels.desktop
	newmenu share/DaVinciResolveCaptureLogs.desktop com.blackmagicdesign.resolve-CaptureLogs.desktop
	newmenu share/DaVinciRemoteMonitoring.desktop com.blackmagicdesign.resolve-DaVinciRemoteMonitoring.desktop
	newmenu share/blackmagicraw-player.desktop com.blackmagicdesign.rawplayer.desktop
	newmenu share/blackmagicraw-speedtest.desktop com.blackmagicdesign.rawspeedtest.desktop

	newmenu "${FILESDIR}"/defaults.list com.blackmagicdesign.list
}

pkg_postinst() {
	udev_reload
	xdg_pkg_postinst

	elog "DaVinci Resolve Studio must be activated with your license key or USB"
	elog "dongle on first launch."
	elog ""
	elog "Resolve on Linux cannot decode AAC audio, so such clips import silent."
	elog "Convert their audio first, e.g.:"
	elog "  ffmpeg -i in.mp4 -c:v copy -c:a pcm_s16le out.mov"
}

pkg_postrm() {
	udev_reload
	xdg_pkg_postrm
}
