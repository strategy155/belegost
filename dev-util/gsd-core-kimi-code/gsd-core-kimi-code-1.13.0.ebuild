# Copyright 2026 strategy155
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="GSD Core spec-driven development system, patched for Kimi Code CLI"
HOMEPAGE="https://github.com/open-gsd/gsd-core"

# Same @opengsd/gsd-core npm tarball as dev-util/gsd-core (hardcoded: our PN
# differs), plus FILESDIR patches fixing the Kimi Code deployment surface:
# hook event/matcher specs, payload normalization, block-reason channels,
# skill/agent path conversion, and a Kimi-shaped statusline. Installs under
# its own libdir prefix and exposes only the deployer symlink, so the two
# packages coexist — the vanilla package keeps serving the Claude deployment
# and the daily-driver /usr/bin symlinks (gsd-tools, gsd_run, gsd-mcp-server).
SRC_URI="https://registry.npmjs.org/@opengsd/gsd-core/-/gsd-core-${PV}.tgz"
S="${WORKDIR}/package"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~arm64"

RDEPEND=">=net-libs/nodejs-24"

PATCHES=(
	"${FILESDIR}/${P}-hooks-toml-specs.patch"
	"${FILESDIR}/${P}-hook-payload-normalization.patch"
	"${FILESDIR}/${P}-hook-output-channels.patch"
	"${FILESDIR}/${P}-skill-paths.patch"
	"${FILESDIR}/${P}-statusline.patch"
)

src_compile() {
	# Upstream pre-builds bin/install.js (esbuild) and gsd-core/bin/lib (tsc)
	# in its prepublishOnly hook; the published tarball is ready to run.
	:
}

src_install() {
	local nmdir="/usr/$(get_libdir)/node_modules/@opengsd/${PN}"
	insinto "${nmdir}"
	doins -r .
	# doins clears the exec bit; restore it on the entrypoints + statusline.
	fperms 0755 \
		"${nmdir}/bin/install.js" \
		"${nmdir}/bin/gsd-mcp-server.js" \
		"${nmdir}/gsd-core/bin/gsd-tools.cjs" \
		"${nmdir}/gsd-core/bin/gsd_run" \
		"${nmdir}/hooks/gsd-statusline-kimi.js"

	# Only the deployer: gsd-tools/gsd_run/gsd-mcp-server stay owned by the
	# vanilla dev-util/gsd-core package.
	dosym "../$(get_libdir)/node_modules/@opengsd/${PN}/bin/install.js" /usr/bin/gsd-core-kimi-code

	einstalldocs
}

pkg_postinst() {
	elog "Kimi-Code-patched build of GSD Core. Deploy with:"
	elog ""
	elog "    gsd-core-kimi-code --kimi-code --global"
	elog ""
	elog "It writes skills/commands/agents into ~/.kimi-code and appends a"
	elog "managed [[hooks]] block to ~/.kimi-code/config.toml. The vanilla"
	elog "dev-util/gsd-core package (which owns /usr/bin/gsd-tools, gsd_run"
	elog "and gsd-mcp-server) is untouched and coexists with this one."
	elog ""
	elog "Kimi Code statusline: the installer cannot wire it (Kimi Code reads"
	elog "the statusline from tui.toml, not from the hooks block). To enable"
	elog "the GSD statusline, add to ~/.kimi-code/tui.toml:"
	elog ""
	elog "    [status_line]"
	elog "    command = \"node ${EPREFIX}/usr/$(get_libdir)/node_modules/@opengsd/${PN}/hooks/gsd-statusline-kimi.js\""
	elog ""
	elog "Known Kimi Code limitations in this release:"
	elog "  * The read-injection scanner is advisory-only: Kimi Code discards"
	elog "    PostToolUse hook output, so scan warnings never reach the model."
	elog "  * prompt-guard/read-guard advisory messages are invisible on Kimi"
	elog "    Code; only their blocking decisions take effect."
	elog "  * Never run /skill:gsd-update under Kimi Code — it reinstalls"
	elog "    upstream hooks and bypasses this ebuild's patches. Update by"
	elog "    emerging a newer dev-util/gsd-core-kimi-code, then re-run:"
	elog "        gsd-core-kimi-code --kimi-code --global"
}
