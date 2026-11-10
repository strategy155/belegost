# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

RUST_MIN_VER="1.94.0"
# Deps (830 crates) vendored in the SRC_URI tarball (cargo_home/gentoo
# layout, cf. ::gentoo's helix/uv/ruff); regenerate: cargo vendor --locked.
CRATES=""

inherit cargo shell-completion

DESCRIPTION="Safe, private runtime for autonomous AI agents (kernel-sandboxed execution, formally verified policy, gateway-brokered credentials)"
HOMEPAGE="https://docs.nvidia.com/openshell/ https://github.com/NVIDIA/OpenShell"

SRC_URI="
	https://github.com/NVIDIA/OpenShell/archive/v${PV}.tar.gz -> ${P}.tar.gz
	https://github.com/strategy155/menegroth/releases/download/openshell-${PV}/openshell-${PV}-crates.tar.xz
"

# Apache-2.0 upstream; aggregate covers the vendored dep tree. Rare tokens
# mapped per ::gentoo licenses/: bzip2-1.0.6 -> BZIP2, BSL-1.0 -> Boost-1.0,
# LGPL-2.1-or-later -> LGPL-2.1+, WTFPL -> WTFPL-2, Zlib -> ZLIB; OR-choice
# omissions: BSD-1-Clause and MIT-0 -> MIT.
LICENSE="0BSD Apache-2.0 Boost-1.0 BSD BSD-2 BZIP2 CC0-1.0 CDLA-Permissive-2.0 ISC LGPL-2.1+ MIT MPL-2.0 Unicode-3.0 Unicode-DFS-2016 Unlicense WTFPL-2 ZLIB"
SLOT="0"
KEYWORDS="~amd64"

S="${WORKDIR}/OpenShell-${PV}"

# z3-sys links system Z3 via pkg-config; aws-lc-sys needs cmake; the build
# honours PROTOC since v0.1.5 (cf. app-misc/anki for the same pattern).
RDEPEND="sci-mathematics/z3:="
DEPEND="sci-mathematics/z3:="
BDEPEND="dev-libs/protobuf[protoc(+)] dev-util/cmake virtual/pkgconfig"

# rustc does not consume *FLAGS from make.conf (ebuild(5), bug 742905);
# scoped to the five built binaries.
QA_FLAGS_IGNORED="usr/bin/openshell usr/bin/openshell-gateway usr/bin/openshell-prover usr/bin/openshell-sandbox usr/bin/openshell-supervisor"

# e2e tests need a container runtime and network egress.
RESTRICT="test"

pkg_setup() {
	# Distro protobuf compiler instead of protoc-bin-vendored (honoured
	# since v0.1.5; cf. app-misc/anki's PROTOC_BINARY for the same idea).
	export PROTOC="${BROOT}/usr/bin/protoc"
}

src_install() {
	cargo_src_install
	einstalldocs
	dodoc deploy/rpm/QUICKSTART.md deploy/rpm/CONFIGURATION.md deploy/rpm/TROUBLESHOOTING.md

	# Completions from the built CLI (cf. net-misc/cscs-key).
	mkdir "${T}/completions" || die
	local shell
	for shell in bash zsh fish; do
		"$(cargo_target_dir)/openshell" completions ${shell} > "${T}/completions/${shell}" || die
		[[ -s "${T}/completions/${shell}" ]] || die "empty ${shell} completion"
	done
	newbashcomp "${T}/completions/bash" openshell
	newzshcomp "${T}/completions/zsh" _openshell
	newfishcomp "${T}/completions/fish" "openshell.fish"

	# OpenRC user service (cf. dbus/pipewire/podman in ::gentoo).
	exeinto /etc/user/init.d
	newexe "${FILESDIR}"/openshell-gateway.initd openshell-gateway
	insinto /etc/user/conf.d
	newins "${FILESDIR}"/openshell-gateway.confd openshell-gateway

	insinto /usr/share/openshell
	newins "${FILESDIR}"/gateway.toml.default gateway.toml.default
}

pkg_postinst() {
	elog "Gateway user service: rc-update --user add openshell-gateway default"
	elog "                 and: rc-service --user openshell-gateway start"
	elog "The service runs preflight + generate-certs before start (mirroring"
	elog "upstream's unit); TLS material lives under \$OPENSHELL_LOCAL_TLS_DIR"
	elog "(default ~/.local/state/openshell/tls)."
	elog "Config: copy /usr/share/openshell/gateway.toml.default to"
	elog "~/.config/openshell/gateway.toml, validate with openshell-gateway"
	elog "config preflight --path <file>. State under ~/.local/state/openshell"
	elog "is never touched by this package, so upgrades preserve it."
	elog "Register the gateway once up: openshell gateway add"
	elog "https://127.0.0.1:17670 --local --name openshell && openshell status"
}
