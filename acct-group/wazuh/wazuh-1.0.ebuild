# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit acct-group

DESCRIPTION="Group for the Wazuh agent (app-admin/wazuh-agent)"

# belegost is an overlay, not ::gentoo: dynamic GID allocation is the
# eclass-documented recommendation for overlays (acct-group.eclass:
# "Overlays should set this to -1 to dynamically allocate GID").
# A fixed GID cannot be guaranteed unique across repositories
# (GLEP 81 uniqueness is per-repository).
ACCT_GROUP_ID=-1
