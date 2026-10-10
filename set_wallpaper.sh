#!/usr/bin/env bash

# ==============================================================================
# Kali Linux & Debian i3wm Wallpaper Switcher
# Switch between bundled minimal wallpapers or set any custom image
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FEHBG="$HOME/.fehbg"

# Bundled wallpaper definitions
declare -A WALLPAPERS=(
    [1]="1-cyan-horizon.jpg"
    [2]="2-kali-dragon.jpg"
    [3]="3-night-mountains.jpg"
    [4]="4-penrose-geometry.jpg"
    [5]="5-dark-stardust.jpg"
)

declare -A WALLPAPER_NAMES=(
    [1]="Cyan Horizon (Minimal Obsidian)"
    [2]="Kali Dragon (Matte Cyber)"
    [3]="Night Mountains (Dark Horizon)"
    [4]="Penrose Geometry (Black & White)"
    [5]="Dark Stardust (Deep Charcoal)"
)

# Resolve wallpaper directory dynamically (Installed dir or repo dir)
if [ -d "$HOME/.wallpaper" ] && [ -f "$HOME/.wallpaper/${WALLPAPERS[1]}" ]; then
    WALL_DIR="$HOME/.wallpaper"
elif [ -d "$SCRIPT_DIR/.wallpaper" ]; then
    WALL_DIR="$SCRIPT_DIR/.wallpaper"
elif [ -d "$SCRIPT_DIR/../../.wallpaper" ]; then
    WALL_DIR="$SCRIPT_DIR/../../.wallpaper"
else
    WALL_DIR="$HOME/.wallpaper"
fi

# Apply wallpaper live and save to ~/.fehbg
apply_wallpaper() {
    local target_img="$1"
    local name="$2"

    if [ ! -f "$target_img" ]; then
        echo "[!] Error: Image file not found at: $target_img"
        exit 1
    fi

    # Update ~/.fehbg
    cat <<EOF > "$FEHBG"
#!/bin/sh
feh --no-fehbg --bg-fill "$target_img"
EOF
    chmod +x "$FEHBG"

    # Live apply if in X session
    if [ -n "$DISPLAY" ] && command -v feh >/dev/null 2>&1; then
        feh --no-fehbg --bg-fill "$target_img" 2>/dev/null || true
    fi

    # Desktop notification
    if command -v notify-send >/dev/null 2>&1; then
        notify-send "Wallpaper Updated" "${name:-$(basename "$target_img")}" -i preferences-desktop-wallpaper 2>/dev/null || true
    fi

    echo "[✔] Wallpaper successfully set to: ${name:-$target_img}"
}

# Rofi GUI Selector
show_rofi_menu() {
    if ! command -v rofi >/dev/null 2>&1; then
        echo "[!] Rofi is not installed. Falling back to terminal prompt."
        show_terminal_menu
        return
    fi

    MENU_OPTIONS=""
    for i in 1 2 3 4 5; do
        MENU_OPTIONS="${MENU_OPTIONS}${i}. ${WALLPAPER_NAMES[$i]}\n"
    done
    MENU_OPTIONS="${MENU_OPTIONS}Custom Image Path..."

    CHOSEN=$(echo -e "$MENU_OPTIONS" | rofi -dmenu -i -p "Select Wallpaper" -lines 6)

    if [ -z "$CHOSEN" ]; then
        exit 0
    fi

    case "$CHOSEN" in
        1*)
            apply_wallpaper "$WALL_DIR/${WALLPAPERS[1]}" "${WALLPAPER_NAMES[1]}"
            ;;
        2*)
            apply_wallpaper "$WALL_DIR/${WALLPAPERS[2]}" "${WALLPAPER_NAMES[2]}"
            ;;
        3*)
            apply_wallpaper "$WALL_DIR/${WALLPAPERS[3]}" "${WALLPAPER_NAMES[3]}"
            ;;
        4*)
            apply_wallpaper "$WALL_DIR/${WALLPAPERS[4]}" "${WALLPAPER_NAMES[4]}"
            ;;
        5*)
            apply_wallpaper "$WALL_DIR/${WALLPAPERS[5]}" "${WALLPAPER_NAMES[5]}"
            ;;
        "Custom Image Path..."*)
            CUSTOM_PATH=$(rofi -dmenu -p "Enter image path" -lines 0)
            if [ -n "$CUSTOM_PATH" ] && [ -f "$CUSTOM_PATH" ]; then
                apply_wallpaper "$CUSTOM_PATH" "Custom Image"
            fi
            ;;
    esac
}

# Interactive Terminal Menu
show_terminal_menu() {
    echo "========================================================"
    echo "           Kali i3wm Wallpaper Switcher                 "
    echo "========================================================"
    echo "Choose a wallpaper:"
    for i in 1 2 3 4 5; do
        echo "  [$i] ${WALLPAPER_NAMES[$i]}"
    done
    echo "  [C] Custom image file path"
    echo "  [Q] Cancel / Quit"
    echo "========================================================"
    read -rp "Select option [1-5 / C / Q]: " choice

    case "$choice" in
        1|2|3|4|5)
            apply_wallpaper "$WALL_DIR/${WALLPAPERS[$choice]}" "${WALLPAPER_NAMES[$choice]}"
            ;;
        [cC])
            read -rp "Enter full path to image file: " custom_img
            # Expand ~ if used
            custom_img="${custom_img/#\~/$HOME}"
            if [ -f "$custom_img" ]; then
                apply_wallpaper "$custom_img" "Custom Image"
            else
                echo "[!] File does not exist: $custom_img"
                exit 1
            fi
            ;;
        [qQ])
            echo "Cancelled."
            exit 0
            ;;
        *)
            echo "[!] Invalid selection."
            exit 1
            ;;
    esac
}

# ------------------------------------------------------------------------------
# Argument Handling
# ------------------------------------------------------------------------------

TARGET="$1"

if [ -z "$TARGET" ]; then
    if [ -t 0 ]; then
        show_terminal_menu
    else
        show_rofi_menu
    fi
    exit 0
fi

case "$TARGET" in
    -r|--rofi)
        show_rofi_menu
        ;;
    1|2|3|4|5)
        apply_wallpaper "$WALL_DIR/${WALLPAPERS[$TARGET]}" "${WALLPAPER_NAMES[$TARGET]}"
        ;;
    -h|--help)
        echo "Usage: set-wallpaper [1-5 | /path/to/image | --rofi]"
        echo ""
        echo "Options:"
        echo "  1-5                 Set one of the 5 bundled dark minimal wallpapers:"
        echo "                        1: Cyan Horizon (Minimal Obsidian)"
        echo "                        2: Kali Dragon (Matte Cyber)"
        echo "                        3: Night Mountains (Dark Horizon)"
        echo "                        4: Penrose Geometry (Black & White)"
        echo "                        5: Dark Stardust (Deep Charcoal)"
        echo "  /path/to/image      Set any custom image file as wallpaper"
        echo "  -r, --rofi          Open Rofi graphical wallpaper selector"
        echo "  -h, --help          Show this help message"
        ;;
    *)
        # Treat as custom image path
        TARGET="${TARGET/#\~/$HOME}"
        if [ -f "$TARGET" ]; then
            apply_wallpaper "$TARGET" "Custom Image ($(basename "$TARGET"))"
        else
            echo "[!] Error: Invalid wallpaper number (1-5) or file not found: $TARGET"
            echo "Run 'set-wallpaper --help' for usage."
            exit 1
        fi
        ;;
esac
