# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

# shell-completion: provides new{bash,zsh,fish}comp helpers for installing
# completion scripts to per-shell convention paths. Source build via
# go-module would be the proper Gentoo way (helm's pattern in main tree)
# but requires hosting a multi-hundred-MB vendor tarball; the prebuilt
# upstream binary is statically linked and matches what every distro
# packages.
inherit shell-completion

# Drop the "-bin" suffix so the binary name and homepage track upstream.
MY_PN="${PN%-bin}"

DESCRIPTION="ArgoCD CLI — declarative GitOps continuous delivery for Kubernetes"
HOMEPAGE="
	https://argo-cd.readthedocs.io
	https://github.com/argoproj/argo-cd
"

# Upstream releases include statically-linked Go binaries for linux/amd64
# and linux/arm64. ppc64le and s390x exist in the release but aren't keyed
# below. Arrow-rename to ${P}- form so distfiles are version-namespaced.
SRC_URI="
	amd64? (
		https://github.com/argoproj/argo-cd/releases/download/v${PV}/argocd-linux-amd64
			-> ${P}-linux-amd64
	)
	arm64? (
		https://github.com/argoproj/argo-cd/releases/download/v${PV}/argocd-linux-arm64
			-> ${P}-linux-arm64
	)
"

LICENSE="Apache-2.0"
SLOT="0"
# Upstream officially supports linux/amd64 + linux/arm64 (also ppc64le and
# s390x, omitted here unless requested).
KEYWORDS="-* ~amd64 ~arm64"

# Upstream ships an unstripped Go binary on purpose — debug_info kept for
# panic traces / pprof. strip(1) on Go binaries also risks corrupting
# runtime reflection metadata. Skip the post-install strip pass.
RESTRICT="strip"

# Pure-Go static binary — no libc linkage, no runtime deps.
RDEPEND=""

S="${WORKDIR}"

src_unpack() {
	# SRC_URI ships one bare binary per arch; pick the one matching the
	# active USE arch and stage as ${S}/argocd for the rest of the phases.
	local my_bin
	use amd64 && my_bin="${P}-linux-amd64"
	use arm64 && my_bin="${P}-linux-arm64"

	cp "${DISTDIR}/${my_bin}" "${S}/${MY_PN}" || die "failed to stage argocd binary"
	chmod +x "${S}/${MY_PN}" || die
}

src_compile() {
	# Regenerate completions from the freshly-staged binary so they always
	# match the version being installed (cobra-based, like helm/kubectl).
	local shell
	for shell in bash zsh fish; do
		./${MY_PN} completion "${shell}" > "${MY_PN}.${shell}" \
			|| die "failed to generate ${shell} completion"
	done
}

src_install() {
	dobin "${MY_PN}"

	newbashcomp "${MY_PN}.bash" "${MY_PN}"
	newzshcomp  "${MY_PN}.zsh"  "_${MY_PN}"
	newfishcomp "${MY_PN}.fish" "${MY_PN}.fish"
}

pkg_postinst() {
	elog "argocd is the CLI client for ArgoCD GitOps controllers."
	elog ""
	elog "Quick start (against an existing cluster):"
	elog "  kubectl config use-context <your-cluster>"
	elog "  argocd login <argocd-server>     # API-server mode"
	elog "  argocd --core <subcommand>       # talk directly to k8s, skip API server"
	elog ""
	elog "CLI/server protocol versions should track each other; this binary"
	elog "is v${PV} (3.3.x line). Pin your in-cluster ArgoCD to the same"
	elog "minor for compatibility."
}
