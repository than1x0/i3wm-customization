#!/usr/bin/env bash

# ==============================================================================
# Kali Linux & Debian i3wm Screen Saver & DPMS Sleep Controller
# Prevents VM screen blackouts, freezes, and controls idle screen timeouts.
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$HOME/.config/i3/screensaver_config"
mkdir -p "$HOME/.config/i3"

apply_screensaver_settings() {
    local mode="$1"
    local minutes="${2:-0}"

    case "$mode" in
        off|disable|0)
            if command -v xset >/dev/null 2>&1; then
                xset s off 2>/dev/null || true
                xset -dpms 2>/dev/null || true
                xset s noblank 2>/dev/null || true
                xset s 0 0 2>/dev/null || true
            fi

            # Disable XFCE Power Manager display blanking & DPMS if present
            if command -v xfconf-query >/dev/null 2>&1; then
                xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/blank-on-ac -s 0 2>/dev/null || true
                xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/dpms-on-ac-sleep -s 0 2>/dev/null || true
                xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/dpms-on-ac-off -s 0 2>/dev/null || true
                xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/dpms-enabled -s false 2>/dev/null || true
                xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/lock-screen-suspend-hibernate -s false 2>/dev/null || true
            fi

            # Terminate background light-locker if running in i3wm
            pkill -f light-locker 2>/dev/null || true

            echo "off" > "$CONFIG_FILE"
            echo "[✔] Screen sleep and screensaver DISABLED (Never turn off screen)."
            if command -v notify-send >/dev/null 2>&1; then
                notify-send "Display Power Settings" "Screen sleep & screensaver DISABLED (Always On)" -i preferences-desktop-screensaver 2>/dev/null || true
            fi
            ;;

        on|enable|timeout)
            if [ -z "$minutes" ] || [ "$minutes" -le 0 ]; then
                minutes=15
            fi
            local seconds=$((minutes * 60))

            if command -v xset >/dev/null 2>&1; then
                xset +dpms 2>/dev/null || true
                xset dpms "$seconds" "$seconds" "$seconds" 2>/dev/null || true
                xset s "$seconds" "$seconds" 2>/dev/null || true
                xset s blank 2>/dev/null || true
            fi

            if command -v xfconf-query >/dev/null 2>&1; then
                xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/blank-on-ac -s "$minutes" 2>/dev/null || true
                xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/dpms-on-ac-sleep -s "$minutes" 2>/dev/null || true
                xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/dpms-on-ac-off -s "$((minutes + 5))" 2>/dev/null || true
                xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/dpms-enabled -s true 2>/dev/null || true
            fi

            echo "$minutes" > "$CONFIG_FILE"
            echo "[✔] Screen timeout set to $minutes minutes ($seconds seconds)."
            if command -v notify-send >/dev/null 2>&1; then
                notify-send "Display Power Settings" "Screen sleep timeout set to $minutes minutes" -i preferences-desktop-screensaver 2>/dev/null || true
            fi
            ;;
    esac
}

show_status() {
    echo "========================================================"
    echo "       Kali i3wm Display Sleep & DPMS Status            "
    echo "========================================================"
    if [ -f "$CONFIG_FILE" ]; then
        current=$(cat "$CONFIG_FILE")
        if [ "$current" == "off" ]; then
            echo "Current Config: DISABLED (Screen will never sleep)"
        else
            echo "Current Config: $current minutes timeout"
        fi
    else
        echo "Current Config: Default (Disabled in i3)"
    fi
    echo ""
    echo "Live X11 (xset) Query:"
    if command -v xset >/dev/null 2>&1; then
        xset q | grep -E "Screen Saver:|timeout:|DPMS is|Standby:|Suspend:|Off:" || true
    else
        echo "[!] xset utility not found."
    fi
    echo "========================================================"
}

show_rofi_menu() {
    if ! command -v rofi >/dev/null 2>&1; then
        show_terminal_menu
        return
    fi

    CHOICES="1. Never Turn Off Screen (Recommended for VM / No Black Screen)\n2. Set Timeout to 15 Minutes\n3. Set Timeout to 30 Minutes\n4. Set Timeout to 60 Minutes\n5. Check Status"

    CHOSEN=$(echo -e "$CHOICES" | rofi -dmenu -i -p "Screen Sleep & Saver" -lines 5 -width 40 2>/dev/null || true)

    case "$CHOSEN" in
        1*) apply_screensaver_settings "off" ;;
        2*) apply_screensaver_settings "on" 15 ;;
        3*) apply_screensaver_settings "on" 30 ;;
        4*) apply_screensaver_settings "on" 60 ;;
        5*) 
            STATUS_MSG=$(xset q 2>/dev/null | grep -E "timeout:|DPMS is" || echo "Status unavailable")
            rofi -e "Display Status: $STATUS_MSG" 2>/dev/null || true
            ;;
        *) exit 0 ;;
    esac
}

show_terminal_menu() {
    echo "========================================================"
    echo "       Kali i3wm Screen Saver & Sleep Settings          "
    echo "========================================================"
    echo "  [1] Never Turn Off Screen (Recommended for VM) - OFF"
    echo "  [2] Set Timeout to 15 Minutes"
    echo "  [3] Set Timeout to 30 Minutes"
    echo "  [4] Set Timeout to 60 Minutes"
    echo "  [5] Check Current Status"
    echo "  [Q] Cancel / Quit"
    echo "========================================================"
    read -rp "Select option [1-5 / Q]: " choice

    case "$choice" in
        1) apply_screensaver_settings "off" ;;
        2) apply_screensaver_settings "on" 15 ;;
        3) apply_screensaver_settings "on" 30 ;;
        4) apply_screensaver_settings "on" 60 ;;
        5) show_status ;;
        [qQ]) echo "Cancelled."; exit 0 ;;
        *) echo "[!] Invalid selection."; exit 1 ;;
    esac
}

# ------------------------------------------------------------------------------
# Entrypoint & Argument Handling
# ------------------------------------------------------------------------------

ACTION="$1"

case "$ACTION" in
    off|disable|0)
        apply_screensaver_settings "off"
        ;;
    on|enable)
        apply_screensaver_settings "on" "$2"
        ;;
    [0-9]*)
        # Numeric timeout in minutes
        apply_screensaver_settings "on" "$ACTION"
        ;;
    status)
        show_status
        ;;
    --rofi|-r)
        show_rofi_menu
        ;;
    -h|--help)
        echo "Kali i3wm Screen Saver & Sleep Controller"
        echo ""
        echo "Usage: set-screensaver [off | on [min] | <minutes> | status | --rofi]"
        echo ""
        echo "Examples:"
        echo "  set-screensaver off        # Completely disable screen sleep & blackouts (Recommended)"
        echo "  set-screensaver 15         # Turn off screen after 15 minutes of inactivity"
        echo "  set-screensaver 30         # Turn off screen after 30 minutes"
        echo "  set-screensaver status     # Display current sleep/DPMS status"
        echo "  set-screensaver --rofi     # Open graphical selection menu"
        ;;
    "")
        if [ -t 0 ]; then
            show_terminal_menu
        else
            show_rofi_menu
        fi
        ;;
    *)
        echo "[!] Unknown option: $ACTION"
        echo "Run 'set-screensaver --help' for usage."
        exit 1
        ;;
esac
