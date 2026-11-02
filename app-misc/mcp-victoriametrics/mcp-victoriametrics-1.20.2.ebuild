# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit go-module

DESCRIPTION="MCP server for VictoriaMetrics (metrics backend)"
HOMEPAGE="https://github.com/VictoriaMetrics/mcp-victoriametrics"
SRC_URI="https://github.com/VictoriaMetrics/mcp-victoriametrics/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"

# go-licenses report ./cmd/mcp-victoriametrics (dev-go/go-licenses):
# Apache-2.0 x28, MIT x28, BSD-3-Clause x15 (-> BSD), BSD-2 x5
LICENSE="Apache-2.0 BSD BSD-2 MIT"
SLOT="0"
KEYWORDS="~amd64"

# go floor per the v1.20.2 tag's go.mod directive (1.26.2; the main
# branch has moved to 1.27.3 - tag facts are authoritative for the
# build); full assignment since it clobbers the eclass floor
BDEPEND=">=dev-lang/go-1.26.2"

QA_FLAGS_IGNORED="usr/bin/${PN}"

src_compile() {
	# upstream release spec (.goreleaser.yaml: CGO off, two stamps -
	# main.version = the v-tag, main.date = {{.CommitDate}} (the tag
	# commit, fb45b04, 2026-04-15T17:23:57Z) - both release constants,
	# matching what upstream ships in the release binary.
	# No -s -w: stripping is portage's job.  No completions: upstream
	# has no flag framework at all - configuration is entirely via
	# MCP_* / VMC_* environment variables.
	local -x CGO_ENABLED=0
	ego build \
		-ldflags "-X main.version=v${PV} -X main.date=2026-04-15T17:23:57Z" \
		-o ${PN} ./cmd/${PN}
}

src_install() {
	dobin ${PN}
	einstalldocs
}
