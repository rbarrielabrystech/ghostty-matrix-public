#!/usr/bin/env bash
# era-bbs.sh - BBS Terminal Simulator (circa 1994)
# Authentic dial-up bulletin board experience.
source "$(dirname "$0")/era-lib.sh"
era_setup_traps

# --- State ---
declare -a MSG_POSTS=()
PLAYER_HANDLE=""
TIME_START=$(date +%s)
DRAGON_GOLD=0

# --- Colors ---
c_cyan=$'\033[1;36m'
c_yellow=$'\033[1;33m'
c_white=$'\033[1;37m'
c_green=$'\033[1;32m'
c_red=$'\033[1;31m'
c_magenta=$'\033[1;35m'
c_blue=$'\033[1;34m'
c_dim=$'\033[2m'
c_reset=$'\033[0m'

# --- Pre-written messages ---
MSG_GENERAL1="From: CyberPunk42      Date: 03/14/94  18:22
Subj: New BBS list
Anyone got the latest NorthEast BBS list? My copy is from
January and half the numbers are dead already."

MSG_GENERAL2="From: DarkStar          Date: 03/15/94  09:41
Subj: Re: New BBS list
I uploaded NEBBS0394.ZIP to file area 2. It's got about
1,200 boards. Most tested last week."

MSG_PROG1="From: ByteWizard        Date: 03/12/94  22:07
Subj: Turbo Pascal vs C
Been coding in TP7 for two years but everyone says learn C.
Is Borland C++ 3.1 any good? Turbo C seems limited."

MSG_WAREZ1="From: PhReAk_0          Date: 03/16/94  01:33
Subj: DOOM v1.2 patch
The id guys released v1.2 patch. Fixes the savegame bug.
FTP from infant2.sphs.indiana.edu - /pub/doom/"

# --- File listings ---
declare -a FILE_NAMES=("DOOM12.ZIP" "PKZIP204.EXE" "ANSI.COM" "LORD41.ZIP")
declare -a FILE_SIZES=("2,341,928" "  202,574" "   29,440" "  412,086")
declare -a FILE_DESCS=(
    "DOOM v1.2 Shareware - id Software"
    "PKZIP 2.04g - File compression utility"
    "ANSI.COM - ANSI art viewer/animator"
    "Legend of the Red Dragon v4.1 - Door game"
)

# --- Dragon's Lair game state ---
DL_ROOM=0
DL_GOLD=0
DL_HAS_SWORD=false
DL_DRAGON_DEAD=false

# --- Helpers ---
bbs_pause() { sleep "${1:-0.8}"; }

bbs_prompt() {
    printf "%s" "${c_cyan}[${c_yellow}$1${c_cyan}]: ${c_white}"
    local input=""
    read -r input
    printf "%s" "$c_reset"
    echo "$input"
}

time_on() {
    local now elapsed
    now=$(date +%s)
    elapsed=$(( (now - TIME_START) / 60 ))
    echo "$elapsed"
}

# --- Modem Connect ---
modem_connect() {
    era_clear
    era_hide_cursor
    printf "%s" "$c_green"
    slow_type "ATDT 555-0199" 0.06
    echo
    bbs_pause 1.2
    echo "${c_dim}RING...${c_reset}"
    bbs_pause 1.5
    echo "${c_dim}RING...${c_reset}"
    bbs_pause 1.0
    printf "%s" "${c_white}"
    slow_type "CONNECT 14400/ARQ/V.32bis/LAPM" 0.03
    echo
    bbs_pause 1.5
}

# --- ANSI Welcome ---
show_welcome() {
    era_clear
    printf "%s" "$c_cyan"
    echo "   ${c_blue}╔══════════════════════════════════════╗"
    echo "   ║${c_magenta}   ████  █  █  ████  ████  ████  ██  ${c_blue}║"
    echo "   ║${c_magenta}   █  █  █  █  █     █  █  █     █ █ ${c_blue}║"
    echo "   ║${c_magenta}   ████  ████  ████  ████  ████  ██  ${c_blue}║"
    echo "   ║${c_magenta}   █     █  █  █     █ █   █     █ █ ${c_blue}║"
    echo "   ║${c_magenta}   █     █  █  ████  █  █  ████  ██  ${c_blue}║"
    echo "   ║${c_blue}                                      ║"
    echo "   ║  ${c_yellow}   THE PHANTOM'S DOMAIN BBS ${c_blue}        ║"
    echo "   ║  ${c_green}      Est. 1994 - Node 1${c_blue}            ║"
    echo "   ║  ${c_cyan}    SysOp: The Phantom${c_blue}               ║"
    echo "   ║  ${c_dim}   USR Sportster 14.4 Dual Std${c_blue}      ║"
    echo "   ╚══════════════════════════════════════╝${c_reset}"
    echo
}

# --- Login ---
do_login() {
    printf "%s" "${c_green}"
    echo "Enter your handle: "
    printf "%s" "${c_white}"
    read -r PLAYER_HANDLE
    [ -z "$PLAYER_HANDLE" ] && PLAYER_HANDLE="NewUser"
    printf "%sPassword: %s" "$c_green" "$c_white"
    read -rs _password
    echo
    echo
    slow_type "${c_green}Checking user file..." 0.04
    echo
    bbs_pause 0.8
    echo "${c_yellow}Welcome back, ${c_white}${PLAYER_HANDLE}${c_yellow}!${c_reset}"
    echo "${c_dim}Last caller: CyberPunk42 from Area Code 212${c_reset}"
    local elapsed
    elapsed=$(time_on)
    echo "${c_cyan}Time on: ${elapsed} min  Time left: 60 min${c_reset}"
    echo
    printf "%s" "${c_dim}Press any key...${c_reset}"
    era_getchar >/dev/null
}

# --- Main Menu ---
main_menu() {
    while true; do
        era_clear
        era_show_cursor
        local elapsed
        elapsed=$(time_on)
        echo "${c_blue}═══════════════════════════════════════${c_reset}"
        echo "${c_yellow}  THE PHANTOM'S DOMAIN - MAIN MENU${c_reset}"
        echo "${c_blue}═══════════════════════════════════════${c_reset}"
        echo
        echo "  ${c_cyan}[${c_white}M${c_cyan}]${c_green} Message Bases${c_reset}"
        echo "  ${c_cyan}[${c_white}F${c_cyan}]${c_green} File Areas${c_reset}"
        echo "  ${c_cyan}[${c_white}D${c_cyan}]${c_green} Door Games${c_reset}"
        echo "  ${c_cyan}[${c_white}W${c_cyan}]${c_green} Who's Online${c_reset}"
        echo "  ${c_cyan}[${c_white}S${c_cyan}]${c_green} Stats${c_reset}"
        echo "  ${c_cyan}[${c_white}C${c_cyan}]${c_green} Chat with SysOp${c_reset}"
        echo "  ${c_cyan}[${c_white}G${c_cyan}]${c_red} Goodbye (Logoff)${c_reset}"
        echo
        echo "${c_dim}  Time on: ${elapsed} min  Time left: $((60 - elapsed)) min${c_reset}"
        echo
        local choice
        choice=$(bbs_prompt "Command")
        case "$(_upper "$choice")" in
            M) message_bases ;;
            F) file_areas ;;
            D) door_games ;;
            W) whos_online ;;
            S) show_stats ;;
            C) chat_sysop ;;
            G) do_logoff; return ;;
        esac
    done
}

# --- Message Bases ---
message_bases() {
    while true; do
        era_clear
        echo "${c_yellow}  MESSAGE BASES${c_reset}"
        echo "${c_blue}═══════════════════════════════════════${c_reset}"
        echo "  ${c_cyan}[${c_white}1${c_cyan}]${c_green} General Discussion    (14 msgs)${c_reset}"
        echo "  ${c_cyan}[${c_white}2${c_cyan}]${c_green} Programming           ( 8 msgs)${c_reset}"
        echo "  ${c_cyan}[${c_white}3${c_cyan}]${c_green} Warez/Trading         ( 6 msgs)${c_reset}"
        echo "  ${c_cyan}[${c_white}4${c_cyan}]${c_green} Trading Post          ( 3 msgs)${c_reset}"
        echo "  ${c_cyan}[${c_white}P${c_cyan}]${c_green} Post a Message${c_reset}"
        echo "  ${c_cyan}[${c_white}Q${c_cyan}]${c_red} Return to Main Menu${c_reset}"
        echo
        local choice
        choice=$(bbs_prompt "Area")
        case "$(_upper "$choice")" in
            1) read_messages "General Discussion" "$MSG_GENERAL1" "$MSG_GENERAL2" ;;
            2) read_messages "Programming" "$MSG_PROG1" ;;
            3) read_messages "Warez/Trading" "$MSG_WAREZ1" ;;
            4) read_messages "Trading Post" ;;
            P) post_message ;;
            Q) return ;;
        esac
    done
}

read_messages() {
    local area="$1"; shift
    era_clear
    echo "${c_yellow}  $area${c_reset}"
    echo "${c_blue}───────────────────────────────────────${c_reset}"
    if [ $# -eq 0 ] && [ ${#MSG_POSTS[@]} -eq 0 ]; then
        echo "${c_dim}  No messages in this area.${c_reset}"
    else
        local num=1
        for msg in "$@"; do
            echo "${c_green}--- Message $num ---${c_reset}"
            echo "${c_white}$msg${c_reset}"
            echo
            num=$((num + 1))
        done
        for msg in "${MSG_POSTS[@]}"; do
            echo "${c_green}--- Message $num ---${c_reset}"
            echo "${c_white}$msg${c_reset}"
            echo
            num=$((num + 1))
        done
    fi
    printf "%s" "${c_dim}Press any key...${c_reset}"
    era_getchar >/dev/null
}

post_message() {
    era_clear
    echo "${c_yellow}  POST A MESSAGE${c_reset}"
    echo "${c_blue}───────────────────────────────────────${c_reset}"
    printf "%s" "${c_green}Subject: ${c_white}"
    local subj=""
    read -r subj
    printf "%s" "${c_green}Message (one line): ${c_white}"
    local body=""
    read -r body
    printf "%s" "$c_reset"
    if [ -n "$subj" ] && [ -n "$body" ]; then
        local ts
        ts=$(date '+%m/%d/%y  %H:%M')
        MSG_POSTS+=("From: ${PLAYER_HANDLE}$(printf '%*s' $((16 - ${#PLAYER_HANDLE})) '')Date: $ts
Subj: $subj
$body")
        echo "${c_green}Message saved!${c_reset}"
    else
        echo "${c_red}Aborted.${c_reset}"
    fi
    bbs_pause
}

# --- File Areas ---
file_areas() {
    while true; do
        era_clear
        echo "${c_yellow}  FILE AREAS${c_reset}"
        echo "${c_blue}═══════════════════════════════════════════════════════════${c_reset}"
        printf "  ${c_cyan}%-4s %-15s %12s  %-s${c_reset}\n" "#" "Filename" "Size" "Description"
        echo "${c_blue}───────────────────────────────────────────────────────────${c_reset}"
        for i in "${!FILE_NAMES[@]}"; do
            printf "  ${c_white}%-4s ${c_green}%-15s ${c_yellow}%12s  ${c_dim}%-s${c_reset}\n" \
                "$((i+1))" "${FILE_NAMES[$i]}" "${FILE_SIZES[$i]}" "${FILE_DESCS[$i]}"
        done
        echo
        echo "  ${c_cyan}[${c_white}1-4${c_cyan}]${c_green} Download file${c_reset}"
        echo "  ${c_cyan}[${c_white}Q${c_cyan}]${c_red}   Return to Main Menu${c_reset}"
        echo
        local choice
        choice=$(bbs_prompt "File #")
        case "$(_upper "$choice")" in
            [1-4]) download_file "$((choice - 1))" ;;
            Q) return ;;
        esac
    done
}

download_file() {
    local idx="$1"
    local fname="${FILE_NAMES[$idx]}"
    local fsize="${FILE_SIZES[$idx]}"
    era_clear
    echo "${c_yellow}  DOWNLOADING: ${c_white}${fname}${c_reset}"
    echo "${c_cyan}  Protocol: Zmodem    Size: ${fsize} bytes${c_reset}"
    echo
    printf "  ${c_green}"
    for i in $(seq 1 40); do
        printf "█"
        # Vary sleep for realism
        sleep 0.$(( RANDOM % 8 + 2 ))
        if (( i % 10 == 0 )); then
            printf " %d%%" $((i * 100 / 40))
        fi
    done
    echo "${c_reset}"
    echo
    echo "  ${c_green}Transfer complete! CRC check passed.${c_reset}"
    printf "%s" "${c_dim}  Press any key...${c_reset}"
    era_getchar >/dev/null
}

# --- Who's Online ---
whos_online() {
    era_clear
    echo "${c_yellow}  WHO'S ONLINE${c_reset}"
    echo "${c_blue}═══════════════════════════════════════${c_reset}"
    printf "  ${c_cyan}%-4s %-16s %-12s %-s${c_reset}\n" "Node" "Handle" "Baud" "Activity"
    echo "${c_blue}───────────────────────────────────────${c_reset}"
    printf "  ${c_white}%-4s ${c_green}%-16s ${c_yellow}%-12s ${c_dim}%-s${c_reset}\n" \
        "1" "$PLAYER_HANDLE" "14400" "Main Menu"
    printf "  ${c_white}%-4s ${c_green}%-16s ${c_yellow}%-12s ${c_dim}%-s${c_reset}\n" \
        "2" "NightOwl" "9600" "File Areas"
    echo
    printf "%s" "${c_dim}Press any key...${c_reset}"
    era_getchar >/dev/null
}

# --- Stats ---
show_stats() {
    era_clear
    echo "${c_yellow}  SYSTEM STATISTICS${c_reset}"
    echo "${c_blue}═══════════════════════════════════════${c_reset}"
    echo "  ${c_cyan}Total Calls  :${c_white} 14,832${c_reset}"
    echo "  ${c_cyan}Total Users  :${c_white} 247${c_reset}"
    echo "  ${c_cyan}Files Online :${c_white} 1,203  (142 MB)${c_reset}"
    echo "  ${c_cyan}Messages     :${c_white} 8,491${c_reset}"
    echo "  ${c_cyan}Doors        :${c_white} 6${c_reset}"
    echo "  ${c_cyan}Nodes        :${c_white} 2${c_reset}"
    echo "  ${c_cyan}BBS Software :${c_white} RemoteAccess 2.50${c_reset}"
    echo "  ${c_cyan}FidoNet Addr :${c_white} 1:234/567${c_reset}"
    echo
    printf "%s" "${c_dim}Press any key...${c_reset}"
    era_getchar >/dev/null
}

# --- Chat with SysOp ---
chat_sysop() {
    era_clear
    echo "${c_yellow}  CHAT WITH SYSOP${c_reset}"
    echo "${c_blue}═══════════════════════════════════════${c_reset}"
    slow_type "${c_cyan}Paging SysOp" 0.06
    for i in 1 2 3 4 5; do
        printf "."
        sleep 0.6
    done
    echo "${c_reset}"
    echo
    echo "  ${c_red}SysOp is not available.${c_reset}"
    echo "  ${c_dim}Leave a message in the General area.${c_reset}"
    echo
    printf "%s" "${c_dim}Press any key...${c_reset}"
    era_getchar >/dev/null
}

# --- Door Games ---
door_games() {
    era_clear
    echo "${c_yellow}  DOOR GAMES${c_reset}"
    echo "${c_blue}═══════════════════════════════════════${c_reset}"
    echo "  ${c_cyan}[${c_white}1${c_cyan}]${c_green} Dragon's Lair - Text Adventure${c_reset}"
    echo "  ${c_cyan}[${c_white}Q${c_cyan}]${c_red} Return to Main Menu${c_reset}"
    echo
    local choice
    choice=$(bbs_prompt "Door")
    case "$(_upper "$choice")" in
        1) dragons_lair ;;
    esac
}

# --- Dragon's Lair ---
dragons_lair() {
    DL_ROOM=0; DL_GOLD=0; DL_HAS_SWORD=false; DL_DRAGON_DEAD=false
    era_clear
    echo "${c_magenta}╔══════════════════════════════════════╗${c_reset}"
    echo "${c_magenta}║      DRAGON'S LAIR v2.1              ║${c_reset}"
    echo "${c_magenta}║   A Text Adventure Door Game         ║${c_reset}"
    echo "${c_magenta}╚══════════════════════════════════════╝${c_reset}"
    echo
    slow_type "${c_dim}Loading door..." 0.04
    echo
    bbs_pause
    while true; do
        dl_show_room
        local cmd
        cmd=$(bbs_prompt "N/S/E/W/Q")
        case "$(_upper "$cmd")" in
            N) dl_move 0 ;;
            S) dl_move 1 ;;
            E) dl_move 2 ;;
            W) dl_move 3 ;;
            Q) echo "${c_yellow}Returning to BBS...${c_reset}"; bbs_pause; return ;;
        esac
    done
}

dl_show_room() {
    echo
    case $DL_ROOM in
        0)  echo "${c_green}-- Entrance Hall --${c_reset}"
            echo "${c_white}You stand in a torchlit stone hall. Cobwebs hang from the"
            echo "ceiling. A cold draft blows from the north passage.${c_reset}"
            echo "${c_dim}Exits: [N]orth  [E]ast${c_reset}"
            ;;
        1)  echo "${c_green}-- Treasure Room --${c_reset}"
            if (( DL_GOLD == 0 )); then
                echo "${c_yellow}Gold coins glitter on the floor! You grab a handful.${c_reset}"
                DL_GOLD=50
                echo "${c_white}+50 gold collected!${c_reset}"
            else
                echo "${c_white}The room is empty. You already took the gold.${c_reset}"
            fi
            echo "${c_dim}Exits: [S]outh${c_reset}"
            ;;
        2)  echo "${c_green}-- Armory --${c_reset}"
            if ! $DL_HAS_SWORD; then
                echo "${c_white}Rusty weapons line the walls. A gleaming sword catches"
                echo "your eye. You take the enchanted blade!${c_reset}"
                DL_HAS_SWORD=true
                echo "${c_cyan}+Enchanted Sword acquired!${c_reset}"
            else
                echo "${c_white}Empty weapon racks. Nothing useful remains.${c_reset}"
            fi
            echo "${c_dim}Exits: [W]est${c_reset}"
            ;;
        3)  echo "${c_green}-- Dragon's Chamber --${c_reset}"
            if $DL_DRAGON_DEAD; then
                echo "${c_white}The dragon's corpse lies still. Victory is yours.${c_reset}"
                echo "${c_dim}Exits: [S]outh  [E]ast${c_reset}"
                return
            fi
            echo "${c_red}A massive red dragon blocks the passage! It breathes fire!${c_reset}"
            echo
            if $DL_HAS_SWORD; then
                echo "${c_cyan}You wield the enchanted sword and strike!${c_reset}"
                bbs_pause
                if (( RANDOM % 100 < 75 )); then
                    echo "${c_green}You have slain the dragon!${c_reset}"
                    DL_DRAGON_DEAD=true
                    DL_GOLD=$((DL_GOLD + 100))
                    echo "${c_yellow}+100 gold from the dragon's hoard!${c_reset}"
                else
                    echo "${c_red}The dragon has defeated you!${c_reset}"
                    echo "${c_dim}You wake up at the entrance...${c_reset}"
                    DL_ROOM=0; bbs_pause; return
                fi
            else
                echo "${c_red}You have no weapon! The dragon has defeated you!${c_reset}"
                echo "${c_dim}You wake up at the entrance...${c_reset}"
                DL_ROOM=0; bbs_pause; return
            fi
            echo "${c_dim}Exits: [S]outh  [E]ast${c_reset}"
            ;;
    esac
    echo "${c_yellow}Gold: ${DL_GOLD}${c_reset}"
}

dl_move() {
    local dir="$1"  # 0=N 1=S 2=E 3=W
    case "${DL_ROOM}:${dir}" in
        0:0) DL_ROOM=3 ;;  # Entrance -> Dragon
        0:2) DL_ROOM=2 ;;  # Entrance -> Armory
        1:1) DL_ROOM=3 ;;  # Treasure -> Dragon (south)
        2:3) DL_ROOM=0 ;;  # Armory -> Entrance
        3:1) DL_ROOM=0 ;;  # Dragon -> Entrance
        3:2) DL_ROOM=1 ;;  # Dragon -> Treasure
        *)   echo "${c_red}You can't go that way.${c_reset}" ;;
    esac
}

# --- Logoff ---
do_logoff() {
    era_clear
    era_hide_cursor
    echo
    slow_type "${c_yellow}Thanks for calling The Phantom's Domain!${c_reset}" 0.04
    echo
    slow_type "${c_cyan}Please call again!${c_reset}" 0.04
    echo
    echo
    bbs_pause 1.5
    printf "%s" "${c_white}"
    slow_type "NO CARRIER" 0.08
    printf "%s" "$c_reset"
    echo
    bbs_pause 2
}

# --- Main ---
main() {
    modem_connect
    show_welcome
    do_login
    main_menu
}

main
