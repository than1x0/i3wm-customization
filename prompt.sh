# ==============================================================================
# Kali Linux & Debian i3wm Custom Prompt Configuration (Bash)
# Dynamically loads and switches terminal prompt styles in Bash
# ==============================================================================

PROMPT_STYLE_FILE="$HOME/.config/i3/prompt_style"

_apply_kali_bash_prompt() {
    local style="arrow"
    [ -f "$PROMPT_STYLE_FILE" ] && style=$(cat "$PROMPT_STYLE_FILE" 2>/dev/null)

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
            PS1='\[\033[01;35m\][\u@\h \W]\$\[\033[00m\] '
            ;;
        arrow|1|*)
            # Minimal Arrow style in Bash
            PS1='\[\033[01;32m\]➜\[\033[00m\]  \[\033[01;36m\]\W\[\033[00m\] \$ '
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
    elif [ -x "$HOME/.local/bin/set-prompt" ]; then
        "$HOME/.local/bin/set-prompt" "$@"
    fi
    _apply_kali_bash_prompt
}

# Convenient aliases
alias prompt-arrow="set-prompt arrow"
alias prompt-classic="set-prompt classic"
alias prompt-kali="set-prompt kali"
alias prompt-compact="set-prompt compact"
