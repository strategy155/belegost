# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit go-module shell-completion

DESCRIPTION="The glamourous AI coding agent for your favourite terminal"
HOMEPAGE="
	https://charm.sh/crush
	https://github.com/charmbracelet/crush
"
SRC_URI="
	https://github.com/charmbracelet/crush/archive/refs/tags/v${PV}.tar.gz
		-> ${P}.tar.gz
	https://github.com/strategy155/menegroth/releases/download/${P}/${P}-deps.tar.xz
"

# Source-available; flips to MIT two years after release.
# License file lives in this overlay's licenses/ dir.
LICENSE="FSL-1.1-MIT"
# Dependent module licenses from vendored deps
LICENSE+=" Apache-2.0 BSD BSD-2 ISC MIT MPL-2.0 Unlicense"
SLOT="0"
KEYWORDS="~amd64 ~arm64"

# Go emits its own stripped binary via -s -w ldflags; further strip(1)
# can break Go's runtime introspection.
RESTRICT="strip"

BDEPEND=">=dev-lang/go-1.26.2"

src_compile() {
	# Match upstream's goreleaser build: CGO disabled, version injected
	# via ldflags, -trimpath for reproducible binaries.
	export CGO_ENABLED=0

	ego build \
		-trimpath \
		-ldflags "-s -w -X github.com/charmbracelet/crush/internal/version.Version=v${PV}" \
		-o crush \
		.

	# Generate shell completions and man page from the built binary
	# (same hooks goreleaser runs pre-archive).
	local shell
	for shell in bash zsh fish; do
		./crush completion "${shell}" > "crush.${shell}" \
			|| die "failed to generate ${shell} completion"
	done
	./crush man | gzip -c > crush.1.gz \
		|| die "failed to generate man page"
}

src_install() {
	dobin crush
	doman crush.1.gz

	newbashcomp crush.bash crush
	newzshcomp  crush.zsh  _crush
	newfishcomp crush.fish crush.fish

	dodoc README.md
}

pkg_postinst() {
	elog "crush requires an LLM provider API key (Anthropic, OpenAI,"
	elog "Google, etc.) to operate. See upstream README for setup."
	elog ""
	elog "Global config:  ~/.config/crush/crush.json"
	elog "Project config: .crush.json or crush.json"
	elog "Data dir:       ~/.local/share/crush/"
	elog ""
	elog "FSL-1.1-MIT is source-available; add to ACCEPT_LICENSE if"
	elog "not already accepted (see /etc/portage/package.license/)."
}
