# Changes

This file records what Jupiter changed from the `ublue-os/image-template`, the
sources that drove each decision, the conflicts between those sources, and what
was actually verified.

## Summary

Jupiter is now a single NVIDIA-only KDE Plasma bootc image:

- Base changed from `ghcr.io/ublue-os/bazzite:stable` to
  `ghcr.io/ublue-os/kinoite-main:44`, with
  `ghcr.io/ublue-os/akmods-nvidia-open:main-44` as the NVIDIA akmods stage.
- Identity rewritten at build time: `NAME=Jupiter`, `ID=jupiter`,
  `PRETTY_NAME="Jupiter 44 (KDE Plasma)"`, `ID_LIKE=fedora`,
  `VARIANT="KDE Plasma"`, `VARIANT_ID=plasma`, `LOGO=jupiter`,
  `DEFAULT_HOSTNAME=jupiter`, Jupiter URLs, Jupiter `ANSI_COLOR`.
  `/etc/system-release` and `/etc/issue` are rewritten too.
- KDE About/KInfoCenter logo override fixed via `/etc/xdg/kcm-about-distrorc`.
- Jupiter wallpaper for the Plasma desktop and Plasma Login Manager greeter.
- Jupiter Plymouth theme, set as default, with the initramfs regenerated during
  the build.
- Steam from RPM Fusion nonfree (i686 multilib), Vesktop 1.7.0 from a pinned,
  checksum-verified vendor RPM, and Sober plus Zen Browser from Flathub via
  `flatpak preinstall`.
- `flatpak-preinstall.service` added because Fedora provides the command but no
  unit; inherited Flatpak preinstall entries are deleted.
- uBlue login tip removed.
- Optional template disk workflow left untouched and unused.
- Placeholder logo, wallpaper and splash added in one location, documented in
  `REPLACING-ASSETS.md`.
- README rewritten. CI remains a single-image build.

## Files changed

| File | Change |
| --- | --- |
| `Containerfile` | KDE base, akmods stage, Jupiter build args, NVIDIA RPM mount, lint retained. |
| `build_files/build.sh` | Overlay copy, identity, branding install, MOTD cleanup, Flatpaks, Steam, Vesktop, NVIDIA, Plymouth, dracut. |
| `build_files/image-info.sh` | Testable os-release, `/etc/system-release` and `/etc/issue` rewrite. |
| `Justfile` | `set dotenv-load := true`, the form accepted by current `just` (needed by the CI `just check`). |
| `image-template.env` | `IMAGE_NAME=jupiter-bootc`, `REPO_ORGANIZATION=Gasterboi2012`, Jupiter description/keywords/logo. |
| `system_files/etc/xdg/kcm-about-distrorc` | `LogoPath=jupiter`. |
| `system_files/etc/xdg/plasma-org.kde.plasma.desktop-appletsrc` | Jupiter wallpaper default. |
| `system_files/usr/lib/plasmalogin/defaults.conf` | Jupiter greeter wallpaper, both plugin keys. |
| `system_files/usr/lib/bootc/kargs.d/00-jupiter-nvidia.toml` | NVIDIA modeset and nouveau/nova_core blacklist kargs. |
| `system_files/usr/lib/systemd/system/flatpak-preinstall.service` | First-boot `flatpak preinstall`. |
| `system_files/usr/share/flatpak/preinstall.d/jupiter.preinstall` | Sober and Zen Browser. |
| `system_files/usr/share/plymouth/themes/jupiter/*` | Theme descriptor and script. |
| `system_files/usr/share/wallpapers/Jupiter/metadata.json` | Plasma wallpaper package metadata. |
| `system_files/usr/share/jupiter/branding/*` | The three replaceable placeholders. |
| `README.md`, `REPLACING-ASSETS.md`, `CHANGES.md` | Documentation. |

## Sources and what they settled

| Source | What it settled |
| --- | --- |
| `ublue-os/image-template` README | Repository layout, `ctx` build stage, `build_files/build.sh` convention, `image-template.env`, NVIDIA akmods `FROM`/mount/installer pattern, `--add ostree` dracut recipe, single-image CI. |
| `ublue-os/akmods` README | `akmods-nvidia-open:main-44` is the open-driver akmods image; installer at `/tmp/akmods-rpms/ublue-os/nvidia-install.sh`; `IMAGE_NAME` controls optional add-ons. |
| Universal Blue site (`universal-blue.org`) | Current documentation entry point; `docs.ublue.ai` no longer resolves. |
| bootc filesystem documentation | OS content belongs in the image (`/usr`), `/etc` holds local configuration, `/var` must not be populated from the image. |
| bootc building guidance | Drivers, themes and initramfs content must be installed during the image build, not at runtime. |
| bootc kernel-argument documentation | `kargs = [...]` in `/usr/lib/bootc/kargs.d/*.toml` is the supported way to ship kernel arguments. |
| `os-release(5)` | Field names and quoting; `/etc/os-release` takes precedence over `/usr/lib/os-release`; `LOGO`, `DEFAULT_HOSTNAME`, `ID_LIKE` semantics. |
| RPM Fusion configuration and FAQ | `rpmfusion-free-release` and `rpmfusion-nonfree-release` URLs; nonfree requires free. |
| RPM Fusion NVIDIA how-to | nvidia-open packages and OSTree kernel arguments `rd.driver.blacklist=nouveau,nova_core`; warning about `nvidia-drm.modeset=1` with RPM Fusion's own kernel package. |
| RPM Fusion nonfree repository metadata | `steam-1.0.0.85-6.fc44.i686` is available; Steam is i686 and needs multilib. |
| Fedora Kinoite documentation | Kinoite is the Fedora Atomic KDE image; the base is immutable and uses the Fedora KDE stack. |
| Fedora Kinoite CI workaround YAML | `fedora-kinoite-plasmalogin-workaround` only repairs missing shadow/gshadow entries before plasmalogin starts; it does not reset the greeter wallpaper. |
| Flatpak `flatpak-preinstall` manual | `.preinstall` GKeyFile format (`[Flatpak Preinstall <id>]`, `Branch`, `IsRuntime`, optional `CollectionID`); first-boot install and opt-out behavior. |
| Flathub setup and Flatpak remote docs | Flathub's `.flatpakrepo` URL, and that system-wide remotes can be statically preconfigured in `/etc/flatpak/remotes.d`. The base already ships `/etc/flatpak/remotes.d/flathub.flatpakrepo`, so Jupiter asserts it rather than writing `/var` at build time. |
| Flatpak upstream issue #6880 and the Bluefin unit | Flatpak does not ship a preinstall unit; distributions supply one. Bluefin's `ExecStart=/usr/bin/flatpak preinstall -y` and `After=network-online.target` were used as the reference. |
| Plasma Login Manager README and source | `/usr/lib/plasmalogin/defaults.conf` is the system default; `/etc/plasmalogin.conf` overrides it; `WallpaperPluginId` is read by the current source and `WallpaperPlugin` appears in the base file. |
| KDE Kiosk documentation | `$XDG_CONFIG_DIRS` cascades system defaults from `/etc/xdg`. |
| KDE wallpaper scripting API | `[Containments][1][Wallpaper][org.kde.image][General]` with an `Image=file://...` key. |
| KInfoCenter branding docs and KDE about-distro source/commit | os-release `LOGO` is resolved as an icon-theme name; `kcm-about-distrorc` `LogoPath` overrides the base's `/usr/share/pixmaps/system-logo-white.png`, and KDE commit `e7e44a7a` explicitly allows `LogoPath` to be an icon-theme name. |
| Plymouth/Fedora package documentation | Theme directory `/usr/share/plymouth/themes/<name>`; `plymouth-set-default-theme`; `plymouth-plugin-script` provides `script.so`; dracut/`-R` rebuild is required. |
| Plymouth script-theme source | `.plymouth` `ModuleName=script` plus `ImageDir`/`ScriptFile`; `Window`, `Image`, `Sprite` API used by the splash script. |
| Vesktop v1.7.0 release metadata | `vesktop-1.7.0.x86_64.rpm` asset and SHA-256 `859e32db6e12345e4a1298effb2282e858ca976e3efb29e95f1a5991a22fd736`. |
| Flathub app pages | `org.vinegarhq.Sober` and `app.zen_browser.zen` are the Flathub IDs. |
| Container registry inspection (`crane`) | `kinoite-main:44` and `akmods-nvidia-open:main-44` exist and share kernel `7.3.4-200.fc44.x86_64`; base contains plasmalogin, Plymouth, Flatpak preinstall directories, no RPM Fusion repos, no `script.so`, no default Flatpak preinstalls and no fastfetch/neofetch config. |

## Conflicts and assumptions

1. **Retired NVIDIA base.** The request and the template's older comments
   suggest a Kinoite NVIDIA variant, but `kinoite-nvidia` is retired upstream.
   Jupiter uses `kinoite-main:44` plus `akmods-nvidia-open:main-44`, which is the
   template-documented way to add NVIDIA support. This is why the image does
   not literally use a `kinoite-nvidia` base.

2. **Template comment vs. base contents.** The template says "RPMfusion repos
   are available by default in ublue main images". The actual
   `kinoite-main:44` image has no RPM Fusion repositories. Jupiter installs the
   free and nonfree release RPMs before installing Steam.

3. **`nvidia-drm.modeset=1` conflict.** RPM Fusion's NVIDIA page says not to use
   `nvidia-drm.modeset=1` with RPM Fusion's own kernel packages. Jupiter uses
   the uBlue/negativo17 NVIDIA stack, where Universal Blue images ship the
   option. Jupiter follows the uBlue stack and documents the discrepancy here.
   The nouveau/nova_core blacklists follow RPM Fusion's OSTree guidance.

4. **Steam before NVIDIA.** The uBlue NVIDIA installer disables `rpmfusion*`
   repositories and does not re-enable them. Steam is installed before the
   installer runs so the RPM Fusion repos are still available.

5. **No Fedora preinstall unit.** Fedora ships `flatpak preinstall` and the
   preinstall directories, but no unit that invokes it. The
   `flatpak-preinstall.service` unit is taken from the Universal Blue/Bluefin
   implementation, with systemd start-limit keys in `[Unit]`.

6. **KDE logo override.** The base image's `/etc/xdg/kcm-about-distrorc`
   hardcodes `LogoPath=/usr/share/pixmaps/system-logo-white.png`, which would
   hide `LOGO=jupiter`. Jupiter replaces that file with `LogoPath=jupiter`.

7. **PLM key naming.** The base `defaults.conf` uses `WallpaperPlugin`, while the
   current Plasma Login Manager source reads `WallpaperPluginId`. Jupiter sets
   both to `org.kde.image` so either version works.

8. **No default Flatpaks or fetch configs.** The base image has empty Flatpak
   preinstall directories and no fastfetch/neofetch configuration, so there was
   nothing to rebrand there. The build still deletes inherited preinstall files
   and the uBlue MOTD tip to keep the final image clean.

9. **No AMD/Intel matrix.** The template's main CI workflow builds one image;
   there was no multi-vendor matrix to remove.

10. **Optional disk workflow.** `build-disk.yml` and `disk_config/` are inherited
    from the template and left untouched. Jupiter's documented and CI build is
    the container image; no installer ISO is produced or customized.

11. **Base tag.** The template README's base-image dropdown does not list every
    KDE tag. `:44` is the Fedora 44 tag consistent with the documented
    `silverblue-main:44`/`fedora-bootc:44` pattern, and both Jupiter tags were
    confirmed to exist in GHCR.

12. **`/etc/system-release` and `/etc/issue`.** Both are rewritten to Jupiter
    regular files so legacy release/console banners do not report Fedora or
    Kinoite. `/etc/system-release-cpe` is left as Fedora platform CPE metadata
    for vulnerability tooling; KDE does not display it.

13. **Justfile formatting.** Current `just` canonicalizes `set dotenv-load` to
    `set dotenv-load := true`, and CI runs `just check`. The one-line setting
    was updated; both just 1.40 and 1.46 accept it, so the check passes without
    pinning an old `just`.

14. **Flathub remote at build time.** The base image already ships the Flathub
    vendor remote at `/etc/flatpak/remotes.d/flathub.flatpakrepo`. Running
    `flatpak remote-add --system` would write `/var/lib/flatpak` during the
    build; bootc applies initial `/var` content only on first install and lint
    warns about unlisted `/var` content. Jupiter asserts the vendor remote is
    present and lets the first-boot `flatpak preinstall` initialize the system
    installation.

## Verification

Static verification performed:

- `just check` with just 1.40 and current just 1.46 (Justfile syntax/format).
- `shellcheck` on `build_files/build.sh` and `build_files/image-info.sh`.
- `shfmt -d` on both scripts.
- `systemd-analyze verify` on `flatpak-preinstall.service` (unit parses; the
  preparation host only warns that `/usr/bin/flatpak` and the man page are not
  installed on the host, which is expected).
- TOML, JSON, GKeyFile, INI and SVG parsing; PNG dimension/mode checks.
- A standalone run of `image-info.sh` against a staged os-release tree,
  including the `/etc/system-release` and `/etc/issue` rewrites.
- Branding grep over the identity and branding files.
- Registry checks with `crane` for both image tags and the shared kernel version.
- RPM Fusion free/nonfree release URLs return HTTP 200; Flathub reports both
  app IDs; the Flathub `.flatpakrepo` vendor remote is present in the base.
- Vesktop RPM SHA-256 re-check against the pinned ARG.
- Flathub app ID lookup and RPM Fusion Steam package presence checks.

Not performed in the preparation environment:

- `podman build` / `just build`.
- `bootc container lint` (it runs inside the image build).
- A real first boot into Plasma, the Plymouth splash, KDE About/KInfoCenter, the
  PLM greeter, NVIDIA driver loading, and first-boot Flatpak installation.
- Any check on AMD/Intel hardware (Jupiter is intentionally NVIDIA-only).

The preparation environment had no Podman, no root privileges and no NVIDIA
GPU, so these remain build-host and hardware checks. The image should not be
described as release-ready until they pass.
