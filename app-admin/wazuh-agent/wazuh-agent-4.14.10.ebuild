# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

# No eclass: plain emake build, OpenRC-only init (no systemd on this
# workstation), acct packages consumed as atoms.

DESCRIPTION="Wazuh agent - host intrusion detection agent (OSSEC fork)"
HOMEPAGE="https://wazuh.com https://github.com/wazuh/wazuh"

# The tag archive plus the three stay-vendored tarballs (Bucket C; see
# files/system-libs.patch for why each cannot unbundle) and Wazuh's own
# http-request tool at the commit src/Makefile pins.  Fetched here, not
# by `make deps`: the sandbox blocks the network at build time.
SRC_URI="
	https://github.com/wazuh/wazuh/archive/v${PV}.tar.gz -> ${P}.tar.gz
	https://packages.wazuh.com/deps/55/libraries/sources/libbpf-bootstrap.tar.gz
	https://packages.wazuh.com/deps/55/libraries/sources/libdb.tar.gz
	https://packages.wazuh.com/deps/55/libraries/sources/procps.tar.gz
	https://github.com/wazuh/wazuh-http-request/tarball/cd50797cfe03c27f3759bdc243fecca6f7535d35
		-> wazuh-http-request-cd50797.tar.gz
"

# GPL-2 for the wazuh code; the vendored set adds AGPL-3.0 (BDB 18.1)
# and LGPL-2.1{,+} (libbpf-bootstrap, procps) - see metadata.xml.
LICENSE="AGPL-3.0 GPL-2 LGPL-2.1 LGPL-2.1+"
SLOT="0"
KEYWORDS="~amd64"
IUSE="audit selinux"

RDEPEND="
	acct-group/wazuh
	acct-user/wazuh
	audit? ( sys-process/audit )
	selinux? ( sec-policy/selinux-base-policy )
	dev-libs/cJSON
	dev-libs/libpcre2
	dev-libs/libyaml
	dev-libs/msgpack
	dev-libs/openssl:=
	dev-cpp/nlohmann_json
	dev-cpp/cpp-httplib
	dev-db/sqlite:3
	net-misc/curl
	sys-apps/dbus
	sys-libs/zlib
	app-arch/rpm
	!!net-analyzer/ossec-hids
"
DEPEND="${RDEPEND}"

# !!net-analyzer/ossec-hids: both packages own /var/ossec (the rpm
# spec declares the same conflict) - without the blocker they collide
# on every file.

# GLEP 81: user/group needed at install and run time.  The system libs
# are the unbundled set from files/system-libs.patch (DT_NEEDED of
# libwazuhext.so).  No gcc pin: the system toolchain builds this; a
# gcc:14 slot pin is the documented fallback if GCC 16 breaks.
BDEPEND="dev-build/cmake"

S="${WORKDIR}/wazuh-${PV}"

PATCHES=(
	"${FILESDIR}/system-libs.patch"
	"${FILESDIR}/trim-fetch-surface.patch"
	"${FILESDIR}/disable-pacman-inventory.patch"
)

src_prepare() {
	default

	# Portage already unpacked everything into ${WORKDIR}; relocate the
	# vendored trees into the layout src/Makefile expects.  Both the
	# trees (for the .a build rules) and the tarball files (for the deps
	# demands) must be present - the Makefile's fetch rule bundles
	# fetch-AND-extract, so a pre-existing tarball suppresses both.
	local dep
	for dep in libbpf-bootstrap libdb procps; do
		mv "${WORKDIR}/${dep}" "${S}/src/external/${dep}" || die
		cp "${DISTDIR}/${dep}.tar.gz" "${S}/src/external/${dep}.tar.gz" || die
	done

	# http-request: renamed to the shared_modules/http-request/ the
	# Makefile's --strip-components=1 rule (src/Makefile, the
	# shared_modules/http-request.tar.gz target) would have produced.
	mv "${WORKDIR}"/wazuh-wazuh-http-request-* \
		"${S}/src/shared_modules/http-request" || die
	cp "${DISTDIR}/wazuh-http-request-cd50797.tar.gz" \
		"${S}/src/shared_modules/http-request.tar.gz" || die
}

src_compile() {
	# Two emake calls mirror the upstream recipe (`make deps` then
	# `make`).  EXTERNAL_SRC_ONLY=yes stays on the source-only path -
	# without it the precompiled-binary branch attempts a network
	# fetch the sandbox blocks.
	local mymakeargs=(
		TARGET=agent
		WAZUH_USER=wazuh
		WAZUH_GROUP=wazuh
	)
	use audit && mymakeargs+=( USE_AUDIT=yes )
	use selinux && mymakeargs+=( USE_SELINUX=yes )

	emake -C src EXTERNAL_SRC_ONLY=yes "${mymakeargs[@]}" deps
	emake -C src "${mymakeargs[@]}"
}

src_install() {
	# No `make install` upstream (AUR source-build mirrors install.sh
	# by hand for the same reason); exeinto/doexe take prefix-relative
	# paths.  The SCA policies are NOT installed - generated data,
	# absent from the tag archive.

	exeinto /var/ossec/bin
	doexe "${S}"/src/{wazuh-agentd,agent-auth,wazuh-logcollector,wazuh-syscheckd,wazuh-execd,manage_agents,active-responses,wazuh-modulesd}
	newexe "${S}"/src/init/wazuh-client.sh wazuh-control

	exeinto /var/ossec/lib
	# src-root pair from the Makefile-driven build
	doexe "${S}"/src/libwazuhext.so* "${S}"/src/libwazuhshared.so*
	# the CMake subproject libraries, from their scattered build trees
	doexe "${S}"/src/shared_modules/{dbsync,rsync}/build/bin/*.so \
		"${S}"/src/data_provider/build/lib/*.so \
		"${S}"/src/wazuh_modules/syscollector/build/bin/*.so \
		"${S}"/src/shared_modules/syscollector/build/modern.bpf.o

	# Default configs shipped as files/ artifacts (the tag archive has
	# no src/etc/ for Linux; the installer synthesizes both).
	insinto /var/ossec/etc
	doins "${FILESDIR}/ossec.conf"
	doins "${FILESDIR}/internal_options.conf"
	fowners wazuh:wazuh /var/ossec/etc/ossec.conf
	fperms 0640 /var/ossec/etc/ossec.conf

	keepdir /var/ossec/logs/{alerts,archives,firewall}
	keepdir /var/ossec/queue/{diff,fts,rids,syscheck}
	keepdir /var/ossec/var/run

	newenvd - 50wazuh-agent <<< 'CONFIG_PROTECT="/var/ossec/etc"'

	# Per-daemon OpenRC services (kea-style, dosym-instantiated; the
	# daemons all take -f, so each runs foregrounded under
	# start-stop-daemon --background with a static pidfile).
	newinitd "${FILESDIR}/wazuh-agent.initd" wazuh-agentd
	newconfd "${FILESDIR}/wazuh-agent.confd" wazuh-agentd
	local daemon
	for daemon in wazuh-execd wazuh-logcollector wazuh-modulesd wazuh-syscheckd; do
		dosym wazuh-agentd /etc/init.d/${daemon}
		newconfd "${FILESDIR}/wazuh-agent.confd" ${daemon}
	done
}

pkg_postinst() {
	elog "Wazuh agent needs a manager to connect to."
	elog "Configure /var/ossec/etc/ossec.conf then enroll:"
	elog "  emerge --config =${CATEGORY}/${PF}"
}

pkg_config() {
	# emerge --config hook: enrollment, mirroring the RPM deployment
	# flow (WAZUH_MANAGER / WAZUH_AGENT_GROUP env vars).
	local manager="${WAZUH_MANAGER:-}"
	local agent_group="${WAZUH_AGENT_GROUP:-}"
	local config="/var/ossec/etc/ossec.conf"

	if [[ -z "${manager}" ]]; then
		eerror "WAZUH_MANAGER is not set (or empty) - enrollment cannot proceed."
		eerror "Usage:"
		eerror "  WAZUH_MANAGER=<ip-or-host> [WAZUH_AGENT_GROUP=<group>] emerge --config =${CATEGORY}/${PF}"
		return 1
	fi

	# Manager address: the substitution src/init/replace_manager_ip.sh
	# performs for the RPM flow.
	ebegin "Setting manager address to ${manager}"
	sed -i "s|<address>.*</address>|<address>${manager}</address>|" "${config}"
	eend $?

	# Agent group: <groups> inside <enrollment> (the placement of
	# register_configure_agent.sh's set_auto_enrollment_tag_value).
	if [[ -n "${agent_group}" ]]; then
		ebegin "Setting agent group to ${agent_group}"
		sed -i "s|</enrollment>|<groups>${agent_group}</groups></enrollment>|" "${config}"
		eend $?
	fi
}
