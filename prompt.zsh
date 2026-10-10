# ==============================================================================
# Kali Linux & Debian i3wm Custom Prompt Configuration
# Dynamically loads and switches terminal prompt styles
# ==============================================================================

PROMPT_STYLE_FILE="$HOME/.config/i3/prompt_style"

_apply_kali_prompt() {
    local style="arrow"
    [ -f "$PROMPT_STYLE_FILE" ] && style=$(cat "$PROMPT_STYLE_FILE" 2>/dev/null)

    case "$style" in
        classic|2)
            # Classic Linux: user@host:path$ (Green for user, Red for root)
            if [ "$EUID" -eq 0 ]; then
                PROMPT='%F{red}%n@%m%f:%F{blue}%~%f# '
            else
                PROMPT='%F{green}%n@%m%f:%F{blue}%~%f$ '
            fi
            ;;
        kali|3)
            # Iconic Kali Linux Two-Line prompt
            if [ "$EUID" -eq 0 ]; then
                PROMPT=$'┌──(%F{red}%n㉿%m%f)-[%F{blue}%~%f]\n└─%F{red}#%f '
            else
                PROMPT=$'┌──(%F{blue}%n㉿%m%f)-[%F{cyan}%~%f]\n└─$ '
            fi
            ;;
        compact|4)
            # Compact brackets: [user@host dir]$
            PROMPT='%F{magenta}[%n@%m %1~]%f%# '
            ;;
        arrow|1|*)
            # Default Minimal Arrow (Oh-My-Zsh style)
            if type git_prompt_info >/dev/null 2>&1; then
                PROMPT='%(?:%F{green}➜ :%F{red}➜ ) %F{cyan}%c%f $(git_prompt_info)'
            else
                PROMPT='%(?:%F{green}➜ :%F{red}➜ ) %F{cyan}%c%f '
            fi
            ;;
    esac
}

# Auto-apply on every prompt draw so changes take effect dynamically
autoload -Uz add-zsh-hook 2>/dev/null || true
if type add-zsh-hook >/dev/null 2>&1; then
    add-zsh-hook precmd _apply_kali_prompt
else
    _apply_kali_prompt
fi

# Shell function for instant live switching within current session
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
