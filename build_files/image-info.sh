#!/bin/bash

# Rewrites Jupiter's identity into an os-release tree.
#
# Usage: IMAGE_ID=jupiter IMAGE_PRETTY_NAME=Jupiter image-info.sh [ROOT]
#
# ROOT defaults to / and exists so the logic can be tested against a staged
# tree. The identity comes from build arguments; nothing is hard-coded twice.

set -ouex pipefail

ROOT="${1:-/}"
FEDORA_VERSION="${FEDORA_VERSION:-$(rpm -E %fedora)}"

set_os_release_field() {
	local file="$1"
	local key="$2"
	local value="$3"

	if grep -qE "^${key}=" "${file}"; then
		sed -i -E "s|^${key}=.*|${key}=${value}|" "${file}"
	else
		printf '%s=%s\n' "${key}" "${value}" >>"${file}"
	fi
}

rewrite_os_release() {
	local file="$1"
	local tmp

	[ -f "${file}" ] || return 0

	tmp="$(mktemp)"
	cp -a "${file}" "${tmp}"

	set_os_release_field "${tmp}" NAME "\"${IMAGE_PRETTY_NAME}\""
	set_os_release_field "${tmp}" PRETTY_NAME "\"${IMAGE_PRETTY_NAME} ${FEDORA_VERSION} (KDE Plasma)\""
	set_os_release_field "${tmp}" ID "${IMAGE_ID}"
	set_os_release_field "${tmp}" ID_LIKE "fedora"
	set_os_release_field "${tmp}" VERSION "\"${FEDORA_VERSION} (KDE Plasma)\""
	set_os_release_field "${tmp}" VARIANT "\"KDE Plasma\""
	set_os_release_field "${tmp}" VARIANT_ID "plasma"
	set_os_release_field "${tmp}" LOGO "jupiter"
	set_os_release_field "${tmp}" HOME_URL "\"https://github.com/Gasterboi2012/jupiter-bootc\""
	set_os_release_field "${tmp}" DOCUMENTATION_URL "\"https://github.com/Gasterboi2012/jupiter-bootc/blob/main/README.md\""
	set_os_release_field "${tmp}" SUPPORT_URL "\"https://github.com/Gasterboi2012/jupiter-bootc/issues\""
	set_os_release_field "${tmp}" BUG_REPORT_URL "\"https://github.com/Gasterboi2012/jupiter-bootc/issues\""
	set_os_release_field "${tmp}" DEFAULT_HOSTNAME "jupiter"
	set_os_release_field "${tmp}" ANSI_COLOR "\"0;38;2;124;58;237\""

	# Writing through the original path follows /etc/os-release if it is a symlink.
	cat "${tmp}" >"${file}"
	rm -f "${tmp}"
}

rewrite_os_release "${ROOT}/usr/lib/os-release"
rewrite_os_release "${ROOT}/etc/os-release"

# /etc/system-release is a symlink to Fedora's release file. Replace it with a
# regular file so `cat /etc/system-release` does not report Fedora/Kinoite.
if [ -e "${ROOT}/etc/system-release" ]; then
	rm -f "${ROOT}/etc/system-release"
	printf '%s release %s (KDE Plasma)\n' \
		"${IMAGE_PRETTY_NAME}" "${FEDORA_VERSION}" >"${ROOT}/etc/system-release"
fi

# /etc/issue is the text-console banner. Replace it so a TTY login also
# reports Jupiter rather than the Fedora base.
if [ -e "${ROOT}/etc/issue" ]; then
	rm -f "${ROOT}/etc/issue"
	printf '%s %s (KDE Plasma) \\n \\l\n' \
		"${IMAGE_PRETTY_NAME}" "${FEDORA_VERSION}" >"${ROOT}/etc/issue"
fi

if grep -qiE 'kinoite|ublue|bluefin|aurora' \
	"${ROOT}/usr/lib/os-release" "${ROOT}/etc/os-release" 2>/dev/null; then
	echo "ERROR: upstream branding remains in os-release under ${ROOT}" >&2
	exit 1
fi
