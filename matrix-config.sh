#!/bin/bash
# Matrix Interactive Configuration
# "There is no spoon." - Spoon Boy
# Cross-platform: Linux, macOS, Windows (WSL/Git Bash)

set -u

# ============================================================
# PATHS
# ============================================================
MATRIX_CONF="${HOME}/.config/ghostty/matrix.conf"
GHOSTTY_CONF="${HOME}/.config/ghostty/config"
SHADER_DIR="${HOME}/.config/ghostty/shaders"

# ============================================================
# COLORS & DRAWING
# ============================================================
GREEN='\033[0;32m'
BRIGHT='\033[1;32m'
DIM='\033[2;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'
BOLD='\033[1m'
INVERT='\033[7m'

get_cols() {
    local cols
    cols=$(tput cols 2>/dev/null) || cols=$(stty size 2>/dev/null | cut -d' ' -f2) || cols=80
    echo "$cols"
}

COLS=$(get_cols)
BOX_W=62

pad() {
    local p=$(( (COLS - BOX_W) / 2 ))
    [ $p -lt 0 ] && p=0
    printf "%*s" $p ""
}

# Box drawing
box_top()    { pad; printf "${DIM}╔"; printf '═%.0s' $(seq 1 $((BOX_W-2))); printf "╗${NC}\n"; }
box_bottom() { pad; printf "${DIM}╚"; printf '═%.0s' $(seq 1 $((BOX_W-2))); printf "╝${NC}\n"; }
box_sep()    { pad; printf "${DIM}╠"; printf '═%.0s' $(seq 1 $((BOX_W-2))); printf "╣${NC}\n"; }
box_thin()   { pad; printf "${DIM}╟"; printf '─%.0s' $(seq 1 $((BOX_W-2))); printf "╢${NC}\n"; }
box_empty()  { pad; printf "${DIM}║${NC}%-*s${DIM}║${NC}\n" $((BOX_W-2)) ""; }

box_center() {
    local text="$1"
    local color="${2:-$GREEN}"
    local len=${#text}
    local inner=$((BOX_W-2))
    local lpad=$(( (inner - len) / 2 ))
    local rpad=$(( inner - len - lpad ))
    pad; printf "${DIM}║${NC}${color}%*s%s%*s${NC}${DIM}║${NC}\n" $lpad "" "$text" $rpad ""
}

box_left() {
    local text="$1"
    local color="${2:-$GREEN}"
    local len=${#text}
    local inner=$((BOX_W-2))
    local rpad=$(( inner - len - 2 ))
    [ $rpad -lt 0 ] && rpad=0
    pad; printf "${DIM}║${NC}${color}  %s%*s${NC}${DIM}║${NC}\n" "$text" $rpad ""
}

box_kv() {
    local key="$1"
    local val="$2"
    local key_color="${3:-$GREEN}"
    local val_color="${4:-$BRIGHT}"
    local inner=$((BOX_W-2))
    local klen=${#key}
    local vlen=${#val}
    local gap=$(( inner - klen - vlen - 4 ))
    [ $gap -lt 1 ] && gap=1
    pad; printf "${DIM}║${NC}${key_color}  %s%*s${val_color}%s  ${NC}${DIM}║${NC}\n" "$key" $gap "" "$val"
}

# ============================================================
# CONFIG I/O
# ============================================================

read_matrix_conf() {
    local key="$1" default="$2"
    if [ -f "$MATRIX_CONF" ]; then
        local val
        val=$(grep -E "^${key}=" "$MATRIX_CONF" 2>/dev/null | tail -1 | cut -d'=' -f2- | tr -d '"' | tr -d "'")
        [ -n "$val" ] && { echo "$val"; return; }
    fi
    echo "$default"
}

read_ghostty_conf() {
    local key="$1" default="$2"
    if [ -f "$GHOSTTY_CONF" ]; then
        local val
        val=$(grep -E "^${key}\s*=" "$GHOSTTY_CONF" 2>/dev/null | tail -1 | sed 's/^[^=]*=\s*//')
        [ -n "$val" ] && { echo "$val"; return; }
    fi
    echo "$default"
}

_sed_inplace() {
    if sed --version 2>/dev/null | grep -q GNU; then
        sed -i "$@"
    else
        sed -i '' "$@"
    fi
}

write_matrix_conf() {
    local key="$1" value="$2"
    [ ! -f "$MATRIX_CONF" ] && { echo "${key}=\"${value}\"" > "$MATRIX_CONF"; return; }
    if grep -qE "^${key}=" "$MATRIX_CONF" 2>/dev/null; then
        _sed_inplace "s|^${key}=.*|${key}=\"${value}\"|" "$MATRIX_CONF"
    else
        echo "${key}=\"${value}\"" >> "$MATRIX_CONF"
    fi
}

write_ghostty_conf() {
    local key="$1" value="$2"
    [ ! -f "$GHOSTTY_CONF" ] && { echo "${key} = ${value}" > "$GHOSTTY_CONF"; return; }
    if grep -qE "^${key} *=" "$GHOSTTY_CONF" 2>/dev/null; then
        _sed_inplace "s|^${key} *=.*|${key} = ${value}|" "$GHOSTTY_CONF"
    else
        echo "${key} = ${value}" >> "$GHOSTTY_CONF"
    fi
}

remove_ghostty_conf() {
    local key="$1"
    [ -f "$GHOSTTY_CONF" ] && _sed_inplace "/^${key} *=/d" "$GHOSTTY_CONF"
}

# ============================================================
# STATE READERS
# ============================================================

get_current_shader() {
    local p
    p=$(read_ghostty_conf "custom-shader" "")
    case "$p" in
        *crt-full*)     echo "crt-full" ;;
        *crt.glsl)      echo "crt" ;;
        *bloom*)        echo "bloom" ;;
        *matrix-glow*)  echo "matrix-glow" ;;
        "")             echo "none" ;;
        *)              echo "custom" ;;
    esac
}

shader_name() {
    case "$1" in
        crt-full)    echo "CRT Full 1999" ;;
        crt)         echo "CRT Scanlines" ;;
        bloom)       echo "Phosphor Bloom" ;;
        matrix-glow) echo "Matrix Glow" ;;
        none)        echo "None" ;;
        *)           echo "Custom" ;;
    esac
}

shader_desc() {
    case "$1" in
        crt-full)    echo "Curvature + scanlines + shadow mask + vignette" ;;
        crt)         echo "Scanlines only, no curvature" ;;
        bloom)       echo "Soft phosphor glow, very readable" ;;
        matrix-glow) echo "Subtle green glow, minimal effect" ;;
        none)        echo "No shader effect" ;;
        *)           echo "" ;;
    esac
}

on_off() { [ "$1" = "true" ] && echo "ON" || echo "OFF"; }

# ============================================================
# CONFIG WRITERS
# ============================================================

set_shader() {
    case "$1" in
        crt-full)
            write_ghostty_conf "custom-shader" "~/.config/ghostty/shaders/crt-full.glsl"
            write_ghostty_conf "custom-shader-animation" "true"
            ;;
        crt)
            write_ghostty_conf "custom-shader" "~/.config/ghostty/shaders/crt.glsl"
            write_ghostty_conf "custom-shader-animation" "true"
            ;;
        bloom)
            write_ghostty_conf "custom-shader" "~/.config/ghostty/shaders/bloom.glsl"
            write_ghostty_conf "custom-shader-animation" "true"
            ;;
        matrix-glow)
            write_ghostty_conf "custom-shader" "~/.config/ghostty/shaders/matrix-glow.glsl"
            write_ghostty_conf "custom-shader-animation" "true"
            ;;
        none)
            remove_ghostty_conf "custom-shader"
            remove_ghostty_conf "custom-shader-animation"
            ;;
    esac
}

toggle() { [ "$1" = "true" ] && echo "false" || echo "true"; }

cycle_freq() {
    case "$1" in
        daily)  echo "weekly" ;;
        weekly) echo "always" ;;
        always) echo "never" ;;
        *)      echo "daily" ;;
    esac
}

cycle_cursor() {
    case "$1" in
        block)     echo "bar" ;;
        bar)       echo "underline" ;;
        underline) echo "block" ;;
        *)         echo "block" ;;
    esac
}

# ============================================================
# APPLY PRESET
# ============================================================

apply_preset() {
    local preset="$1"
    case "$preset" in
        1999)
            # === THE FULL 1999 CRT EXPERIENCE ===
            set_shader "crt-full"
            write_ghostty_conf "font-thicken" "true"
            write_ghostty_conf "background-opacity" "1.0"
            write_ghostty_conf "window-padding-x" "12"
            write_ghostty_conf "window-padding-y" "8"
            write_ghostty_conf "cursor-style" "block"
            write_ghostty_conf "cursor-style-blink" "true"
            write_ghostty_conf "bold-is-bright" "true"
            write_matrix_conf "MATRIX_ANIMATION_FREQUENCY" "daily"
            write_matrix_conf "MATRIX_ANIMATION_DURATION" "10"
            write_matrix_conf "MATRIX_SHOW_TEXT_SEQUENCE" "true"
            write_matrix_conf "MATRIX_TYPING_SPEED" "0.08"
            write_matrix_conf "MATRIX_SHOW_QUOTE" "true"
            write_matrix_conf "MATRIX_SHOW_SYSTEM_INFO" "true"
            write_matrix_conf "MATRIX_SHOW_HEADER" "true"
            write_matrix_conf "MATRIX_DIFFUSE" "true"
            write_matrix_conf "MATRIX_TWINKLE" "true"
            write_matrix_conf "MATRIX_SEQUENCE" "number,rain,banner"
            STATUS_MSG="PRESET APPLIED: Full 1999 CRT -- restart Ghostty"
            ;;
        crt-lite)
            # === CRT LITE - scanlines without curvature ===
            set_shader "crt"
            write_ghostty_conf "font-thicken" "true"
            write_ghostty_conf "background-opacity" "0.95"
            write_ghostty_conf "window-padding-x" "8"
            write_ghostty_conf "window-padding-y" "6"
            write_ghostty_conf "cursor-style" "block"
            write_ghostty_conf "cursor-style-blink" "true"
            write_ghostty_conf "bold-is-bright" "true"
            write_matrix_conf "MATRIX_ANIMATION_FREQUENCY" "daily"
            write_matrix_conf "MATRIX_ANIMATION_DURATION" "8"
            write_matrix_conf "MATRIX_SHOW_TEXT_SEQUENCE" "true"
            write_matrix_conf "MATRIX_TYPING_SPEED" "0.06"
            STATUS_MSG="PRESET APPLIED: CRT Lite -- restart Ghostty"
            ;;
        bloom-default)
            # === PHOSPHOR BLOOM - recommended default ===
            set_shader "bloom"
            write_ghostty_conf "font-thicken" "true"
            write_ghostty_conf "background-opacity" "0.92"
            write_ghostty_conf "window-padding-x" "4"
            write_ghostty_conf "window-padding-y" "4"
            write_ghostty_conf "cursor-style" "block"
            write_ghostty_conf "cursor-style-blink" "true"
            write_ghostty_conf "bold-is-bright" "true"
            write_matrix_conf "MATRIX_ANIMATION_FREQUENCY" "daily"
            write_matrix_conf "MATRIX_ANIMATION_DURATION" "8"
            write_matrix_conf "MATRIX_SHOW_TEXT_SEQUENCE" "true"
            write_matrix_conf "MATRIX_TYPING_SPEED" "0.06"
            STATUS_MSG="PRESET APPLIED: Phosphor Bloom -- restart Ghostty"
            ;;
        subtle)
            # === SUBTLE GLOW - minimal effects ===
            set_shader "matrix-glow"
            write_ghostty_conf "font-thicken" "false"
            write_ghostty_conf "background-opacity" "0.90"
            write_ghostty_conf "window-padding-x" "4"
            write_ghostty_conf "window-padding-y" "4"
            write_ghostty_conf "cursor-style" "bar"
            write_ghostty_conf "cursor-style-blink" "true"
            write_ghostty_conf "bold-is-bright" "true"
            write_matrix_conf "MATRIX_ANIMATION_FREQUENCY" "weekly"
            write_matrix_conf "MATRIX_ANIMATION_DURATION" "6"
            write_matrix_conf "MATRIX_SHOW_TEXT_SEQUENCE" "false"
            STATUS_MSG="PRESET APPLIED: Subtle Glow -- restart Ghostty"
            ;;
        clean)
            # === CLEAN TERMINAL - just the color scheme ===
            set_shader "none"
            write_ghostty_conf "font-thicken" "false"
            write_ghostty_conf "background-opacity" "0.92"
            write_ghostty_conf "window-padding-x" "4"
            write_ghostty_conf "window-padding-y" "4"
            write_ghostty_conf "cursor-style" "bar"
            write_ghostty_conf "cursor-style-blink" "false"
            write_ghostty_conf "bold-is-bright" "true"
            write_matrix_conf "MATRIX_ANIMATION_FREQUENCY" "never"
            write_matrix_conf "MATRIX_SHOW_TEXT_SEQUENCE" "false"
            write_matrix_conf "MATRIX_SHOW_HEADER" "true"
            write_matrix_conf "MATRIX_SHOW_QUOTE" "true"
            STATUS_MSG="PRESET APPLIED: Clean Terminal -- restart Ghostty"
            ;;
    esac
}

# ============================================================
# SCREENS
# ============================================================

STATUS_MSG=""

# ---- PRESETS SCREEN ----
screen_presets() {
    clear
    echo ""
    box_top
    box_center "[ MATRIX TERMINAL CONFIGURATION ]" "$BRIGHT"
    box_center "\"There is no spoon.\"" "$DIM"
    box_sep
    box_empty
    box_center "CHOOSE YOUR REALITY" "$BRIGHT"
    box_empty
    box_thin

    box_empty
    box_kv "1) Full 1999 CRT" "" "$BRIGHT" "$NC"
    box_left "   Curvature + scanlines + shadow mask + vignette" "$DIM"
    box_left "   Thick phosphor font, solid background, slow type" "$DIM"
    box_left "   Like being teleported back to 1999" "$DIM"
    box_empty

    box_kv "2) CRT Lite" "" "$GREEN" "$NC"
    box_left "   Scanlines without curvature" "$DIM"
    box_left "   Retro feel, easier on the eyes" "$DIM"
    box_empty

    box_kv "3) Phosphor Bloom" "(recommended)" "$GREEN" "$DIM"
    box_left "   Soft glow around text, very readable" "$DIM"
    box_left "   The default Matrix experience" "$DIM"
    box_empty

    box_kv "4) Subtle Glow" "" "$GREEN" "$NC"
    box_left "   Minimal green glow, clean look" "$DIM"
    box_left "   For daily driving" "$DIM"
    box_empty

    box_kv "5) Clean Terminal" "" "$GREEN" "$NC"
    box_left "   Matrix colors only, no shader effects" "$DIM"
    box_left "   All the green, none of the distortion" "$DIM"
    box_empty

    box_thin
    box_kv "c) Custom settings..." "" "$GREEN" "$NC"
    box_kv "q) Quit" "" "$GREEN" "$NC"
    box_empty

    if [ -n "$STATUS_MSG" ]; then
        box_sep
        box_center "$STATUS_MSG" "$BRIGHT"
    fi

    box_bottom
    echo ""
    printf "  ${GREEN}> ${NC}"
}

# ---- CUSTOM SETTINGS SCREEN ----
screen_custom() {
    clear

    local shader=$(get_current_shader)
    local freq=$(read_matrix_conf "MATRIX_ANIMATION_FREQUENCY" "daily")
    local dur=$(read_matrix_conf "MATRIX_ANIMATION_DURATION" "8")
    local text_seq=$(read_matrix_conf "MATRIX_SHOW_TEXT_SEQUENCE" "true")
    local skip=$(read_matrix_conf "MATRIX_ALLOW_SKIP" "true")
    local header=$(read_matrix_conf "MATRIX_SHOW_HEADER" "true")
    local quote=$(read_matrix_conf "MATRIX_SHOW_QUOTE" "true")
    local sysinfo=$(read_matrix_conf "MATRIX_SHOW_SYSTEM_INFO" "true")
    local diffuse=$(read_matrix_conf "MATRIX_DIFFUSE" "true")
    local twinkle=$(read_matrix_conf "MATRIX_TWINKLE" "true")
    local seq=$(read_matrix_conf "MATRIX_SEQUENCE" "number,rain,banner")
    local speed=$(read_matrix_conf "MATRIX_TYPING_SPEED" "0.06")
    local font_thick=$(read_ghostty_conf "font-thicken" "true")
    local opacity=$(read_ghostty_conf "background-opacity" "0.92")
    local font_size=$(read_ghostty_conf "font-size" "14")
    local cursor=$(read_ghostty_conf "cursor-style" "block")
    local blink=$(read_ghostty_conf "cursor-style-blink" "true")
    local pad_x=$(read_ghostty_conf "window-padding-x" "4")
    local pad_y=$(read_ghostty_conf "window-padding-y" "4")

    echo ""
    box_top
    box_center "[ CUSTOM CONFIGURATION ]" "$BRIGHT"
    box_center "Current: $(shader_name $shader)" "$DIM"
    box_sep

    # -- SHADER --
    box_empty
    box_center "SHADER" "$YELLOW"
    box_kv "1) Shader Effect" "[$(shader_name $shader)]"
    box_left "   $(shader_desc $shader)" "$DIM"
    box_empty

    # -- ANIMATION --
    box_thin
    box_center "ANIMATION" "$YELLOW"
    box_kv "2) Frequency" "[$freq]"
    box_kv "3) Duration" "[${dur}s]"
    box_kv "4) Sequence" "[$seq]"
    box_kv "5) Text Sequence" "[$(on_off $text_seq)]"
    box_kv "6) Typing Speed" "[${speed}s/char]"
    box_kv "7) Allow Skip" "[$(on_off $skip)]"
    box_kv "8) Diffuse Glow" "[$(on_off $diffuse)]"
    box_kv "9) Twinkle Effect" "[$(on_off $twinkle)]"
    box_empty

    # -- TERMINAL --
    box_thin
    box_center "TERMINAL APPEARANCE" "$YELLOW"
    box_kv "a) Font Thicken (phosphor)" "[$(on_off $font_thick)]"
    box_kv "b) Font Size" "[$font_size]"
    box_kv "c) Background Opacity" "[$opacity]"
    box_kv "d) Cursor Style" "[$cursor]"
    box_kv "e) Cursor Blink" "[$(on_off $blink)]"
    box_kv "f) Window Padding" "[${pad_x}x${pad_y}]"
    box_empty

    # -- HEADER --
    box_thin
    box_center "HEADER & QUOTES" "$YELLOW"
    box_kv "g) Show Header" "[$(on_off $header)]"
    box_kv "h) Show Quote" "[$(on_off $quote)]"
    box_kv "i) Show System Info" "[$(on_off $sysinfo)]"
    box_empty

    # -- ACTIONS --
    box_thin
    box_kv "p) Preview animation" "" "$GREEN" "$NC"
    box_kv "r) Reset to defaults" "" "$GREEN" "$NC"
    box_kv "m) Edit config manually" "" "$GREEN" "$NC"
    box_kv "x) Back to presets" "" "$GREEN" "$NC"
    box_kv "q) Quit" "" "$GREEN" "$NC"
    box_empty

    if [ -n "$STATUS_MSG" ]; then
        box_sep
        box_center "$STATUS_MSG" "$BRIGHT"
        STATUS_MSG=""
    fi

    box_bottom
    echo ""
    printf "  ${GREEN}> ${NC}"
}

# ---- SHADER PICKER ----
screen_shader_picker() {
    clear
    local current=$(get_current_shader)

    echo ""
    box_top
    box_center "[ SELECT SHADER ]" "$BRIGHT"
    box_sep
    box_empty

    local shaders=("crt-full" "crt" "bloom" "matrix-glow" "none")
    local labels=("1" "2" "3" "4" "5")
    for idx in "${!shaders[@]}"; do
        local s="${shaders[$idx]}"
        local marker=""
        [ "$s" = "$current" ] && marker=" <-- active"
        box_kv "${labels[$idx]}) $(shader_name $s)" "$marker"
        box_left "   $(shader_desc $s)" "$DIM"
        box_empty
    done

    box_thin
    box_kv "x) Cancel" "" "$GREEN" "$NC"
    box_bottom
    echo ""
    printf "  ${GREEN}> ${NC}"

    read -rsn1 choice
    case "$choice" in
        1) set_shader "crt-full"; STATUS_MSG="Shader: CRT Full 1999 -- restart Ghostty" ;;
        2) set_shader "crt"; STATUS_MSG="Shader: CRT Scanlines -- restart Ghostty" ;;
        3) set_shader "bloom"; STATUS_MSG="Shader: Phosphor Bloom -- restart Ghostty" ;;
        4) set_shader "matrix-glow"; STATUS_MSG="Shader: Matrix Glow -- restart Ghostty" ;;
        5) set_shader "none"; STATUS_MSG="Shader: None -- restart Ghostty" ;;
    esac
}

# ---- SEQUENCE PICKER ----
screen_sequence_picker() {
    clear
    local current=$(read_matrix_conf "MATRIX_SEQUENCE" "number,rain,banner")

    echo ""
    box_top
    box_center "[ SELECT ANIMATION SEQUENCE ]" "$BRIGHT"
    box_center "Current: $current" "$DIM"
    box_sep
    box_empty

    box_kv "1) number,rain,banner" "(default)"
    box_left "   Number cascade, rain, then your banner" "$DIM"
    box_empty
    box_kv "2) rain" ""
    box_left "   Just the iconic digital rain" "$DIM"
    box_empty
    box_kv "3) number,rain,banner,conway" ""
    box_left "   Default + Conway's Game of Life" "$DIM"
    box_empty
    box_kv "4) number,banner,rain,conway,mandelbrot" ""
    box_left "   The full show" "$DIM"
    box_empty
    box_kv "5) Custom..." ""
    box_left "   Enter your own sequence" "$DIM"
    box_empty

    box_thin
    box_kv "x) Cancel" "" "$GREEN" "$NC"
    box_bottom
    echo ""
    printf "  ${GREEN}> ${NC}"

    read -rsn1 choice
    case "$choice" in
        1) write_matrix_conf "MATRIX_SEQUENCE" "number,rain,banner"; STATUS_MSG="Sequence: number,rain,banner" ;;
        2) write_matrix_conf "MATRIX_SEQUENCE" "rain"; STATUS_MSG="Sequence: rain" ;;
        3) write_matrix_conf "MATRIX_SEQUENCE" "number,rain,banner,conway"; STATUS_MSG="Sequence: +conway" ;;
        4) write_matrix_conf "MATRIX_SEQUENCE" "number,banner,rain,conway,mandelbrot"; STATUS_MSG="Sequence: full show" ;;
        5)
            echo ""
            printf "  ${GREEN}Options: number, rain, banner, conway, mandelbrot, rain-forever${NC}\n"
            printf "  ${GREEN}Comma-separated: ${NC}"
            read -r custom_seq
            if [ -n "$custom_seq" ]; then
                write_matrix_conf "MATRIX_SEQUENCE" "$custom_seq"
                STATUS_MSG="Sequence: $custom_seq"
            fi
            ;;
    esac
}

# ---- NUMERIC PROMPT ----
prompt_number() {
    local label="$1" current="$2" min="$3" max="$4"
    echo ""
    printf "  ${GREEN}Current ${label}: ${BRIGHT}${current}${NC}\n"
    printf "  ${GREEN}Enter new value (${min}-${max}): ${NC}"
    read -r val
    if [[ "$val" =~ ^[0-9]+$ ]] && [ "$val" -ge "$min" ] && [ "$val" -le "$max" ]; then
        echo "$val"
    else
        echo "$current"
    fi
}

prompt_decimal() {
    local label="$1" current="$2" min="$3" max="$4"
    echo ""
    printf "  ${GREEN}Current ${label}: ${BRIGHT}${current}${NC}\n"
    printf "  ${GREEN}Enter new value (${min}-${max}): ${NC}"
    read -r val
    if [[ "$val" =~ ^[0-9]*\.?[0-9]+$ ]]; then
        local ok
        ok=$(awk "BEGIN {print ($val >= $min && $val <= $max) ? 1 : 0}")
        [ "$ok" = "1" ] && { echo "$val"; return; }
    fi
    echo "$current"
}

# ============================================================
# MAIN LOOP
# ============================================================

if [ ! -f "$MATRIX_CONF" ]; then
    echo -e "${RED}Error: matrix.conf not found at ${MATRIX_CONF}${NC}"
    echo -e "${YELLOW}Run the install script first.${NC}"
    exit 1
fi

current_screen="presets"

while true; do
    COLS=$(get_cols)

    case "$current_screen" in
    # ====================
    # PRESETS SCREEN
    # ====================
    presets)
        screen_presets
        read -rsn1 choice
        case "$choice" in
            1) apply_preset "1999" ;;
            2) apply_preset "crt-lite" ;;
            3) apply_preset "bloom-default" ;;
            4) apply_preset "subtle" ;;
            5) apply_preset "clean" ;;
            c|C) current_screen="custom" ;;
            q|Q|$'\e') break ;;
            *) STATUS_MSG="Press 1-5 for presets, c for custom, q to quit" ;;
        esac
        ;;

    # ====================
    # CUSTOM SCREEN
    # ====================
    custom)
        screen_custom
        read -rsn1 choice
        case "$choice" in
            1) screen_shader_picker ;;
            2)
                cur=$(read_matrix_conf "MATRIX_ANIMATION_FREQUENCY" "daily")
                new=$(cycle_freq "$cur")
                write_matrix_conf "MATRIX_ANIMATION_FREQUENCY" "$new"
                STATUS_MSG="Animation frequency: $new"
                ;;
            3)
                cur=$(read_matrix_conf "MATRIX_ANIMATION_DURATION" "8")
                new=$(prompt_number "duration (seconds)" "$cur" 1 30)
                write_matrix_conf "MATRIX_ANIMATION_DURATION" "$new"
                STATUS_MSG="Duration: ${new}s"
                ;;
            4) screen_sequence_picker ;;
            5)
                cur=$(read_matrix_conf "MATRIX_SHOW_TEXT_SEQUENCE" "true")
                write_matrix_conf "MATRIX_SHOW_TEXT_SEQUENCE" "$(toggle "$cur")"
                STATUS_MSG="Text sequence: $(on_off $(toggle "$cur"))"
                ;;
            6)
                cur=$(read_matrix_conf "MATRIX_TYPING_SPEED" "0.06")
                new=$(prompt_decimal "typing speed (s/char)" "$cur" 0.01 0.20)
                write_matrix_conf "MATRIX_TYPING_SPEED" "$new"
                STATUS_MSG="Typing speed: ${new}s/char"
                ;;
            7)
                cur=$(read_matrix_conf "MATRIX_ALLOW_SKIP" "true")
                write_matrix_conf "MATRIX_ALLOW_SKIP" "$(toggle "$cur")"
                STATUS_MSG="Allow skip: $(on_off $(toggle "$cur"))"
                ;;
            8)
                cur=$(read_matrix_conf "MATRIX_DIFFUSE" "true")
                write_matrix_conf "MATRIX_DIFFUSE" "$(toggle "$cur")"
                STATUS_MSG="Diffuse glow: $(on_off $(toggle "$cur"))"
                ;;
            9)
                cur=$(read_matrix_conf "MATRIX_TWINKLE" "true")
                write_matrix_conf "MATRIX_TWINKLE" "$(toggle "$cur")"
                STATUS_MSG="Twinkle: $(on_off $(toggle "$cur"))"
                ;;
            a|A)
                cur=$(read_ghostty_conf "font-thicken" "true")
                write_ghostty_conf "font-thicken" "$(toggle "$cur")"
                STATUS_MSG="Font thicken: $(on_off $(toggle "$cur")) -- restart Ghostty"
                ;;
            b|B)
                cur=$(read_ghostty_conf "font-size" "14")
                new=$(prompt_number "font size" "$cur" 8 32)
                write_ghostty_conf "font-size" "$new"
                STATUS_MSG="Font size: $new -- restart Ghostty"
                ;;
            c|C)
                cur=$(read_ghostty_conf "background-opacity" "0.92")
                new=$(prompt_decimal "opacity" "$cur" 0.3 1.0)
                write_ghostty_conf "background-opacity" "$new"
                STATUS_MSG="Opacity: $new -- restart Ghostty"
                ;;
            d|D)
                cur=$(read_ghostty_conf "cursor-style" "block")
                new=$(cycle_cursor "$cur")
                write_ghostty_conf "cursor-style" "$new"
                STATUS_MSG="Cursor: $new -- restart Ghostty"
                ;;
            e|E)
                cur=$(read_ghostty_conf "cursor-style-blink" "true")
                write_ghostty_conf "cursor-style-blink" "$(toggle "$cur")"
                STATUS_MSG="Cursor blink: $(on_off $(toggle "$cur")) -- restart Ghostty"
                ;;
            f|F)
                cur_x=$(read_ghostty_conf "window-padding-x" "4")
                cur_y=$(read_ghostty_conf "window-padding-y" "4")
                new_x=$(prompt_number "horizontal padding" "$cur_x" 0 40)
                new_y=$(prompt_number "vertical padding" "$cur_y" 0 40)
                write_ghostty_conf "window-padding-x" "$new_x"
                write_ghostty_conf "window-padding-y" "$new_y"
                STATUS_MSG="Padding: ${new_x}x${new_y} -- restart Ghostty"
                ;;
            g|G)
                cur=$(read_matrix_conf "MATRIX_SHOW_HEADER" "true")
                write_matrix_conf "MATRIX_SHOW_HEADER" "$(toggle "$cur")"
                STATUS_MSG="Header: $(on_off $(toggle "$cur"))"
                ;;
            h|H)
                cur=$(read_matrix_conf "MATRIX_SHOW_QUOTE" "true")
                write_matrix_conf "MATRIX_SHOW_QUOTE" "$(toggle "$cur")"
                STATUS_MSG="Quote: $(on_off $(toggle "$cur"))"
                ;;
            i|I)
                cur=$(read_matrix_conf "MATRIX_SHOW_SYSTEM_INFO" "true")
                write_matrix_conf "MATRIX_SHOW_SYSTEM_INFO" "$(toggle "$cur")"
                STATUS_MSG="System info: $(on_off $(toggle "$cur"))"
                ;;
            p|P)
                clear
                if [ -x ~/.config/ghostty/matrix-startup.sh ]; then
                    ~/.config/ghostty/matrix-startup.sh
                else
                    bash ~/.config/ghostty/matrix-startup.sh
                fi
                STATUS_MSG="Preview complete"
                ;;
            r|R)
                echo ""
                printf "  ${YELLOW}Reset all settings to defaults? (y/N): ${NC}"
                read -rsn1 confirm
                if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
                    apply_preset "bloom-default"
                    STATUS_MSG="Reset to defaults (Phosphor Bloom)"
                else
                    STATUS_MSG="Reset cancelled"
                fi
                ;;
            m|M)
                ${EDITOR:-nano} "$MATRIX_CONF"
                STATUS_MSG="Config edited"
                ;;
            x|X) current_screen="presets" ;;
            q|Q|$'\e') break ;;
            *) STATUS_MSG="Unknown option" ;;
        esac
        ;;
    esac
done

# Exit message
clear
echo ""
box_top
box_center "Configuration saved." "$BRIGHT"
box_empty
box_center "Restart Ghostty for visual changes to take effect." "$DIM"
box_center "Run 'matrix-demo' to preview the animation now." "$DIM"
box_empty
box_bottom
echo ""
