# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit shell-completion

DESCRIPTION="Yandex Cloud command-line interface"
HOMEPAGE="
	https://yandex.cloud/en/docs/cli/
	https://cloud.yandex.com/en/docs/cli/
"
SRC_URI="
	amd64? (
		https://storage.yandexcloud.net/yandexcloud-yc/release/${PV}/linux/amd64/yc
			-> ${P}-linux-amd64
	)
	arm64? (
		https://storage.yandexcloud.net/yandexcloud-yc/release/${PV}/linux/arm64/yc
			-> ${P}-linux-arm64
	)
"

# Proprietary, source-unavailable upstream. No LICENSE file in the
# distribution; "all-rights-reserved" is Gentoo's convention for closed
# prebuilts that lack a declared redistribution grant.
LICENSE="all-rights-reserved"
SLOT="0"
KEYWORDS="-* ~amd64 ~arm64"

# bindist/mirror: closed-source, no redistribution rights.
# strip:          upstream already strips; Go runtime carries reflection
#                 data that strip(1) can corrupt.
RESTRICT="bindist mirror strip"

S="${WORKDIR}"

src_unpack() {
	local my_bin
	use amd64 && my_bin="${P}-linux-amd64"
	use arm64 && my_bin="${P}-linux-arm64"

	cp "${DISTDIR}/${my_bin}" "${S}/yc" || die "failed to stage yc binary"
	chmod +x "${S}/yc" || die
}

src_compile() {
	# Regenerate completions from the shipped binary so they always match
	# the version being installed.
	local shell
	for shell in bash zsh fish; do
		./yc completion "${shell}" > "yc.${shell}" \
			|| die "failed to generate ${shell} completion"
	done
}

src_install() {
	dobin yc

	newbashcomp yc.bash yc
	newzshcomp  yc.zsh  _yc
	newfishcomp yc.fish yc.fish
}

pkg_postinst() {
	elog "Initialize with:  yc init"
	elog "Config directory: ~/.config/yandex-cloud/"
	elog ""
	elog "yc is source-unavailable (all-rights-reserved). Accept the"
	elog "license via ACCEPT_LICENSE or /etc/portage/package.license/."
}
