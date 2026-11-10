# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

EGIT_REPO_URI="https://github.com/NVIDIA/OpenShell.git"
RUST_MIN_VER="1.94.0"

inherit cargo git-r3 shell-completion

DESCRIPTION="Safe, private runtime for autonomous AI agents"
HOMEPAGE="https://docs.nvidia.com/openshell/ https://github.com/NVIDIA/OpenShell"

# Live: dependent-crate licenses resolve at build time via
# cargo_live_src_unpack (Apache-2.0 upstream).
LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS=""
PROPERTIES="live"

# z3-sys links system Z3 via pkg-config; aws-lc-sys needs cmake; the build
# honours PROTOC since v0.1.5 (cf. app-misc/anki for the same pattern).
RDEPEND="sci-mathematics/z3:="
DEPEND="sci-mathematics/z3:="
BDEPEND="dev-libs/protobuf[protoc(+)] dev-build/cmake virtual/pkgconfig"

# rustc does not consume *FLAGS from make.conf (ebuild(5), bug 742905);
# scoped to the five built binaries.
QA_FLAGS_IGNORED="usr/bin/openshell usr/bin/openshell-gateway usr/bin/openshell-prover usr/bin/openshell-sandbox usr/bin/openshell-supervisor"

# e2e tests need a container runtime and network egress.
RESTRICT="test"

src_unpack() {
	git-r3_src_unpack
	cargo_live_src_unpack
}

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
