#!/usr/bin/env bash

# ==============================================================================
# Kali Linux & Debian i3wm Terminal Prompt Switcher
# Switch between Minimal Arrow, Classic Linux, and Iconic Kali prompt styles
# Supports both ZSH (with Oh My Zsh) and BASH!
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROMPT_STYLE_FILE="$HOME/.config/i3/prompt_style"
mkdir -p "$HOME/.config/i3/scripts"

ensure_prompt_configured() {
    # 1. Ensure prompt.zsh and prompt.sh exist in ~/.config/i3/scripts/
    for script_name in "prompt.zsh" "prompt.sh"; do
        if [ ! -f "$HOME/.config/i3/scripts/$script_name" ]; then
            if [ -f "$SCRIPT_DIR/$script_name" ]; then
                cp "$SCRIPT_DIR/$script_name" "$HOME/.config/i3/scripts/$script_name"
            elif [ -f "$SCRIPT_DIR/../$script_name" ]; then
                cp "$SCRIPT_DIR/../$script_name" "$HOME/.config/i3/scripts/$script_name"
            elif [ -f "$SCRIPT_DIR/.config/i3/scripts/$script_name" ]; then
                cp "$SCRIPT_DIR/.config/i3/scripts/$script_name" "$HOME/.config/i3/scripts/$script_name"
            fi
        fi
    done

    # 2. Add hook to ~/.zshrc for ZSH
    ZSHRC="$HOME/.zshrc"
    if [ -f "$ZSHRC" ]; then
        if ! grep -q "prompt.zsh" "$ZSHRC" 2>/dev/null; then
            echo "" >> "$ZSHRC"
            echo "# Kali i3wm Custom Prompt Hook (ZSH)" >> "$ZSHRC"
            echo '[ -f "$HOME/.config/i3/scripts/prompt.zsh" ] && source "$HOME/.config/i3/scripts/prompt.zsh"' >> "$ZSHRC"
        fi
    fi

    # 3. Add hook to ~/.bashrc for BASH
    BASHRC="$HOME/.bashrc"
    if [ -f "$BASHRC" ]; then
        # Clean up any legacy incorrect prompt.zsh in .bashrc
        sed -i '/prompt\.zsh/d' "$BASHRC" 2>/dev/null || true
        if ! grep -q "prompt.sh" "$BASHRC" 2>/dev/null; then
            echo "" >> "$BASHRC"
            echo "# Kali i3wm Custom Prompt Hook (Bash)" >> "$BASHRC"
            echo '[ -f "$HOME/.config/i3/scripts/prompt.sh" ] && source "$HOME/.config/i3/scripts/prompt.sh"' >> "$BASHRC"
        fi
    fi
}

apply_prompt() {
    local style="$1"
    local name="$2"

    ensure_prompt_configured
    echo "$style" > "$PROMPT_STYLE_FILE"

    echo "[✔] Terminal prompt set to: $name"
    echo "[✔] ~/.zshrc and ~/.bashrc prompt integration verified."
    
    # Context-aware tip based on current shell
    if [ -n "$BASH_VERSION" ]; then
        echo "[i] Current shell is BASH. Run 'source ~/.bashrc' to apply."
        echo "[i] Or type 'zsh' to launch Oh My Zsh."
    else
        echo "[i] Current shell is ZSH. Run 'source ~/.zshrc' (or 'exec zsh') to apply."
    fi

    if command -v notify-send >/dev/null 2>&1; then
        notify-send "Terminal Prompt Updated" "$name" -i utilities-terminal 2>/dev/null || true
    fi
}

show_menu() {
    echo "========================================================"
    echo "       Kali i3wm Terminal Prompt Style Switcher         "
    echo "========================================================"
    echo "Select a prompt style:"
    echo "  [1] Minimal Arrow (Default)   ➜  ~ "
    echo "  [2] Classic Linux             user@kali:~$  (root@kali:~#)"
    echo "  [3] Iconic Kali Linux         ┌──(user㉿kali)-[~]"
    echo "                                └─$ "
    echo "  [4] Compact Brackets          [user@kali ~]$ "
    echo "  [Q] Cancel / Quit"
    echo "========================================================"
    read -rp "Select option [1-4 / Q]: " choice

    case "$choice" in
        1) apply_prompt "arrow" "Minimal Arrow (➜ ~)" ;;
        2) apply_prompt "classic" "Classic Linux (user@kali:~$)" ;;
        3) apply_prompt "kali" "Iconic Kali Linux Two-Line" ;;
        4) apply_prompt "compact" "Compact Brackets ([user@kali ~]$)" ;;
        [qQ]) echo "Cancelled."; exit 0 ;;
        *) echo "[!] Invalid selection."; exit 1 ;;
    esac
}

STYLE="$1"

if [ -z "$STYLE" ]; then
    show_menu
    exit 0
fi

case "$STYLE" in
    1|arrow)
        apply_prompt "arrow" "Minimal Arrow (➜ ~)"
        ;;
    2|classic)
        apply_prompt "classic" "Classic Linux (user@kali:~$)"
        ;;
    3|kali)
        apply_prompt "kali" "Iconic Kali Linux Two-Line"
        ;;
    4|compact)
        apply_prompt "compact" "Compact Brackets ([user@kali ~]$)"
        ;;
    -h|--help)
        echo "Usage: set-prompt [1-4 | arrow | classic | kali | compact]"
        echo ""
        echo "Available Styles:"
        echo "  1, arrow       Minimal Arrow: ➜  ~ "
        echo "  2, classic     Classic Linux: user@kali:~$ (root@kali:~#)"
        echo "  3, kali        Iconic Kali: ┌──(user㉿kali)-[~] \n └─$ "
        echo "  4, compact     Compact: [user@kali ~]$ "
        echo ""
        echo "Examples:"
        echo "  set-prompt classic       # Set classic user@kali:~$ prompt"
        echo "  set-prompt kali          # Set iconic Kali two-line prompt"
        echo "  set-prompt arrow         # Set minimal arrow prompt"
        ;;
    *)
        echo "[!] Unknown style: $STYLE"
        echo "Available styles: arrow (1), classic (2), kali (3), compact (4)"
        exit 1
        ;;
esac
