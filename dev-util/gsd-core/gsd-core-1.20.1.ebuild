# Copyright 2026 strategy155
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Spec-driven development and context-engineering for AI coding agents"
HOMEPAGE="https://github.com/open-gsd/gsd-core"

# Open continuation of the now-deprecated get-shit-done-cc. Published only on
# npm under the @opengsd scope; GitHub releases carry no asset tarballs.
SRC_URI="https://registry.npmjs.org/@opengsd/${PN}/-/${PN}-${PV}.tgz"
S="${WORKDIR}/package"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~arm64"

# engines.node is >=24 since 1.7.x. No build/runtime npm deps are actually
# needed: every shipped code path (bin/install.js, bin/gsd-mcp-server.js,
# gsd-core/bin/gsd-tools.cjs, gsd_run) uses only Node builtins + relative
# requires. The package.json deps (@anthropic-ai/claude-agent-sdk, ws) are
# vestigial since the SDK seam was retired, so we ship no vendor cache and
# run no npm install. The get-shit-done-cc blocker from 1.5.0 is dropped: the
# deprecated package no longer exists in any repo and was unmerged.
RDEPEND=">=net-libs/nodejs-24"

src_compile() {
	# Upstream pre-builds bin/install.js (esbuild) and gsd-core/bin/lib (tsc)
	# in its prepublishOnly hook; the published tarball is ready to run.
	:
}

src_install() {
	# Drop the package tree in place (no npm: the bins are self-contained) and
	# expose the four CLIs the same way npm's global bin links would.
	local nmdir="/usr/$(get_libdir)/node_modules/@opengsd/${PN}"
	insinto "${nmdir}"
	doins -r .
	# doins clears the exec bit; restore it on the entrypoints.
	fperms 0755 \
		"${nmdir}/bin/install.js" \
		"${nmdir}/bin/gsd-mcp-server.js" \
		"${nmdir}/gsd-core/bin/gsd-tools.cjs" \
		"${nmdir}/gsd-core/bin/gsd_run"

	dosym "../$(get_libdir)/node_modules/@opengsd/${PN}/bin/install.js" /usr/bin/gsd-core
	dosym "../$(get_libdir)/node_modules/@opengsd/${PN}/bin/gsd-mcp-server.js" /usr/bin/gsd-mcp-server
	dosym "../$(get_libdir)/node_modules/@opengsd/${PN}/gsd-core/bin/gsd-tools.cjs" /usr/bin/gsd-tools
	dosym "../$(get_libdir)/node_modules/@opengsd/${PN}/gsd-core/bin/gsd_run" /usr/bin/gsd_run

	einstalldocs
}

pkg_postinst() {
	elog "Deploy GSD Core into your AI runtime with the bundled installer, e.g.:"
	elog ""
	elog "    gsd-core --claude --global"
	elog "    gsd-core --opencode --global"
	elog "    gsd-core --kimi-code --global   # Kimi Code CLI (Node) since 1.10.0"
	elog ""
	elog "It writes skills/commands/agents into the runtime's config dir (or the"
	elog "project dir with --local); for kimi-code it also appends a managed"
	elog "[[hooks]] block to ~/.kimi-code/config.toml. A prior get-shit-done-cc"
	elog "deployment is migrated: manifest-tracked files in the legacy command/"
	elog "and get-shit-done/ dirs are removed, but hooks/ leftovers and emptied"
	elog "directories are not; prune those by hand."
	elog ""
	elog "For OpenCode the installer registers the MCP server as an npx command"
	elog "that fetches npm 'latest' on every start (upstream #5263, won't fix)."
	elog "Edit mcp.gsd.command in opencode.json once to"
	elog "    [\"gsd-mcp-server\", \"--no-prompts\"]"
	elog "to use this package's binary; an existing mcp.gsd entry is never"
	elog "overwritten by later deploys."
}
