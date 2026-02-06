#!/usr/bin/env bash
# era-frontpanel.sh - Altair 8800 / PDP-8 / IMSAI 8080 Front Panel Simulator
# An interactive blinkenlights experience in your terminal.
source "$(dirname "$0")/era-lib.sh"
era_setup_traps

# --- Globals ---
declare -A MEM          # Simulated memory (256 bytes)
ADDR=0                  # Current address register
DATA=0                  # Current data register (switches)
RUNNING=0               # Run mode flag
MACHINE=""              # "altair", "pdp8", or "imsai"
MACHINE_LABEL=""        # Display name
ADDR_BITS=16            # Address width
DATA_BITS=8             # Data width
WAIT_LED=0              # Status LEDs
HLDA_LED=0
STAT_LEDS=(0 0 0 0 0 0 0 0)  # MEMR INP M1 OUT HLTA STACK WO INT
SWITCHES=(0 0 0 0 0 0 0 0)   # 8 toggle switches

# --- Colors ---
LED_ON=$'\033[38;2;255;60;60m'    # Bright red for lit LEDs
LED_OFF=$'\033[38;2;80;40;40m'    # Dim red for unlit LEDs
PANEL_FG=$'\033[38;2;200;200;200m'
PANEL_DIM=$'\033[38;2;120;120;120m'
LABEL_FG=$'\033[38;2;180;180;255m'
TITLE_FG=$'\033[38;2;255;220;100m'
RST=$'\033[0m'

# --- Memory Initialisation ---
init_memory() {
    for (( i=0; i<256; i++ )); do MEM[$i]=0; done
}

# --- Bit Manipulation ---
get_bit() { echo $(( ($1 >> $2) & 1 )); }

led() {
    if [ "$1" -eq 1 ]; then printf '%s●%s' "$LED_ON" "$RST"
    else printf '%s○%s' "$LED_OFF" "$RST"; fi
}

led_group() {
    local val=$1 bits=$2 start=$3
    local i
    for (( i=start; i>=0; i-- )); do
        led $(( (val >> i) & 1 ))
        if (( i > 0 && i % 3 == 0 )); then printf ' '; fi
    done
}

to_octal() { printf '%06o' "$1"; }
to_octal_short() { printf '%03o' "$1"; }

switches_to_value() {
    local val=0 i
    for (( i=0; i<8; i++ )); do
        val=$(( val | (SWITCHES[i] << (7-i)) ))
    done
    echo $val
}

switch_char() {
    if [ "${SWITCHES[$1]}" -eq 1 ]; then printf '▲'
    else printf '▼'; fi
}

# --- Panel Drawing ---
W=64

draw_panel() {
    era_move 1 1
    local title_pad addr_label data_label
    printf '%s' "$PANEL_FG"

    # Top border
    printf '╔'; era_repeat '═' $((W-2)); printf '╗\n'

    # Title bar
    local subtitle="COMPUTER"
    [ "$MACHINE" = "imsai" ] && subtitle="MICROCOMPUTER"
    printf '║  %s%-28s%s%30s║\n' "$TITLE_FG" "$MACHINE_LABEL" "$PANEL_FG" "$subtitle  "

    # Separator
    printf '╠'; era_repeat '═' $((W-2)); printf '╣\n'

    # Blank line
    printf '║%*s║\n' $((W-2)) ""

    # Status LEDs row
    printf '║  %sWAIT  HLDA%s%*s║\n' "$LABEL_FG" "$PANEL_FG" $((W-15)) ""
    printf '║   '; led $WAIT_LED; printf '     '; led $HLDA_LED
    printf '%*s║\n' $((W-16)) ""

    # Blank
    printf '║%*s║\n' $((W-2)) ""

    # Address LEDs
    local addr_oct
    addr_oct=$(to_octal $ADDR)
    printf '║  %sADDR:%s ' "$LABEL_FG" "$RST$PANEL_FG"
    led_group $ADDR $ADDR_BITS $((ADDR_BITS-1))
    local addr_led_width=$(( ADDR_BITS + (ADDR_BITS/3 - 1) ))
    local addr_suffix
    if [ "$MACHINE" = "pdp8" ]; then
        addr_suffix="  A11..A0    ($addr_oct)"
    else
        addr_suffix="  A15..A0    ($addr_oct)"
    fi
    printf '  %s%s%s' "$PANEL_DIM" "$addr_suffix" "$PANEL_FG"
    local used=$(( 8 + addr_led_width + ${#addr_suffix} + 2 ))
    (( used < W-2 )) && printf '%*s' $((W-2-used)) ""
    printf '║\n'

    # Data LEDs
    local data_oct sw_val
    sw_val=$(switches_to_value)
    local display_data=$DATA
    data_oct=$(to_octal_short $display_data)
    printf '║  %sDATA:%s ' "$LABEL_FG" "$RST$PANEL_FG"
    led_group $display_data $DATA_BITS $((DATA_BITS-1))
    local data_led_width=$(( DATA_BITS + (DATA_BITS/3 - 1) ))
    local data_suffix
    if [ "$MACHINE" = "pdp8" ]; then
        data_suffix="  D11..D0     ($data_oct)"
    else
        data_suffix="  D7..D0      ($data_oct)"
    fi
    printf '  %s%s%s' "$PANEL_DIM" "$data_suffix" "$PANEL_FG"
    used=$(( 8 + data_led_width + ${#data_suffix} + 2 ))
    (( used < W-2 )) && printf '%*s' $((W-2-used)) ""
    printf '║\n'

    # Blank
    printf '║%*s║\n' $((W-2)) ""

    # Status register LEDs
    printf '║  %sSTAT: MEMR INP  M1 OUT HLTA STK  WO  INT%s' "$LABEL_FG" "$PANEL_FG"
    printf '%*s║\n' $((W-46)) ""
    printf '║         '
    for (( i=0; i<8; i++ )); do
        led ${STAT_LEDS[$i]}
        printf '    '
    done
    local stat_used=$(( 9 + 8*5 - 1 ))
    (( stat_used < W-2 )) && printf '%*s' $((W-2-stat_used)) ""
    printf '║\n'

    # Blank
    printf '║%*s║\n' $((W-2)) ""

    # Switches row
    printf '║  %sSW:%s   ' "$LABEL_FG" "$PANEL_FG"
    for (( i=0; i<8; i++ )); do
        switch_char $i
        if (( i < 7 && (7-i) % 3 == 0 )); then printf ' '; fi
    done
    printf '   %s[0-7: toggle]%s' "$PANEL_DIM" "$PANEL_FG"
    printf '%*s║\n' 17 ""

    # Blank
    printf '║%*s║\n' $((W-2)) ""

    # Separator
    printf '╟'; era_repeat '─' $((W-2)); printf '╢\n'

    # Command rows
    printf '║  %s[E]%sxamine %s[D]%seposit %s[N]%sext %s[R]%sun %s[S]%stop %s[L]%soad %s[K]%sill' \
        "$LABEL_FG" "$PANEL_FG" "$LABEL_FG" "$PANEL_FG" "$LABEL_FG" "$PANEL_FG" \
        "$LABEL_FG" "$PANEL_FG" "$LABEL_FG" "$PANEL_FG" "$LABEL_FG" "$PANEL_FG" \
        "$LABEL_FG" "$PANEL_FG"
    printf '%*s║\n' 5 ""
    printf '║  %s[P]%srogram loader  %s[G]%same: Kill the Bit  %s[X]%sexit' \
        "$LABEL_FG" "$PANEL_FG" "$LABEL_FG" "$PANEL_FG" "$LABEL_FG" "$PANEL_FG"
    printf '%*s║\n' 10 ""

    # Bottom border
    printf '╚'; era_repeat '═' $((W-2)); printf '╝\n'

    # Status message area
    printf '%s' "$RST"
}

STATUS_MSG=""
draw_status() {
    era_move 22 1
    printf '\033[K'  # Clear line
    printf '%s> %s%s\n' "$PANEL_DIM" "$STATUS_MSG" "$RST"
    printf '\033[K'
}

# --- Front Panel Operations ---

cmd_examine() {
    ADDR=$(( $(switches_to_value) & 0xFF ))
    DATA=${MEM[$ADDR]:-0}
    STAT_LEDS=(1 0 1 0 0 0 1 0)
    WAIT_LED=1; HLDA_LED=0
    STATUS_MSG="EXAMINE addr=$(to_octal_short $ADDR) data=$(to_octal_short $DATA)"
}

cmd_deposit() {
    DATA=$(switches_to_value)
    MEM[$ADDR]=$DATA
    STAT_LEDS=(0 0 0 1 0 0 0 0)
    STATUS_MSG="DEPOSIT addr=$(to_octal_short $ADDR) data=$(to_octal_short $DATA)"
}

cmd_deposit_next() {
    ADDR=$(( (ADDR + 1) & 0xFF ))
    DATA=$(switches_to_value)
    MEM[$ADDR]=$DATA
    STAT_LEDS=(0 0 0 1 0 0 0 0)
    STATUS_MSG="DEP NEXT addr=$(to_octal_short $ADDR) data=$(to_octal_short $DATA)"
}

cmd_load_addr() {
    ADDR=$(( $(switches_to_value) & 0xFF ))
    STAT_LEDS=(0 0 0 0 0 0 0 0)
    WAIT_LED=1; HLDA_LED=0
    STATUS_MSG="LOAD ADDRESS=$(to_octal_short $ADDR)"
}

cmd_run() {
    RUNNING=1; WAIT_LED=0; HLDA_LED=0
    STATUS_MSG="RUNNING... press S to stop"
    STAT_LEDS=(1 0 1 0 0 0 1 0)
    draw_panel; draw_status
    local pc=$ADDR
    while [ $RUNNING -eq 1 ]; do
        DATA=${MEM[$pc]:-0}
        ADDR=$pc
        # Cycle status LEDs for visual interest
        STAT_LEDS=($(( (pc>>1) & 1 )) $(( pc & 1 )) $(( (pc>>2) & 1 )) \
                   $(( (pc>>3) & 1 )) 0 $(( (pc>>4) & 1 )) \
                   $(( (pc>>5) & 1 )) $(( (pc>>6) & 1 )))
        draw_panel
        STATUS_MSG="RUN  PC=$(to_octal_short $pc) DATA=$(to_octal_short $DATA)"
        draw_status
        local key
        key=$(era_getchar_timeout 0.1)
        if [[ "$key" == "s" || "$key" == "S" ]]; then
            RUNNING=0
            WAIT_LED=1
            STAT_LEDS=(0 0 0 0 1 0 0 0)
            STATUS_MSG="HALT at addr=$(to_octal_short $pc)"
            break
        fi
        pc=$(( (pc + 1) & 0xFF ))
    done
}

# --- Program Loader ---

load_counter() {
    # Simple counting program: increments a value and loops
    # Stores incrementing values at address 0x80+
    local prog=(
        076 000   # MVI A, 0      (start value)
        062 200   # STA 0x80      (store to display addr)
        074 001   # ADI 1         (increment)
        303 000   # JMP 0         (loop back)
    )
    local i=0
    for byte in "${prog[@]}"; do
        MEM[$i]=$(( 8#$byte ))
        (( i++ ))
    done
    STATUS_MSG="Loaded: Counter program (8 bytes at 000)"
}

load_chaser() {
    # LED chaser: rotates a bit pattern through memory
    local prog=(
        076 001   # MVI A, 1      (single bit)
        062 200   # STA 0x80
        007       # RLC           (rotate left)
        303 002   # JMP 2         (loop to STA)
    )
    local i=0
    for byte in "${prog[@]}"; do
        MEM[$i]=$(( 8#$byte ))
        (( i++ ))
    done
    STATUS_MSG="Loaded: LED Chaser program (7 bytes at 000)"
}

load_killbit_prog() {
    # Kill-the-bit pattern data: alternating bits for the game
    local prog=(
        076 200   # MVI A, 0x80   (start with high bit)
        062 200   # STA 0x80
        017       # RRC           (rotate right)
        303 002   # JMP 2         (loop to STA)
    )
    local i=0
    for byte in "${prog[@]}"; do
        MEM[$i]=$(( 8#$byte ))
        (( i++ ))
    done
    STATUS_MSG="Loaded: Kill-the-Bit data (7 bytes at 000)"
}

program_loader() {
    STATUS_MSG="PROGRAM LOADER: [1]Counter [2]LED Chaser [3]Kill-the-Bit [C]ancel"
    draw_status
    local key
    key=$(era_getchar)
    case "$key" in
        1) init_memory; load_counter ;;
        2) init_memory; load_chaser ;;
        3) init_memory; load_killbit_prog ;;
        *) STATUS_MSG="Loader cancelled." ;;
    esac
    ADDR=0; DATA=${MEM[0]:-0}
}

# --- Kill the Bit Game ---

kill_the_bit() {
    STATUS_MSG="KILL THE BIT! Toggle the switch matching the lit LED. Q=quit"
    local bit_pos=7 direction=1 score=0 speed=0.18 lives=3
    WAIT_LED=0; HLDA_LED=0

    while [ $lives -gt 0 ]; do
        DATA=$(( 1 << bit_pos ))
        ADDR=$(( score & 0xFF ))
        STAT_LEDS=(0 0 0 0 0 0 0 0)
        STAT_LEDS[$((7-lives))]=${lives:+1}
        draw_panel
        STATUS_MSG="KILL THE BIT  Score:$score  Lives:$lives  Speed:${speed}s"
        draw_status

        local key
        key=$(era_getchar_timeout "$speed")

        if [[ "$key" == "q" || "$key" == "Q" ]]; then
            STATUS_MSG="Game over! Final score: $score"; return
        fi

        # Check if player toggled matching switch
        if [[ "$key" =~ ^[0-7]$ ]]; then
            local sw_bit=$(( 7 - key ))
            if [ $sw_bit -eq $bit_pos ]; then
                (( score++ ))
                # Speed up slightly
                speed=$(awk "BEGIN{s=$speed*0.92; if(s<0.04)s=0.04; printf \"%.2f\",s}")
                # Reset to random position
                bit_pos=$(( RANDOM % 8 ))
                direction=$(( RANDOM % 2 == 0 ? 1 : -1 ))
                DATA=0; draw_panel
                STATUS_MSG="HIT! Score:$score"
                draw_status; sleep 0.3
                continue
            fi
        fi

        # Move the bit
        if [ $direction -eq 1 ]; then
            (( bit_pos-- ))
            [ $bit_pos -lt 0 ] && { bit_pos=0; direction=-1; (( lives-- ));
                STATUS_MSG="MISS! Lives:$lives"; draw_status; sleep 0.4; }
        else
            (( bit_pos++ ))
            [ $bit_pos -gt 7 ] && { bit_pos=7; direction=1; (( lives-- ));
                STATUS_MSG="MISS! Lives:$lives"; draw_status; sleep 0.4; }
        fi
    done

    DATA=255; draw_panel
    STATUS_MSG="GAME OVER! Final score: $score. Press any key."
    draw_status; era_getchar
}

# --- Machine Selection ---

select_machine() {
    clear
    era_fg 200 200 200
    echo ""
    echo "  ╔══════════════════════════════════════╗"
    echo "  ║      FRONT PANEL SIMULATOR           ║"
    echo "  ╠══════════════════════════════════════╣"
    echo "  ║                                      ║"
    echo "  ║   [1]  Altair 8800      (1975)       ║"
    echo "  ║   [2]  PDP-8            (1965)       ║"
    echo "  ║   [3]  IMSAI 8080      (1975)       ║"
    echo "  ║                                      ║"
    echo "  ╚══════════════════════════════════════╝"
    echo ""
    era_reset
    printf "  Select machine: "
    local key
    key=$(era_getchar)
    case "$key" in
        2) MACHINE="pdp8";  MACHINE_LABEL="PDP-8";     ADDR_BITS=12; DATA_BITS=12 ;;
        3) MACHINE="imsai"; MACHINE_LABEL="IMSAI 8080"; ADDR_BITS=16; DATA_BITS=8 ;;
        *) MACHINE="altair"; MACHINE_LABEL="ALTAIR 8800"; ADDR_BITS=16; DATA_BITS=8 ;;
    esac
}

# --- Main Loop ---

main() {
    era_hide_cursor
    stty -echo 2>/dev/null
    select_machine
    init_memory
    WAIT_LED=1
    STATUS_MSG="Ready. Toggle switches [0-7], then use commands."
    clear

    while true; do
        draw_panel
        draw_status

        local key
        key=$(era_getchar)

        case "$key" in
            [0-7])
                # Toggle switch
                local idx=$key
                SWITCHES[$idx]=$(( 1 - SWITCHES[$idx] ))
                STATUS_MSG="Switch $idx toggled $([ ${SWITCHES[$idx]} -eq 1 ] && echo UP || echo DOWN)  SW=$(to_octal_short $(switches_to_value))"
                ;;
            e|E) cmd_examine ;;
            d|D) cmd_deposit ;;
            n|N) cmd_deposit_next ;;
            r|R) cmd_run ;;
            s|S)
                RUNNING=0; WAIT_LED=1; HLDA_LED=0
                STAT_LEDS=(0 0 0 0 1 0 0 0)
                STATUS_MSG="STOP"
                ;;
            l|L) cmd_load_addr ;;
            p|P) program_loader ;;
            g|G) kill_the_bit ;;
            k|K) kill_the_bit ;;
            x|X|q|Q)
                STATUS_MSG="Powering down..."
                draw_status
                sleep 0.5
                clear
                era_show_cursor
                era_reset
                stty echo 2>/dev/null
                exit 0
                ;;
            *)
                STATUS_MSG="Unknown command. Use keys shown in panel."
                ;;
        esac
    done
}

main
