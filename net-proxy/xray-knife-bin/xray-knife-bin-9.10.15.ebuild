# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

# shell-completion: provides new{bash,zsh,fish}comp helpers.
# Upstream MIT. Go source would compile from github.com/lilendian0x00/
# xray-knife but its transitive xtls/xray-core pins a gvisor pseudo-version
# that upstream never validated under `go build` (Bazel-only upstream, Go
# 1.26 hits two separate gvisor bugs: a build-tag conflict in
# pkg/sync/runtime_constants_go125.go and a package-name conflict in
# pkg/tcpip/stack/bridge_test.go). Ship the statically-linked binary that
# upstream's own CI produces until xtls/xray-core bumps its gvisor pin.
inherit shell-completion

MY_PN="${PN%-bin}"
MY_P="${MY_PN}-${PV}"

DESCRIPTION="CLI for Xray/sing-box: subscriptions, perf, cfscanner, auto-rotating proxy (binary)"
HOMEPAGE="
	https://github.com/lilendian0x00/xray-knife
"

# Upstream ZIPs carry platform in the name, not the version. Arrow-rename
# to include ${PV} so distfiles are per-version and cache-safe.
SRC_URI="
	amd64? (
		https://github.com/lilendian0x00/${MY_PN}/releases/download/v${PV}/Xray-knife-linux-64.zip
			-> ${P}-linux-amd64.zip
	)
	arm64? (
		https://github.com/lilendian0x00/${MY_PN}/releases/download/v${PV}/Xray-knife-linux-arm64-v8a.zip
			-> ${P}-linux-arm64.zip
	)
"

LICENSE="MIT"
SLOT="0"
# Upstream releases Linux amd64 + arm64 only; keywords track that.
KEYWORDS="-* ~amd64 ~arm64"

# Upstream already ships a stripped binary via -s -w Go ldflags; re-strip
# risks corrupting Go's runtime type reflection (pclntab etc.).
RESTRICT="strip"

# Pure-Go static binary — no libc linkage, no runtime deps.
RDEPEND=""
BDEPEND="
	app-arch/unzip
"

S="${WORKDIR}"

src_unpack() {
	# Two arch-specific distfiles with the same internal layout (LICENSE,
	# README.md, xray-knife). Pick the one matching the active USE arch.
	local my_zip
	use amd64 && my_zip="${P}-linux-amd64.zip"
	use arm64 && my_zip="${P}-linux-arm64.zip"

	unpack "${my_zip}"
	chmod +x xray-knife || die
}

src_compile() {
	# Running the binary touches ~/.xray-knife/ (SQLite DB init) even for
	# the completion subcommand — redirect HOME into the portage temp
	# sandbox so the build stays hermetic. Drop the "migrations applied"
	# stderr banner so the completion output on stdout is clean.
	export HOME="${T}"

	local shell
	for shell in bash zsh fish; do
		./xray-knife completion "${shell}" 2>/dev/null > "xray-knife.${shell}" \
			|| die "failed to generate ${shell} completion"
	done
}

src_install() {
	dobin xray-knife

	newbashcomp xray-knife.bash xray-knife
	newzshcomp  xray-knife.zsh  _xray-knife
	newfishcomp xray-knife.fish xray-knife.fish

	dodoc README.md
}

pkg_postinst() {
	elog "xray-knife keeps state at ~/.xray-knife/ (SQLite DB + web UI"
	elog "JWT secret), auto-created on first invocation."
	elog ""
	elog "Both Xray and sing-box engines are compiled into the binary;"
	elog "no external engine package needed."
	elog ""
	elog "This is a prebuilt binary ebuild. A source build is currently"
	elog "blocked by upstream bugs in xtls/xray-core's transitive gvisor"
	elog "pin under Go 1.26+; revisit once xray-core bumps gvisor."
}
