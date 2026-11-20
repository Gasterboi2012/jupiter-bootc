# Jupiter — NVIDIA-only atomic KDE Plasma desktop
#
# Base: ghcr.io/ublue-os/kinoite-main:44 (Fedora 44 + KDE Plasma).
# NVIDIA: ghcr.io/ublue-os/akmods-nvidia-open:main-44, installed with the
# nvidia-install.sh documented in the image-template README. The standalone
# kinoite-nvidia base image was retired upstream; see README.md.

# Allow build scripts to be referenced without being copied into the final image
FROM scratch AS ctx
COPY build_files /
COPY system_files /system_files

# NVIDIA akmods (open kernel modules) for Fedora 44
FROM ghcr.io/ublue-os/akmods-nvidia-open:main-44 AS nvidia-akmods

# Base image
FROM ghcr.io/ublue-os/kinoite-main:44

# Image identity, consumed by build_files/build.sh and by the NVIDIA installer
ARG IMAGE_NAME="jupiter-bootc"
ARG IMAGE_ID="jupiter"
ARG IMAGE_PRETTY_NAME="Jupiter"

# Vesktop is not in Fedora; pin the vendor RPM version and checksum
ARG VESKTOP_VERSION="1.7.0"
ARG VESKTOP_SHA256="859e32db6e12345e4a1298effb2282e858ca976e3efb29e95f1a5991a22fd736"

### MODIFICATIONS
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    --mount=type=bind,from=nvidia-akmods,source=/rpms,target=/tmp/akmods-rpms \
    /ctx/build.sh

### LINTING
RUN bootc container lint
