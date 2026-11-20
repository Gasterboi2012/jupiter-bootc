# Replacing Jupiter's placeholder assets

Every replaceable asset lives in one directory:

```text
system_files/usr/share/jupiter/branding/
```

The build copies each file to the runtime location that KDE, the Plasma Login
Manager or Plymouth reads. Replace the file in place, keep the filename and
format, and rebuild. No build script changes are needed.

| Source file | Purpose | Dimensions | Format | Installed at |
| --- | --- | --- | --- | --- |
| `jupiter-logo.svg` | OS logo for KDE About, KInfoCenter and anything that resolves `LOGO=jupiter` | 512 × 512 viewBox, square, scalable | SVG | `/usr/share/icons/hicolor/scalable/apps/jupiter.svg` |
| `wallpaper-3840x2160.png` | System-wide Plasma desktop wallpaper and Plasma Login Manager greeter background | 3840 × 2160 | PNG (RGB) | `/usr/share/wallpapers/Jupiter/contents/images/3840x2160.png` |
| `plymouth-1920x1080.png` | Plymouth boot splash | 1920 × 1080 | PNG (RGB) | `/usr/share/plymouth/themes/jupiter/splash.png` |

## Requirements

- **Logo:** square and scalable. Keep `LOGO=jupiter` and the installed filename
  `jupiter.svg`; KDE resolves the os-release `LOGO` value through the icon
  theme. A transparent background is allowed. Replace the placeholder
  `PLACEHOLDER` text with your own mark.
- **Wallpaper:** keep the `3840x2160.png` filename. Both
  `/etc/xdg/plasma-org.kde.plasma.desktop-appletsrc` and
  `/usr/lib/plasmalogin/defaults.conf` reference that exact path/directory.
  If you change the dimensions, update those two files as well.
- **Plymouth splash:** keep the `splash.png` filename because
  `system_files/usr/share/plymouth/themes/jupiter/jupiter.script` loads that
  name. The script centers the image on the boot framebuffer; 1920 × 1080 is
  the required asset size.
- Keep the placeholders free of third-party trademarks and logos.

## After replacing

```bash
just build
```

The build regenerates the initramfs after installing the theme, so the new
splash is included. Rebase and reboot to see the desktop, greeter and boot
splash changes.

The Plymouth theme description and script
(`system_files/usr/share/plymouth/themes/jupiter/jupiter.plymouth` and
`jupiter.script`) are theme logic, not placeholder artwork. Leave them alone
unless you are changing how the splash is drawn.

The logo is also the image logo referenced by `IMAGE_LOGO_URL` in
`image-template.env`, so replacing the SVG updates the ArtifactHub-facing logo
on the next build.
