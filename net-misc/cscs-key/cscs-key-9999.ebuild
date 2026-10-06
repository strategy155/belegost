# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

EGIT_REPO_URI="https://github.com/eth-cscs/cscs-key.git"
RUST_MIN_VER="1.88.0"

inherit cargo git-r3 shell-completion

DESCRIPTION="CLI to sign, list and revoke SSH keys for CSCS user accounts"
HOMEPAGE="https://github.com/eth-cscs/cscs-key"

LICENSE="BSD"
SLOT="0"
KEYWORDS=""
PROPERTIES="live"

# rustc does not consume *FLAGS from make.conf, so the flags QA checks
# (which verify the C/C++ toolchain contract) cannot apply to cargo
# builds; this is the standard opt-out, scoped to the single binary.
# Cf.: ebuild(5) on QA_FLAGS_IGNORED,
# https://bugs.gentoo.org/742905 (non-C/C++ context hint),
# https://wiki.gentoo.org/wiki/User:Sam/Drafts/QA_warnings
QA_FLAGS_IGNORED="usr/bin/${PN}"

src_unpack() {
	git-r3_src_unpack
	cargo_live_src_unpack
}

src_install() {
	cargo_src_install
	einstalldocs

	# upstream ships no completion files; the binary itself is the
	# generator (same pattern as sys-apps/ripgrep, app-shells/starship)
	local bin="$(cargo_target_dir)/${PN}"
	mkdir "${T}/completions" || die
	local shell
	for shell in bash zsh fish; do
		"${bin}" completion ${shell} > "${T}/completions/${shell}" || die
		[[ -s "${T}/completions/${shell}" ]] || die "empty ${shell} completion"
	done
	newbashcomp "${T}/completions/bash" ${PN}
	newzshcomp "${T}/completions/zsh" _${PN}
	newfishcomp "${T}/completions/fish" "${PN}.fish"
}
