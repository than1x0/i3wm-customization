# ==============================================================================
# Kali Linux & Debian i3wm Custom Prompt Configuration
# ==============================================================================

PROMPT_STYLE_FILE="$HOME/.config/i3/prompt_style"

_apply_kali_prompt() {
    local style="arrow"
    [ -f "$PROMPT_STYLE_FILE" ] && style=$(cat "$PROMPT_STYLE_FILE" 2>/dev/null)

    case "$style" in
        classic|2)
            # Classic Linux prompt (Green for normal user, Red for root)
            PROMPT='%(?.%F{green}.%F{red})%n@%m%f:%F{blue}%~%f%# '
            ;;
        kali|3)
            # Iconic Kali Linux Two-Line Prompt
            PROMPT=$'%(?.%F{blue}.%F{red})┌──(%F{white}%n%F{red}㉿%F{white}%m%F{blue})-[%F{cyan}%~%F{blue}]\n└─%F{white}%#%f '
            ;;
        compact|4)
            # Compact brackets
            PROMPT='%F{magenta}[%n@%m %1~]%f%# '
            ;;
        arrow|1|*)
            # Default Minimal Arrow (Oh-My-Zsh style)
            PROMPT='%(?:%F{green}➜ :%F{red}➜ ) %F{cyan}%c%f '
            ;;
    esac
}

_apply_kali_prompt

# Interactive shell function for live in-terminal switching
set-prompt() {
    if [ -x "$HOME/.config/i3/scripts/set_prompt.sh" ]; then
        "$HOME/.config/i3/scripts/set_prompt.sh" "$@"
    elif [ -x "$HOME/.local/bin/set-prompt" ]; then
        "$HOME/.local/bin/set-prompt" "$@"
    fi
    _apply_kali_prompt
    zle && zle reset-prompt 2>/dev/null || true
}

# Convenient aliases
alias prompt-arrow="set-prompt arrow"
alias prompt-classic="set-prompt classic"
alias prompt-kali="set-prompt kali"
alias prompt-compact="set-prompt compact"
