#!/usr/bin/env bash
# era-lib.sh - Shared library for Terminal Era scripts
# Source this file from era scripts: source "$(dirname "$0")/era-lib.sh"

# --- Config ---
MATRIX_CONF="${HOME}/.config/ghostty/matrix.conf"

read_matrix_conf() {
    local key="$1" default="$2"
    if [ -f "$MATRIX_CONF" ]; then
        local val
        val=$(grep "^${key}=" "$MATRIX_CONF" 2>/dev/null | tail -1 | cut -d'=' -f2- | sed 's/^"//;s/"$//' | xargs)
        [ -n "$val" ] && echo "$val" || echo "$default"
    else
        echo "$default"
    fi
}

era_name() { read_matrix_conf "MATRIX_ERA" ""; }

# --- Portable helpers (bash 3.2 lacks ${var^^}) ---

_upper() { echo "$1" | tr 'a-z' 'A-Z'; }
_lower() { echo "$1" | tr 'A-Z' 'a-z'; }

# --- Terminal output ---

# Slow character-by-character typing (like a real terminal/printer)
slow_type() {
    local text="$1" delay="${2:-0.05}"
    local i
    for (( i=0; i<${#text}; i++ )); do
        printf '%s' "${text:$i:1}"
        sleep "$delay"
    done
}

# Print with newline (fast)
fast_print() { echo "$1"; }

# Wait for keypress with optional timeout (returns the key)
wait_key() {
    local key=""
    read -rsn1 -t "${1:-0}" key 2>/dev/null
    echo "$key"
}

# Clear screen with optional delay
era_clear() { sleep "${1:-0}"; clear; }

# --- ANSI helpers ---

era_fg() { printf '\033[38;2;%d;%d;%dm' "$1" "$2" "$3"; }
era_bg() { printf '\033[48;2;%d;%d;%dm' "$1" "$2" "$3"; }
era_reset() { printf '\033[0m'; }
era_bold() { printf '\033[1m'; }
era_dim() { printf '\033[2m'; }
era_reverse() { printf '\033[7m'; }
era_hide_cursor() { printf '\033[?25l'; }
era_show_cursor() { printf '\033[?25h'; }
era_move() { printf '\033[%d;%dH' "$1" "$2"; }
era_save_cursor() { printf '\033[s'; }
era_restore_cursor() { printf '\033[u'; }

# Bell character
era_click() { printf '\007'; }

# --- Layout helpers ---

# Center text on screen
era_center() {
    local cols
    cols=$(tput cols 2>/dev/null || echo 80)
    local text="$1"
    local padding=$(( (cols - ${#text}) / 2 ))
    [ "$padding" -lt 0 ] && padding=0
    printf "%${padding}s%s\n" "" "$text"
}

# Repeat a character N times
era_repeat() {
    local char="$1" count="$2"
    printf '%*s' "$count" '' | tr ' ' "$char"
}

# Box drawing (single line)
era_box_top() {
    local w="${1:-60}"
    printf '╔'; era_repeat '═' $((w-2)); printf '╗\n'
}
era_box_bottom() {
    local w="${1:-60}"
    printf '╚'; era_repeat '═' $((w-2)); printf '╝\n'
}
era_box_sep() {
    local w="${1:-60}"
    printf '╠'; era_repeat '═' $((w-2)); printf '╣\n'
}
era_box_line() {
    local text="$1" w="${2:-60}"
    local inner=$((w-4))
    printf '║ %-*s ║\n' "$inner" "$text"
}

# --- Input helpers ---

# Simple line editor (for BASIC, DOS, etc.)
era_readline() {
    local prompt="$1"
    local line=""
    read -rep "$prompt" line
    echo "$line"
}

# Read single character without echo
era_getchar() {
    local char=""
    read -rsn1 char
    echo "$char"
}

# Read with timeout (returns empty on timeout)
era_getchar_timeout() {
    local timeout="${1:-1}"
    local char=""
    read -rsn1 -t "$timeout" char 2>/dev/null
    echo "$char"
}

# --- Cleanup ---

era_cleanup() {
    era_show_cursor
    era_reset
    stty echo 2>/dev/null
}

# Set up trap for clean exit
era_setup_traps() {
    trap 'era_cleanup; exit 0' INT TERM EXIT
}
