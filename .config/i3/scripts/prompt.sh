# ==============================================================================
# Kali Linux & Debian i3wm Custom Prompt Configuration (Bash)
# Dynamically loads and switches terminal prompt styles in Bash
# Fully supports regular users, root, and sudo su sessions
# ==============================================================================

_get_kali_bash_prompt_style() {
    local style_file="$HOME/.config/i3/prompt_style"
    if [ "$EUID" -eq 0 ]; then
        if [ -n "$SUDO_USER" ] && [ -f "/home/$SUDO_USER/.config/i3/prompt_style" ]; then
            style_file="/home/$SUDO_USER/.config/i3/prompt_style"
        elif [ ! -f "$style_file" ]; then
            for u_style in /home/*/.config/i3/prompt_style; do
                if [ -f "$u_style" ]; then
                    style_file="$u_style"
                    break
                fi
            done
        fi
    fi

    if [ -f "$style_file" ]; then
        cat "$style_file" 2>/dev/null || echo "arrow"
    else
        echo "arrow"
    fi
}

_apply_kali_bash_prompt() {
    local style
    style=$(_get_kali_bash_prompt_style)

    case "$style" in
        classic|2)
            # Classic Linux: user@host:path$ (Green for user, Red for root)
            if [ "$EUID" -eq 0 ]; then
                PS1='\[\033[01;31m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]# '
            else
                PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
            fi
            ;;
        kali|3)
            # Iconic Kali Linux Two-Line prompt
            if [ "$EUID" -eq 0 ]; then
                PS1='┌──(\[\033[01;31m\]\u㉿\h\[\033[00m\])-[\[\033[01;34m\]\w\[\033[00m\]]\n└─\[\033[01;31m\]#\[\033[00m\] '
            else
                PS1='┌──(\[\033[01;34m\]\u㉿\h\[\033[00m\])-[\[\033[01;36m\]\w\[\033[00m\]]\n└─\$ '
            fi
            ;;
        compact|4)
            # Compact brackets: [user@host dir]$
            if [ "$EUID" -eq 0 ]; then
                PS1='\[\033[01;31m\][\u@\h \W]#\[\033[00m\] '
            else
                PS1='\[\033[01;35m\][\u@\h \W]\$\[\033[00m\] '
            fi
            ;;
        arrow|1|*)
            # Minimal Arrow style in Bash
            if [ "$EUID" -eq 0 ]; then
                PS1='\[\033[01;31m\]➜\[\033[00m\]  \[\033[01;36m\]\W\[\033[00m\] # '
            else
                PS1='\[\033[01;32m\]➜\[\033[00m\]  \[\033[01;36m\]\W\[\033[00m\] \$ '
            fi
            ;;
    esac
}

# Run on every prompt command in Bash (avoid duplicate hooks if sourced multiple times)
if [[ "${PROMPT_COMMAND:-}" != *"_apply_kali_bash_prompt"* ]]; then
    PROMPT_COMMAND="_apply_kali_bash_prompt; ${PROMPT_COMMAND:-}"
fi

# Shell function for instant live switching within current bash session
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
    _apply_kali_bash_prompt
}

# Convenient aliases
alias prompt-arrow="set-prompt arrow"
alias prompt-classic="set-prompt classic"
alias prompt-kali="set-prompt kali"
alias prompt-compact="set-prompt compact"
