# Copyright 2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit go-module

DESCRIPTION="Grafana k6 is a CLI interface for load testing functionality"
HOMEPAGE="https://github.com/grafana/k6"
SRC_URI="https://github.com/grafana/k6/archive/refs/tags/v0.41.0.tar.gz"

LICENSE="AGPL-3
MIT
BSD
BSD-2
Apache-2.0

"
SLOT="0"
KEYWORDS="~amd64"

DEPEND=""
RDEPEND="${DEPEND}"
BDEPEND=""

src_compile() {
	ego build
}

src_install() {
	dobin k6
}


