# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

# Drop the "-bin" suffix so the installed binary name (and homepage layout)
# tracks upstream's "kubeconform" naming.
MY_PN="${PN%-bin}"

DESCRIPTION="Kubernetes manifest validator — fast schema validation for YAML manifests"
HOMEPAGE="https://github.com/yannh/kubeconform"

# Upstream releases statically-linked Go binaries as per-platform tar.gz
# bundles containing { LICENSE, kubeconform }. Source build via go-module
# would require hosting a vendor tarball; the prebuilt binary is what
# every distro packages and what upstream itself signs CHECKSUMS for.
SRC_URI="
	amd64? (
		https://github.com/yannh/${MY_PN}/releases/download/v${PV}/${MY_PN}-linux-amd64.tar.gz
			-> ${P}-linux-amd64.tar.gz
	)
	arm64? (
		https://github.com/yannh/${MY_PN}/releases/download/v${PV}/${MY_PN}-linux-arm64.tar.gz
			-> ${P}-linux-arm64.tar.gz
	)
"

LICENSE="Apache-2.0"
SLOT="0"
# Upstream releases linux 386/amd64/arm64/armv6 + darwin + windows; we
# expose amd64 + arm64 to match the overlay's other -bin packages.
KEYWORDS="-* ~amd64 ~arm64"

# Upstream ships Go binaries with debug_info kept (verified via file(1));
# strip(1) on Go binaries risks corrupting runtime reflection metadata.
RESTRICT="strip"

# Pure-Go static binary — no libc linkage, no runtime deps.
RDEPEND=""

S="${WORKDIR}"

src_unpack() {
	# Two arch-specific distfiles with identical internal layout (LICENSE
	# at the root + kubeconform binary). Pick the one matching active USE.
	local my_arch
	use amd64 && my_arch="amd64"
	use arm64 && my_arch="arm64"

	unpack "${P}-linux-${my_arch}.tar.gz"
}

src_install() {
	dobin "${MY_PN}"
	dodoc LICENSE
}

pkg_postinst() {
	elog "kubeconform validates Kubernetes manifests against JSON Schemas:"
	elog ""
	elog "    kubeconform manifest.yaml"
	elog "    kubeconform -kubernetes-version 1.31.0 manifests/"
	elog "    kubeconform -schema-location default                # local GVK cache"
	elog "    kubeconform -summary -output junit manifests/       # CI-friendly"
	elog ""
	elog "No 'completion' subcommand exists — upstream uses plain"
	elog "getopt-style flags, not cobra."
}
