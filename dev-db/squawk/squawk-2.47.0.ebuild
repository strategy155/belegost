# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="PostgreSQL migration linter and SQL anti-pattern detector"
HOMEPAGE="
	https://squawkhq.com
	https://github.com/sbdchd/squawk
"

GH_URI="https://github.com/sbdchd/squawk/releases/download/v${PV}"
SRC_URI="
	amd64? (
		elibc_glibc? (
			${GH_URI}/squawk-linux-x64
				-> squawk-amd64-glibc-${PV}
		)
		elibc_musl? (
			${GH_URI}/squawk-linux-musl-x64
				-> squawk-amd64-musl-${PV}
		)
	)
	arm64? (
		elibc_glibc? (
			${GH_URI}/squawk-linux-arm64
				-> squawk-arm64-glibc-${PV}
		)
		elibc_musl? (
			${GH_URI}/squawk-linux-musl-arm64
				-> squawk-arm64-musl-${PV}
		)
	)
"
S="${WORKDIR}"

LICENSE="Apache-2.0 MIT"
SLOT="0"
KEYWORDS="~amd64 ~arm64"
RESTRICT="strip"
QA_PREBUILT="usr/bin/squawk"

src_compile() {
	:
}

src_install() {
	newbin "${DISTDIR}/${A[0]}" squawk
}
