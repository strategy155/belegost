# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Kibana MCP server (8.x OpenAPI spec, multi-space)"
HOMEPAGE="https://github.com/TocharianOU/MCP-Server-Kibana"
SRC_URI="
	https://registry.npmjs.org/@tocharianou/${PN}/-/${PN}-${PV}.tgz
	https://github.com/strategy155/menegroth/releases/download/${P}/${P}-npm-cache.tar.xz
"

# package itself Apache-2.0; license scan of the offline-resolved
# tree (144 packages from the frozen cache): MIT x129, ISC x9,
# BSD-3-Clause x3 (-> BSD), Apache-2.0 x3, BSD-2 x1, and argparse
# (a JS port of Python's argparse) carries the PSF license ->
# PSF-2 (text verified against licenses/PSF-2, the only live
# Gentoo name for it; PSF-2.0 and Python-2.0 both 404 in-tree)
LICENSE="Apache-2.0 BSD BSD-2 ISC MIT PSF-2"
SLOT="0"
KEYWORDS="~amd64"

# engines: node >=18 (package.json); the 11 runtime deps resolve
# offline from the frozen npm cache - dev-lang/typescript +
# dev-util/bash-language-server pattern (::gentoo + GURU)
RDEPEND="net-libs/nodejs"
BDEPEND="net-libs/nodejs[npm]"

# npm tarball top dir is "package" - but it is never unpacked: npm
# consumes it directly from ${DISTDIR} (GURU dev-util/bash-language-
# server form).  S=${WORKDIR} satisfies the prepare-phase S-existence
# check against the empty workdir that src_unpack leaves in place.
S="${WORKDIR}"

# NOTE: to regenerate the npm-cache tarball:
#   npm --cache ./npm-cache install <distdir>/${P}.tgz
#   tar -caf ${P}-npm-cache.tar.xz npm-cache

src_unpack() {
	# cache only - the npm tarball is consumed directly from
	# ${DISTDIR} by src_install and never unpacked (GURU
	# dev-util/bash-language-server form)
	cd "${T}" || die "Could not cd to temporary directory"
	unpack ${P}-npm-cache.tar.xz
}

src_install() {
	npm --prefix="${ED}"/usr --omit=dev --audit=false --color=false \
		--progress=false --foreground-scripts --global --offline --verbose \
		--cache "${T}"/npm-cache \
		install "${DISTDIR}"/${P}.tgz || die "npm offline install failed"

	cd "${ED}"/usr/$(get_libdir)/node_modules/@tocharianou/${PN} || die
	einstalldocs
}
