# ==============================================================================
# Kali Linux & Debian i3wm Custom Prompt Configuration (ZSH)
# Dynamically loads and switches terminal prompt styles in ZSH
# Fully supports regular users, root, and sudo su sessions
# ==============================================================================

_get_kali_zsh_prompt_style() {
    local style_file="$HOME/.config/i3/prompt_style"
    if [[ $EUID -eq 0 ]]; then
        if [[ -n "$SUDO_USER" ]] && [[ -f "/home/$SUDO_USER/.config/i3/prompt_style" ]]; then
            style_file="/home/$SUDO_USER/.config/i3/prompt_style"
        elif [[ ! -f "$style_file" ]]; then
            for u_style in /home/*/.config/i3/prompt_style; do
                if [[ -f "$u_style" ]]; then
                    style_file="$u_style"
                    break
                fi
            done
        fi
    fi

    if [[ -f "$style_file" ]]; then
        cat "$style_file" 2>/dev/null || echo "arrow"
    else
        echo "arrow"
    fi
}

_apply_kali_prompt() {
    local style
    style=$(_get_kali_zsh_prompt_style)

    case "$style" in
        classic|2)
            # Classic Linux: user@host:path$ (Green for user, Red for root)
            if [[ $EUID -eq 0 ]]; then
                PROMPT='%F{red}%n@%m%f:%F{blue}%~%f# '
            else
                PROMPT='%F{green}%n@%m%f:%F{blue}%~%f$ '
            fi
            ;;
        kali|3)
            # Iconic Kali Linux Two-Line prompt
            if [[ $EUID -eq 0 ]]; then
                PROMPT=$'┌──(%F{red}%n㉿%m%f)-[%F{blue}%~%f]\n└─%F{red}#%f '
            else
                PROMPT=$'┌──(%F{blue}%n㉿%m%f)-[%F{cyan}%~%f]\n└─$ '
            fi
            ;;
        compact|4)
            # Compact brackets: [user@host dir]$
            if [[ $EUID -eq 0 ]]; then
                PROMPT='%F{red}[%n@%m %1~]%f# '
            else
                PROMPT='%F{magenta}[%n@%m %1~]%f%# '
            fi
            ;;
        arrow|1|*)
            # Default Minimal Arrow (Oh-My-Zsh style)
            if [[ $EUID -eq 0 ]]; then
                PROMPT='%(?:%F{red}➜ :%F{yellow}➜ ) %F{cyan}%c%f # '
            else
                if type git_prompt_info >/dev/null 2>&1; then
                    PROMPT='%(?:%F{green}➜ :%F{red}➜ ) %F{cyan}%c%f $(git_prompt_info)'
                else
                    PROMPT='%(?:%F{green}➜ :%F{red}➜ ) %F{cyan}%c%f '
                fi
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
    elif [ -n "$SUDO_USER" ] && [ -x "/home/$SUDO_USER/.config/i3/scripts/set_prompt.sh" ]; then
        "/home/$SUDO_USER/.config/i3/scripts/set_prompt.sh" "$@"
    elif [ -x "$HOME/.local/bin/set-prompt" ]; then
        "$HOME/.local/bin/set-prompt" "$@"
    elif [ -x "/usr/local/bin/set-prompt" ]; then
        "/usr/local/bin/set-prompt" "$@"
    fi
    _apply_kali_prompt
    zle && zle reset-prompt 2>/dev/null || true
}

# Convenient aliases
alias prompt-arrow="set-prompt arrow"
alias prompt-classic="set-prompt classic"
alias prompt-kali="set-prompt kali"
alias prompt-compact="set-prompt compact"
