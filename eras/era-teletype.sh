#!/usr/bin/env bash
# era-teletype.sh - ASR-33 Teletype Simulator
# 110 baud, uppercase-only, 10 chars/sec with mechanical timing.
source "$(dirname "$0")/era-lib.sh"
era_setup_traps

# --- Teletype output: 10 chars/sec ---
tty_print() {
    local text="${1^^}" i ch
    for (( i=0; i<${#text}; i++ )); do
        ch="${text:$i:1}"
        if [[ "$ch" == $'\007' ]]; then
            for c in '[' D I N G ']'; do printf '%s' "$c"; sleep 0.1; done
        else
            printf '%s' "$ch"; sleep 0.1
        fi
    done
}

tty_println() { tty_print "$1"; sleep 0.3; echo; }

# --- Paper roll: perforation marks every 66 lines ---
LINE_COUNT=0
tty_line() {
    tty_println "$1"
    (( ++LINE_COUNT % 66 == 0 )) && echo "---"
}

# --- Paper tape visual (8-hole ASCII encoding) ---
punch_tape() {
    local text="${1^^}" i ch byte bit holes="" labels=""
    tty_println "PUNCHING TAPE..."
    for (( i=0; i<${#text}; i++ )); do
        ch="${text:$i:1}"; byte=$(printf '%d' "'$ch")
        local col=""
        for (( bit=7; bit>=0; bit-- )); do
            (( (byte >> bit) & 1 )) && col+="\xe2\x97\x8f" || col+="\xe2\x97\x8b"
        done
        holes+="$col "; labels+="$(printf '  %s       ' "$ch")"
    done
    printf '%b\n' "$holes"; echo "$labels"
}

# --- Rubout: DEL key prints <- (like real teletype) ---
tty_readline() {
    local prompt="$1" line="" ch
    tty_print "$prompt"
    while IFS= read -rsn1 ch; do
        case "$ch" in
            $'\x7f'|$'\x08')
                [[ -n "$line" ]] && { line="${line%?}"; printf '\xe2\x86\x90'; } ;;
            '')  sleep 0.3; echo; break ;;
            *)   ch="${ch^^}"; printf '%s' "$ch"; line+="$ch" ;;
        esac
    done
    echo "$line"
}

# --- Startup banner (10 cps slow type) ---
startup() {
    clear
    tty_line "ASR-33 TELETYPE"
    tty_line "MODEL 33 - 110 BAUD"
    tty_line ""
    tty_line "READY"
    tty_line ""
}

# --- Launch era-basic.sh in teletype mode if available ---
BASIC_SCRIPT="$(dirname "$0")/era-basic.sh"

run_basic() {
    [[ -x "$BASIC_SCRIPT" ]] && exec bash "$BASIC_SCRIPT" trs80
    return 1
}

# --- Standalone fallback mode ---
standalone_mode() {
    while true; do
        local input
        input=$(tty_readline "")
        input="${input^^}"
        [[ -z "$input" ]] && continue
        case "$input" in
            BYE|QUIT|EXIT)
                tty_line "END OF SESSION"; exit 0 ;;
            TIME)
                tty_line "$(date '+%H:%M:%S')" ;;
            DATE)
                tty_line "$(date '+%Y-%m-%d')" ;;
            SAVE\ *)
                punch_tape "${input#SAVE }" ;;
            PRINT\ *)
                local text="${input#PRINT }"
                text="${text#\"}"; text="${text%\"}"
                tty_line "$text" ;;
            HELP)
                tty_line "COMMANDS:"
                tty_line "  PRINT \"TEXT\"  - TYPE TEXT"
                tty_line "  TIME         - SHOW TIME"
                tty_line "  DATE         - SHOW DATE"
                tty_line "  SAVE TEXT    - PUNCH TAPE"
                tty_line "  HELP         - THIS LIST"
                tty_line "  BYE          - END SESSION" ;;
            *)
                tty_line "?UNKNOWN COMMAND" ;;
        esac
        tty_line "READY"
        tty_line ""
    done
}

# --- Main ---
startup
run_basic 2>/dev/null
standalone_mode
