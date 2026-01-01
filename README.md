# autoscope
A lightweight Bash wrapper for [Gamescope](https://github.com/ValveSoftware/gamescope) that automatically detects your primary display's hardware native resolution and launches Gamescope with the correct flags.

## Why use this?
Gamescope is excellent, but it requires you to manually specify `-w`, `-h`, `-W`, and `-H` flags. If you switch displays (e.g., between a monitor and a TV) or use a multi-monitor setup, hardcoding these values is annoying.

**Autoscope** solves this by:
1. Detecting your primary display via `xrandr`.
2. Reading the kernel DRM mode directly from `/sys/class/drm` to find the strict hardware native resolution.
3. Launching Gamescope with the perfect resolution flags automatically.

## Compatibility
* **Distros:** Works on any Linux distribution (Arch, Fedora, Debian, Ubuntu, etc.).
* **Sessions (X11 & Wayland):**
  * **X11:** Works natively.
  * **Wayland:** Works on compositors that expose physical display names to XWayland (e.g., KDE Plasma, Hyprland, Sway).
  * *Note:* If your Wayland session abstracts display names (e.g., renaming them to `XWAYLAND0`), Autoscope may fall back to 1080p.

## Dependencies
* `gamescope`
* `xrandr`
* `bash`

## Installation

### Manual
1. Clone the repository:
   ```bash
   git clone [https://github.com/calebjarrell2006/autoscope.git](https://github.com/calebjarrell2006/autoscope.git)
   ```
2. Change directory to autoscope install folder.
   ```bash
   cd autoscope
   ```
3. Run the install script.
   ```bash
   ./install.sh
   ```
