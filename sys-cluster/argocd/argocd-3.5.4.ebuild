# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

ARGOCD_COMMIT=d6d5b248ce00e1a2c512068002a93d3319767087

inherit go-module shell-completion

DESCRIPTION="CLI for Argo CD, declarative GitOps continuous delivery for Kubernetes"
HOMEPAGE="https://argo-cd.readthedocs.io https://github.com/argoproj/argo-cd"
SRC_URI="
	https://github.com/argoproj/argo-cd/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz
	https://github.com/strategy155/menegroth/releases/download/${P}/${P}-deps.tar.xz
"

S="${WORKDIR}/argo-cd-${PV}"

# go-licenses report ./cmd (dev-go/go-licenses)
LICENSE="Apache-2.0 BSD BSD-2 Boost-1.0 ISC MIT MPL-2.0 Unlicense"
SLOT="0"
KEYWORDS="~amd64"

# go floor per go.mod directive (go 1.26.3; full assignment since it
# clobbers the eclass floor of 1.24.11 - syncthing/helm/mcpproxy pattern)
BDEPEND=">=dev-lang/go-1.26.3"

src_compile() {
	# CLI-only build: upstream ships ui/dist/app as .gitkeep placeholders
	# precisely so the tree compiles without the pnpm UI build - the web
	# UI is served by argocd-server only, never by the CLI.  ./cmd is the
	# multi-call binary upstream also builds (argocd, argocd-server, ...
	# differ only by argv[0]); we install it under the CLI name alone.
	#
	# CGO off pins parity with the official release binary (Makefile
	# DEFAULT_CGO_FLAG=0): without it go's auto-detect enables cgo
	# whenever a compiler exists (always true in portage), switching the
	# net package to the getaddrinfo resolver and linking glibc
	# dynamically - a different binary than upstream ships and tests.
	local -x CGO_ENABLED=0
	local common=github.com/argoproj/argo-cd/v3/common
	# kubectlVersion: upstream Makefile formula (go list -m), template
	# form per GURU net-proxy/Throne - resolves through the client-go
	# self-replace in go.mod
	local kubectl_ver=$(ego list -m -f '{{.Version}}' k8s.io/client-go)
	# kube-style name (hack/lib/golang.sh): go linker flags, distinct
	# from portage's LDFLAGS.  Stamps mirror the Makefile LDFLAGS block;
	# buildDate is upstream's own formula (Makefile:25) - the build
	# moment, same as every official binary and Gentoo's kubectl.
	# ARGOCD_COMMIT is the v3.5.4 tag SHA (helm hardcodes GIT_COMMIT
	# the same way - GitHub archives carry no commit metadata).
	local -a goldflags=(
		-X ${common}.version=${PV}
		-X ${common}.gitTag=v${PV}
		-X ${common}.gitCommit=${ARGOCD_COMMIT}
		-X ${common}.gitTreeState=clean
		-X ${common}.kubectlVersion=${kubectl_ver}
		-X ${common}.buildDate=$(date -u +%Y-%m-%dT%H:%M:%SZ)
	)
	ego build -ldflags "${goldflags[*]}" -o ${PN} ./cmd
}

src_install() {
	dobin ${PN}
	einstalldocs

	# the binary is the completion generator (same pattern as
	# net-proxy/mcpproxy, net-misc/cscs-key)
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
