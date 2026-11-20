# Jupiter

Jupiter is a bootable, rebaseable atomic desktop image built from the
[Universal Blue image-template](https://github.com/ublue-os/image-template)
layout: KDE Plasma on Fedora 44, delivered as a bootc container image.

It is deliberately small. The base image supplies Plasma, the Plasma Login
Manager, Flatpak, Plymouth and the usual Fedora KDE stack. Jupiter adds only
the packages and defaults listed below.

> **NVIDIA only.** Jupiter requires an NVIDIA GPU supported by NVIDIA's open
> kernel modules (`nvidia-open`). It will not boot correctly on AMD or Intel
> graphics. This is intentional, not a bug. There is exactly one image; there
> are no AMD, Intel or generic variants.

## Base image

| Component | Reference |
| --- | --- |
| KDE base | `ghcr.io/ublue-os/kinoite-main:44` |
| NVIDIA akmods (open) | `ghcr.io/ublue-os/akmods-nvidia-open:main-44` |

The upstream template README documents the `*-main:<fedora>` base tag pattern
(for example `silverblue-main:44`) and the akmods installer. The standalone
`kinoite-nvidia` image was retired upstream, so Jupiter follows the documented
"add NVIDIA drivers to your own image" path rather than depending on a retired
base.

At the time of writing, the base and akmods images are both Fedora 44 with
kernel `7.3.4-200.fc44.x86_64`. Both tags are rolling: if the base kernel moves
ahead of the akmods image, the NVIDIA install or boot can fail. Verify that the
two images share a kernel before building.

## Preinstalled applications

Jupiter installs exactly four applications and uses one installation method
for each.

| Application | Method | Reason |
| --- | --- | --- |
| Steam | native RPM from RPM Fusion nonfree | Requested; not in Fedora. |
| Vesktop 1.7.0 | native vendor RPM, pinned and SHA-256 verified | Requested; not in Fedora. |
| Sober (`org.vinegarhq.Sober`) | Flatpak from Flathub, preinstalled on first boot | Requested. |
| Zen Browser (`app.zen_browser.zen`) | Flatpak from Flathub, preinstalled on first boot | Requested. |

Beyond the four applications and the NVIDIA stack, the only other package
Jupiter adds is `plymouth-plugin-script`, which provides the Plymouth script
module used by the Jupiter boot theme.

The NVIDIA stack is installed by the documented uBlue installer:
`ublue-os-nvidia-addons`, the `nvidia-driver`/`nvidia-driver-cuda` packages and
the matching `kmod-nvidia` built from the nvidia-open sources. No AMD or Intel
akmods are installed.

Repositories: Jupiter adds RPM Fusion free and nonfree for Steam (RPM Fusion
documents that nonfree requires free). Flathub is used through the vendor
remote the base image already ships at
`/etc/flatpak/remotes.d/flathub.flatpakrepo`; the build asserts it is present.
No other third-party repositories are added by Jupiter.

The base image ships no Flatpak preinstall entries, so there were no default
Flatpaks to remove. The build also deletes any inherited `.preinstall` entries
so only Jupiter's two remain. The base ships no fastfetch or neofetch
configuration. The base's uBlue login tip is removed so it cannot show up as
Jupiter branding.

## Build locally

Prerequisites: x86_64 Linux with Podman (rootless or rootful), `just`, `jq`,
`git`, network access, and enough disk space for the Fedora/KDE base image.

```bash
just build
```

`just build` reads `image-template.env` and produces `jupiter-bootc:latest`.
The equivalent direct command is:

```bash
podman build --pull=newer -t jupiter-bootc:latest -f Containerfile .
```

The Containerfile ends with `bootc container lint`, so a successful image build
includes that lint. Shell linting is available with `just lint`, and Justfile
syntax checking with `just check`.

CI (`.github/workflows/build.yml`) builds this single NVIDIA image, rechunks it,
pushes it to GHCR and signs it with the repository's `SIGNING_SECRET`. No AMD,
Intel or generic image is built. Jupiter does not use the template's optional
disk-image workflow; no installer ISO is part of Jupiter's build.

## Rebase onto Jupiter

From an existing bootc system:

```bash
sudo bootc switch ghcr.io/gasterboi2012/jupiter-bootc:latest
sudo reboot
```

CI publishes the image at `ghcr.io/gasterboi2012/jupiter-bootc`.

## Identity and branding

Jupiter rewrites both `/usr/lib/os-release` and `/etc/os-release` at build time
from the Containerfile build arguments, using `build_files/image-info.sh`. The
fields are:

- `NAME=Jupiter`
- `PRETTY_NAME="Jupiter 44 (KDE Plasma)"`
- `ID=jupiter`
- `ID_LIKE=fedora`
- `VERSION="44 (KDE Plasma)"`
- `VARIANT="KDE Plasma"`
- `VARIANT_ID=plasma`
- `LOGO=jupiter`
- `HOME_URL`, `DOCUMENTATION_URL`, `SUPPORT_URL`, `BUG_REPORT_URL` point at this repository
- `DEFAULT_HOSTNAME=jupiter`
- `ANSI_COLOR="0;38;2;124;58;237"`

`/etc/system-release` is replaced with a regular file so it reports Jupiter
rather than the Fedora base. `/etc/issue` is rewritten as well, so a text
console login shows Jupiter instead of Fedora.

KDE reads the display name and version from os-release, and the About page and
KInfoCenter resolve `LOGO=jupiter` as an icon-theme name. The logo is installed
as `/usr/share/icons/hicolor/scalable/apps/jupiter.svg`, and
`/etc/xdg/kcm-about-distrorc` sets `LogoPath=jupiter` so the base image's
generic logo override cannot hide it.

The Plasma Login Manager greeter background is set in
`/usr/lib/plasmalogin/defaults.conf`; the system-wide Plasma desktop wallpaper
default is set in `/etc/xdg/plasma-org.kde.plasma.desktop-appletsrc`. Both point
at the Jupiter wallpaper package.

NVIDIA kernel arguments ship through bootc's documented
`/usr/lib/bootc/kargs.d/00-jupiter-nvidia.toml`: `nvidia-drm.modeset=1` and the
`nouveau,nova_core` blacklists. The initramfs is regenerated at build time
after the NVIDIA driver, Plymouth plugin and theme are installed, so the
Plymouth splash and the NVIDIA driver are present in the initramfs.

### Replacing the placeholder assets

Every placeholder lives in `system_files/usr/share/jupiter/branding/`. See
[REPLACING-ASSETS.md](REPLACING-ASSETS.md) for each file, its dimensions and
format, and the runtime path it is copied to.

## Branding audit

`grep -RniE 'ublue|bluefin|aurora|kinoite|fedora'` over the identity and
branding files leaves only these classes of hit, all intentional:

- `ID_LIKE=fedora` — the documented compatibility field for a Fedora derivative.
- `CPE_NAME`, `REDHAT_*`, `VERSION_ID`, `SUPPORT_END`, `OSTREE_VERSION` and
  `/etc/system-release-cpe` — machine-readable Fedora base-platform metadata
  used by vulnerability and bug-reporting tools. KDE does not display these.
- Base image and upstream package names (`ghcr.io/ublue-os/...`,
  `ublue-os-nvidia-addons`, `fedora` repositories, RPM Fusion) in the
  Containerfile and documentation — references, not user-visible branding.
- Documentation references to Fedora, RPM Fusion, Flatpak and Universal Blue —
  citations, not image branding.

No user-visible distro identity strings remain in KDE About/KInfoCenter, the
Plasma Login Manager, Plymouth or the login banner. The `kinoite-main` base
reference in the Containerfile is the upstream image name; the image itself
reports `Jupiter`, `jupiter` and `KDE Plasma`. Inherited upstream CLI tooling and
package names are not treated as Jupiter identity.

## Documentation used

- [Universal Blue image-template README](https://github.com/ublue-os/image-template) — repository layout, build conventions, NVIDIA akmods stage/installer and the initramfs recipe.
- [Universal Blue akmods README](https://github.com/ublue-os/akmods) — nvidia-open image and installer path.
- [bootc documentation](https://bootc.dev/) — filesystem rules, build-time OS content and `/usr/lib/bootc/kargs.d` kernel arguments.
- [os-release(5)](https://www.freedesktop.org/software/systemd/man/latest/os-release.html) — identity fields and `/etc/os-release` precedence.
- [RPM Fusion configuration](https://rpmfusion.org/Configuration), [FAQ](https://rpmfusion.org/FAQ) and [NVIDIA how-to](https://rpmfusion.org/Howto/NVIDIA) — repositories, nonfree/free dependency and OSTree kernel arguments.
- [Fedora Kinoite documentation](https://docs.fedoraproject.org/en-US/fedora-kinoite/) — Fedora Atomic KDE base behaviour.
- [Flatpak `flatpak-preinstall` manual](https://docs.flatpak.org/en/latest/flatpak-command-reference.html) and [Flathub setup](https://flathub.org/setup/Fedora) — preinstall file format, Flathub's `.flatpakrepo`, and the `/etc/flatpak/remotes.d` vendor-remote mechanism.
- [Plasma Login Manager](https://invent.kde.org/plasma/plasma-login-manager) and [KDE Kiosk documentation](https://develop.kde.org/docs/administration/kiosk/) — system-wide greeter and `/etc/xdg` defaults.
- [KDE KInfoCenter branding documentation](https://userbase.kde.org/KInfoCenter) and the [about-distro logo commit](https://invent.kde.org/plasma/kinfocenter/-/commit/e7e44a7af825c7db2c86399940b3d260a730cdf5) — `LOGO` resolution, and that `LogoPath` may be an icon-theme name.
- [Plymouth](https://www.freedesktop.org/wiki/Software/Plymouth/) and Fedora's `plymouth-plugin-script` package — script theme format, theme directory and default theme.
- [Vesktop releases](https://github.com/Vencord/Vesktop/releases) — pinned v1.7.0 RPM and checksum.
- [Flathub](https://flathub.org/) — `org.vinegarhq.Sober` and `app.zen_browser.zen` app IDs.

`CHANGES.md` records what each source settled, the conflicts between sources,
and the verification that was and was not possible in the preparation
environment.

## Verification status

The repository was prepared in an environment without Podman, root privileges
or an NVIDIA GPU. Static checks (shell linting, config parsing, asset
dimensions, checksums and registry lookups) were run; `just build`,
`bootc container lint` and a real boot into Plasma were not possible there.
Run `just build` on a build host and boot the result before treating the image
as release-ready. See [CHANGES.md](CHANGES.md#verification).
