#!/bin/bash

echo "---------------------------------"
echo "   Autoscope Installer"
echo "---------------------------------"

# --- Function to install a package based on distro ---
install_package() {
    PACKAGE_NAME=$1
    if command -v pacman &> /dev/null; then
        echo "Detected Arch Linux (pacman)"
        sudo pacman -S --noconfirm "$PACKAGE_NAME"
    elif command -v apt &> /dev/null; then
        echo "Detected Debian/Ubuntu (apt)"
        sudo apt update && sudo apt install -y "$PACKAGE_NAME"
    elif command -v dnf &> /dev/null; then
        echo "Detected Fedora (dnf)"
        sudo dnf install -y "$PACKAGE_NAME"
    else
        echo "❌ Could not detect package manager. Please install '$PACKAGE_NAME' manually."
        exit 1
    fi
}

# --- 1. Check for xrandr ---
if ! command -v xrandr &> /dev/null; then
    echo "⚠️  'xrandr' is missing."
    read -p "Would you like to install it now? [Y/n] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # On Debian/Ubuntu, xrandr is often in x11-xserver-utils
        if command -v apt &> /dev/null; then
            install_package "x11-xserver-utils"
        else
            install_package "xorg-xrandr" 2>/dev/null || install_package "xrandr"
        fi
    else
        echo "❌ Autoscope requires xrandr. Aborting."
        exit 1
    fi
else
    echo "✅ Found xrandr"
fi

# --- 2. Check for Gamescope ---
if ! command -v gamescope &> /dev/null; then
    echo "⚠️  'gamescope' is missing."
    read -p "Would you like to install it now? [Y/n] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        install_package "gamescope"
    else
        echo "❌ Autoscope requires Gamescope. Aborting."
        exit 1
    fi
else
    echo "✅ Found gamescope"
fi

# --- 3. Install Autoscope ---
echo "Installing autoscope to /usr/local/bin/..."
if [ -f "./autoscope" ]; then
    sudo cp ./autoscope /usr/local/bin/autoscope
    sudo chmod +x /usr/local/bin/autoscope
    echo "✅ Success! You can now use 'autoscope' from anywhere."
else
    echo "❌ Error: Could not find 'autoscope' script in current directory."
fi
