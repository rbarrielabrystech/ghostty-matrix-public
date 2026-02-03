#!/bin/bash
# Matrix Terminal Header - Shows on every new terminal window
# Cross-platform: Linux, macOS, Windows (WSL/Git Bash)
# "There is no spoon." - Spoon Boy

# ============================================================
# CONFIGURATION
# ============================================================

# Cross-platform config path
MATRIX_CONFIG="${MATRIX_CONFIG:-$HOME/.config/ghostty/matrix.conf}"

# Load user configuration if it exists
if [ -f "$MATRIX_CONFIG" ]; then
    # shellcheck source=/dev/null
    source "$MATRIX_CONFIG"
fi

# Default values (if not set in config)
MATRIX_SHOW_HEADER="${MATRIX_SHOW_HEADER:-true}"
MATRIX_SHOW_QUOTE="${MATRIX_SHOW_QUOTE:-true}"
MATRIX_SHOW_SYSTEM_INFO="${MATRIX_SHOW_SYSTEM_INFO:-true}"
MATRIX_CUSTOM_QUOTES="${MATRIX_CUSTOM_QUOTES:-}"
MATRIX_CUSTOM_COLORS="${MATRIX_CUSTOM_COLORS:-false}"
MATRIX_COLOR_PRIMARY="${MATRIX_COLOR_PRIMARY:-0;32m}"
MATRIX_COLOR_BRIGHT="${MATRIX_COLOR_BRIGHT:-1;32m}"
MATRIX_COLOR_DIM="${MATRIX_COLOR_DIM:-2;32m}"

# Exit early if header is disabled
[ "$MATRIX_SHOW_HEADER" != "true" ] && exit 0

# ============================================================
# COLORS
# ============================================================

if [ "$MATRIX_CUSTOM_COLORS" = "true" ]; then
    GREEN="\033[${MATRIX_COLOR_PRIMARY}"
    BRIGHT_GREEN="\033[${MATRIX_COLOR_BRIGHT}"
    DIM_GREEN="\033[${MATRIX_COLOR_DIM}"
else
    GREEN='\033[0;32m'
    BRIGHT_GREEN='\033[1;32m'
    DIM_GREEN='\033[2;32m'
fi
NC='\033[0m'

# ============================================================
# CROSS-PLATFORM HELPERS
# ============================================================

# Get terminal dimensions (with fallbacks)
get_cols() {
    local cols
    cols=$(tput cols 2>/dev/null) || cols=$(stty size 2>/dev/null | cut -d' ' -f2) || cols=80
    echo "$cols"
}

COLS=$(get_cols)

# Center calculation helper
center_text() {
    local text="$1"
    local text_len=${#text}
    local padding=$(( (COLS - text_len) / 2 ))
    [ $padding -lt 0 ] && padding=0
    printf "%*s%s" $padding "" "$text"
}

# Get system info (cross-platform)
get_kernel_info() {
    case "$(uname -s)" in
        Linux*|Darwin*)
            uname -r | cut -d'-' -f1
            ;;
        MINGW*|MSYS*|CYGWIN*)
            uname -r 2>/dev/null || echo "Windows"
            ;;
        *)
            uname -r 2>/dev/null || echo "unknown"
            ;;
    esac
}

# Get quotes array (default + custom)
get_quotes() {
    local quotes=(
        "\"There is no spoon.\" - Spoon Boy"
        "\"I know kung fu.\" - Neo"
        "\"Free your mind.\" - Morpheus"
        "\"The Matrix is everywhere.\" - Morpheus"
        "\"What is real? How do you define real?\" - Morpheus"
        "\"You have to let it all go. Fear, doubt, disbelief.\" - Morpheus"
        "\"I'm trying to free your mind, Neo.\" - Morpheus"
        "\"The body cannot live without the mind.\" - Morpheus"
        "\"You are The One, Neo.\" - Trinity"
        "\"Guns. Lots of guns.\" - Neo"
    )

    # Add custom quotes if defined
    if [ -n "$MATRIX_CUSTOM_QUOTES" ]; then
        IFS='|' read -ra custom_quotes <<< "$MATRIX_CUSTOM_QUOTES"
        quotes+=("${custom_quotes[@]}")
    fi

    # Return random quote
    echo "${quotes[$RANDOM % ${#quotes[@]}]}"
}

# ============================================================
# DISPLAY HEADER
# ============================================================

# System info header
printf "${DIM_GREEN}"
center_text "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
printf "${NC}"

printf "${GREEN}"
center_text "[ SYSTEM BREACH SUCCESSFUL ]"
echo ""
echo ""

if [ "$MATRIX_SHOW_SYSTEM_INFO" = "true" ]; then
    center_text "Operator: $(whoami)    Node: $(hostname -s 2>/dev/null || hostname)    Shell: $(basename $SHELL)"
    echo ""
    center_text "$(date '+%Y.%m.%d // %H:%M:%S')    Kernel: $(get_kernel_info)"
    echo ""
fi

printf "${NC}"

printf "${DIM_GREEN}"
center_text "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
printf "${NC}"
echo ""
echo ""

# Random Matrix quote
if [ "$MATRIX_SHOW_QUOTE" = "true" ]; then
    random_quote=$(get_quotes)
    printf "${BRIGHT_GREEN}"
    center_text "$random_quote"
    printf "${NC}"
    echo ""
    echo ""
fi
