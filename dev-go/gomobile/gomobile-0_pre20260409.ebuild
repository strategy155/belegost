# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

# go-module: unpacks a pre-populated ${WORKDIR}/go-mod cache so `ego build`
# runs fully offline under portage's network sandbox, and exports the
# sandbox-safe `ego` wrapper around go(1).
inherit go-module

# Upstream tags nothing — golang.org/x/mobile is pseudo-version-only. Pin by
# full commit SHA; the Gentoo version `0_pre<YYYYMMDD>` encodes the snapshot
# date in a way portage orders sensibly across future bumps.
EGIT_COMMIT="2cfb76559b7b64602788d193d8f1387d81bbb481"

DESCRIPTION="Go mobile toolchain: gomobile build/bind + gobind bindings generator"
HOMEPAGE="
	https://pkg.go.dev/golang.org/x/mobile
	https://github.com/golang/mobile
"

# Primary tarball: upstream source at the pinned commit (github archive URL).
# Secondary tarball: pre-populated GOMODCACHE packed locally and hosted as a
# menegroth release asset. Matches the dev-util/crush pattern.
SRC_URI="
	https://github.com/golang/mobile/archive/${EGIT_COMMIT}.tar.gz
		-> ${P}.tar.gz
	https://github.com/strategy155/menegroth/releases/download/${P}/${P}-deps.tar.xz
"

LICENSE="BSD"
# Transitive deps in go-mod: audited golang.org/x/{exp/shiny,image,mod,sync,
# tools} — all BSD-3-Clause. No additional license tokens needed; listed
# explicitly for clarity.
SLOT="0"
KEYWORDS="~amd64 ~arm64"

# Go emits its own stripped binary via -s -w ldflags; re-strip corrupts
# Go's runtime type reflection (pclntab / itab data).
RESTRICT="strip"

# Upstream go.mod declares `go 1.25.0`. Gentoo only ships one Go slot at a
# time (SLOT=0/${PV}) — pick the oldest present in the tree that satisfies.
BDEPEND=">=dev-lang/go-1.25"

S="${WORKDIR}/mobile-${EGIT_COMMIT}"

src_compile() {
	# Pure-Go tool — gomobile shells out to Android NDK / Xcode at the
	# user's invocation, but the binary itself needs no native linkage.
	# CGO off also makes the produced binary fully static.
	export CGO_ENABLED=0

	# -trimpath  drop build-host paths from binary metadata for
	#            reproducible, privacy-respecting builds.
	# -ldflags -s / -w  strip symbol table + DWARF (≈30% smaller binary).
	local flags=(-trimpath -ldflags "-s -w")

	# Upstream exposes two separate main packages under cmd/.
	ego build "${flags[@]}" -o gomobile ./cmd/gomobile
	ego build "${flags[@]}" -o gobind   ./cmd/gobind
}

src_install() {
	dobin gomobile gobind
	dodoc README.md
}

pkg_postinst() {
	elog "gomobile is a cross-compile driver; it shells out to toolchains"
	elog "that you install separately:"
	elog "  Android:  set ANDROID_NDK_HOME (for gomobile build/bind -target=android)"
	elog "  iOS:      macOS + Xcode (not supported on Gentoo/Linux)"
	elog ""
	elog "Run 'gomobile init' once before first use — it sanity-checks the"
	elog "toolchain environment and (optionally, with -openal) can build"
	elog "user-supplied OpenAL from source."
	elog ""
	# Upstream quirk, not a packaging bug: `gomobile version` shells out
	# to `go list -m golang.org/x/mobile/cmd/gomobile` which requires a
	# Go module in CWD that references the module. Outside such a dir
	# (e.g. from $HOME) it prints "version unknown" with a module-not-
	# found error. For a module-agnostic sanity check use `gomobile help`.
	elog "Note: 'gomobile version' only works from inside a Go module that"
	elog "imports golang.org/x/mobile — that's upstream behaviour, not a"
	elog "packaging bug. Use 'gomobile help' for a CWD-independent sanity"
	elog "check, or just run 'gomobile build/bind' from inside your project."
}
