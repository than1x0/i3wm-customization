#!/usr/bin/env bash

# ==============================================================================
# Kali Linux & Debian i3wm Customization Installer
# Fully optimized for modern Kali Linux & Debian 12+ (Bookworm / Testing)
# ==============================================================================

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "========================================================"
echo "    Starting Kali Linux & Debian i3 Setup Installer     "
echo "========================================================"

# 1. Check sudo / root privileges
if [ "$EUID" -ne 0 ]; then
    if ! command -v sudo >/dev/null 2>&1; then
        echo "[!] Error: sudo is required to run this script. Please install sudo or run as root."
        exit 1
    fi
    SUDO="sudo"
else
    SUDO=""
fi

# 2. Detect OS Distribution
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$NAME
    echo "[+] Detected OS: $DISTRO ($VERSION_ID)"
else
    echo "[!] Warning: Cannot identify Linux distribution. Proceeding with standard Debian/APT commands."
fi

# 3. Update Package Repositories
echo "[+] Updating package repositories..."
$SUDO apt-get update -y

# 4. Install Core Packages & Dependencies
echo "[+] Installing Window Manager, Terminal, Compositor, and Utilities..."
PACKAGES=(
    # Window Manager & Bar
    i3
    i3status
    i3blocks
    i3lock
    
    # Terminal
    alacritty
    
    # Compositor & Launchers
    picom
    rofi
    
    # Wallpaper & Theming
    feh
    lxappearance
    arc-theme
    papirus-icon-theme
    
    # Utilities
    flameshot
    thunar
    unclutter
    imagemagick
    unzip
    curl
    wget
    git
    zsh
    pulseaudio-utils
    xclip
    
    # Fonts
    fonts-font-awesome
    fonts-dejavu-core
)

# Install packages gracefully
$SUDO apt-get install -y "${PACKAGES[@]}"

# Install VM guest tools if inside a virtual machine (optional)
if lscpu 2>/dev/null | grep -iq "hypervisor"; then
    echo "[+] Virtual Machine detected. Installing VM guest integration..."
    $SUDO apt-get install -y open-vm-tools-desktop 2>/dev/null || true
fi

# 5. Download and Install Nerd Fonts
FONTS_DIR="$HOME/.local/share/fonts"
mkdir -p "$FONTS_DIR"

if [ ! -f "$FONTS_DIR/IosevkaNerdFont-Regular.ttf" ] && [ ! -f "$FONTS_DIR/Iosevka Nerd Font Complete.ttf" ]; then
    echo "[+] Downloading and installing Nerd Fonts (Iosevka & RobotoMono)..."
    TMP_FONT_DIR=$(mktemp -d)
    
    wget -q --show-progress "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/Iosevka.zip" -O "$TMP_FONT_DIR/Iosevka.zip" || true
    wget -q --show-progress "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/RobotoMono.zip" -O "$TMP_FONT_DIR/RobotoMono.zip" || true
    
    if [ -f "$TMP_FONT_DIR/Iosevka.zip" ]; then
        unzip -qo "$TMP_FONT_DIR/Iosevka.zip" -d "$FONTS_DIR"
    fi
    if [ -f "$TMP_FONT_DIR/RobotoMono.zip" ]; then
        unzip -qo "$TMP_FONT_DIR/RobotoMono.zip" -d "$FONTS_DIR"
    fi
    
    rm -rf "$TMP_FONT_DIR"
    echo "[+] Refreshing font cache..."
    fc-cache -f "$FONTS_DIR"
else
    echo "[+] Nerd Fonts already present. Skipping font download."
fi

# 6. Install Oh My Zsh (Non-interactive)
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "[+] Installing Oh My Zsh (unattended mode)..."
    RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended || true
fi

# 7. Deploy Configuration Files
echo "[+] Deploying dotfiles to $HOME/.config/..."
mkdir -p "$HOME/.config/i3/scripts"
mkdir -p "$HOME/.config/picom"
mkdir -p "$HOME/.config/compton"
mkdir -p "$HOME/.config/rofi"
mkdir -p "$HOME/.config/alacritty"
mkdir -p "$HOME/.wallpaper"

# Copy configurations
cp "$SCRIPT_DIR/.config/i3/config" "$HOME/.config/i3/config"
cp "$SCRIPT_DIR/.config/i3/i3blocks.conf" "$HOME/.config/i3/i3blocks.conf"
cp "$SCRIPT_DIR/.config/i3/clipboard_fix.sh" "$HOME/.config/i3/clipboard_fix.sh"
cp "$SCRIPT_DIR/.config/i3/scripts/"*.sh "$HOME/.config/i3/scripts/"

cp "$SCRIPT_DIR/.config/picom/picom.conf" "$HOME/.config/picom/picom.conf"
cp "$SCRIPT_DIR/.config/compton/compton.conf" "$HOME/.config/compton/compton.conf"

cp "$SCRIPT_DIR/.config/alacritty/alacritty.toml" "$HOME/.config/alacritty/alacritty.toml"
cp "$SCRIPT_DIR/.config/alacritty/alacritty.yml" "$HOME/.config/alacritty/alacritty.yml"

cp "$SCRIPT_DIR/.config/rofi/config.rasi" "$HOME/.config/rofi/config.rasi"
cp "$SCRIPT_DIR/.config/rofi/config" "$HOME/.config/rofi/config"

cp "$SCRIPT_DIR/.fehbg" "$HOME/.fehbg"
cp -r "$SCRIPT_DIR/.wallpaper/"* "$HOME/.wallpaper/"

# Set executable permissions
chmod +x "$HOME/.fehbg"
chmod +x "$HOME/.config/i3/clipboard_fix.sh"
chmod +x "$HOME/.config/i3/scripts/"*.sh

echo "========================================================"
echo "          Installation Completed Successfully!          "
echo "========================================================"
echo "Next Steps:"
echo " 1. Log out or reboot your system."
echo " 2. At the display manager login screen, select 'i3' as your session."
echo " 3. Press 'Win + Enter' to open Alacritty terminal."
echo " 4. Press 'Win + d' to launch applications with Rofi."
echo " 5. Run 'lxappearance' to set the Widget theme to 'Arc-Dark' and Icon theme to 'Papirus-Dark'."
echo "========================================================"