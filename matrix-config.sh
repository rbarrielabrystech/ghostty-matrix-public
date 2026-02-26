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
        *retro-crt*)    echo "retro-crt" ;;
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
        retro-crt)   echo "Retro CRT" ;;
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
        retro-crt)   echo "CRT with switchable phosphor (green/amber/white)" ;;
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
        retro-crt)
            write_ghostty_conf "custom-shader" "~/.config/ghostty/shaders/retro-crt.glsl"
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

# ============================================================
# SHADER DEFINE HELPERS
# ============================================================
# Read whether a #define ENABLE_X is active (uncommented) in a shader file
read_shader_define() {
    local shader_file="$1" define_name="$2"
    if [ -f "$shader_file" ]; then
        # Active = uncommented line like: #define ENABLE_NOISE 1
        if grep -qE "^#define ${define_name} " "$shader_file" 2>/dev/null; then
            echo "true"
            return
        fi
    fi
    echo "false"
}

# Toggle a #define line between commented and uncommented
toggle_shader_define() {
    local shader_file="$1" define_name="$2"
    if [ ! -f "$shader_file" ]; then return; fi
    local current
    current=$(read_shader_define "$shader_file" "$define_name")
    if [ "$current" = "true" ]; then
        # Comment it out
        _sed_inplace "s|^#define ${define_name} |// #define ${define_name} |" "$shader_file"
    else
        # Uncomment it
        _sed_inplace "s|^// *#define ${define_name} |#define ${define_name} |" "$shader_file"
    fi
}

# Set a #define to a specific state (true=uncommented, false=commented)
set_shader_define() {
    local shader_file="$1" define_name="$2" state="$3"
    if [ ! -f "$shader_file" ]; then return; fi
    if [ "$state" = "true" ]; then
        _sed_inplace "s|^// *#define ${define_name} |#define ${define_name} |" "$shader_file"
    else
        _sed_inplace "s|^#define ${define_name} |// #define ${define_name} |" "$shader_file"
    fi
}

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
            # Enable enhanced CRT effects
            write_matrix_conf "MATRIX_CRT_NOISE" "true"
            write_matrix_conf "MATRIX_CRT_INTERLACE" "true"
            write_matrix_conf "MATRIX_SHUTDOWN_ANIMATION" "true"
            local crt_shader="${SHADER_DIR}/crt-full.glsl"
            set_shader_define "$crt_shader" "ENABLE_NOISE" "true"
            set_shader_define "$crt_shader" "ENABLE_INTERLACE" "true"
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
# TERMINAL ERAS
# ============================================================

# Set one of several radio-style #defines in a shader file
set_shader_radio() {
    local file="$1" active="$2"
    shift 2
    for def in "$@"; do
        if [ "$def" = "$active" ]; then
            set_shader_define "$file" "$def" "true"
        else
            set_shader_define "$file" "$def" "false"
        fi
    done
}

# Replace all palette lines in Ghostty config
write_ghostty_palette() {
    [ -f "$GHOSTTY_CONF" ] && _sed_inplace '/^palette *=/d' "$GHOSTTY_CONF"
    for entry in "$@"; do
        echo "palette = ${entry}" >> "$GHOSTTY_CONF"
    done
}

# Restore the default Matrix palette
restore_matrix_palette() {
    write_ghostty_palette \
        "0=#0d0208" "1=#00FF41" "2=#00FF41" "3=#008F11" \
        "4=#008F11" "5=#00FF41" "6=#005F00" "7=#00FF41" \
        "8=#003B00" "9=#39FF14" "10=#39FF14" "11=#00FF41" \
        "12=#00FF41" "13=#39FF14" "14=#00FF41" "15=#FFFFFF"
    write_ghostty_conf "background" "#0d0208"
    write_ghostty_conf "foreground" "#00FF41"
    write_ghostty_conf "cursor-color" "#00FF41"
    write_ghostty_conf "cursor-text" "#000000"
    write_ghostty_conf "selection-background" "#003B00"
}

# Apply a terminal era — sets palette, shader, phosphor, and era config
apply_era() {
    local era="$1"
    local retro_shader="${SHADER_DIR}/retro-crt.glsl"

    # Clear previous era
    write_matrix_conf "MATRIX_ERA" "$era"

    case "$era" in
        # ---- WWII (1940s) ----
        enigma)
            write_ghostty_palette \
                "0=#1A1A0E" "1=#8B4513" "2=#556B2F" "3=#DAA520" \
                "4=#8B7355" "5=#CD853F" "6=#6B8E23" "7=#FFE4B5" \
                "8=#2F2F1A" "9=#D2691E" "10=#9ACD32" "11=#FFD700" \
                "12=#DEB887" "13=#F4A460" "14=#BDB76B" "15=#FFFACD"
            write_ghostty_conf "background" "#1A1A0E"
            write_ghostty_conf "foreground" "#FFE4B5"
            write_ghostty_conf "cursor-color" "#FFE4B5"
            set_shader "none"
            ;;
        colossus)
            write_ghostty_palette \
                "0=#0A0A0A" "1=#FF6B35" "2=#4A9E4A" "3=#FFB347" \
                "4=#4A6E8C" "5=#CC5500" "6=#6B8E8E" "7=#FF6B35" \
                "8=#333333" "9=#FF8C00" "10=#66CD66" "11=#FFD700" \
                "12=#6A9EC6" "13=#FF7F50" "14=#8CBEBE" "15=#FFCC80"
            write_ghostty_conf "background" "#0A0A0A"
            write_ghostty_conf "foreground" "#FF6B35"
            write_ghostty_conf "cursor-color" "#FF6B35"
            set_shader "none"
            ;;

        # ---- Pre-CRT (1950s-1960s) ----
        punchcard)
            write_ghostty_palette \
                "0=#F5F0E1" "1=#8B0000" "2=#006400" "3=#8B8000" \
                "4=#00008B" "5=#8B008B" "6=#008B8B" "7=#1A1A1A" \
                "8=#D4CDB8" "9=#FF0000" "10=#008000" "11=#CCCC00" \
                "12=#0000FF" "13=#FF00FF" "14=#00CCCC" "15=#000000"
            write_ghostty_conf "background" "#F5F0E1"
            write_ghostty_conf "foreground" "#1A1A1A"
            write_ghostty_conf "cursor-color" "#1A1A1A"
            set_shader "none"
            ;;
        teletype)
            write_ghostty_palette \
                "0=#F5F5DC" "1=#8B0000" "2=#006400" "3=#8B8000" \
                "4=#00008B" "5=#8B008B" "6=#008B8B" "7=#1A1A1A" \
                "8=#D4D4AA" "9=#FF0000" "10=#008000" "11=#CCCC00" \
                "12=#0000FF" "13=#FF00FF" "14=#00CCCC" "15=#000000"
            write_ghostty_conf "background" "#F5F5DC"
            write_ghostty_conf "foreground" "#1A1A1A"
            write_ghostty_conf "cursor-color" "#1A1A1A"
            set_shader "none"
            ;;
        lineprinter)
            write_ghostty_palette \
                "0=#F5F5F5" "1=#8B0000" "2=#006400" "3=#8B8000" \
                "4=#00008B" "5=#8B008B" "6=#008B8B" "7=#1A1A1A" \
                "8=#D0D0D0" "9=#FF0000" "10=#008000" "11=#CCCC00" \
                "12=#0000FF" "13=#FF00FF" "14=#00CCCC" "15=#000000"
            write_ghostty_conf "background" "#F5F5F5"
            write_ghostty_conf "foreground" "#1A1A1A"
            write_ghostty_conf "cursor-color" "#1A1A1A"
            set_shader "none"
            ;;

        # ---- Mainframe (1960s-1970s) ----
        ibm3270)
            write_ghostty_palette \
                "0=#0A0A0A" "1=#FF3300" "2=#33FF33" "3=#FFFF00" \
                "4=#3399FF" "5=#FF33FF" "6=#33FFFF" "7=#33FF33" \
                "8=#1A3A1A" "9=#FF6633" "10=#66FF66" "11=#FFFF66" \
                "12=#66B2FF" "13=#FF66FF" "14=#66FFFF" "15=#FFFFFF"
            write_ghostty_conf "background" "#0A0A0A"
            write_ghostty_conf "foreground" "#33FF33"
            write_ghostty_conf "cursor-color" "#33FF33"
            set_shader "retro-crt"
            set_shader_radio "$retro_shader" "PHOSPHOR_GREEN" "PHOSPHOR_GREEN" "PHOSPHOR_AMBER" "PHOSPHOR_WHITE"
            ;;
        system360)
            write_ghostty_palette \
                "0=#3A3A3A" "1=#FF3300" "2=#33CC33" "3=#FFCC00" \
                "4=#3366CC" "5=#CC33CC" "6=#33CCCC" "7=#FF3300" \
                "8=#555555" "9=#FF6633" "10=#66FF66" "11=#FFFF66" \
                "12=#6699FF" "13=#FF66FF" "14=#66FFFF" "15=#FFCCCC"
            write_ghostty_conf "background" "#3A3A3A"
            write_ghostty_conf "foreground" "#FF3300"
            write_ghostty_conf "cursor-color" "#FF3300"
            set_shader "none"
            ;;
        pdp8)
            write_ghostty_palette \
                "0=#8B7355" "1=#FF0000" "2=#33CC33" "3=#FFAA00" \
                "4=#4A6D8C" "5=#CC33CC" "6=#33CCCC" "7=#FFAA00" \
                "8=#6B5335" "9=#FF3333" "10=#66FF66" "11=#FFCC33" \
                "12=#6A8DAC" "13=#FF66FF" "14=#66FFFF" "15=#FFE4B5"
            write_ghostty_conf "background" "#8B7355"
            write_ghostty_conf "foreground" "#FFAA00"
            write_ghostty_conf "cursor-color" "#FFAA00"
            set_shader "none"
            ;;

        # ---- Early Terminals (1970s) ----
        vt100)
            write_ghostty_palette \
                "0=#000000" "1=#33FF00" "2=#33FF00" "3=#1A8C00" \
                "4=#1A8C00" "5=#33FF00" "6=#0D4A00" "7=#33FF00" \
                "8=#0A3A0A" "9=#66FF33" "10=#66FF33" "11=#33FF00" \
                "12=#33FF00" "13=#66FF33" "14=#33FF00" "15=#CCFFCC"
            write_ghostty_conf "background" "#000000"
            write_ghostty_conf "foreground" "#33FF00"
            write_ghostty_conf "cursor-color" "#33FF00"
            set_shader "retro-crt"
            set_shader_radio "$retro_shader" "PHOSPHOR_GREEN" "PHOSPHOR_GREEN" "PHOSPHOR_AMBER" "PHOSPHOR_WHITE"
            ;;
        vt220)
            write_ghostty_palette \
                "0=#0A0800" "1=#FFB000" "2=#FFB000" "3=#CC8C00" \
                "4=#CC8C00" "5=#FFB000" "6=#8C6000" "7=#FFB000" \
                "8=#1A1400" "9=#FFCC33" "10=#FFCC33" "11=#FFB000" \
                "12=#FFB000" "13=#FFCC33" "14=#FFB000" "15=#FFE8AA"
            write_ghostty_conf "background" "#0A0800"
            write_ghostty_conf "foreground" "#FFB000"
            write_ghostty_conf "cursor-color" "#FFB000"
            set_shader "retro-crt"
            set_shader_radio "$retro_shader" "PHOSPHOR_AMBER" "PHOSPHOR_GREEN" "PHOSPHOR_AMBER" "PHOSPHOR_WHITE"
            ;;
        altair)
            write_ghostty_palette \
                "0=#4A6D8C" "1=#FF0000" "2=#00FF00" "3=#FFAA00" \
                "4=#3366CC" "5=#FF3399" "6=#33CCCC" "7=#FF0000" \
                "8=#2A4D6C" "9=#FF3333" "10=#33FF33" "11=#FFCC33" \
                "12=#6699FF" "13=#FF66CC" "14=#66FFFF" "15=#FFFFFF"
            write_ghostty_conf "background" "#4A6D8C"
            write_ghostty_conf "foreground" "#FF0000"
            write_ghostty_conf "cursor-color" "#FF0000"
            set_shader "none"
            ;;

        # ---- Home Computers (late 1970s-1980s) ----
        apple2)
            write_ghostty_palette \
                "0=#000000" "1=#DD0033" "2=#00AA00" "3=#DD8800" \
                "4=#0000CC" "5=#DD00DD" "6=#00AAAA" "7=#33FF00" \
                "8=#555555" "9=#FF3366" "10=#33FF33" "11=#FFFF00" \
                "12=#3366FF" "13=#FF33FF" "14=#33FFFF" "15=#FFFFFF"
            write_ghostty_conf "background" "#000000"
            write_ghostty_conf "foreground" "#33FF00"
            write_ghostty_conf "cursor-color" "#33FF00"
            set_shader "retro-crt"
            set_shader_radio "$retro_shader" "PHOSPHOR_GREEN" "PHOSPHOR_GREEN" "PHOSPHOR_AMBER" "PHOSPHOR_WHITE"
            ;;
        pet)
            write_ghostty_palette \
                "0=#000000" "1=#33FF00" "2=#33FF00" "3=#1A8C00" \
                "4=#1A8C00" "5=#33FF00" "6=#0D4A00" "7=#33FF00" \
                "8=#0A3A0A" "9=#66FF33" "10=#66FF33" "11=#33FF00" \
                "12=#33FF00" "13=#66FF33" "14=#33FF00" "15=#CCFFCC"
            write_ghostty_conf "background" "#000000"
            write_ghostty_conf "foreground" "#33FF00"
            write_ghostty_conf "cursor-color" "#33FF00"
            set_shader "retro-crt"
            set_shader_radio "$retro_shader" "PHOSPHOR_GREEN" "PHOSPHOR_GREEN" "PHOSPHOR_AMBER" "PHOSPHOR_WHITE"
            ;;
        trs80)
            write_ghostty_palette \
                "0=#000000" "1=#C8C8C8" "2=#C8C8C8" "3=#969696" \
                "4=#969696" "5=#C8C8C8" "6=#646464" "7=#C8C8C8" \
                "8=#323232" "9=#E0E0E0" "10=#E0E0E0" "11=#C8C8C8" \
                "12=#C8C8C8" "13=#E0E0E0" "14=#C8C8C8" "15=#FFFFFF"
            write_ghostty_conf "background" "#000000"
            write_ghostty_conf "foreground" "#C8C8C8"
            write_ghostty_conf "cursor-color" "#C8C8C8"
            set_shader "retro-crt"
            set_shader_radio "$retro_shader" "PHOSPHOR_WHITE" "PHOSPHOR_GREEN" "PHOSPHOR_AMBER" "PHOSPHOR_WHITE"
            ;;
        c64)
            write_ghostty_palette \
                "0=#000000" "1=#9F4E44" "2=#5CAB5E" "3=#C9D487" \
                "4=#50459B" "5=#A057A3" "6=#6ABFC6" "7=#ADADAD" \
                "8=#626262" "9=#CB7E75" "10=#9AE29B" "11=#C9D487" \
                "12=#887ECB" "13=#A057A3" "14=#6ABFC6" "15=#FFFFFF"
            write_ghostty_conf "background" "#50459B"
            write_ghostty_conf "foreground" "#887ECB"
            write_ghostty_conf "cursor-color" "#887ECB"
            set_shader "retro-crt"
            set_shader_radio "$retro_shader" "" "PHOSPHOR_GREEN" "PHOSPHOR_AMBER" "PHOSPHOR_WHITE"
            ;;
        spectrum)
            write_ghostty_palette \
                "0=#000000" "1=#D70000" "2=#00D700" "3=#D7D700" \
                "4=#0000D7" "5=#D700D7" "6=#00D7D7" "7=#D7D7D7" \
                "8=#000000" "9=#FF0000" "10=#00FF00" "11=#FFFF00" \
                "12=#0000FF" "13=#FF00FF" "14=#00FFFF" "15=#FFFFFF"
            write_ghostty_conf "background" "#D8D8D8"
            write_ghostty_conf "foreground" "#000000"
            write_ghostty_conf "cursor-color" "#000000"
            set_shader "retro-crt"
            set_shader_radio "$retro_shader" "" "PHOSPHOR_GREEN" "PHOSPHOR_AMBER" "PHOSPHOR_WHITE"
            ;;
        bbc)
            write_ghostty_palette \
                "0=#000000" "1=#FF0000" "2=#00FF00" "3=#FFFF00" \
                "4=#0000FF" "5=#FF00FF" "6=#00FFFF" "7=#FFFFFF" \
                "8=#555555" "9=#FF5555" "10=#55FF55" "11=#FFFF55" \
                "12=#5555FF" "13=#FF55FF" "14=#55FFFF" "15=#FFFFFF"
            write_ghostty_conf "background" "#000000"
            write_ghostty_conf "foreground" "#FFFFFF"
            write_ghostty_conf "cursor-color" "#FFFFFF"
            set_shader "retro-crt"
            set_shader_radio "$retro_shader" "" "PHOSPHOR_GREEN" "PHOSPHOR_AMBER" "PHOSPHOR_WHITE"
            ;;
        amstrad)
            write_ghostty_palette \
                "0=#000000" "1=#800000" "2=#008000" "3=#808000" \
                "4=#000080" "5=#800080" "6=#008080" "7=#808080" \
                "8=#404040" "9=#FF0000" "10=#00FF00" "11=#FFFF00" \
                "12=#0000FF" "13=#FF00FF" "14=#00FFFF" "15=#FFFFFF"
            write_ghostty_conf "background" "#000080"
            write_ghostty_conf "foreground" "#FFFF00"
            write_ghostty_conf "cursor-color" "#FFFF00"
            set_shader "retro-crt"
            set_shader_radio "$retro_shader" "" "PHOSPHOR_GREEN" "PHOSPHOR_AMBER" "PHOSPHOR_WHITE"
            ;;
        msx)
            write_ghostty_palette \
                "0=#000000" "1=#B71E1E" "2=#3EB849" "3=#CAC15E" \
                "4=#5455ED" "5=#B666B6" "6=#65DBEF" "7=#D4D4D4" \
                "8=#767676" "9=#CF4D4D" "10=#73CE7C" "11=#DADA89" \
                "12=#8086F3" "13=#D88DD8" "14=#93E6F3" "15=#FFFFFF"
            write_ghostty_conf "background" "#5455ED"
            write_ghostty_conf "foreground" "#FFFFFF"
            write_ghostty_conf "cursor-color" "#FFFFFF"
            set_shader "retro-crt"
            set_shader_radio "$retro_shader" "" "PHOSPHOR_GREEN" "PHOSPHOR_AMBER" "PHOSPHOR_WHITE"
            ;;
        atari800)
            write_ghostty_palette \
                "0=#000000" "1=#7C2C00" "2=#38580C" "3=#686800" \
                "4=#4646B4" "5=#7C3C78" "6=#2C6C6C" "7=#CACACA" \
                "8=#444444" "9=#EC6A28" "10=#70A850" "11=#B4B400" \
                "12=#7878E8" "13=#B06CB0" "14=#60A0A0" "15=#ECECEC"
            write_ghostty_conf "background" "#4646B4"
            write_ghostty_conf "foreground" "#CACACA"
            write_ghostty_conf "cursor-color" "#CACACA"
            set_shader "retro-crt"
            set_shader_radio "$retro_shader" "" "PHOSPHOR_GREEN" "PHOSPHOR_AMBER" "PHOSPHOR_WHITE"
            ;;
        amiga)
            write_ghostty_palette \
                "0=#000000" "1=#AA0000" "2=#00AA00" "3=#AA5500" \
                "4=#0055AA" "5=#AA00AA" "6=#00AAAA" "7=#AAAAAA" \
                "8=#555555" "9=#FF5555" "10=#55FF55" "11=#FFFF55" \
                "12=#5599FF" "13=#FF55FF" "14=#55FFFF" "15=#FFFFFF"
            write_ghostty_conf "background" "#0055AA"
            write_ghostty_conf "foreground" "#FFFFFF"
            write_ghostty_conf "cursor-color" "#FFFFFF"
            set_shader "retro-crt"
            set_shader_radio "$retro_shader" "" "PHOSPHOR_GREEN" "PHOSPHOR_AMBER" "PHOSPHOR_WHITE"
            ;;

        # ---- IBM PC Era (1981-1995) ----
        ibmmda)
            write_ghostty_palette \
                "0=#000000" "1=#33FF33" "2=#33FF33" "3=#1A8C00" \
                "4=#1A8C00" "5=#33FF33" "6=#0D4A00" "7=#33FF33" \
                "8=#0A3A0A" "9=#66FF66" "10=#66FF66" "11=#33FF33" \
                "12=#33FF33" "13=#66FF66" "14=#33FF33" "15=#CCFFCC"
            write_ghostty_conf "background" "#000000"
            write_ghostty_conf "foreground" "#33FF33"
            write_ghostty_conf "cursor-color" "#33FF33"
            set_shader "retro-crt"
            set_shader_radio "$retro_shader" "PHOSPHOR_GREEN" "PHOSPHOR_GREEN" "PHOSPHOR_AMBER" "PHOSPHOR_WHITE"
            ;;
        ibmcga)
            write_ghostty_palette \
                "0=#000000" "1=#AA0000" "2=#00AA00" "3=#AA5500" \
                "4=#0000AA" "5=#AA00AA" "6=#00AAAA" "7=#AAAAAA" \
                "8=#555555" "9=#FF5555" "10=#55FF55" "11=#FFFF55" \
                "12=#5555FF" "13=#FF55FF" "14=#55FFFF" "15=#FFFFFF"
            write_ghostty_conf "background" "#000000"
            write_ghostty_conf "foreground" "#AAAAAA"
            write_ghostty_conf "cursor-color" "#AAAAAA"
            set_shader "retro-crt"
            set_shader_radio "$retro_shader" "" "PHOSPHOR_GREEN" "PHOSPHOR_AMBER" "PHOSPHOR_WHITE"
            ;;
        dos)
            write_ghostty_palette \
                "0=#000000" "1=#AA0000" "2=#00AA00" "3=#AA5500" \
                "4=#0000AA" "5=#AA00AA" "6=#00AAAA" "7=#AAAAAA" \
                "8=#555555" "9=#FF5555" "10=#55FF55" "11=#FFFF55" \
                "12=#5555FF" "13=#FF55FF" "14=#55FFFF" "15=#FFFFFF"
            write_ghostty_conf "background" "#000000"
            write_ghostty_conf "foreground" "#AAAAAA"
            write_ghostty_conf "cursor-color" "#AAAAAA"
            set_shader "retro-crt"
            set_shader_radio "$retro_shader" "" "PHOSPHOR_GREEN" "PHOSPHOR_AMBER" "PHOSPHOR_WHITE"
            ;;

        # ---- Professional (1980s-1990s) ----
        solaris)
            write_ghostty_palette \
                "0=#000040" "1=#CC0000" "2=#00CC00" "3=#CCCC00" \
                "4=#4444CC" "5=#CC00CC" "6=#00CCCC" "7=#D7D6D2" \
                "8=#666666" "9=#FF3333" "10=#33FF33" "11=#FFFF33" \
                "12=#6666FF" "13=#FF33FF" "14=#33FFFF" "15=#FFFFFF"
            write_ghostty_conf "background" "#000040"
            write_ghostty_conf "foreground" "#D7D6D2"
            write_ghostty_conf "cursor-color" "#D7D6D2"
            set_shader "retro-crt"
            set_shader_radio "$retro_shader" "" "PHOSPHOR_GREEN" "PHOSPHOR_AMBER" "PHOSPHOR_WHITE"
            ;;
        irix)
            write_ghostty_palette \
                "0=#000040" "1=#CC3333" "2=#33CC33" "3=#CCCC33" \
                "4=#6666CC" "5=#CC33CC" "6=#33CCCC" "7=#D7D6D2" \
                "8=#666680" "9=#FF6666" "10=#66FF66" "11=#FFFF66" \
                "12=#9999FF" "13=#FF66FF" "14=#66FFFF" "15=#FFFFFF"
            write_ghostty_conf "background" "#000040"
            write_ghostty_conf "foreground" "#D7D6D2"
            write_ghostty_conf "cursor-color" "#D7D6D2"
            set_shader "retro-crt"
            set_shader_radio "$retro_shader" "" "PHOSPHOR_GREEN" "PHOSPHOR_AMBER" "PHOSPHOR_WHITE"
            ;;
        next)
            write_ghostty_palette \
                "0=#555555" "1=#CC3333" "2=#33CC33" "3=#CCCC33" \
                "4=#3333CC" "5=#CC33CC" "6=#33CCCC" "7=#FFFFFF" \
                "8=#333333" "9=#FF6666" "10=#66FF66" "11=#FFFF66" \
                "12=#6666FF" "13=#FF66FF" "14=#66FFFF" "15=#FFFFFF"
            write_ghostty_conf "background" "#555555"
            write_ghostty_conf "foreground" "#FFFFFF"
            write_ghostty_conf "cursor-color" "#FFFFFF"
            set_shader "bloom"
            ;;

        # ---- BBS & Networking ----
        bbs)
            write_ghostty_palette \
                "0=#000000" "1=#AA0000" "2=#00AA00" "3=#AA5500" \
                "4=#0000AA" "5=#AA00AA" "6=#00AAAA" "7=#AAAAAA" \
                "8=#555555" "9=#FF5555" "10=#55FF55" "11=#FFFF55" \
                "12=#5555FF" "13=#FF55FF" "14=#55FFFF" "15=#FFFFFF"
            write_ghostty_conf "background" "#000000"
            write_ghostty_conf "foreground" "#AAAAAA"
            write_ghostty_conf "cursor-color" "#AAAAAA"
            set_shader "retro-crt"
            set_shader_radio "$retro_shader" "" "PHOSPHOR_GREEN" "PHOSPHOR_AMBER" "PHOSPHOR_WHITE"
            ;;

        # ---- Modern (1990s-2000s) ----
        linux)
            write_ghostty_palette \
                "0=#000000" "1=#AA0000" "2=#00AA00" "3=#AA5500" \
                "4=#0000AA" "5=#AA00AA" "6=#00AAAA" "7=#AAAAAA" \
                "8=#555555" "9=#FF5555" "10=#55FF55" "11=#FFFF55" \
                "12=#5555FF" "13=#FF55FF" "14=#55FFFF" "15=#FFFFFF"
            write_ghostty_conf "background" "#000000"
            write_ghostty_conf "foreground" "#AAAAAA"
            write_ghostty_conf "cursor-color" "#AAAAAA"
            set_shader "none"
            ;;
        win98)
            write_ghostty_palette \
                "0=#000000" "1=#800000" "2=#008000" "3=#808000" \
                "4=#000080" "5=#800080" "6=#008080" "7=#C0C0C0" \
                "8=#808080" "9=#FF0000" "10=#00FF00" "11=#FFFF00" \
                "12=#0000FF" "13=#FF00FF" "14=#00FFFF" "15=#FFFFFF"
            write_ghostty_conf "background" "#000000"
            write_ghostty_conf "foreground" "#C0C0C0"
            write_ghostty_conf "cursor-color" "#C0C0C0"
            set_shader "none"
            ;;

        # ---- Return to Matrix ----
        matrix|"")
            restore_matrix_palette
            set_shader "bloom"
            write_matrix_conf "MATRIX_ERA" ""
            STATUS_MSG="Restored Matrix theme -- restart Ghostty"
            return
            ;;
    esac

    # Common settings for all eras
    write_ghostty_conf "cursor-style" "block"
    write_ghostty_conf "cursor-style-blink" "true"
    write_ghostty_conf "font-thicken" "true"
    write_ghostty_conf "background-opacity" "1.0"
    STATUS_MSG="ERA: $(era_display_name "$era") -- restart Ghostty"
}

era_display_name() {
    case "$1" in
        enigma)      echo "Enigma Machine (1940s)" ;;
        colossus)    echo "Colossus (1940s)" ;;
        punchcard)   echo "IBM Punch Card (1950s)" ;;
        teletype)    echo "Teletype ASR-33 (1960s)" ;;
        lineprinter) echo "Line Printer (1960s)" ;;
        ibm3270)     echo "IBM 3270 (1970s)" ;;
        system360)   echo "IBM System/360 (1960s)" ;;
        pdp8)        echo "DEC PDP-8 (1960s)" ;;
        vt100)       echo "DEC VT100 (1978)" ;;
        vt220)       echo "DEC VT220 (1983)" ;;
        altair)      echo "Altair 8800 (1975)" ;;
        apple2)      echo "Apple II (1977)" ;;
        pet)         echo "Commodore PET (1977)" ;;
        trs80)       echo "TRS-80 (1977)" ;;
        c64)         echo "Commodore 64 (1982)" ;;
        spectrum)    echo "ZX Spectrum (1982)" ;;
        bbc)         echo "BBC Micro (1981)" ;;
        amstrad)     echo "Amstrad CPC (1984)" ;;
        msx)         echo "MSX (1983)" ;;
        atari800)    echo "Atari 800 (1979)" ;;
        amiga)       echo "Commodore Amiga (1985)" ;;
        ibmmda)      echo "IBM MDA (1981)" ;;
        ibmcga)      echo "IBM CGA (1981)" ;;
        dos)         echo "MS-DOS (1991)" ;;
        solaris)     echo "Sun Solaris (1997)" ;;
        irix)        echo "SGI IRIX (1998)" ;;
        next)        echo "NeXT (1995)" ;;
        bbs)         echo "BBS Terminal (1993)" ;;
        linux)       echo "Early Linux (1998)" ;;
        win98)       echo "Windows 98 (1998)" ;;
        *)           echo "$1" ;;
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
    box_kv "e) Terminal Eras..." "TIME MACHINE" "$CYAN" "$DIM"
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

# ---- TERMINAL ERAS BROWSER (single-screen interactive) ----
screen_era_browser() {
    # ----------------------------------------------------------
    # Data: all eras + category headers as a flat indexed array.
    # Format: "CAT|Header Text"  or  "era_id|Display Name|short desc|detail line"
    # ----------------------------------------------------------
    local ERA_LIST
    ERA_LIST=(
        "CAT|WWII Computing (1940s)"
        "enigma|Enigma Machine|Rotor encryption simulator|Palette: warm sepia, No shader"
        "colossus|Colossus|Codebreaking computer|Palette: amber/orange, No shader"
        "CAT|Pre-CRT Era (1950s-1960s)"
        "punchcard|IBM Punch Card|Keypunch + card reader|Palette: paper white, No shader"
        "teletype|Teletype ASR-33|10 chars/sec paper terminal|Palette: cream/beige, No shader"
        "lineprinter|Line Printer|Greenbar output|Palette: white paper, No shader"
        "CAT|Mainframes (1960s-1970s)"
        "ibm3270|IBM 3270|Block-mode terminal|Palette: green phosphor, Shader: retro-crt green"
        "system360|IBM System/360|Mainframe console|Palette: red-on-gray, No shader"
        "pdp8|DEC PDP-8|Front panel minicomputer|Palette: amber/brown, No shader"
        "CAT|Early Terminals (1970s)"
        "vt100|DEC VT100|Green phosphor terminal|Palette: green phosphor, Shader: retro-crt green"
        "vt220|DEC VT220|Amber phosphor terminal|Palette: amber phosphor, Shader: retro-crt amber"
        "altair|Altair 8800|Front panel computer|Palette: red-on-blue, No shader"
        "CAT|Home Computers (1977-1985)"
        "apple2|Apple II|Green phosphor, Applesoft BASIC|Palette: green phosphor, Shader: retro-crt green"
        "pet|Commodore PET|Green CRT, Commodore BASIC|Palette: green phosphor, Shader: retro-crt green"
        "trs80|TRS-80|White phosphor, Level II BASIC|Palette: white phosphor, Shader: retro-crt white"
        "c64|Commodore 64|Blue-on-blue, BASIC V2|Palette: C64 blue, Shader: retro-crt"
        "spectrum|ZX Spectrum|Keyword entry, Sinclair BASIC|Palette: Spectrum colors, Shader: retro-crt"
        "bbc|BBC Micro|White-on-black, BBC BASIC|Palette: white-on-black, Shader: retro-crt"
        "amstrad|Amstrad CPC|Yellow-on-blue, Locomotive BASIC|Palette: yellow-on-blue, Shader: retro-crt"
        "msx|MSX|White-on-blue, MSX-BASIC|Palette: MSX standard, Shader: retro-crt"
        "atari800|Atari 800|Atari BASIC|Palette: Atari colors, Shader: retro-crt"
        "amiga|Commodore Amiga|AmigaDOS Workbench|Palette: Amiga colors, Shader: retro-crt"
        "CAT|IBM PC Era (1981-1995)"
        "ibmmda|IBM MDA|Green phosphor, DOS 3.30|Palette: green phosphor, Shader: retro-crt green"
        "ibmcga|IBM CGA|Color graphics adapter|Palette: CGA standard, Shader: retro-crt"
        "dos|MS-DOS / VGA|DOS 6.22, VGA display|Palette: DOS gray, Shader: retro-crt"
        "CAT|Professional Unix (1985-1998)"
        "solaris|Sun Solaris|SunOS 5.6 workstation|Palette: navy-on-blue, Shader: retro-crt"
        "irix|SGI IRIX|Silicon Graphics workstation|Palette: indigo-blue, Shader: retro-crt"
        "next|NeXT|NeXTSTEP grayscale|Palette: gray/white, Shader: bloom"
        "CAT|BBS & Online (1985-1997)"
        "bbs|BBS Terminal|Dial-up with ANSI art & door games|Palette: DOS gray, Shader: retro-crt"
        "CAT|Modern (1995-2000)"
        "linux|Early Linux|Slackware, LILO, kernel 2.0|Palette: gray/white, No shader"
        "win98|Windows 98|DOS prompt under Windows|Palette: win98 gray, No shader"
    )

    local total_items=${#ERA_LIST[@]}

    # Build parallel arrays for navigation (era-only items, skipping CAT lines)
    # nav_indices[i] = index into ERA_LIST for the i-th selectable era
    local nav_indices=()
    local ni=0
    local idx=0
    while [ $idx -lt $total_items ]; do
        local entry="${ERA_LIST[$idx]}"
        local entry_type="${entry%%|*}"
        if [ "$entry_type" != "CAT" ]; then
            nav_indices[$ni]=$idx
            ni=$(( ni + 1 ))
        fi
        idx=$(( idx + 1 ))
    done
    local total_nav=${#nav_indices[@]}   # total selectable eras

    # ---- State ----
    local cursor=0          # index into nav_indices (which era is selected)
    local scroll=0          # first visible row index into ERA_LIST
    local VIEWPORT=15       # visible rows in the list area
    local search_mode=0     # 1 when / search is active
    local search_str=""     # current search filter string
    local interactive
    interactive=$(read_matrix_conf "MATRIX_ERA_INTERACTIVE" "false")
    local current_era
    current_era=$(read_matrix_conf "MATRIX_ERA" "")

    # Helper: get field N (1-based) from a pipe-delimited string
    _era_field() {
        local str="$1" n="$2"
        local i=1 part=""
        local IFS="|"
        for part in $str; do
            [ $i -eq $n ] && { echo "$part"; return; }
            i=$(( i + 1 ))
        done
        echo ""
    }

    # Helper: check if era entry matches search string (case-insensitive naive match)
    _era_matches() {
        local entry="$1" needle="$2"
        [ -z "$needle" ] && { echo "1"; return; }
        local lower_entry lower_needle
        # Bash 3.2 compatible lower: use tr
        lower_entry=$(echo "$entry" | tr 'ABCDEFGHIJKLMNOPQRSTUVWXYZ' 'abcdefghijklmnopqrstuvwxyz')
        lower_needle=$(echo "$needle" | tr 'ABCDEFGHIJKLMNOPQRSTUVWXYZ' 'abcdefghijklmnopqrstuvwxyz')
        case "$lower_entry" in
            *"$lower_needle"*) echo "1" ;;
            *) echo "0" ;;
        esac
    }

    # Rebuild nav_indices filtering by search_str
    _rebuild_nav() {
        nav_indices=()
        ni=0
        idx=0
        while [ $idx -lt $total_items ]; do
            local entry="${ERA_LIST[$idx]}"
            local etype="${entry%%|*}"
            if [ "$etype" != "CAT" ]; then
                local match
                match=$(_era_matches "$entry" "$search_str")
                if [ "$match" = "1" ]; then
                    nav_indices[$ni]=$idx
                    ni=$(( ni + 1 ))
                fi
            fi
            idx=$(( idx + 1 ))
        done
        total_nav=${#nav_indices[@]}
        # clamp cursor
        [ $total_nav -eq 0 ] && cursor=0
        [ $cursor -ge $total_nav ] && cursor=$(( total_nav > 0 ? total_nav - 1 : 0 ))
    }

    # Ensure the selected cursor row is visible; adjust scroll if needed.
    # We scroll over ERA_LIST rows, so we need to find the ERA_LIST index of
    # the current cursor and make sure it falls in [scroll, scroll+VIEWPORT).
    _ensure_visible() {
        [ $total_nav -eq 0 ] && return
        local era_row=${nav_indices[$cursor]}
        if [ $era_row -lt $scroll ]; then
            scroll=$era_row
        elif [ $era_row -ge $(( scroll + VIEWPORT )) ]; then
            scroll=$(( era_row - VIEWPORT + 1 ))
        fi
        # Clamp scroll to valid range
        local max_scroll=$(( total_items - VIEWPORT ))
        [ $max_scroll -lt 0 ] && max_scroll=0
        [ $scroll -gt $max_scroll ] && scroll=$max_scroll
        [ $scroll -lt 0 ] && scroll=0
    }

    # ---- Scrollbar helpers ----
    # Returns the scrollbar character for a given viewport row (0-based).
    # Sets global _SB_CHAR.
    _scrollbar_char() {
        local vrow="$1"
        local rows=$VIEWPORT
        local track=$(( rows - 2 ))   # rows between top arrow and bottom arrow

        # If all content fits in the viewport, no thumb needed — show track
        if [ $total_items -le $VIEWPORT ]; then
            case $vrow in
                0)              _SB_CHAR="▲" ;;
                $(( rows-1 )))  _SB_CHAR="▼" ;;
                *)              _SB_CHAR="│" ;;
            esac
            return
        fi

        # thumb_size in track rows (min 1)
        local thumb_size=$(( VIEWPORT * track / total_items ))
        [ $thumb_size -lt 1 ] && thumb_size=1

        # thumb_start position within track (0-based)
        local max_scroll=$(( total_items - VIEWPORT ))
        local thumb_start=0
        if [ $max_scroll -gt 0 ]; then
            thumb_start=$(( scroll * (track - thumb_size) / max_scroll ))
        fi
        local thumb_end=$(( thumb_start + thumb_size - 1 ))

        case $vrow in
            0)             _SB_CHAR="▲" ;;
            $(( rows-1 ))) _SB_CHAR="▼" ;;
            *)
                local track_row=$(( vrow - 1 ))
                if [ $track_row -ge $thumb_start ] && [ $track_row -le $thumb_end ]; then
                    _SB_CHAR="█"
                else
                    _SB_CHAR="│"
                fi
                ;;
        esac
    }

    # ---- Render one list row at a specific terminal row offset from top of box ----
    # Arguments: viewport_row (0-based within the list area)
    # Uses: scroll, cursor, nav_indices, ERA_LIST, VIEWPORT
    # terminal_row_base is set externally before calling
    _render_list_row() {
        local vrow="$1"
        local list_idx=$(( scroll + vrow ))

        # Scrollbar char for this row
        _SB_CHAR="│"
        _scrollbar_char $vrow

        # Content area width: BOX_W-2 inner, minus 1 for scrollbar = BOX_W-3
        # BOX_W=62 → inner=60 → content=59
        local content_w=$(( BOX_W - 3 ))

        local line_content=""
        local line_color="$GREEN"
        local is_selected=0

        if [ $list_idx -lt $total_items ]; then
            local entry="${ERA_LIST[$list_idx]}"
            local etype="${entry%%|*}"

            if [ "$etype" = "CAT" ]; then
                # Category header
                local cat_label
                cat_label=$(_era_field "$entry" 2)
                # Format: "── Label ──────────"
                local prefix=" ── "
                local suffix_space=$(( content_w - ${#prefix} - ${#cat_label} - 1 ))
                [ $suffix_space -lt 2 ] && suffix_space=2
                local dashes=""
                local di=0
                while [ $di -lt $suffix_space ]; do
                    dashes="${dashes}─"
                    di=$(( di + 1 ))
                done
                line_content="${prefix}${cat_label} ${dashes}"
                line_color="$YELLOW"
            else
                # Era row — check if it's currently selected in nav
                local era_id
                era_id=$(_era_field "$entry" 1)
                local name
                name=$(_era_field "$entry" 2)
                local desc
                desc=$(_era_field "$entry" 3)

                # Is this nav cursor?
                if [ $total_nav -gt 0 ] && [ ${nav_indices[$cursor]} -eq $list_idx ]; then
                    is_selected=1
                fi

                # Marker for active era
                local marker="  "
                [ "$era_id" = "$current_era" ] && marker="* "

                # Format: "  [>] Name           desc"
                # cursor indicator is 3 chars: "> " or "  "
                local cursor_indicator="  "
                [ $is_selected -eq 1 ] && cursor_indicator="> "

                # Name column: left-aligned in 22 chars, desc fills the rest
                local name_w=22
                local desc_w=$(( content_w - ${#marker} - ${#cursor_indicator} - name_w - 1 ))
                [ $desc_w -lt 0 ] && desc_w=0

                # Truncate if needed
                local name_trunc="$name"
                if [ ${#name} -gt $name_w ]; then
                    name_trunc="${name:0:$(( name_w - 1 ))}…"
                fi
                local desc_trunc="$desc"
                if [ ${#desc} -gt $desc_w ]; then
                    desc_trunc="${desc:0:$(( desc_w - 1 ))}…"
                fi

                # Pad name to name_w
                local name_padded
                printf -v name_padded "%-*s" $name_w "$name_trunc"
                # Pad desc to desc_w
                local desc_padded
                printf -v desc_padded "%-*s" $desc_w "$desc_trunc"

                line_content="${marker}${cursor_indicator}${name_padded} ${desc_padded}"
            fi
        fi
        # Pad/truncate to content_w
        local padded_content
        printf -v padded_content "%-*s" $content_w "$line_content"
        padded_content="${padded_content:0:$content_w}"

        # Move cursor to the correct terminal row and render
        local trow=$(( _BROWSER_LIST_TOP + vrow ))
        tput cup $trow $_BROWSER_LEFT_COL

        if [ $is_selected -eq 1 ]; then
            printf "${DIM}║${NC}${INVERT}${line_color}%s${NC}${DIM}%s║${NC}" "$padded_content" "$_SB_CHAR"
        elif [ "$line_color" = "$YELLOW" ]; then
            printf "${DIM}║${NC}${YELLOW}%s${NC}${DIM}%s║${NC}" "$padded_content" "$_SB_CHAR"
        else
            printf "${DIM}║${NC}${GREEN}%s${NC}${DIM}%s║${NC}" "$padded_content" "$_SB_CHAR"
        fi
    }

    # ---- Render the detail panel (2 lines at bottom of box) ----
    _render_detail() {
        local detail_line1="" detail_line2=""
        if [ $total_nav -gt 0 ]; then
            local entry="${ERA_LIST[${nav_indices[$cursor]}]}"
            local era_id
            era_id=$(_era_field "$entry" 1)
            local name
            name=$(_era_field "$entry" 2)
            local detail
            detail=$(_era_field "$entry" 4)
            detail_line1="${name} — ${detail}"
            detail_line2="Press Enter to apply this era"
        else
            detail_line1="No eras match your search."
            detail_line2="Press Esc to clear the filter."
        fi

        local inner=$(( BOX_W - 2 ))

        tput cup $_BROWSER_DETAIL1_ROW $_BROWSER_LEFT_COL
        local d1_trunc="${detail_line1:0:$(( inner - 2 ))}"
        printf "${DIM}║${NC}${CYAN}  %-*s${NC}${DIM}║${NC}" $(( inner - 2 )) "$d1_trunc"

        tput cup $_BROWSER_DETAIL2_ROW $_BROWSER_LEFT_COL
        local d2_trunc="${detail_line2:0:$(( inner - 2 ))}"
        printf "${DIM}║${NC}${DIM}  %-*s${NC}${DIM}║${NC}" $(( inner - 2 )) "$d2_trunc"
    }

    # ---- Full screen draw ----
    _draw_browser_full() {
        COLS=$(get_cols)
        _BROWSER_LEFT_COL=$(( (COLS - BOX_W) / 2 ))
        [ $_BROWSER_LEFT_COL -lt 0 ] && _BROWSER_LEFT_COL=0

        clear
        echo ""  # blank line before box

        # Calculate starting terminal row (after echo "")
        # We use tput lines for terminal height; the box starts at row 1 (0-indexed after clear+echo)
        _BROWSER_BOX_TOP=1

        # Render the static chrome (header, separators, footer)
        # We print the full box top-to-bottom, then will overwrite list rows in place.
        local current_era_label=""
        [ -n "$current_era" ] && current_era_label="Current: $(era_display_name "$current_era")"

        local interactive_label="[$(on_off $interactive)]"

        box_top
        box_center "[ TERMINAL ERAS - TIME MACHINE ]" "$BRIGHT"
        box_center "\"Choose your decade.\"" "$DIM"
        if [ -n "$current_era_label" ]; then
            box_center "$current_era_label" "$CYAN"
            box_sep
        else
            box_sep
        fi

        # Record where list area starts (current row = after sep)
        # tput lines gives terminal height; we count printed lines.
        # After clear: row 0. echo "" → row 1. box_top → row 2.
        # box_center x3 (or x2) + box_sep...
        # Instead, we use tput cup to figure out current row by counting:
        # Header rows:
        #   row 0: blank (echo "")
        #   row 1: box_top
        #   row 2: [ TERMINAL ERAS... ]
        #   row 3: "Choose your decade."
        #   row 4: Current: ... (if present) OR box_sep
        #   row 5: box_sep (if current era shown)
        if [ -n "$current_era_label" ]; then
            _BROWSER_LIST_TOP=6
        else
            _BROWSER_LIST_TOP=5
        fi

        # Print VIEWPORT empty lines for the list area (placeholders)
        local vr=0
        while [ $vr -lt $VIEWPORT ]; do
            pad; printf "${DIM}║${NC}%-*s${DIM}║${NC}\n" $(( BOX_W - 2 )) ""
            vr=$(( vr + 1 ))
        done

        # Separator + key help + detail
        box_thin
        if [ $search_mode -eq 1 ]; then
            box_kv "Search: ${search_str}_" "" "$CYAN" "$NC"
        else
            box_kv "[↑/↓] Navigate  [Enter] Apply  [i] Interactive ${interactive_label}" "" "$DIM" "$BRIGHT"
        fi
        box_kv "[m] Matrix  [/] Search  [Esc] Back" "" "$DIM" "$NC"
        box_sep

        # Detail rows
        pad; printf "${DIM}║${NC}%-*s${DIM}║${NC}\n" $(( BOX_W - 2 )) ""
        pad; printf "${DIM}║${NC}%-*s${DIM}║${NC}\n" $(( BOX_W - 2 )) ""

        box_bottom

        # Key help area top is list_top + VIEWPORT + 1 (thin sep)
        local help_top=$(( _BROWSER_LIST_TOP + VIEWPORT + 1 ))
        _BROWSER_HELP1_ROW=$help_top
        _BROWSER_HELP2_ROW=$(( help_top + 1 ))
        _BROWSER_SEP2_ROW=$(( help_top + 2 ))
        _BROWSER_DETAIL1_ROW=$(( help_top + 3 ))
        _BROWSER_DETAIL2_ROW=$(( help_top + 4 ))

        # Now fill in all list rows
        vr=0
        while [ $vr -lt $VIEWPORT ]; do
            _render_list_row $vr
            vr=$(( vr + 1 ))
        done

        _render_detail

        # Park cursor at bottom
        tput cup $(( _BROWSER_DETAIL2_ROW + 2 )) 0
    }

    # ---- Redraw only changed rows (list + detail) ----
    _redraw_list() {
        local vr=0
        while [ $vr -lt $VIEWPORT ]; do
            _render_list_row $vr
            vr=$(( vr + 1 ))
        done
        _render_detail
        tput cup $(( _BROWSER_DETAIL2_ROW + 2 )) 0
    }

    # ---- Redraw just the help line (for interactive toggle / search mode) ----
    _redraw_help() {
        local interactive_label="[$(on_off $interactive)]"
        local inner=$(( BOX_W - 2 ))
        tput cup $_BROWSER_HELP1_ROW $_BROWSER_LEFT_COL
        if [ $search_mode -eq 1 ]; then
            local search_display="Search: ${search_str}_"
            printf "${DIM}║${NC}${CYAN}  %-*s${NC}${DIM}║${NC}" $(( inner - 2 )) "$search_display"
        else
            local help1="[↑/↓] Navigate  [Enter] Apply  [i] Interactive ${interactive_label}"
            printf "${DIM}║${NC}${DIM}  %-*s${NC}${DIM}║${NC}" $(( inner - 2 )) "$help1"
        fi
    }

    # ---- Initialize ----
    _BROWSER_LEFT_COL=0
    _BROWSER_LIST_TOP=5
    _BROWSER_HELP1_ROW=0
    _BROWSER_HELP2_ROW=0
    _BROWSER_SEP2_ROW=0
    _BROWSER_DETAIL1_ROW=0
    _BROWSER_DETAIL2_ROW=0
    _SB_CHAR="│"

    _ensure_visible
    _draw_browser_full

    # ---- Input loop ----
    while true; do
        local key="" key2=""
        read -rsn1 key

        if [ $search_mode -eq 1 ]; then
            # In search mode: printable chars add to filter, Esc clears, Backspace removes
            case "$key" in
                $'\x1b')
                    # Could be escape or arrow — peek for bracket
                    local _c1="" _c2=""
                    read -rsn1 -t 1 _c1
                    read -rsn1 -t 1 _c2
                    key2="${_c1}${_c2}"
                    if [ -z "$key2" ]; then
                        # Plain Esc: exit search mode, clear filter
                        search_mode=0
                        search_str=""
                        _rebuild_nav
                        cursor=0
                        scroll=0
                        _ensure_visible
                        _redraw_help
                        _redraw_list
                    else
                        case "$key2" in
                            '[A')
                                [ $cursor -gt 0 ] && cursor=$(( cursor - 1 ))
                                _ensure_visible
                                _redraw_list
                                ;;
                            '[B')
                                [ $cursor -lt $(( total_nav - 1 )) ] && cursor=$(( cursor + 1 ))
                                _ensure_visible
                                _redraw_list
                                ;;
                        esac
                    fi
                    ;;
                $'\x7f'|$'\b')
                    # Backspace
                    if [ ${#search_str} -gt 0 ]; then
                        search_str="${search_str:0:$(( ${#search_str} - 1 ))}"
                        _rebuild_nav
                        _ensure_visible
                        _redraw_help
                        _redraw_list
                    fi
                    ;;
                $'\r'|$'\n')
                    # Enter in search: apply selected era
                    if [ $total_nav -gt 0 ]; then
                        local sel_entry="${ERA_LIST[${nav_indices[$cursor]}]}"
                        local sel_id
                        sel_id=$(_era_field "$sel_entry" 1)
                        apply_era "$sel_id"
                        current_era="$sel_id"
                        search_mode=0
                        search_str=""
                        _rebuild_nav
                        _ensure_visible
                        _draw_browser_full
                    fi
                    ;;
                *)
                    # Accept any single printable character (length=1, not a control char)
                    if [ ${#key} -eq 1 ]; then
                        # Filter out remaining control chars by ASCII range check via printf hex
                        local key_hex
                        key_hex=$(printf '%02x' "'$key" 2>/dev/null) || key_hex="00"
                        # Accept 0x20 (space) through 0x7e (~)
                        local key_dec=$(( 16#$key_hex ))
                        if [ $key_dec -ge 32 ] && [ $key_dec -le 126 ]; then
                            search_str="${search_str}${key}"
                            _rebuild_nav
                            cursor=0
                            scroll=0
                            _ensure_visible
                            _redraw_help
                            _redraw_list
                        fi
                    fi
                    ;;
            esac
            continue
        fi

        # Normal (non-search) mode
        case "$key" in
            $'\x1b')
                local _c1="" _c2=""
                read -rsn1 -t 1 _c1
                read -rsn1 -t 1 _c2
                key2="${_c1}${_c2}"
                if [ -z "$key2" ]; then
                    # Plain Esc — go back to presets
                    current_screen="presets"
                    return
                fi
                case "$key2" in
                    '[A'|'OA')
                        # Up arrow
                        if [ $cursor -gt 0 ]; then
                            cursor=$(( cursor - 1 ))
                            _ensure_visible
                            _redraw_list
                        fi
                        ;;
                    '[B'|'OB')
                        # Down arrow
                        if [ $cursor -lt $(( total_nav - 1 )) ]; then
                            cursor=$(( cursor + 1 ))
                            _ensure_visible
                            _redraw_list
                        fi
                        ;;
                esac
                ;;
            k|K)
                if [ $cursor -gt 0 ]; then
                    cursor=$(( cursor - 1 ))
                    _ensure_visible
                    _redraw_list
                fi
                ;;
            j|J)
                if [ $cursor -lt $(( total_nav - 1 )) ]; then
                    cursor=$(( cursor + 1 ))
                    _ensure_visible
                    _redraw_list
                fi
                ;;
            $'\r'|$'\n')
                if [ $total_nav -gt 0 ]; then
                    local sel_entry="${ERA_LIST[${nav_indices[$cursor]}]}"
                    local sel_id
                    sel_id=$(_era_field "$sel_entry" 1)
                    apply_era "$sel_id"
                    current_era="$sel_id"
                    _draw_browser_full
                fi
                ;;
            i|I)
                local cur_int
                cur_int=$(read_matrix_conf "MATRIX_ERA_INTERACTIVE" "false")
                write_matrix_conf "MATRIX_ERA_INTERACTIVE" "$(toggle "$cur_int")"
                interactive="$(toggle "$cur_int")"
                _redraw_help
                ;;
            m|M)
                apply_era "matrix"
                current_era=""
                _draw_browser_full
                ;;
            '/')
                search_mode=1
                search_str=""
                _rebuild_nav
                _redraw_help
                ;;
            x|X|q|Q)
                current_screen="presets"
                return
                ;;
        esac
    done
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
    local scrollbar=$(read_ghostty_conf "scrollbar" "never")
    box_kv "o) Scrollbar" "[$scrollbar]"
    box_empty

    # -- HEADER --
    box_thin
    box_center "HEADER & QUOTES" "$YELLOW"
    box_kv "g) Show Header" "[$(on_off $header)]"
    box_kv "h) Show Quote" "[$(on_off $quote)]"
    box_kv "i) Show System Info" "[$(on_off $sysinfo)]"
    box_empty

    # -- CRT EFFECTS (only shown for crt-full shader) --
    if [ "$shader" = "crt-full" ]; then
        local crt_shader="${SHADER_DIR}/crt-full.glsl"
        local noise_on=$(read_shader_define "$crt_shader" "ENABLE_NOISE")
        local jitter_on=$(read_shader_define "$crt_shader" "ENABLE_JITTER")
        local interlace_on=$(read_shader_define "$crt_shader" "ENABLE_INTERLACE")
        local halation_on=$(read_shader_define "$crt_shader" "ENABLE_HALATION")

        box_thin
        box_center "CRT EFFECTS (crt-full)" "$YELLOW"
        box_kv "j) Static Noise" "[$(on_off $noise_on)]"
        box_kv "k) Horizontal Jitter" "[$(on_off $jitter_on)]"
        box_kv "l) Interlacing" "[$(on_off $interlace_on)]"
        box_kv "n) Enhanced Halation" "[$(on_off $halation_on)]"
        box_empty
    fi

    # -- SHUTDOWN --
    local shutdown=$(read_matrix_conf "MATRIX_SHUTDOWN_ANIMATION" "true")
    local shutdown_exit=$(read_matrix_conf "MATRIX_SHUTDOWN_ON_EXIT" "false")

    box_thin
    box_center "SHUTDOWN ANIMATION" "$YELLOW"
    box_kv "s) CRT Shutdown Effect" "[$(on_off $shutdown)]"
    box_kv "t) Auto-trigger on exit" "[$(on_off $shutdown_exit)]"
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
            e|E) current_screen="eras" ;;
            c|C) current_screen="custom" ;;
            q|Q|$'\e') break ;;
            *) STATUS_MSG="Press 1-5 for presets, e for eras, c for custom, q to quit" ;;
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
            o|O)
                cur=$(read_ghostty_conf "scrollbar" "never")
                if [ "$cur" = "system" ]; then
                    write_ghostty_conf "scrollbar" "never"
                    STATUS_MSG="Scrollbar: never -- restart Ghostty"
                else
                    write_ghostty_conf "scrollbar" "system"
                    STATUS_MSG="Scrollbar: system -- restart Ghostty"
                fi
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
            j|J)
                local crt_shader="${SHADER_DIR}/crt-full.glsl"
                toggle_shader_define "$crt_shader" "ENABLE_NOISE"
                local new_state=$(read_shader_define "$crt_shader" "ENABLE_NOISE")
                write_matrix_conf "MATRIX_CRT_NOISE" "$new_state"
                STATUS_MSG="Static noise: $(on_off $new_state)"
                ;;
            k|K)
                local crt_shader="${SHADER_DIR}/crt-full.glsl"
                toggle_shader_define "$crt_shader" "ENABLE_JITTER"
                local new_state=$(read_shader_define "$crt_shader" "ENABLE_JITTER")
                write_matrix_conf "MATRIX_CRT_JITTER" "$new_state"
                STATUS_MSG="Horizontal jitter: $(on_off $new_state)"
                ;;
            l|L)
                local crt_shader="${SHADER_DIR}/crt-full.glsl"
                toggle_shader_define "$crt_shader" "ENABLE_INTERLACE"
                local new_state=$(read_shader_define "$crt_shader" "ENABLE_INTERLACE")
                write_matrix_conf "MATRIX_CRT_INTERLACE" "$new_state"
                STATUS_MSG="Interlacing: $(on_off $new_state)"
                ;;
            n|N)
                local crt_shader="${SHADER_DIR}/crt-full.glsl"
                toggle_shader_define "$crt_shader" "ENABLE_HALATION"
                local new_state=$(read_shader_define "$crt_shader" "ENABLE_HALATION")
                write_matrix_conf "MATRIX_CRT_HALATION" "$new_state"
                STATUS_MSG="Enhanced halation: $(on_off $new_state)"
                ;;
            s|S)
                cur=$(read_matrix_conf "MATRIX_SHUTDOWN_ANIMATION" "true")
                write_matrix_conf "MATRIX_SHUTDOWN_ANIMATION" "$(toggle "$cur")"
                STATUS_MSG="CRT shutdown: $(on_off $(toggle "$cur"))"
                ;;
            t|T)
                cur=$(read_matrix_conf "MATRIX_SHUTDOWN_ON_EXIT" "false")
                write_matrix_conf "MATRIX_SHUTDOWN_ON_EXIT" "$(toggle "$cur")"
                STATUS_MSG="Auto-shutdown on exit: $(on_off $(toggle "$cur"))"
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

    # ====================
    # ERAS BROWSER SCREEN
    # ====================
    eras)
        screen_era_browser
        # screen_era_browser runs its own input loop and sets current_screen="presets" on exit
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
