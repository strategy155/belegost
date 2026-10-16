# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit go-module shell-completion

DESCRIPTION="CLI for Rancher (short-lived kubeconfig credential acquisition for k8s clusters)"
HOMEPAGE="https://github.com/rancher/cli"
SRC_URI="
	https://github.com/rancher/cli/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz
	https://github.com/strategy155/menegroth/releases/download/${P}/${P}-deps.tar.xz
"

# repo is rancher/cli, so the archive top dir is cli-${PV}
S="${WORKDIR}/cli-${PV}"

# go-licenses report . (dev-go/go-licenses)
LICENSE="Apache-2.0 BSD BSD-2 ISC MIT"
SLOT="0"
KEYWORDS="~amd64"

# go floor: go.mod says go 1.26.5 + toolchain pin go1.26.6 - floor at
# the pin so no local toolchain ever falls below it (below-pin local +
# GOTOOLCHAIN=auto would attempt an auto-download, which network-sandbox
# kills); full assignment since it clobbers the eclass floor
BDEPEND=">=dev-lang/go-1.26.6"

# binary is rancher, not rancher-cli (upstream scripts/build:11)
QA_FLAGS_IGNORED="usr/bin/rancher"

src_compile() {
	# CGO off pins parity with the official release binary
	# (scripts/build:11 CGO_ENABLED=0).  Version stamp mirrors upstream
	# ldflags minus -w -s (stripping is portage's job): main.VERSION
	# is the v-prefixed git tag; -extldflags -static is moot with CGO off.
	local -x CGO_ENABLED=0
	ego build -ldflags "-X main.VERSION=v${PV}" -o rancher .
}

src_install() {
	dobin rancher
	einstalldocs

	# urfave/cli v3 completion command, explicitly enabled and unhidden
	# upstream (main.go: EnableShellCompletion + Hidden = false);
	# all three shells verified generating
	mkdir "${T}"/completions || die
	local shell
	for shell in bash zsh fish; do
		./rancher completion ${shell} > "${T}"/completions/${shell} || die
		[[ -s "${T}"/completions/${shell} ]] || die "empty ${shell} completion"
	done
	newbashcomp "${T}"/completions/bash rancher
	newzshcomp "${T}"/completions/zsh _rancher
	newfishcomp "${T}"/completions/fish rancher.fish
}
