#!/usr/bin/env bash

# ==============================================================================
# Kali Linux & Debian i3wm Customization Installer & Updater
# Fully optimized for modern Kali Linux & Debian 12+ (Bookworm / Testing)
# ==============================================================================

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Global SUDO helper initialization
if [ "$EUID" -ne 0 ]; then
    if command -v sudo >/dev/null 2>&1; then
        SUDO="sudo"
    else
        SUDO=""
    fi
else
    SUDO=""
fi

# ------------------------------------------------------------------------------
# Helper Functions
# ------------------------------------------------------------------------------

print_banner() {
    echo "========================================================"
    echo "    Kali Linux & Debian i3 Setup Installer & Updater    "
    echo "========================================================"
}

check_privileges() {
    if [ "$EUID" -ne 0 ]; then
        if ! command -v sudo >/dev/null 2>&1; then
            echo "[!] Error: sudo is required for package installations. Please install sudo or run as root."
            exit 1
        fi
        SUDO="sudo"
    else
        SUDO=""
    fi
}

detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$NAME
        echo "[+] Detected OS: $DISTRO ($VERSION_ID)"
    else
        echo "[!] Warning: Cannot identify Linux distribution. Proceeding with standard Debian/APT commands."
    fi
}

install_packages() {
    check_privileges
    detect_os

    echo "[+] Updating package repositories..."
    $SUDO apt-get update -y

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
        
        # Utilities & System Controls
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
        brightnessctl
        libnotify-bin
        
        # Fonts
        fonts-font-awesome
        fonts-dejavu-core
    )

    $SUDO apt-get install -y "${PACKAGES[@]}"

    # Install VM guest tools if inside a virtual machine
    if lscpu 2>/dev/null | grep -iq "hypervisor"; then
        echo "[+] Virtual Machine detected. Checking guest integration tools..."
        if command -v systemd-detect-virt >/dev/null 2>&1 && systemd-detect-virt | grep -iq "oracle\|virtualbox"; then
            $SUDO apt-get install -y virtualbox-guest-x11 2>/dev/null || true
        else
            $SUDO apt-get install -y open-vm-tools-desktop 2>/dev/null || true
        fi
    fi
}

install_fonts() {
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
}

install_zsh() {
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        echo "[+] Installing Oh My Zsh (unattended mode)..."
        RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended || true
    fi

    # Ensure default login shell is zsh
    ZSH_BIN=$(command -v zsh || echo "/bin/zsh")
    if [ -x "$ZSH_BIN" ]; then
        TARGET_USER="${SUDO_USER:-$USER}"
        echo "[+] Ensuring default login shell is zsh for $TARGET_USER..."
        $SUDO chsh -s "$ZSH_BIN" "$TARGET_USER" 2>/dev/null || chsh -s "$ZSH_BIN" "$TARGET_USER" 2>/dev/null || true
    fi
}

backup_configs() {
    if [ -d "$HOME/.config/i3" ]; then
        BACKUP_DIR="$HOME/.config/i3_backup_$(date +%Y%m%d_%H%M%S)"
        echo "[+] Creating safety backup of current configs at $BACKUP_DIR..."
        mkdir -p "$BACKUP_DIR"
        cp -r "$HOME/.config/i3" "$BACKUP_DIR/" 2>/dev/null || true
        [ -f "$HOME/.config/picom/picom.conf" ] && cp -r "$HOME/.config/picom" "$BACKUP_DIR/" 2>/dev/null || true
        [ -f "$HOME/.config/alacritty/alacritty.toml" ] && cp -r "$HOME/.config/alacritty" "$BACKUP_DIR/" 2>/dev/null || true
        [ -f "$HOME/.config/rofi/config.rasi" ] && cp -r "$HOME/.config/rofi" "$BACKUP_DIR/" 2>/dev/null || true
    fi
}

deploy_configs() {
    TARGET_USER="${SUDO_USER:-$USER}"
    if [ "$EUID" -eq 0 ] && [ "$TARGET_USER" == "root" ]; then
        PRIMARY_USER=$(ls -1 /home 2>/dev/null | grep -v 'lost+found' | head -n 1)
        if [ -n "$PRIMARY_USER" ] && [ -d "/home/$PRIMARY_USER" ]; then
            TARGET_USER="$PRIMARY_USER"
        fi
    fi
    TARGET_HOME=$(eval echo "~$TARGET_USER")

    echo "[+] Deploying dotfiles to $TARGET_HOME/.config/..."
    mkdir -p "$TARGET_HOME/.config/i3/scripts"
    mkdir -p "$TARGET_HOME/.config/picom"
    mkdir -p "$TARGET_HOME/.config/rofi"
    mkdir -p "$TARGET_HOME/.config/alacritty"
    mkdir -p "$TARGET_HOME/.wallpaper"
    mkdir -p "$TARGET_HOME/.local/bin"

    # Copy configurations
    cp "$SCRIPT_DIR/.config/i3/config" "$TARGET_HOME/.config/i3/config"
    cp "$SCRIPT_DIR/.config/i3/i3blocks.conf" "$TARGET_HOME/.config/i3/i3blocks.conf"
    cp "$SCRIPT_DIR/.config/i3/clipboard_fix.sh" "$TARGET_HOME/.config/i3/clipboard_fix.sh"
    cp "$SCRIPT_DIR/.config/i3/scripts/"*.sh "$TARGET_HOME/.config/i3/scripts/" 2>/dev/null || true
    cp "$SCRIPT_DIR/.config/i3/scripts/"*.zsh "$TARGET_HOME/.config/i3/scripts/" 2>/dev/null || true

    cp "$SCRIPT_DIR/.config/picom/picom.conf" "$TARGET_HOME/.config/picom/picom.conf"

    cp "$SCRIPT_DIR/.config/alacritty/alacritty.toml" "$TARGET_HOME/.config/alacritty/alacritty.toml"
    cp "$SCRIPT_DIR/.config/alacritty/alacritty.yml" "$TARGET_HOME/.config/alacritty/alacritty.yml"

    cp "$SCRIPT_DIR/.config/rofi/config.rasi" "$TARGET_HOME/.config/rofi/config.rasi"

    cp "$SCRIPT_DIR/.fehbg" "$TARGET_HOME/.fehbg"
    cp -r "$SCRIPT_DIR/.wallpaper/"* "$TARGET_HOME/.wallpaper/"

    # Set executable permissions
    chmod +x "$TARGET_HOME/.fehbg"
    chmod +x "$TARGET_HOME/.config/i3/clipboard_fix.sh"
    chmod +x "$TARGET_HOME/.config/i3/scripts/"*.sh

    # Initialize default prompt style (Minimal Arrow) if not already configured
    if [ ! -f "$TARGET_HOME/.config/i3/prompt_style" ]; then
        echo "arrow" > "$TARGET_HOME/.config/i3/prompt_style"
    fi

    # Integrate custom prompt with ~/.zshrc (ZSH)
    if [ -f "$TARGET_HOME/.zshrc" ]; then
        if ! grep -q "prompt.zsh" "$TARGET_HOME/.zshrc" 2>/dev/null; then
            cat <<'EOF' >> "$TARGET_HOME/.zshrc"

# Kali i3wm Custom Prompt Hook (ZSH)
[ -f "$HOME/.config/i3/scripts/prompt.zsh" ] && source "$HOME/.config/i3/scripts/prompt.zsh"
EOF
        fi
    fi

    # Integrate custom prompt with ~/.bashrc (Bash)
    if [ -f "$TARGET_HOME/.bashrc" ]; then
        sed -i '/prompt\.zsh/d' "$TARGET_HOME/.bashrc" 2>/dev/null || true
        if ! grep -q "prompt.sh" "$TARGET_HOME/.bashrc" 2>/dev/null; then
            cat <<'EOF' >> "$TARGET_HOME/.bashrc"

# Kali i3wm Custom Prompt Hook (Bash)
[ -f "$HOME/.config/i3/scripts/prompt.sh" ] && source "$HOME/.config/i3/scripts/prompt.sh"
EOF
        fi
    fi

    # Fix ownership if running as root for a normal user
    if [ "$EUID" -eq 0 ] && [ "$TARGET_USER" != "root" ]; then
        chown -R "$TARGET_USER:$TARGET_USER" "$TARGET_HOME/.config/i3" "$TARGET_HOME/.config/picom" "$TARGET_HOME/.config/rofi" "$TARGET_HOME/.config/alacritty" "$TARGET_HOME/.wallpaper" "$TARGET_HOME/.local" "$TARGET_HOME/.fehbg" "$TARGET_HOME/.bashrc" "$TARGET_HOME/.zshrc" 2>/dev/null || true
    fi

    # Deploy prompt configuration to /root for seamless sudo su / root experience
    if [ -d "/root" ]; then
        $SUDO mkdir -p /root/.config/i3/scripts 2>/dev/null || true
        $SUDO cp "$SCRIPT_DIR/.config/i3/scripts/"*.sh /root/.config/i3/scripts/ 2>/dev/null || true
        $SUDO cp "$SCRIPT_DIR/.config/i3/scripts/"*.zsh /root/.config/i3/scripts/ 2>/dev/null || true
        $SUDO chmod +x /root/.config/i3/scripts/*.sh 2>/dev/null || true

        # Sync prompt style to /root
        [ -f "$TARGET_HOME/.config/i3/prompt_style" ] && $SUDO cp "$TARGET_HOME/.config/i3/prompt_style" /root/.config/i3/prompt_style 2>/dev/null || true

        # Inject hook into /root/.bashrc
        if $SUDO test -f /root/.bashrc; then
            $SUDO sed -i '/prompt\.zsh/d' /root/.bashrc 2>/dev/null || true
            if ! $SUDO grep -q "prompt.sh" /root/.bashrc 2>/dev/null; then
                $SUDO bash -c "cat <<'EOF' >> /root/.bashrc

# Kali i3wm Custom Prompt Hook (Bash)
if [ -f \"\$HOME/.config/i3/scripts/prompt.sh\" ]; then
    source \"\$HOME/.config/i3/scripts/prompt.sh\"
elif [ -n \"\$SUDO_USER\" ] && [ -f \"/home/\$SUDO_USER/.config/i3/scripts/prompt.sh\" ]; then
    source \"/home/\$SUDO_USER/.config/i3/scripts/prompt.sh\"
fi
EOF" 2>/dev/null || true
            fi
        fi

        # Inject hook into /root/.zshrc
        if $SUDO test -f /root/.zshrc; then
            if ! $SUDO grep -q "prompt.zsh" /root/.zshrc 2>/dev/null; then
                $SUDO bash -c "cat <<'EOF' >> /root/.zshrc

# Kali i3wm Custom Prompt Hook (ZSH)
if [ -f \"\$HOME/.config/i3/scripts/prompt.zsh\" ]; then
    source \"\$HOME/.config/i3/scripts/prompt.zsh\"
elif [ -n \"\$SUDO_USER\" ] && [ -f \"/home/\$SUDO_USER/.config/i3/scripts/prompt.zsh\" ]; then
    source \"/home/\$SUDO_USER/.config/i3/scripts/prompt.zsh\"
fi
EOF" 2>/dev/null || true
            fi
        fi
    fi

    # Deploy to /etc/skel so any new users created via adduser inherit the prompt hooks
    if [ -d "/etc/skel" ]; then
        if $SUDO test -f /etc/skel/.bashrc && ! $SUDO grep -q "prompt.sh" /etc/skel/.bashrc 2>/dev/null; then
            $SUDO bash -c "cat <<'EOF' >> /etc/skel/.bashrc

# Kali i3wm Custom Prompt Hook (Bash)
[ -f \"\$HOME/.config/i3/scripts/prompt.sh\" ] && source \"\$HOME/.config/i3/scripts/prompt.sh\"
EOF" 2>/dev/null || true
        fi
        if $SUDO test -f /etc/skel/.zshrc && ! $SUDO grep -q "prompt.zsh" /etc/skel/.zshrc 2>/dev/null; then
            $SUDO bash -c "cat <<'EOF' >> /etc/skel/.zshrc

# Kali i3wm Custom Prompt Hook (ZSH)
[ -f \"\$HOME/.config/i3/scripts/prompt.zsh\" ] && source \"\$HOME/.config/i3/scripts/prompt.zsh\"
EOF" 2>/dev/null || true
        fi
    fi

    install_cli_tools
}

install_cli_tools() {
    # 1. Global Updater Script
    UPDATER_SCRIPT="$TARGET_HOME/.local/bin/i3-update"
    cat <<EOF > "$UPDATER_SCRIPT"
#!/usr/bin/env bash
# Global quick updater for Kali i3 Customization
REPO_DIR="$SCRIPT_DIR"

echo "========================================================"
echo "           Kali i3 Dotfiles Live Updater                "
echo "========================================================"

if [ -d "\$REPO_DIR/.git" ]; then
    echo "[+] Fetching latest updates from GitHub..."
    git -C "\$REPO_DIR" pull --ff-only || {
        echo "[!] Git pull encountered conflicts or failed. Proceeding with local update."
    }
fi

bash "\$REPO_DIR/installer.sh" --update
EOF
    chmod +x "$UPDATER_SCRIPT"

    # 2. Global Wallpaper Switcher Script
    WALL_SCRIPT="$TARGET_HOME/.local/bin/set-wallpaper"
    ln -sf "$TARGET_HOME/.config/i3/scripts/set_wallpaper.sh" "$WALL_SCRIPT"
    ln -sf "$TARGET_HOME/.config/i3/scripts/set_wallpaper.sh" "$TARGET_HOME/.local/bin/i3-wallpaper"

    # 3. Global Terminal Prompt Switcher Script
    PROMPT_SCRIPT="$TARGET_HOME/.local/bin/set-prompt"
    ln -sf "$TARGET_HOME/.config/i3/scripts/set_prompt.sh" "$PROMPT_SCRIPT"
    ln -sf "$TARGET_HOME/.config/i3/scripts/set_prompt.sh" "$TARGET_HOME/.local/bin/i3-prompt"

    # Link to /usr/local/bin if root or sudo is available so it's in system PATH
    if [ -n "$SUDO" ] || [ "$EUID" -eq 0 ]; then
        $SUDO ln -sf "$UPDATER_SCRIPT" /usr/local/bin/i3-update 2>/dev/null || true
        $SUDO ln -sf "$WALL_SCRIPT" /usr/local/bin/set-wallpaper 2>/dev/null || true
        $SUDO ln -sf "$WALL_SCRIPT" /usr/local/bin/i3-wallpaper 2>/dev/null || true
        $SUDO ln -sf "$PROMPT_SCRIPT" /usr/local/bin/set-prompt 2>/dev/null || true
        $SUDO ln -sf "$PROMPT_SCRIPT" /usr/local/bin/i3-prompt 2>/dev/null || true
    fi
}

reload_i3_live() {
    # If currently running inside an X11 / i3 session, live-reload without restarting session
    if [ -n "$DISPLAY" ] && command -v i3-msg >/dev/null 2>&1 && pgrep -x i3 >/dev/null 2>&1; then
        echo "[+] Active i3 session detected! Reloading live..."
        i3-msg reload >/dev/null 2>&1 || true
        
        # Refresh wallpaper
        if [ -x "$HOME/.fehbg" ]; then
            "$HOME/.fehbg" >/dev/null 2>&1 || true
        fi

        # Restart compositor smoothly if running
        if pgrep -x picom >/dev/null 2>&1; then
            pkill -x picom 2>/dev/null || true
            sleep 0.2
            picom -b --config "$HOME/.config/picom/picom.conf" >/dev/null 2>&1 || true
        fi

        # Re-trigger VM clipboard sync
        if [ -x "$HOME/.config/i3/clipboard_fix.sh" ]; then
            "$HOME/.config/i3/clipboard_fix.sh" >/dev/null 2>&1 || true
        fi

        # Send desktop notification if notify-send is available
        if command -v notify-send >/dev/null 2>&1; then
            notify-send "i3wm Customization" "Dotfiles and status bar updated successfully!" -i preferences-desktop-theme 2>/dev/null || true
        fi
        
        echo "[✔] Live reload completed! Changes are now active."
    fi
}

full_install() {
    print_banner
    install_packages
    install_fonts
    install_zsh
    deploy_configs
    reload_i3_live

    echo "========================================================"
    echo "          Installation Completed Successfully!          "
    echo "========================================================"
    echo "Quick Tips:"
    echo " 1. Select 'i3' as your session at login screen."
    echo " 2. Press 'Win + Enter' for Alacritty terminal."
    echo " 3. Press 'Win + d' for Rofi application launcher."
    echo " 4. Press 'Win + Shift + w' to open the Wallpaper Switcher."
    echo " 5. Run 'set-wallpaper [1-5|path]' to switch wallpaper anytime."
    echo " 6. Run 'set-prompt [arrow|classic|kali]' to switch prompt style."
    echo " 7. Run 'i3-update' or 'bash update.sh' to update dotfiles."
    echo "========================================================"
}

quick_update() {
    print_banner
    echo "[*] Running Quick Dotfiles Update (No reinstall needed)..."
    backup_configs
    deploy_configs
    reload_i3_live

    echo "========================================================"
    echo "           Update Completed Successfully!               "
    echo "========================================================"
    echo "[✔] All dotfiles, scripts, prompts, and status bars updated."
    echo "[✔] You can run 'i3-update' anytime to sync changes."
    echo "========================================================"
}

git_update() {
    print_banner
    echo "[*] Checking for updates from Git repository..."
    if [ -d "$SCRIPT_DIR/.git" ]; then
        git -C "$SCRIPT_DIR" pull || {
            echo "[!] Git pull failed. Continuing with local files..."
        }
    else
        echo "[!] Not a git repository. Skipping git pull."
    fi
    quick_update
}

change_wallpaper() {
    TARGET_IMG="$1"
    if [ ! -f "$HOME/.config/i3/scripts/set_wallpaper.sh" ]; then
        deploy_configs
    fi
    bash "$HOME/.config/i3/scripts/set_wallpaper.sh" "$TARGET_IMG"
}

change_prompt() {
    TARGET_STYLE="$1"
    deploy_configs
    bash "$HOME/.config/i3/scripts/set_prompt.sh" "$TARGET_STYLE"
}

show_help() {
    echo "Kali Linux & Debian i3wm Customization Installer & Updater"
    echo ""
    echo "Usage: ./installer.sh [OPTION]"
    echo ""
    echo "Options:"
    echo "  -u, --update                 Quick update dotfiles & scripts only (No sudo / No package install)"
    echo "  -g, --git-update             Pull latest changes from Git and update dotfiles"
    echo "  -f, --full                   Run full installation (Packages, fonts, dotfiles)"
    echo "  -w, --wallpaper [1-5|PATH]   Switch wallpaper (1-5 for minimal presets, or path to custom image)"
    echo "  -p, --prompt [1-4|STYLE]     Switch terminal prompt style (arrow, classic, kali, compact)"
    echo "  -h, --help                   Show this help message"
    echo ""
    echo "Examples:"
    echo "  ./installer.sh --wallpaper 2             # Switch to wallpaper #2 (Kali Dragon)"
    echo "  ./installer.sh -w ~/Downloads/bg.png     # Set custom wallpaper"
    echo "  ./installer.sh --prompt classic          # Set classic user@host:~$ prompt"
    echo "  ./installer.sh --prompt kali             # Set iconic Kali two-line prompt"
    echo "  ./installer.sh --update                  # Quick update without reinstalling"
    echo "  ./installer.sh --full                    # Complete first-time installation"
    echo "  set-wallpaper                            # Wallpaper menu anytime"
    echo "  set-prompt                               # Prompt menu anytime"
    echo "  i3-update                                # Update anytime from terminal"
}

# ------------------------------------------------------------------------------
# Entrypoint & CLI Parsing
# ------------------------------------------------------------------------------

case "$1" in
    -u|--update)
        quick_update
        exit 0
        ;;
    -g|--git-update)
        git_update
        exit 0
        ;;
    -f|--full)
        full_install
        exit 0
        ;;
    -w|--wallpaper)
        change_wallpaper "$2"
        exit 0
        ;;
    -p|--prompt)
        change_prompt "$2"
        exit 0
        ;;
    -h|--help)
        show_help
        exit 0
        ;;
    "")
        # Interactive mode if running in a terminal
        if [ -t 0 ]; then
            print_banner
            echo "Please choose an option:"
            echo "  1) Full Installation  (First time setup - packages, fonts & configs)"
            echo "  2) Quick Update        (Update dotfiles & scripts only - Instant)"
            echo "  3) Git Pull & Update   (Pull latest from GitHub & update configs)"
            echo "  4) Switch Wallpaper    (Choose from 5 minimal wallpapers or custom)"
            echo "  5) Terminal Prompt     (Arrow / Classic Linux user@host / Kali)"
            echo "  6) Exit"
            echo ""
            read -rp "Select an option [1-6] (Default: 1): " choice
            case "$choice" in
                2)
                    quick_update
                    ;;
                3)
                    git_update
                    ;;
                4)
                    change_wallpaper ""
                    ;;
                5)
                    change_prompt ""
                    ;;
                6)
                    echo "Aborted."
                    exit 0
                    ;;
                *)
                    full_install
                    ;;
            esac
        else
            # Non-interactive default to full install
            full_install
        fi
        ;;
    *)
        echo "[!] Unknown option: $1"
        show_help
        exit 1
        ;;
esac