# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_SINGLE_IMPL=1
DISTUTILS_USE_PEP517=hatchling
PYTHON_COMPAT=( python3_14 )

inherit distutils-r1 pypi

DESCRIPTION="Atlassian MCP server for Jira and Confluence"
HOMEPAGE="
	https://github.com/sooperset/mcp-atlassian
	https://pypi.org/project/mcp-atlassian/
"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

# e2e and integration suites require live Jira/Confluence instances
RESTRICT="test"

RDEPEND="
	$(python_gen_cond_dep '
		>=dev-python/anyio-4.0.0[${PYTHON_USEDEP}]
		>=dev-python/atlassian-python-api-4.0.0[${PYTHON_USEDEP}]
		<dev-python/atlassian-python-api-5[${PYTHON_USEDEP}]
		>=dev-python/beautifulsoup4-4.12.3[${PYTHON_USEDEP}]
		>=dev-python/cachetools-5.0.0[${PYTHON_USEDEP}]
		>=dev-python/click-8.1.7[${PYTHON_USEDEP}]
		>=dev-python/httpx-0.28.0[${PYTHON_USEDEP}]
		>=dev-python/keyring-25.6.0[${PYTHON_USEDEP}]
		>=dev-python/mcp-1.27.0[${PYTHON_USEDEP}]
		<dev-python/mcp-2[${PYTHON_USEDEP}]
		>=dev-python/fastmcp-3.2.4[${PYTHON_USEDEP}]
		<dev-python/fastmcp-4[${PYTHON_USEDEP}]
		>=dev-python/markdown-3.7.0[${PYTHON_USEDEP}]
		>=dev-python/markdown-to-confluence-0.6.0[${PYTHON_USEDEP}]
		<dev-python/markdown-to-confluence-0.7[${PYTHON_USEDEP}]
		>=dev-python/markdownify-0.11.6[${PYTHON_USEDEP}]
		>=dev-python/pydantic-2.10.6[${PYTHON_USEDEP}]
		<dev-python/pydantic-3[${PYTHON_USEDEP}]
		>=dev-python/python-dateutil-2.9.0_p0[${PYTHON_USEDEP}]
		>=dev-python/python-dotenv-1.0.1[${PYTHON_USEDEP}]
		>=dev-python/requests-2.31.0[socks5,${PYTHON_USEDEP}]
		>=dev-python/starlette-1.0.1[${PYTHON_USEDEP}]
		>=dev-python/thefuzz-0.22.1[${PYTHON_USEDEP}]
		>=dev-python/trio-0.29.0[${PYTHON_USEDEP}]
		>=dev-python/truststore-0.10.0[${PYTHON_USEDEP}]
		>=dev-python/unidecode-1.3.0[${PYTHON_USEDEP}]
		>=dev-python/urllib3-2.6.3[${PYTHON_USEDEP}]
		>=dev-python/uvicorn-0.27.1[${PYTHON_USEDEP}]
	')
"
BDEPEND="
	$(python_gen_cond_dep '
		>=dev-python/uv-dynamic-versioning-0.7.0[${PYTHON_USEDEP}]
	')
"

python_compile() {
	# pyproject.toml declares dynamic = ["version"]; uv-dynamic-versioning
	# would derive it from git, which does not exist in the sdist.  The
	# sdist's PKG-INFO normally provides it, but stamp it explicitly so
	# the wheel version can never silently fall back to pyproject's
	# fallback-version (0.0.0).
	local -x UV_DYNAMIC_VERSIONING_BYPASS=${PV}
	distutils-r1_python_compile
}
