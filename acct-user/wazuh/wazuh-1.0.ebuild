# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit acct-user

DESCRIPTION="User for the Wazuh agent (app-admin/wazuh-agent)"

# belegost is an overlay, not ::gentoo: dynamic UID allocation is the
# eclass-documented recommendation for overlays (acct-user.eclass:
# "Overlays should set this to -1 to dynamically allocate UID").
ACCT_USER_ID=-1

# Mirrors ::gentoo acct-user/ossec and the tthh430/wazuh-gentoo
# precedent: /var/ossec is the agent's state root (upstream default
# INSTALLDIR, src/Makefile).  The agent ebuild keepdirs and owns the
# subtree itself (devmanual users-and-groups: the consuming package
# must not rely on the acct-user package transitively).
ACCT_USER_HOME=/var/ossec
ACCT_USER_GROUPS=( wazuh )

acct-user_add_deps
