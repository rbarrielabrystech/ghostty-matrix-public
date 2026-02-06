#!/usr/bin/env bash
# era-enigma.sh - Enigma M3 Rotor Machine Simulator
# Authentic 3-rotor Enigma I / M3 with correct wirings, double-stepping, plugboard
# Compatible with bash 3.2+ (macOS default)
source "$(dirname "$0")/era-lib.sh"
era_setup_traps

# --- Historical rotor wirings (Enigma I / M3) ---
ROTOR_W_0="EKMFLGDQVZNTOWYHXUSPAIBRCJ"  # Rotor I
ROTOR_W_1="AJDKSIRUXBLHWTMCQGZNPYFVOE"  # Rotor II
ROTOR_W_2="BDFHJLCPRTXVZNYEIWGAKMUSQO"  # Rotor III
ROTOR_W_3="ESOVPZJAYQUIRHXLNFTGKDCMWB"  # Rotor IV
ROTOR_W_4="VZBRGITYUPSDNHLXAWMJQOFECK"  # Rotor V
ROTOR_NOTCH_0=16  # Q (Rotor I turnover)
ROTOR_NOTCH_1=4   # E (Rotor II turnover)
ROTOR_NOTCH_2=21  # V (Rotor III turnover)
ROTOR_NOTCH_3=9   # J (Rotor IV turnover)
ROTOR_NOTCH_4=25  # Z (Rotor V turnover)
ROTOR_NAMES_0="I"; ROTOR_NAMES_1="II"; ROTOR_NAMES_2="III"
ROTOR_NAMES_3="IV"; ROTOR_NAMES_4="V"
REFLECTOR_B="YRUHQSLDPXNGOKMIEBFZCWVJAT"
REFLECTOR_C="FVPJIAOYEDRZXWGCTKUQSBNMHL"
ALPHA="ABCDEFGHIJKLMNOPQRSTUVWXYZ"
LAMP_ROW_0="QWERTZUIO"
LAMP_ROW_1="ASDFGHJKL"
LAMP_ROW_2="PYXCVBNML"

# --- Machine state ---
SEL_L=0; SEL_M=1; SEL_R=2         # selected rotor indices
RING_L=0; RING_M=0; RING_R=0      # ring settings 0-25
POS_L=0; POS_M=0; POS_R=0         # rotor positions 0-25
REFLECTOR="$REFLECTOR_B"
PLUG_MAP="ABCDEFGHIJKLMNOPQRSTUVWXYZ"  # self-mapping = no plugboard
PLUG_PAIRS=""
OUTPUT_TEXT=""
INPUT_TEXT=""
RET=""  # global return value for functions

# --- Helpers using global RET to avoid subshells ---
_mod26() { RET=$(( (($1 % 26) + 26) % 26 )); }
_num_to_chr() { RET="${ALPHA:$1:1}"; }
_chr_to_num() {
    local c="$1" i
    for ((i=0;i<26;i++)); do
        if [[ "${ALPHA:$i:1}" == "$c" ]]; then RET=$i; return; fi
    done
    RET=0
}

_get_wiring() {
    case "$1" in
        0) RET="$ROTOR_W_0";; 1) RET="$ROTOR_W_1";; 2) RET="$ROTOR_W_2";;
        3) RET="$ROTOR_W_3";; 4) RET="$ROTOR_W_4";;
    esac
}
_get_notch() {
    case "$1" in
        0) RET=$ROTOR_NOTCH_0;; 1) RET=$ROTOR_NOTCH_1;; 2) RET=$ROTOR_NOTCH_2;;
        3) RET=$ROTOR_NOTCH_3;; 4) RET=$ROTOR_NOTCH_4;;
    esac
}
_get_name() {
    case "$1" in
        0) RET="$ROTOR_NAMES_0";; 1) RET="$ROTOR_NAMES_1";; 2) RET="$ROTOR_NAMES_2";;
        3) RET="$ROTOR_NAMES_3";; 4) RET="$ROTOR_NAMES_4";;
    esac
}

# Plugboard: swap via PLUG_MAP string (index = input letter, char = output)
_plug_swap() {
    _chr_to_num "$1"; local idx=$RET
    RET="${PLUG_MAP:$idx:1}"
}

init_plugboard() {
    PLUG_MAP="ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    PLUG_PAIRS=""
}

add_plug_pair() {
    local a="$1" b="$2"
    _chr_to_num "$a"; local ai=$RET
    _chr_to_num "$b"; local bi=$RET
    # Swap characters at positions ai and bi in PLUG_MAP
    local new="" i ch
    for ((i=0;i<26;i++)); do
        if ((i == ai)); then ch="$b"
        elif ((i == bi)); then ch="$a"
        else ch="${PLUG_MAP:$i:1}"
        fi
        new+="$ch"
    done
    PLUG_MAP="$new"
    [[ -n "$PLUG_PAIRS" ]] && PLUG_PAIRS+=" "
    PLUG_PAIRS+="${a}${b}"
}

# --- Rotor stepping with double-step anomaly ---
step_rotors() {
    _get_notch "$SEL_R"; local r_notch=$RET
    _get_notch "$SEL_M"; local m_notch=$RET
    # Double-step: if middle rotor is at its notch, both middle and left advance
    if ((POS_M == m_notch)); then
        _mod26 $((POS_M + 1)); POS_M=$RET
        _mod26 $((POS_L + 1)); POS_L=$RET
    # Normal carry: if right rotor is at its notch, middle advances
    elif ((POS_R == r_notch)); then
        _mod26 $((POS_M + 1)); POS_M=$RET
    fi
    # Right rotor always advances
    _mod26 $((POS_R + 1)); POS_R=$RET
}

# --- Signal through one rotor (forward direction) ---
# Args: wiring_string signal_num position ring_setting
_rotor_fwd() {
    local wiring="$1" sig="$2" pos="$3" ring="$4"
    _mod26 $((sig + pos - ring)); local shifted=$RET
    local out_char="${wiring:$shifted:1}"
    _chr_to_num "$out_char"; local out_num=$RET
    _mod26 $((out_num - pos + ring)); # result in RET
}

# --- Signal through one rotor (reverse / inverse direction) ---
_rotor_rev() {
    local wiring="$1" sig="$2" pos="$3" ring="$4"
    _mod26 $((sig + pos - ring)); local shifted=$RET
    _num_to_chr "$shifted"; local shifted_chr=$RET
    local i
    for ((i=0;i<26;i++)); do
        [[ "${wiring:$i:1}" == "$shifted_chr" ]] && break
    done
    _mod26 $((i - pos + ring)); # result in RET
}

# --- Full encryption of a single character (modifies globals, result in RET) ---
encrypt_char() {
    local ch="$1"
    step_rotors
    # Plugboard in
    _plug_swap "$ch"; ch=$RET
    _chr_to_num "$ch"; local sig=$RET
    # Right -> Middle -> Left (forward)
    _get_wiring "$SEL_R"; _rotor_fwd "$RET" "$sig" "$POS_R" "$RING_R"; sig=$RET
    _get_wiring "$SEL_M"; _rotor_fwd "$RET" "$sig" "$POS_M" "$RING_M"; sig=$RET
    _get_wiring "$SEL_L"; _rotor_fwd "$RET" "$sig" "$POS_L" "$RING_L"; sig=$RET
    # Reflector
    local ref_chr="${REFLECTOR:$sig:1}"
    _chr_to_num "$ref_chr"; sig=$RET
    # Left -> Middle -> Right (reverse)
    _get_wiring "$SEL_L"; _rotor_rev "$RET" "$sig" "$POS_L" "$RING_L"; sig=$RET
    _get_wiring "$SEL_M"; _rotor_rev "$RET" "$sig" "$POS_M" "$RING_M"; sig=$RET
    _get_wiring "$SEL_R"; _rotor_rev "$RET" "$sig" "$POS_R" "$RING_R"; sig=$RET
    # Plugboard out
    _num_to_chr "$sig"; _plug_swap "$RET"
    # RET now holds the encrypted character
}

# --- Display functions ---
draw_header() {
    era_move 1 1; era_bold; era_fg 0 255 65
    era_center "=== ENIGMA M3 ROTOR MACHINE ==="
    era_reset
}

draw_rotor_display() {
    local row="$1"
    _get_name "$SEL_L"; local nl=$RET
    _get_name "$SEL_M"; local nm=$RET
    _get_name "$SEL_R"; local nr=$RET
    _num_to_chr "$POS_L"; local pl=$RET
    _num_to_chr "$POS_M"; local pm=$RET
    _num_to_chr "$POS_R"; local pr=$RET
    era_move "$row" 1; era_fg 180 180 180
    printf '  Rotors: '
    era_bold; era_fg 0 255 65
    printf '[%s] [%s] [%s]' "$nl" "$nm" "$nr"
    era_reset; era_fg 180 180 180
    printf '    Positions: '
    era_bold; era_fg 255 200 0
    printf ' %s  %s  %s ' "$pl" "$pm" "$pr"
    era_reset
    era_move $((row+1)) 1; era_fg 180 180 180
    printf '  Ring settings: %02d %02d %02d' "$((RING_L+1))" "$((RING_M+1))" "$((RING_R+1))"
    local rname="B"; [[ "$REFLECTOR" != "$REFLECTOR_B" ]] && rname="C"
    printf '      Reflector: %s' "$rname"
    era_reset
    era_move $((row+2)) 1; era_fg 180 180 180
    printf '  Plugboard: '
    era_fg 0 200 200
    printf '%s' "${PLUG_PAIRS:-none}"
    era_reset
}

draw_lampboard() {
    local lit="$1" row="$2"
    local r c ch pad lamp_row
    for r in 0 1 2; do
        case $r in 0) lamp_row="$LAMP_ROW_0";; 1) lamp_row="$LAMP_ROW_1";; 2) lamp_row="$LAMP_ROW_2";; esac
        era_move $((row + r * 2)) 1
        pad=$(( (40 - ${#lamp_row} * 4) / 2 ))
        printf '%*s' "$pad" ''
        for ((c=0; c<${#lamp_row}; c++)); do
            ch="${lamp_row:$c:1}"
            if [[ "$ch" == "$lit" ]]; then
                era_bg 255 200 0; era_fg 0 0 0; era_bold
                printf ' %s ' "$ch"
                era_reset
            else
                era_fg 100 100 100
                printf ' %s ' "$ch"
            fi
        done
        era_reset
    done
}

draw_io() {
    local row="$1"
    era_move "$row" 1
    era_fg 180 180 180; printf '  Input:  '; era_fg 0 255 65
    printf '%-60s' "$INPUT_TEXT"; era_reset
    era_move $((row+1)) 1
    era_fg 180 180 180; printf '  Output: '; era_fg 255 200 0; era_bold
    local i=0 formatted=""
    while ((i < ${#OUTPUT_TEXT})); do
        formatted+="${OUTPUT_TEXT:$i:5} "
        ((i+=5))
    done
    printf '%-60s' "$formatted"
    era_reset
}

# --- Setup screen ---
setup_screen() {
    era_clear; era_hide_cursor; draw_header
    era_move 3 1; era_fg 0 255 65; era_bold
    echo "  MACHINE SETUP"; era_reset; echo ""
    era_fg 180 180 180
    echo "  Available rotors: I II III IV V"
    _get_name "$SEL_L"; printf '  Select LEFT rotor (1-5) [current: %s]: ' "$RET"
    era_show_cursor; local inp
    read -rn1 inp; echo; [[ "$inp" =~ [1-5] ]] && SEL_L=$((inp-1))
    _get_name "$SEL_M"; printf '  Select MIDDLE rotor (1-5) [current: %s]: ' "$RET"
    read -rn1 inp; echo; [[ "$inp" =~ [1-5] ]] && SEL_M=$((inp-1))
    _get_name "$SEL_R"; printf '  Select RIGHT rotor (1-5) [current: %s]: ' "$RET"
    read -rn1 inp; echo; [[ "$inp" =~ [1-5] ]] && SEL_R=$((inp-1))
    echo ""
    local rs
    printf '  Ring setting LEFT (01-26) [current: %02d]: ' "$((RING_L+1))"
    read -r rs; [[ "$rs" =~ ^[0-9]+$ ]] && ((rs>=1 && rs<=26)) && RING_L=$((rs-1))
    printf '  Ring setting MIDDLE (01-26) [current: %02d]: ' "$((RING_M+1))"
    read -r rs; [[ "$rs" =~ ^[0-9]+$ ]] && ((rs>=1 && rs<=26)) && RING_M=$((rs-1))
    printf '  Ring setting RIGHT (01-26) [current: %02d]: ' "$((RING_R+1))"
    read -r rs; [[ "$rs" =~ ^[0-9]+$ ]] && ((rs>=1 && rs<=26)) && RING_R=$((rs-1))
    echo ""
    _num_to_chr "$POS_L"; printf '  Start position LEFT (A-Z) [current: %s]: ' "$RET"
    read -rn1 inp; echo; inp="${inp^^}"
    [[ "$inp" =~ [A-Z] ]] && { _chr_to_num "$inp"; POS_L=$RET; }
    _num_to_chr "$POS_M"; printf '  Start position MIDDLE (A-Z) [current: %s]: ' "$RET"
    read -rn1 inp; echo; inp="${inp^^}"
    [[ "$inp" =~ [A-Z] ]] && { _chr_to_num "$inp"; POS_M=$RET; }
    _num_to_chr "$POS_R"; printf '  Start position RIGHT (A-Z) [current: %s]: ' "$RET"
    read -rn1 inp; echo; inp="${inp^^}"
    [[ "$inp" =~ [A-Z] ]] && { _chr_to_num "$inp"; POS_R=$RET; }
    local cur_ref="B"; [[ "$REFLECTOR" != "$REFLECTOR_B" ]] && cur_ref="C"
    printf '  Reflector (B/C) [current: %s]: ' "$cur_ref"
    read -rn1 inp; echo; inp="${inp^^}"
    [[ "$inp" == "C" ]] && REFLECTOR="$REFLECTOR_C" || REFLECTOR="$REFLECTOR_B"
    echo ""
    printf '  Plugboard pairs (e.g. AB CD EF, up to 13 pairs, blank=clear): '
    local pp; read -r pp
    init_plugboard
    if [[ -n "$pp" ]]; then
        for pair in $pp; do
            pair="${pair^^}"
            if [[ ${#pair} -eq 2 ]]; then
                local a="${pair:0:1}" b="${pair:1:1}"
                [[ "$a" =~ [A-Z] && "$b" =~ [A-Z] ]] && add_plug_pair "$a" "$b"
            fi
        done
    fi
    era_hide_cursor; echo ""
    era_fg 0 255 65; echo "  Setup complete. Press any key..."
    era_getchar >/dev/null
}

# --- Quick start with daily key ---
quick_start() {
    SEL_L=1; SEL_M=3; SEL_R=0      # II IV I
    RING_L=5; RING_M=11; RING_R=19  # 06 12 20
    POS_L=12; POS_M=0; POS_R=19    # M A T
    REFLECTOR="$REFLECTOR_B"
    init_plugboard
    add_plug_pair "A" "N"; add_plug_pair "E" "R"; add_plug_pair "I" "S"
    add_plug_pair "T" "W"; add_plug_pair "H" "K"; add_plug_pair "D" "G"
    OUTPUT_TEXT=""; INPUT_TEXT=""
}

# --- Encrypt/Decrypt mode ---
cipher_mode() {
    local mode_label="$1"
    OUTPUT_TEXT=""; INPUT_TEXT=""
    local save_l=$POS_L save_m=$POS_M save_r=$POS_R
    era_clear; era_hide_cursor; draw_header
    era_move 3 1; era_fg 0 255 65; era_bold
    printf '  MODE: %s' "$mode_label"; era_reset
    era_move 4 1; era_fg 100 100 100
    printf '  Type A-Z to encode. BACKSPACE clears all. ESC returns to menu.'
    draw_rotor_display 6; draw_lampboard "" 10; draw_io 17
    era_move 20 1; era_fg 100 100 100; printf '  >'
    era_show_cursor
    local lit=""
    while true; do
        local ch; read -rsn1 ch
        # ESC
        if [[ "$ch" == $'\x1b' ]]; then
            POS_L=$save_l; POS_M=$save_m; POS_R=$save_r; break
        fi
        # Backspace - clear all and reset (simpler, avoids subshell re-encrypt)
        if [[ "$ch" == $'\x7f' || "$ch" == $'\b' ]]; then
            OUTPUT_TEXT=""; INPUT_TEXT=""; lit=""
            POS_L=$save_l; POS_M=$save_m; POS_R=$save_r
            draw_rotor_display 6; draw_lampboard "" 10; draw_io 17
            era_move 20 1; printf '                              '
            era_move 20 1; era_fg 100 100 100; printf '  >'
            continue
        fi
        ch="${ch^^}"
        [[ ! "$ch" =~ [A-Z] ]] && continue
        encrypt_char "$ch"; lit=$RET
        INPUT_TEXT+="$ch"; OUTPUT_TEXT+="$lit"
        draw_rotor_display 6; draw_lampboard "$lit" 10; draw_io 17
        era_move 20 1; printf '                              '
        era_move 20 1
        era_fg 100 100 100; printf '  > '
        era_fg 0 255 65; printf '%s' "$ch"
        era_fg 255 200 0; printf ' -> '
        era_bold; printf '%s' "$lit"; era_reset
    done
    era_hide_cursor
}

# --- Main menu ---
main_menu() {
    while true; do
        era_clear; era_hide_cursor; draw_header
        era_move 3 1; era_fg 100 100 100
        era_center "Accurate Enigma I / M3 simulation with double-stepping"
        draw_rotor_display 5
        era_move 9 1; era_fg 0 255 65; echo ""
        printf '    [S] Setup rotors, rings, plugboard\n'
        printf '    [E] Encrypt message\n'
        printf '    [D] Decrypt message\n'
        printf '    [Q] Quick start (daily key)\n'
        printf '    [X] Exit\n'
        echo ""; era_fg 180 180 180
        printf '    Select option: '; era_show_cursor
        local key; read -rsn1 key; key="${key^^}"
        case "$key" in
            S) setup_screen ;;
            E) cipher_mode "ENCRYPT" ;;
            D) cipher_mode "DECRYPT" ;;
            Q) quick_start; era_clear; draw_header
               era_move 4 1; era_fg 0 255 65; era_bold
               echo "  Daily key loaded: Rotors II-IV-I  Ring 06-12-20  Pos MAT  Ref B"
               echo "  Plugboard: AN ER IS TW HK DG"
               era_reset; era_fg 180 180 180
               echo ""; echo "  Press any key to continue..."
               era_getchar >/dev/null ;;
            X) era_clear; era_show_cursor; exit 0 ;;
        esac
    done
}

# --- Entry point ---
init_plugboard
main_menu
