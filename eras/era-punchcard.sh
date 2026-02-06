#!/usr/bin/env bash
# era-punchcard.sh - IBM 029 Keypunch Simulator
# Authentic Hollerith encoding on 80-column punch cards.
# Source the shared era library.
source "$(dirname "$0")/era-lib.sh"
era_setup_traps

# --- Constants ---
CARD_COLS=80
VIEW_COLS=40
ROWS=(12 11 0 1 2 3 4 5 6 7 8 9)
BOX_W=62

# --- State ---
declare -a DECK=()              # completed cards (text per card)
declare -a CARD_PUNCHES=()      # current card: CARD_PUNCHES[row*80+col] = 0|1
CARD_TEXT=""                     # printed interpretation of current card
CURSOR_COL=0                    # 0-based column cursor
VIEW_START=0                    # viewport first visible column
PREV_CARD_TEXT=""                # for DUP

init_card() {
    CARD_TEXT=""
    CURSOR_COL=0
    VIEW_START=0
    CARD_PUNCHES=()
    for (( i=0; i<12*CARD_COLS; i++ )); do CARD_PUNCHES[$i]=0; done
}

# --- Hollerith Encoding ---
# Returns space-separated row indices to punch for a character.
hollerith_encode() {
    local ch="$1"
    case "$ch" in
        [0-9]) echo "$ch" ;;
        A) echo "12 1" ;; B) echo "12 2" ;; C) echo "12 3" ;;
        D) echo "12 4" ;; E) echo "12 5" ;; F) echo "12 6" ;;
        G) echo "12 7" ;; H) echo "12 8" ;; I) echo "12 9" ;;
        J) echo "11 1" ;; K) echo "11 2" ;; L) echo "11 3" ;;
        M) echo "11 4" ;; N) echo "11 5" ;; O) echo "11 6" ;;
        P) echo "11 7" ;; Q) echo "11 8" ;; R) echo "11 9" ;;
        S) echo "0 2"  ;; T) echo "0 3"  ;; U) echo "0 4"  ;;
        V) echo "0 5"  ;; W) echo "0 6"  ;; X) echo "0 7"  ;;
        Y) echo "0 8"  ;; Z) echo "0 9"  ;;
        ' ') echo ""    ;;
        '.') echo "12 3 8" ;; ',') echo "0 3 8" ;;
        '/') echo "0 1"    ;; '+') echo "12 0"  ;;
        '-') echo "11 0"   ;; '*') echo "11 4 8" ;;
        '=') echo "0 6 8"  ;; '(') echo "12 5 8" ;;
        ')') echo "11 5 8" ;; '$') echo "11 3 8" ;;
        '#') echo "0 3 8"  ;; '@') echo "0 4 8"  ;;
        '&') echo "12 0"   ;; '!') echo "11 2 8" ;;
        ';') echo "11 6 8" ;; ':') echo "0 2 8"  ;;
        "'") echo "0 5 8"  ;; '"') echo "0 7 8"  ;;
        '?') echo "12 6 8" ;; '%') echo "0 4 8"  ;;
        *) echo "12 0 1"   ;;  # unmapped -> zone punch
    esac
}

# Map row name to array index (0..11)
row_index() {
    case "$1" in
        12) echo 0 ;; 11) echo 1 ;; 0) echo 2 ;;
        *) echo $(( $1 + 2 )) ;;
    esac
}

punch_char() {
    local ch="${1^^}"  # uppercase
    local col="$CURSOR_COL"
    if (( col >= CARD_COLS )); then return 1; fi
    local rows_to_punch
    rows_to_punch=$(hollerith_encode "$ch")
    for r in $rows_to_punch; do
        local ri
        ri=$(row_index "$r")
        CARD_PUNCHES[$((ri * CARD_COLS + col))]=1
    done
    CARD_TEXT+="$ch"
    CURSOR_COL=$(( col + 1 ))
    # Scroll viewport if cursor moves past visible area
    if (( CURSOR_COL - VIEW_START >= VIEW_COLS )); then
        VIEW_START=$(( CURSOR_COL - VIEW_COLS + 1 ))
    fi
}

# --- Display ---
draw_card() {
    era_move 1 1
    local col_display
    printf -v col_display "%02d" $(( CURSOR_COL + 1 ))

    era_fg 180 180 180
    era_box_top $BOX_W
    era_box_line "$(printf 'IBM 029 KEYPUNCH %*sCOLUMN: %s' 28 '' "$col_display")" $BOX_W
    era_box_sep $BOX_W

    # Printed interpretation line (the text on top of the card)
    local interp=""
    for (( c=VIEW_START; c<VIEW_START+VIEW_COLS && c<CARD_COLS; c++ )); do
        if (( c < ${#CARD_TEXT} )); then
            interp+="${CARD_TEXT:$c:1}"
        elif (( c == CURSOR_COL )); then
            interp+="_"
        else
            interp+=" "
        fi
    done
    era_box_line "$(printf 'CARD: %-42s' "$interp")" $BOX_W

    # Draw each punch row
    for ri in "${!ROWS[@]}"; do
        local label
        printf -v label "%2s" "${ROWS[$ri]}"
        local row_str="$label: "
        for (( c=VIEW_START; c<VIEW_START+VIEW_COLS && c<CARD_COLS; c++ )); do
            if (( CARD_PUNCHES[ri * CARD_COLS + c] )); then
                row_str+="■"
            else
                row_str+="□"
            fi
        done
        era_box_line "$(printf '%-56s' "$row_str")" $BOX_W
    done

    era_box_sep $BOX_W
    local deck_count=${#DECK[@]}
    era_box_line "$(printf 'DECK: %d cards  [^R:REL] [^D:DUP] [^S:SUBMIT] [^C:QUIT]' "$deck_count")" $BOX_W
    era_box_bottom $BOX_W
    era_reset
}

release_card() {
    if (( ${#CARD_TEXT} > 0 || CURSOR_COL > 0 )); then
        # Pad card text to however far cursor went
        while (( ${#CARD_TEXT} < CURSOR_COL )); do CARD_TEXT+=" "; done
        PREV_CARD_TEXT="$CARD_TEXT"
        DECK+=("$CARD_TEXT")
    fi
    init_card
}

duplicate_card() {
    if [[ -z "$PREV_CARD_TEXT" ]]; then return; fi
    init_card
    local i
    for (( i=0; i<${#PREV_CARD_TEXT}; i++ )); do
        local ch="${PREV_CARD_TEXT:$i:1}"
        punch_char "$ch"
        draw_card
        sleep 0.02
    done
}

# --- Card Reader Animation ---
card_reader_feed() {
    local total=${#DECK[@]}
    if (( total == 0 )); then return; fi
    era_clear
    era_hide_cursor
    era_fg 180 180 180
    echo ""
    echo "  ╔══════════════════════════════════════╗"
    echo "  ║       IBM 2540 CARD READER           ║"
    echo "  ╠══════════════════════════════════════╣"

    for (( n=0; n<total; n++ )); do
        printf "  ║  READING CARD %3d / %3d  " "$((n+1))" "$total"
        # Progress bar
        local pct=$(( (n+1) * 20 / total ))
        local bar=""
        for (( b=0; b<20; b++ )); do
            if (( b < pct )); then bar+="█"; else bar+="░"; fi
        done
        printf "%s  ║\n" "$bar"
        era_move 5 1
        sleep 0.15
    done
    printf "  ║  ALL CARDS READ              OK    ║\n"
    echo "  ╚══════════════════════════════════════╝"
    sleep 0.6
}

# --- Greenbar Output ---
greenbar_print() {
    local lines=("$@")
    echo ""
    era_fg 50 50 50
    echo "  ┌──────────────────────────────────────────────────────────────────────────────────┐"
    era_reset
    local lnum=0
    for line in "${lines[@]}"; do
        if (( lnum % 2 == 0 )); then
            era_fg 100 200 100
        else
            era_fg 60 160 60
        fi
        printf "  │ %-80s │\n" "$line"
        lnum=$(( lnum + 1 ))
    done
    era_fg 50 50 50
    echo "  └──────────────────────────────────────────────────────────────────────────────────┘"
    era_reset
}

# --- JCL Processing ---
process_deck() {
    local total=${#DECK[@]}
    if (( total == 0 )); then
        echo "  ** NO CARDS IN DECK **"
        sleep 1
        return
    fi
    card_reader_feed

    # Check for JCL
    local has_jcl=false
    local jobname=""
    for card in "${DECK[@]}"; do
        if [[ "$card" == //* ]]; then has_jcl=true; fi
        if [[ "$card" =~ ^//([A-Z0-9]+)\ +JOB ]]; then
            jobname="${BASH_REMATCH[1]}"
        fi
    done

    echo ""
    if $has_jcl; then
        [[ -z "$jobname" ]] && jobname="UNNAMED"
        era_fg 180 180 180
        echo "  JES2 JOB $jobname  STARTED"
        echo "  ────────────────────────────────────"
        sleep 0.4

        local output_lines=()
        local abend=false
        for card in "${DECK[@]}"; do
            if [[ "$card" == "//SYSIN DD *" ]]; then continue; fi
            if [[ "$card" == //* ]]; then
                output_lines+=("$card")
                # Check for EXEC PGM
                if [[ "$card" =~ EXEC\ +PGM=([A-Z0-9]+) ]]; then
                    local pgm="${BASH_REMATCH[1]}"
                    output_lines+=("  IEF236I PGM=$pgm STEPNAME=STEP01")
                    # Known programs pass; unknown ones ABEND
                    case "$pgm" in
                        IEFBR14|IEBGENER|SORT|IDCAMS|IKJEFT01|HEWL|IEWL)
                            output_lines+=("  IEF142I $jobname STEP01 - STEP WAS EXECUTED - COND CODE 0000")
                            ;;
                        *)
                            output_lines+=("  IEF450I $jobname STEP01 - ABEND=S806 U0000")
                            output_lines+=("  SYSTEM COMPLETION CODE=806  REASON CODE=00000001")
                            output_lines+=("  ** MODULE $pgm NOT FOUND IN LINKLIST **")
                            abend=true
                            ;;
                    esac
                fi
            else
                output_lines+=("  $card")
            fi
        done

        if $abend; then
            output_lines+=("  JOB $jobname  ENDED -- ABEND")
        else
            output_lines+=("  JOB $jobname  ENDED -- RC=0000")
        fi
        output_lines+=("  $(date '+%H.%M.%S') JOB $jobname  PURGED")
        greenbar_print "${output_lines[@]}"
    else
        # Non-JCL: just print card contents
        local output_lines=()
        for card in "${DECK[@]}"; do
            output_lines+=("$card")
        done
        greenbar_print "${output_lines[@]}"
    fi
    echo ""
    era_fg 180 180 180
    echo "  Press any key to continue..."
    era_reset
    era_getchar >/dev/null
    DECK=()
}

# --- Help Screen ---
show_help() {
    era_clear
    era_hide_cursor
    era_fg 180 180 180
    era_box_top $BOX_W
    era_box_line "$(printf '%-56s' '       IBM 029 KEYPUNCH SIMULATOR')" $BOX_W
    era_box_sep $BOX_W
    era_box_line "$(printf '%-56s' 'CONTROLS:')" $BOX_W
    era_box_line "$(printf '%-56s' '  Type A-Z, 0-9, specials  Punch character on card')" $BOX_W
    era_box_line "$(printf '%-56s' '  Backspace                Move cursor back one col')" $BOX_W
    era_box_line "$(printf '%-56s' '  Ctrl-R  (REL)            Release card to deck')" $BOX_W
    era_box_line "$(printf '%-56s' '  Ctrl-D  (DUP)            Duplicate previous card')" $BOX_W
    era_box_line "$(printf '%-56s' '  Ctrl-S  (SUBMIT)         Feed deck through reader')" $BOX_W
    era_box_line "$(printf '%-56s' '  Ctrl-C                   Quit')" $BOX_W
    era_box_sep $BOX_W
    era_box_line "$(printf '%-56s' 'CARD FORMAT:')" $BOX_W
    era_box_line "$(printf '%-56s' '  80 columns, 12 rows (12,11,0-9)')" $BOX_W
    era_box_line "$(printf '%-56s' '  Characters encoded via Hollerith punches')" $BOX_W
    era_box_line "$(printf '%-56s' '  ■ = punched hole   □ = unpunched')" $BOX_W
    era_box_sep $BOX_W
    era_box_line "$(printf '%-56s' 'JCL: Cards starting with // are treated as JCL.')" $BOX_W
    era_box_line "$(printf '%-56s' '  Example: //MYJOB JOB ,CLASS=A')" $BOX_W
    era_box_line "$(printf '%-56s' '           //STEP01 EXEC PGM=IEFBR14')" $BOX_W
    era_box_sep $BOX_W
    era_box_line "$(printf '%-56s' '     Press any key to begin keypunching...')" $BOX_W
    era_box_bottom $BOX_W
    era_reset
    era_getchar >/dev/null
}

# --- Main Loop ---
main() {
    stty -echo 2>/dev/null
    era_hide_cursor
    show_help
    init_card
    era_clear
    draw_card

    while true; do
        local ch
        IFS= read -rsn1 ch

        # Handle control characters
        case "$ch" in
            $'\x12')  # Ctrl-R: release
                release_card
                era_clear
                draw_card
                continue
                ;;
            $'\x04')  # Ctrl-D: duplicate
                duplicate_card
                draw_card
                continue
                ;;
            $'\x13')  # Ctrl-S: submit
                release_card
                era_clear
                process_deck
                init_card
                era_clear
                draw_card
                continue
                ;;
            $'\x7f'|$'\x08')  # Backspace
                if (( CURSOR_COL > 0 )); then
                    CURSOR_COL=$(( CURSOR_COL - 1 ))
                    if (( CURSOR_COL < VIEW_START )); then
                        VIEW_START=$CURSOR_COL
                    fi
                    # Remove last character from text if at end
                    if (( CURSOR_COL < ${#CARD_TEXT} )); then
                        CARD_TEXT="${CARD_TEXT:0:$CURSOR_COL}${CARD_TEXT:$((CURSOR_COL+1))}"
                    elif (( ${#CARD_TEXT} > 0 )); then
                        CARD_TEXT="${CARD_TEXT:0:${#CARD_TEXT}-1}"
                    fi
                    # Clear punches in that column
                    for (( ri=0; ri<12; ri++ )); do
                        CARD_PUNCHES[$((ri * CARD_COLS + CURSOR_COL))]=0
                    done
                fi
                draw_card
                continue
                ;;
            '')  # empty = Enter or timeout, treat as space-fill to end
                continue
                ;;
        esac

        # Printable characters
        if [[ "$ch" =~ [[:print:]] ]]; then
            if (( CURSOR_COL < CARD_COLS )); then
                punch_char "$ch"
                era_click  # audible keypunch sound
                draw_card
            fi
        fi
    done
}

main
