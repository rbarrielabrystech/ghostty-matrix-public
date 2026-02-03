#!/bin/bash
# THE MATRIX - Terminal Startup Sequence
# Cross-platform: Linux, macOS, Windows (WSL/Git Bash)
# Press any key to skip
# "Unfortunately, no one can be told what the Matrix is. You have to see it for yourself."

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
MATRIX_ANIMATION_DURATION="${MATRIX_ANIMATION_DURATION:-8}"
MATRIX_FRAME_RATE="${MATRIX_FRAME_RATE:-60}"
MATRIX_DIFFUSE="${MATRIX_DIFFUSE:-true}"
MATRIX_TWINKLE="${MATRIX_TWINKLE:-true}"
MATRIX_SEQUENCE="${MATRIX_SEQUENCE:-number,rain,banner}"
MATRIX_BANNER_MESSAGE="${MATRIX_BANNER_MESSAGE:-WAKE UP NEO}"
MATRIX_SHOW_TEXT_SEQUENCE="${MATRIX_SHOW_TEXT_SEQUENCE:-true}"
MATRIX_TYPING_SPEED="${MATRIX_TYPING_SPEED:-0.06}"
MATRIX_SHOW_QUOTE="${MATRIX_SHOW_QUOTE:-true}"
MATRIX_SHOW_SYSTEM_INFO="${MATRIX_SHOW_SYSTEM_INFO:-true}"
MATRIX_CUSTOM_QUOTES="${MATRIX_CUSTOM_QUOTES:-}"
MATRIX_CUSTOM_COLORS="${MATRIX_CUSTOM_COLORS:-false}"
MATRIX_COLOR_PRIMARY="${MATRIX_COLOR_PRIMARY:-0;32m}"
MATRIX_COLOR_BRIGHT="${MATRIX_COLOR_BRIGHT:-1;32m}"
MATRIX_COLOR_DIM="${MATRIX_COLOR_DIM:-2;32m}"
MATRIX_ALLOW_SKIP="${MATRIX_ALLOW_SKIP:-true}"
MATRIX_USE_FALLBACK="${MATRIX_USE_FALLBACK:-true}"
MATRIX_FALLBACK_DURATION="${MATRIX_FALLBACK_DURATION:-5}"

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

# Cross-platform temp directory
TEMP_DIR="${TMPDIR:-${TMP:-/tmp}}"

# Get terminal dimensions (with fallbacks)
get_cols() {
    local cols
    cols=$(tput cols 2>/dev/null) || cols=$(stty size 2>/dev/null | cut -d' ' -f2) || cols=80
    echo "$cols"
}

get_lines() {
    local lines
    lines=$(tput lines 2>/dev/null) || lines=$(stty size 2>/dev/null | cut -d' ' -f1) || lines=24
    echo "$lines"
}

COLS=$(get_cols)
LINES=$(get_lines)

# Skip flag file (cross-platform temp directory)
SKIP_FLAG="${TEMP_DIR}/.matrix_skip_$$"
rm -f "$SKIP_FLAG"

# Cleanup on exit
cleanup() {
    rm -f "$SKIP_FLAG"
    # Kill any remaining background processes
    jobs -p 2>/dev/null | xargs -r kill 2>/dev/null || true
}
trap cleanup EXIT

# Center calculation helper
center_text() {
    local text="$1"
    local text_len=${#text}
    local padding=$(( (COLS - text_len) / 2 ))
    [ $padding -lt 0 ] && padding=0
    printf "%*s%s" $padding "" "$text"
}

# Check if skip was requested
is_skipped() {
    [ "$MATRIX_ALLOW_SKIP" = "true" ] && [ -f "$SKIP_FLAG" ]
}

# Background key listener - cross-platform approach
start_key_listener() {
    [ "$MATRIX_ALLOW_SKIP" != "true" ] && return
    # Try /dev/tty first (Unix), fall back to stdin
    (
        if [ -c /dev/tty ]; then
            read -n 1 -s </dev/tty 2>/dev/null
        else
            read -n 1 -s 2>/dev/null
        fi
        touch "$SKIP_FLAG"
    ) &
    KEY_LISTENER_PID=$!
}

stop_key_listener() {
    if [ -n "$KEY_LISTENER_PID" ]; then
        kill $KEY_LISTENER_PID 2>/dev/null || true
        wait $KEY_LISTENER_PID 2>/dev/null || true
    fi
}

# Typing effect - like the original movie (skippable)
type_text() {
    local text="$1"
    local delay="${2:-$MATRIX_TYPING_SPEED}"
    if is_skipped; then
        printf "%s" "$text"
        return
    fi
    for ((i=0; i<${#text}; i++)); do
        if is_skipped; then
            printf "%s" "${text:$i}"
            return
        fi
        printf "%s" "${text:$i:1}"
        sleep "$delay"
    done
}

# Skippable sleep (using awk instead of bc for cross-platform compatibility)
skip_sleep() {
    local duration="$1"
    local interval=0.1
    local elapsed=0
    while true; do
        if is_skipped; then return; fi
        # Use awk for floating point comparison (cross-platform, unlike bc)
        if awk "BEGIN {exit !($elapsed >= $duration)}"; then
            break
        fi
        sleep $interval
        elapsed=$(awk "BEGIN {print $elapsed + $interval}")
    done
}

# Cross-platform process killer
kill_process() {
    local pattern="$1"
    if command -v pkill &>/dev/null; then
        pkill -f "$pattern" 2>/dev/null || true
    elif command -v killall &>/dev/null; then
        killall "$pattern" 2>/dev/null || true
    else
        # Fallback: find PID manually
        ps aux 2>/dev/null | grep -v grep | grep "$pattern" | awk '{print $2}' | xargs -r kill 2>/dev/null || true
    fi
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

# Build cxxmatrix command options
build_cxxmatrix_opts() {
    local opts=""
    opts="--frame-rate=$MATRIX_FRAME_RATE"
    [ "$MATRIX_DIFFUSE" = "true" ] && opts="$opts --diffuse"
    [ "$MATRIX_TWINKLE" = "true" ] && opts="$opts --twinkle"
    echo "$opts"
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
# MAIN ANIMATION SEQUENCE
# ============================================================

clear

# Start listening for keypress
start_key_listener

# Run cxxmatrix - the full Matrix experience
CXXMATRIX_OPTS=$(build_cxxmatrix_opts)

if [ -f ~/.local/bin/cxxmatrix ]; then
    # Kill cxxmatrix after configured duration (background timer)
    ( sleep "$MATRIX_ANIMATION_DURATION"; kill_process "cxxmatrix.*$MATRIX_BANNER_MESSAGE" ) &
    TIMER_PID=$!

    # Run cxxmatrix in foreground - receives SIGWINCH directly for resize
    # User can press 'q' to exit early
    ~/.local/bin/cxxmatrix -s "$MATRIX_SEQUENCE" -m "$MATRIX_BANNER_MESSAGE" $CXXMATRIX_OPTS 2>/dev/null || true

    # Clean up timer if cxxmatrix exited early
    kill $TIMER_PID 2>/dev/null || true
    wait $TIMER_PID 2>/dev/null || true
elif command -v cxxmatrix &> /dev/null; then
    # cxxmatrix in PATH
    ( sleep "$MATRIX_ANIMATION_DURATION"; kill_process "cxxmatrix.*$MATRIX_BANNER_MESSAGE" ) &
    TIMER_PID=$!

    cxxmatrix -s "$MATRIX_SEQUENCE" -m "$MATRIX_BANNER_MESSAGE" $CXXMATRIX_OPTS 2>/dev/null || true

    kill $TIMER_PID 2>/dev/null || true
    wait $TIMER_PID 2>/dev/null || true
elif [ "$MATRIX_USE_FALLBACK" = "true" ] && command -v cmatrix &> /dev/null; then
    ( sleep "$MATRIX_FALLBACK_DURATION"; kill_process "cmatrix" ) &
    TIMER_PID=$!

    cmatrix -b -a -u 2 2>/dev/null || true

    kill $TIMER_PID 2>/dev/null || true
    wait $TIMER_PID 2>/dev/null || true
fi

# Stop the key listener and start a new one for the text phase
stop_key_listener

clear

# Recalculate terminal dimensions (in case of resize during animation)
COLS=$(get_cols)
LINES=$(get_lines)

# ============================================================
# DISPLAY FUNCTIONS
# ============================================================

show_system_header() {
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
}

show_quote() {
    if [ "$MATRIX_SHOW_QUOTE" = "true" ]; then
        local quote
        quote=$(get_quotes)
        printf "${BRIGHT_GREEN}"
        center_text "$quote"
        printf "${NC}"
        echo ""
        echo ""
    fi
}

# ============================================================
# TEXT SEQUENCE OR SKIP TO END
# ============================================================

# If skipped during cxxmatrix, jump to end
if is_skipped; then
    show_system_header
    show_quote
    exit 0
fi

# Show iconic text sequence if enabled
if [ "$MATRIX_SHOW_TEXT_SEQUENCE" = "true" ]; then
    # Start new key listener for text phase
    start_key_listener

    # Position cursor roughly center of screen for the iconic text
    echo ""
    for ((i=0; i<(LINES/3); i++)); do echo ""; done

    # The iconic Matrix opening sequence (skippable with any key)
    printf "${GREEN}"
    center_text ""
    type_text "Wake up, Neo..." 0.08
    echo ""
    skip_sleep 1.2

    center_text ""
    type_text "The Matrix has you..." "$MATRIX_TYPING_SPEED"
    echo ""
    skip_sleep 1.2

    center_text ""
    type_text "Follow the white rabbit." "$MATRIX_TYPING_SPEED"
    echo ""
    skip_sleep 1.0

    echo ""
    center_text ""
    type_text "Knock, knock, Neo." 0.08
    printf "${NC}"
    echo ""
    echo ""

    skip_sleep 1.5

    stop_key_listener
    clear

    # Recalculate terminal dimensions again
    COLS=$(get_cols)
fi

# ============================================================
# FINAL DISPLAY
# ============================================================

show_system_header
show_quote
