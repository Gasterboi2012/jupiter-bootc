#!/bin/bash

set -ouex pipefail

# Used by the RPM Fusion release URLs and exported to image-info.sh.
FEDORA_VERSION="$(rpm -E %fedora)"
export FEDORA_VERSION

# Copy the contents of system_files/ of the git repo to /
cp -avf "/ctx/system_files"/. /

### Identity
# os-release is the single source of truth for the name, variant and logo that
# KDE About, KInfoCenter and Plasma Login Manager show. It is rewritten from
# the Containerfile build arguments by the image-info script.
/ctx/image-info.sh

### Branding assets
# Replaceable sources live in /usr/share/jupiter/branding/; the build copies
# them to the runtime paths that KDE, Plasma Login Manager and Plymouth read.
install -Dm0644 /usr/share/jupiter/branding/jupiter-logo.svg \
	/usr/share/icons/hicolor/scalable/apps/jupiter.svg
install -Dm0644 /usr/share/jupiter/branding/wallpaper-3840x2160.png \
	/usr/share/wallpapers/Jupiter/contents/images/3840x2160.png
install -Dm0644 /usr/share/jupiter/branding/plymouth-1920x1080.png \
	/usr/share/plymouth/themes/jupiter/splash.png

# The base image's uBlue login tip is user-visible branding. Jupiter ships no
# MOTD; upstream command and package names elsewhere are not branding.
rm -f /etc/profile.d/user-motd.sh \
	/etc/motd \
	/usr/share/ublue-os/motd/tips/15-ublue-config.md

### Flatpaks
# The base image has no Flatpak preinstall entries. Remove any inherited ones so
# only the two applications Jupiter declares are installed on first boot.
for preinstall_dir in /usr/share/flatpak/preinstall.d /etc/flatpak/preinstall.d; do
	[ -d "${preinstall_dir}" ] || continue
	find "${preinstall_dir}" -maxdepth 1 -type f -name '*.preinstall' \
		! -name 'jupiter.preinstall' -delete
done

# Flathub is already shipped by the base image as a vendor remote in
# /etc/flatpak/remotes.d/, which Flatpak reads when it creates the system
# installation. Assert it rather than writing /var state at build time; the
# first-boot preinstall service then resolves the CollectionID.
test -f /etc/flatpak/remotes.d/flathub.flatpakrepo

# Fedora ships `flatpak preinstall` but no unit that runs it. Universal Blue
# images ship this unit; it is the documented distribution-side mechanism.
systemctl enable flatpak-preinstall.service

### Steam
# RPM Fusion nonfree carries Steam; RPM Fusion's nonfree repository requires
# the free repository to be installed as well.
dnf5 install -y \
	"https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${FEDORA_VERSION}.noarch.rpm" \
	"https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${FEDORA_VERSION}.noarch.rpm"

# steam is an i686 package; dnf5 pulls the i686 multilib runtime with it.
dnf5 install -y steam
rpm -q glibc.i686 >/dev/null

### Vesktop (pinned vendor RPM)
VESKTOP_RPM="/tmp/vesktop-${VESKTOP_VERSION}.x86_64.rpm"
curl -fL --retry 3 -o "${VESKTOP_RPM}" \
	"https://github.com/Vencord/Vesktop/releases/download/v${VESKTOP_VERSION}/vesktop-${VESKTOP_VERSION}.x86_64.rpm"
echo "${VESKTOP_SHA256}  ${VESKTOP_RPM}" | sha256sum -c -
dnf5 install -y "${VESKTOP_RPM}"
rm -f "${VESKTOP_RPM}"

### NVIDIA
# The installer comes from ghcr.io/ublue-os/akmods-nvidia-open:main-44 and is
# mounted at /tmp/akmods-rpms by the Containerfile. IMAGE_NAME is already set
# from the build argument, which keeps the optional supergfxctl out of Jupiter.
/tmp/akmods-rpms/ublue-os/nvidia-install.sh

### Plymouth
# The theme and its script plugin must exist before the initramfs is generated,
# otherwise the boot splash is not included in the initramfs.
dnf5 install -y plymouth-plugin-script
plymouth-set-default-theme jupiter

KERNEL_VERSION="$(rpm -q --queryformat='%{VERSION}-%{RELEASE}.%{ARCH}' kernel-core)"
export DRACUT_NO_XATTR=1
dracut --no-hostonly --kver "${KERNEL_VERSION}" --reproducible --add ostree \
	-f "/usr/lib/modules/${KERNEL_VERSION}/initramfs.img"
chmod 0600 "/usr/lib/modules/${KERNEL_VERSION}/initramfs.img"
