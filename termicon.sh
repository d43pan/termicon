#!/usr/bin/env bash
# termicon.sh - set terminal tab emojis per SSH host or directory
# Source this file in your .bashrc or .zshrc:
#   source /path/to/termicon/termicon.sh

TERMICON_CONFIG="${TERMICON_CONFIG:-$HOME/.config/termicon/config}"

_termicon_set_title() {
    local title="$1"
    if [[ -n "$TMUX" ]]; then
        # In tmux: set the window name
        printf '\ek%s\e\\' "$title"
    else
        # Standard terminals: OSC 0 sets both tab and window title
        printf '\033]0;%s\007' "$title"
    fi
}

_termicon_lookup() {
    local type="$1"  # "ssh" or "dir"
    local key="$2"

    [[ ! -f "$TERMICON_CONFIG" ]] && return 1

    local best_emoji=""
    local best_len=0

    while IFS=' ' read -r entry emoji_val || [[ -n "$entry" ]]; do
        [[ "$entry" == "#"* || -z "$entry" || -z "$emoji_val" ]] && continue
        local etype="${entry%%:*}"
        local ekey="${entry#*:}"
        [[ "$etype" != "$type" ]] && continue

        if [[ "$type" == "ssh" ]]; then
            if [[ "$ekey" == "$key" ]]; then
                echo "$emoji_val"
                return 0
            fi
        elif [[ "$type" == "dir" ]]; then
            # Expand ~ so stored paths with ~ work
            ekey="${ekey/#\~/$HOME}"
            local len="${#ekey}"
            if [[ "$key" == "$ekey" || "$key" == "$ekey/"* ]]; then
                if (( len > best_len )); then
                    best_len=$len
                    best_emoji="$emoji_val"
                fi
            fi
        fi
    done < "$TERMICON_CONFIG"

    if [[ "$type" == "dir" && -n "$best_emoji" ]]; then
        echo "$best_emoji"
        return 0
    fi
    return 1
}

_termicon_on_cd() {
    local dir="$PWD"
    local emoji
    emoji=$(_termicon_lookup "dir" "$dir")
    local label
    label="$(basename "$dir")"
    if [[ -n "$emoji" ]]; then
        _termicon_set_title "$emoji $label"
    else
        _termicon_set_title "$label"
    fi
}

# SSH wrapper — sets title before connecting, restores on exit
ssh() {
    local host="" skip_next=false
    # SSH single-char flags that consume the next argument
    local flags_with_args="bcDEeFIiJLlmoOpQRSWw"
    for arg in "$@"; do
        if $skip_next; then
            skip_next=false
            continue
        fi
        if [[ "$arg" == -* ]]; then
            local flag="${arg:1:1}"
            # Only skip next arg if the flag is alone (e.g. -p, not -p22)
            if [[ "$flags_with_args" == *"$flag"* && ${#arg} -eq 2 ]]; then
                skip_next=true
            fi
        elif [[ -z "$host" ]]; then
            host="$arg"
            break
        fi
    done

    # Strip user@ prefix from host
    host="${host##*@}"
    # Strip port suffix (e.g. host:22 or host/path for ProxyJump)
    host="${host%%:*}"

    if [[ -n "$host" ]]; then
        local emoji
        emoji=$(_termicon_lookup "ssh" "$host")
        if [[ -n "$emoji" ]]; then
            _termicon_set_title "$emoji $host"
        else
            _termicon_set_title "🖥️ $host"
        fi
    fi

    command ssh "$@"
    local exit_code=$?

    # Restore local title after SSH exits
    _termicon_on_cd
    return $exit_code
}

# Register directory change hooks
if [[ -n "$ZSH_VERSION" ]]; then
    autoload -Uz add-zsh-hook 2>/dev/null
    add-zsh-hook chpwd _termicon_on_cd
elif [[ -n "$BASH_VERSION" ]]; then
    cd() { builtin cd "$@" && _termicon_on_cd; }
    pushd() { builtin pushd "$@" && _termicon_on_cd; }
    popd() { builtin popd "$@" && _termicon_on_cd; }
fi

# Set title for the current directory on shell startup
_termicon_on_cd
