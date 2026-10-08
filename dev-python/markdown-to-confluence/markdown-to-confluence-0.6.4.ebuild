# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{11..14} )

inherit distutils-r1 pypi

DESCRIPTION="Publish Markdown files to Confluence wiki"
HOMEPAGE="
	https://github.com/hunyadi/md2conf
	https://pypi.org/project/markdown-to-confluence/
"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

# upstream floors verified against ::gentoo; orjson needed via
# cattrs.preconf.orjson, pymdown-extensions via markdown's dynamic
# extension loading (module pymdownx) - both invisible to ^import greps
RDEPEND="
	>=dev-python/cattrs-26.2[${PYTHON_USEDEP}]
	>=dev-python/lxml-6.1[${PYTHON_USEDEP}]
	>=dev-python/markdown-3.10[${PYTHON_USEDEP}]
	>=dev-python/orjson-3.12[${PYTHON_USEDEP}]
	>=dev-python/pathspec-1.1[${PYTHON_USEDEP}]
	>=dev-python/pymdown-extensions-12.0[${PYTHON_USEDEP}]
	>=dev-python/pyyaml-6.0[${PYTHON_USEDEP}]
	>=dev-python/requests-2.34[${PYTHON_USEDEP}]
	>=dev-python/truststore-0.10[${PYTHON_USEDEP}]
"

# typing-extensions dropped: requires_dist marks it python_version < "3.11"
# and PYTHON_COMPAT starts at 3.11
#
# orjson: DeprecatedDep warning accepted - upstream md2conf hard-imports
# cattrs.preconf.orjson (no fallback). ::gentoo deprecates dev-python/
# orjson (2026-04-01: upstream accepts no bug reports; unsafe Rust) but
# keeps it current (3.13.0) and GURU's fastapi chain blocks near-term
# removal. TRIPWIRE: if orjson lands in package.mask, inherit it here
# via cargo+distutils-r1 (pycargoebuild, 23 crates) - or patch/re-drop.

distutils_enable_tests pytest
