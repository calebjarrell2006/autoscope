#!/bin/bash

# --- Configuration for Source Build ---
GAMESCOPE_SRC_DIR="gamescope_src"
LEGACY_COMMIT="5e8fddf" # Fix for Ubuntu 24.04 / Older Wayland

echo "---------------------------------"
echo "   Autoscope Universal Installer"
echo "---------------------------------"

# --- Helper: Install packages safely ---
install_packages_helper() {
    PACKAGES="$1"
    if command -v pacman &> /dev/null; then
        sudo pacman -S --needed --noconfirm $PACKAGES
    elif command -v apt &> /dev/null; then
        sudo apt update -y
        sudo apt install -y $PACKAGES
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y $PACKAGES
    else
        echo "❌ No supported package manager found."
        return 1
    fi
}

# --- 1. System Dependency Check (xrandr) ---
check_xrandr() {
    echo "Checking core dependencies..."
    if ! command -v xrandr &> /dev/null; then
        echo "⚠️  'xrandr' is missing. Installing..."
        if command -v apt &> /dev/null; then 
            install_packages_helper "x11-xserver-utils"
        else 
            install_packages_helper "xorg-xrandr" || install_packages_helper "xrandr"
        fi
    else
        echo "✅ Found xrandr"
    fi
}

# --- 2. Method A: Install via Package Manager (V1 Logic) ---
install_gamescope_package() {
    echo "---------------------------------"
    echo "   Installing via System Repo"
    echo "---------------------------------"
    
    if command -v pacman &> /dev/null; then
        install_packages_helper "gamescope"
    elif command -v apt &> /dev/null; then
        install_packages_helper "gamescope"
    elif command -v dnf &> /dev/null; then
        install_packages_helper "gamescope"
    else
        echo "❌ Could not detect package manager."
        return 1
    fi
}

# --- 3. Method B: Build from Source (V2 Logic) ---
build_gamescope_source() {
    echo "---------------------------------"
    echo "   Building from Source (Advanced)"
    echo "---------------------------------"

    # 1. Install Build Tools
    echo ">> Installing build dependencies..."
    CORE_TOOLS="git meson cmake ninja-build pkg-config build-essential"
    [ -x "$(command -v pacman)" ] && CORE_TOOLS="git meson cmake ninja base-devel"
    [ -x "$(command -v dnf)" ] && CORE_TOOLS="git meson cmake ninja-build pkgconf-pkg-config @development-tools"
    
    if ! install_packages_helper "$CORE_TOOLS"; then
        echo "❌ Failed to install build tools."
        return 1
    fi

    # 2. Install Distro Libraries
    if command -v apt &> /dev/null; then
        LIBS="libbenchmark-dev libdisplay-info-dev libevdev-dev libgav1-dev libgudev-1.0-dev libmtdev-dev libseat-dev libstb-dev libwacom-dev libxcb-ewmh-dev libxcb-shape0-dev libxcb-xfixes0-dev libxmu-headers libyuv-dev libx11-xcb-dev libxres-dev libxmu-dev libinput-dev libxcb-composite0-dev libxcb-icccm4-dev libxcb-res0-dev libcap-dev wayland-protocols libvulkan-dev libwayland-dev libx11-dev libxdamage-dev libxcomposite-dev libxcursor-dev libxxf86vm-dev libxtst-dev libxkbcommon-dev libdrm-dev libpixman-1-dev libdecor-0-dev glslang-tools libsdl2-dev libglm-dev libeis-dev libavif-dev"
    elif command -v dnf &> /dev/null; then
        LIBS="libdrm-devel libX11-devel libXcomposite-devel libXrender-devel libXext-devel libXfixes-devel libXdamage-devel libXxf86vm-devel libXrandr-devel libXres-devel libXi-devel libcap-devel wayland-devel wayland-protocols-devel vulkan-loader-devel pipewire-devel libXcursor-devel libxkbcommon-devel libinput-devel libXtst-devel libXmu-devel libXinerama-devel pixman-devel SDL2-devel libavif-devel systemd-devel libeis-devel libxml2-devel google-benchmark-devel libdisplay-info-devel libseat-devel libmanette-devel libliftoff-devel"
    elif command -v pacman &> /dev/null; then
        LIBS="wayland-protocols libdrm vulkan-headers libx11 libxcomposite libxrender libxext libxfixes libxdamage libxxf86vm libxrandr libxres libxi libcap pipewire libxcursor libxkbcommon libinput libxtst libxmu libxinerama pixman sdl2 libavif libepoll-shim benchmark libdisplay-info libseat"
    fi
    install_packages_helper "$LIBS"

    # 3. Clone
    if [ -d "$GAMESCOPE_SRC_DIR" ]; then
        echo ">> Cleaning existing source directory..."
        cd "$GAMESCOPE_SRC_DIR" || exit
        git reset --hard HEAD
        git clean -fxd
        git pull
    else
        echo ">> Cloning Gamescope..."
        git clone https://github.com/ValveSoftware/gamescope.git "$GAMESCOPE_SRC_DIR"
        cd "$GAMESCOPE_SRC_DIR" || exit
    fi

    # 4. Check Wayland Version (The Fix)
    CURRENT_VER=$(pkg-config --modversion wayland-server 2>/dev/null || echo "0.0.0")
    REQUIRED_VER="1.23"

    if [ "$(printf '%s\n' "$REQUIRED_VER" "$CURRENT_VER" | sort -V | head -n1)" != "$REQUIRED_VER" ]; then
        echo "⚠️  System Wayland ($CURRENT_VER) is too old for latest Gamescope."
        echo "   >> ACTIVATING FIX: Downgrading to commit $LEGACY_COMMIT..."
        git reset "$LEGACY_COMMIT" --hard
        git clean -fxd
        git submodule update --init --force --recursive
    else
        echo "✅ System Wayland ($CURRENT_VER) is supported. Building latest..."
        git submodule update --init --recursive
    fi

    # 5. Build
    echo ">> Configuring Meson..."
    [ -d "build" ] && rm -rf build
    meson setup build/

    echo ">> Compiling..."
    if ninja -C build/; then
        echo ">> Installing..."
        sudo meson install -C build/ --skip-subprojects
        cd ..
        echo "✅ Gamescope Built and Installed!"
    else
        echo "❌ Build Failed. Please check the logs."
        exit 1
    fi
}

# --- 4. Install Autoscope Script ---
install_autoscope() {
    echo "---------------------------------"
    echo "   Finalizing Setup"
    echo "---------------------------------"
    if [ -f "./autoscope" ]; then
        echo "Installing autoscope to /usr/local/bin..."
        sudo cp ./autoscope /usr/local/bin/autoscope
        sudo chmod +x /usr/local/bin/autoscope
        echo "✅ Success! Run 'autoscope' to start."
    else
        echo "⚠️  'autoscope' file not found in the current folder."
        echo "    Please ensure 'autoscope' is in the same folder as this script."
    fi
}

# --- MAIN EXECUTION FLOW ---

check_xrandr

# Check if Gamescope is already installed
if command -v gamescope &> /dev/null; then
    echo "✅ Gamescope is already installed."
    read -p "Do you want to reinstall/update it? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        install_autoscope
        exit 0
    fi
fi

echo ""
echo "Select installation method:"
echo "1) System Package (Recommended)"
echo "   - Fast, stable, managed by your OS."
echo "2) Build from Source (Advanced)"
echo "   - Takes longer. Use this if you are on Ubuntu 24.04 or need specific fixes."
echo ""
read -p "Enter choice [1/2]: " CHOICE

case "$CHOICE" in
    1)
        # Try to install via package manager. If it fails (!), ask to build from source.
        if ! install_gamescope_package; then
            echo ""
            echo "❌ System package installation failed (package might not exist in your repo)."
            read -p "Would you like to try building from source instead? [Y/n] " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                build_gamescope_source
            else
                echo "❌ Installation aborted."
                exit 1
            fi
        fi
        ;;
    2)
        build_gamescope_source
        ;;
    *)
        echo "Invalid choice. Exiting."
        exit 1
        ;;
esac

install_autoscope
