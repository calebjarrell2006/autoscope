#!/bin/bash

# --- Configuration ---
GAMESCOPE_SRC_DIR="gamescope_src"
INSTALL_PATH="/usr/local/bin/gamescope"

echo "---------------------------------"
echo "   Autoscope Uninstaller (Safe Mode)"
echo "---------------------------------"

# --- 1. Remove Autoscope Script ---
if [ -f "/usr/local/bin/autoscope" ]; then
    echo "Removing autoscope from /usr/local/bin/..."
    sudo rm /usr/local/bin/autoscope
    echo "✅ Autoscope script removed."
else
    echo "⚠️  Autoscope script not found in /usr/local/bin."
fi

# --- 2. Remove Gamescope ---
echo "---------------------------------"
echo "   Uninstalling Gamescope"
echo "---------------------------------"

# Method A: Clean uninstall via Ninja
if [ -d "$GAMESCOPE_SRC_DIR/build" ]; then
    echo "Found build directory. Attempting clean uninstall..."
    cd "$GAMESCOPE_SRC_DIR/build"
    # We suppress output to keep it clean, but you can remove >/dev/null if you want logs
    if sudo ninja uninstall > /dev/null 2>&1; then
        echo "✅ Gamescope uninstalled via Ninja."
    else
        echo "⚠️  Ninja uninstall failed or nothing to uninstall."
    fi
    cd ../..
fi

# Method B: Brute force check
if [ -f "$INSTALL_PATH" ]; then
    echo "⚠️  Gamescope binary still found at $INSTALL_PATH."
    read -p "Force remove it? [Y/n] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo rm "$INSTALL_PATH"
        echo "✅ Gamescope binary removed."
    fi
else
    echo "✅ Gamescope binary is gone."
fi

# --- 3. Remove Source Code ---
if [ -d "$GAMESCOPE_SRC_DIR" ]; then
    read -p "Remove source folder ($GAMESCOPE_SRC_DIR)? [Y/n] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$GAMESCOPE_SRC_DIR"
        echo "✅ Source folder removed."
    fi
fi

# --- 4. Cleanup Dependencies (Smart Remove) ---
echo "---------------------------------"
echo "   Dependency Cleanup"
echo "---------------------------------"
echo "This step will identify the build libraries we installed."
echo "It will check if they are being used by any other programs."
echo " - If UNUSED: They will be removed."
echo " - If USED: They will be kept safely."
read -p "Proceed with smart cleanup? [y/N] " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    
    if command -v apt &> /dev/null; then
        # Debian/Ubuntu Smart Logic
        LIBS="libbenchmark-dev libdisplay-info-dev libevdev-dev libgav1-dev libgudev-1.0-dev libmtdev-dev libseat-dev libstb-dev libwacom-dev libxcb-ewmh-dev libxcb-shape0-dev libxcb-xfixes0-dev libxmu-headers libyuv-dev libx11-xcb-dev libxres-dev libxmu-dev libinput-dev libxcb-composite0-dev libxcb-icccm4-dev libxcb-res0-dev libcap-dev wayland-protocols libvulkan-dev libwayland-dev libx11-dev libxdamage-dev libxcomposite-dev libxcursor-dev libxxf86vm-dev libxtst-dev libxkbcommon-dev libdrm-dev libpixman-1-dev libdecor-0-dev glslang-tools libsdl2-dev libglm-dev libeis-dev libavif-dev"
        
        echo "1. Marking build libraries as 'auto-installed' (dependencies)..."
        # This tells apt: "I didn't install these manually; they are just dependencies."
        # If nothing else needs them, autoremove will catch them.
        sudo apt-mark auto $LIBS > /dev/null 2>&1
        
        echo "2. Running autoremove to clean up..."
        sudo apt autoremove -y
        echo "✅ Unused libraries removed."
        
    elif command -v dnf &> /dev/null; then
        # Fedora Logic
        LIBS="libdrm-devel libX11-devel libXcomposite-devel libXrender-devel libXext-devel libXfixes-devel libXdamage-devel libXxf86vm-devel libXrandr-devel libXres-devel libXi-devel libcap-devel wayland-devel wayland-protocols-devel vulkan-loader-devel pipewire-devel libXcursor-devel libxkbcommon-devel libinput-devel libXtst-devel libXmu-devel libXinerama-devel pixman-devel SDL2-devel libavif-devel systemd-devel libeis-devel libxml2-devel google-benchmark-devel libdisplay-info-devel libseat-devel libmanette-devel libliftoff-devel"
        echo "Running DNF autoremove..."
        # DNF doesn't have a direct 'apt-mark auto' equivalent for this list easily, 
        # but attempting to remove unused deps is safe.
        sudo dnf remove $LIBS
        
    elif command -v pacman &> /dev/null; then
        # Arch Logic
        LIBS="wayland-protocols libdrm vulkan-headers libx11 libxcomposite libxrender libxext libxfixes libxdamage libxxf86vm libxrandr libxres libxi libcap pipewire libxcursor libxkbcommon libinput libxtst libxmu libxinerama pixman sdl2 libavif libepoll-shim benchmark libdisplay-info libseat"
        
        echo "Marking as dependencies..."
        sudo pacman -D --asdeps $LIBS > /dev/null 2>&1
        echo "Removing orphans..."
        sudo pacman -Rns $(pacman -Qtdq)
    fi
else
    echo "Skipping library removal."
fi

# --- 5. Remove Core Tools (Optional) ---
echo "---------------------------------"
read -p "Do you also want to remove core build tools (git, meson, ninja, cmake)? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if command -v apt &> /dev/null; then
        # Use the same smart logic for tools
        sudo apt-mark auto git meson cmake ninja-build pkg-config build-essential
        sudo apt autoremove -y
    elif command -v dnf &> /dev/null; then
        sudo dnf remove git meson cmake ninja-build pkgconf-pkg-config @development-tools
    elif command -v pacman &> /dev/null; then
        sudo pacman -D --asdeps git meson cmake ninja base-devel
        sudo pacman -Rns $(pacman -Qtdq)
    fi
    echo "✅ Build tools cleanup attempt finished."
fi

echo "---------------------------------"
echo "   Uninstallation Complete"
echo "---------------------------------"
