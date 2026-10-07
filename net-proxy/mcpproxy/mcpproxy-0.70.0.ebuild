# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit go-module shell-completion

DESCRIPTION="Smart MCP Proxy - tool discovery and proxying for MCP servers"
HOMEPAGE="https://mcpproxy.app https://github.com/smart-mcp-proxy/mcpproxy-go"
SRC_URI="
	https://github.com/smart-mcp-proxy/mcpproxy-go/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz
	https://github.com/strategy155/menegroth/releases/download/${P}/${P}-deps.tar.xz
	https://github.com/strategy155/menegroth/releases/download/${P}/${P}-node_modules.tar.xz
"

# go-licenses report ./cmd/mcpproxy (dev-go/go-licenses); frontend deps MIT
S="${WORKDIR}/mcpproxy-go-${PV}"

LICENSE="Apache-2.0 BSD BSD-2 MIT MIT-Lucent"
SLOT="0"
KEYWORDS="~amd64"

# frontend build: vue-tsc + vite (upstream engines floor: node >=22.18.0)
BDEPEND=">=net-libs/nodejs-22.18[npm]"

src_prepare() {
	default
	# node_modules tarball unpacks to ${WORKDIR}/node_modules
	# (pattern from ::guru app-backup/restic-browser)
	mv "${WORKDIR}"/node_modules "${S}"/frontend/ || die
}

src_compile() {
	# web UI: vue-tsc type-check + vite build; offline, node_modules is
	# pre-fetched via the dist tarball, no npm ci / registry access
	(
		cd frontend || die
		npm run build || die "npm run build failed"
	)

	# embed the freshly built frontend/dist into web/frontend/dist, the
	# go:embed target, which the source tarball ships with only a
	# .gitkeep placeholder (upstream release.yml recipe). The rm protects
	# against stale assets when phases re-run on a dirty WORKDIR.
	rm -rf web/frontend/dist || die
	mkdir -p web/frontend/dist || die
	cp -r frontend/dist/. web/frontend/dist/ || die
	touch web/frontend/dist/.gitkeep || die

	# version-stamped as upstream releases are (Makefile LDFLAGS and
	# release.yml agree: git-describe tag, v-prefixed; commit/date stamps
	# are local-dev flavor and stay out of distributed binaries).
	# Deliberately NO install-channel marker: an unstamped binary detects
	# as ChannelUnknown, so `mcpproxy update` refuses to self-replace and
	# portage keeps owning /usr/bin/mcpproxy (internal/updatecheck/
	# channel.go, Spec 092 FR-020).
	#
	# no -s -w here on purpose: stripping is portage's job (FEATURES=strip,
	# default) and FEATURES=nostrip users keep their debug symbols
	local v="v${PV}"
	ego build \
		-ldflags "-X main.version=${v} -X github.com/smart-mcp-proxy/mcpproxy-go/internal/httpapi.buildVersion=${v}" \
		-o ${PN} ./cmd/${PN}
}

src_install() {
	dobin ${PN}
	einstalldocs

	# upstream ships no completion files; the binary is the generator
	# (same pattern as sys-apps/ripgrep, net-misc/cscs-key)
	mkdir "${T}"/completions || die
	local shell
	for shell in bash zsh fish; do
		./${PN} completion ${shell} > "${T}"/completions/${shell} || die
		[[ -s "${T}"/completions/${shell} ]] || die "empty ${shell} completion"
	done
	newbashcomp "${T}"/completions/bash ${PN}
	newzshcomp "${T}"/completions/zsh _${PN}
	newfishcomp "${T}"/completions/fish "${PN}.fish"
}
