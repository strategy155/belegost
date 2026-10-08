# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{11..14} )

inherit distutils-r1 pypi

DESCRIPTION="Python Atlassian REST API Wrapper"
HOMEPAGE="
	https://github.com/atlassian-api/atlassian-python-api
	https://pypi.org/project/atlassian-python-api/
"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64"

# 4.x line: net-misc/mcp-atlassian pins <5.0.0 (PyPI latest is 5.x)
RDEPEND="
	dev-python/beautifulsoup4[${PYTHON_USEDEP}]
	dev-python/deprecated[${PYTHON_USEDEP}]
	dev-python/jmespath[${PYTHON_USEDEP}]
	dev-python/oauthlib[${PYTHON_USEDEP}]
	dev-python/requests[${PYTHON_USEDEP}]
	dev-python/requests-oauthlib[${PYTHON_USEDEP}]
	dev-python/typing-extensions[${PYTHON_USEDEP}]
"

distutils_enable_tests pytest
