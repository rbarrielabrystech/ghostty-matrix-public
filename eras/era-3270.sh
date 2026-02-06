#!/usr/bin/env bash
# era-3270.sh - IBM 3270 Block-Mode Terminal Simulator
# Authentic TSO/ISPF mainframe experience circa 1990s.
source "$(dirname "$0")/era-lib.sh"
era_setup_traps

# --- State ---
USERID=""
SYSNAME="MVS1"
COLS=$(tput cols 2>/dev/null || echo 80)
ROWS=$(tput lines 2>/dev/null || echo 24)

# --- Colors: 3270-style green on black ---
c_green=$'\033[32m'
c_bright=$'\033[1;32m'
c_reverse=$'\033[7;32m'
c_reset=$'\033[0m'

# --- Datasets ---
DATASETS=("JCL" "COBOL.SOURCE" "LOAD" "DATA.INPUT" "DATA.OUTPUT" "CLIST" "REXX.EXEC" "ISPF.PROFILE")

# --- Helpers ---
ts_now() { date '+%H:%M:%S'; }
dt_now() { date '+%m/%d/%Y'; }
mainframe_time() { date '+%H:%M:%S ON %B %d, %Y' | tr '[:lower:]' '[:upper:]'; }

status_line() {
    era_move "$ROWS" 1
    printf "${c_reverse}%-*s${c_reset}" "$COLS" " COMMAND ===>                                         $SYSNAME  $(ts_now)"
}

pause_key() {
    era_move $((ROWS - 1)) 2
    printf "${c_green}Press ENTER to continue..."
    read -rs
}

# --- TSO Login Screen ---
tso_login() {
    era_clear
    era_hide_cursor
    printf "${c_green}"
    era_move 2 26; printf "TSO/E LOGON"
    era_move 3 26; printf "-----------"
    era_move 5 10; printf "IKJ56700A ENTER USERID -"
    era_move 6 10; printf "USERID    ===>"
    era_move 7 10; printf "PASSWORD  ===>"
    era_move 9 10; printf "PROCEDURE ===> IKJACCNT"
    era_move 10 10; printf "ACCT NMBR ===> ACCT#"
    era_move 12 10; printf "Enter LOGON parameters below:       RACF LOGON parameters:"
    era_move 13 13; printf "SIZE     ===> 4096                GROUP ===>"
    era_move 14 13; printf "PERFORM  ===>"
    era_move 15 13; printf "COMMAND  ===>"
    era_move 17 10; printf "PF1/PF13 ==> Help    PF3/PF15 ==> Logoff"
    status_line

    era_show_cursor
    era_move 6 25
    printf "${c_bright}"
    read -rn 8 USERID
    [ -z "$USERID" ] && USERID="USER01"
    USERID="${USERID^^}"
    era_move 7 25
    read -rsn 8 _pass
    printf "${c_reset}"

    era_clear
    printf "${c_green}"
    era_move 2 2; printf "IKJ56455I %s LOGON IN PROGRESS AT %s" "$USERID" "$(ts_now)"
    era_move 3 2; printf "IKJ56951I NO BROADCAST MESSAGES"
    era_move 4 2; printf "ICH70001I %s  LAST ACCESS AT %s ON %s" "$USERID" "$(ts_now)" "$(dt_now)"
    era_move 6 2; printf "***"
    sleep 0.8
    era_move 7 2; printf "READY"
    sleep 0.6
}

# --- ISPF Primary Option Menu ---
ispf_main() {
    while true; do
        era_clear
        printf "${c_bright}"
        era_move 1 2; printf "Menu  Utilities  Compilers  Options  Status  Help"
        printf "${c_green}"
        era_move 2 2; printf "%s" "$(era_repeat '─' 55)"
        era_move 3 12; printf "ISPF PRIMARY OPTION MENU"
        era_move 5 3;  printf "0  Settings      Terminal and user parameters"
        era_move 6 3;  printf "1  View          Display source data or listings"
        era_move 7 3;  printf "2  Edit          Create or change source data"
        era_move 8 3;  printf "3  Utilities     Perform utility functions"
        era_move 9 3;  printf "4  Foreground    Interactive language processing"
        era_move 10 3; printf "5  Batch         Submit job for language processing"
        era_move 11 3; printf "6  Command       Enter TSO or Workstation commands"
        era_move 12 3; printf "T  Tutorial      Display information about ISPF"
        era_move 13 3; printf "X  Exit          Terminate ISPF using log/list defaults"
        era_move 15 2; printf "Option ===> "
        era_move "$((ROWS - 1))" 2
        printf "${c_green}F1=Help  F2=Split  F3=Exit  F7=Up  F8=Down  F10=Left  F12=Cancel"
        status_line

        era_show_cursor
        era_move 15 14
        printf "${c_bright}"
        local opt=""
        read -rn 1 opt
        printf "${c_reset}"
        case "${opt^^}" in
            0) settings_panel ;;
            3) utility_menu ;;
            6) tso_command ;;
            T) tutorial_panel ;;
            X) do_logoff; return ;;
            1|2|4|5)
                era_clear; printf "${c_green}"
                era_move 3 5; printf "FUNCTION NOT AVAILABLE IN SIMULATION"
                pause_key ;;
            *) ;;
        esac
    done
}

# --- Settings Panel ---
settings_panel() {
    era_clear
    printf "${c_bright}"; era_move 1 2; printf "Settings"
    printf "${c_green}"; era_move 2 2; printf "%s" "$(era_repeat '─' 55)"
    era_move 3 12; printf "TERMINAL AND USER PARAMETERS"
    local r=5
    for line in "Terminal type   ===> 3278-2" "Screen format   ===> 24 x 80" \
        "Userid          ===> $USERID" "Prefix          ===> $USERID" \
        "System name     ===> $SYSNAME" \
        "Log data set    ===> $USERID.ISPF.LOG" \
        "List data set   ===> $USERID.ISPF.LIST"; do
        era_move $r 3; printf "%s" "$line"; r=$((r+1))
    done
    era_move $((r+1)) 3; printf "Options:"
    era_move $((r+2)) 5; printf "Command line at bottom   ===> YES"
    era_move $((r+3)) 5; printf "Long message             ===> NO"
    status_line; pause_key
}

# --- Utility Selection Panel ---
utility_menu() {
    while true; do
        era_clear
        printf "${c_bright}"
        era_move 1 2; printf "Utilities"
        printf "${c_green}"
        era_move 2 2; printf "%s" "$(era_repeat '─' 55)"
        era_move 3 12; printf "UTILITY SELECTION PANEL"
        era_move 5 3; printf "1  Library     Library utility"
        era_move 6 3; printf "2  Dataset     Dataset utility"
        era_move 7 3; printf "3  Move/Copy   Move, copy, or promote"
        era_move 8 3; printf "4  Dslist      Data set list (short)"
        era_move 10 2; printf "Option ===> "
        status_line

        era_show_cursor
        era_move 10 14
        printf "${c_bright}"
        local opt=""
        read -rn 1 opt
        printf "${c_reset}"
        case "$opt" in
            4) dslist_panel ;;
            [1-3])
                era_clear; printf "${c_green}"
                era_move 3 5; printf "FUNCTION NOT AVAILABLE IN SIMULATION"
                pause_key ;;
            *) return ;;
        esac
    done
}

# --- Dataset List ---
dslist_panel() {
    era_clear
    printf "${c_bright}"; era_move 1 2; printf "DSLIST - DATA SETS MATCHING: %s.*" "$USERID"
    printf "${c_green}"; era_move 2 2; printf "COMMAND ===>"
    local r=4
    for ds in "${DATASETS[@]}"; do
        era_move $r 3; printf "%s.%s" "$USERID" "$ds"; r=$((r+1))
    done
    era_move $r 3; printf "**END**"
    status_line; pause_key
}

# --- Tutorial Panel ---
tutorial_panel() {
    era_clear
    printf "${c_bright}"; era_move 1 2; printf "Tutorial"
    printf "${c_green}"; era_move 2 2; printf "%s" "$(era_repeat '─' 55)"
    era_move 3 12; printf "ISPF TUTORIAL TABLE OF CONTENTS"
    era_move 5 3; printf "The following topics are covered:"
    local r=7
    for t in "0  - General information about ISPF" "1  - How to use the View facility" \
        "2  - How to use the Edit facility" "3  - How to use the Utility functions" \
        "4  - Foreground processing" "5  - Batch processing"; do
        era_move $r 5; printf "%s" "$t"; r=$((r+1))
    done
    era_move $((r+1)) 3; printf "Press PF3 to exit tutorial."
    status_line; pause_key
}

# --- TSO Command Processor ---
tso_command() {
    era_clear
    printf "${c_bright}"
    era_move 1 2; printf "ISPF Command Shell"
    printf "${c_green}"
    era_move 2 2; printf "%s" "$(era_repeat '─' 55)"
    era_move 3 3; printf "Enter TSO or CLIST commands below:"
    era_move 5 3; printf "===>"
    local row=7
    while true; do
        status_line
        era_show_cursor
        era_move 5 8
        printf "${c_bright}%*s" 60 ""
        era_move 5 8
        local cmd=""
        read -r cmd
        printf "${c_reset}"
        [ -z "$cmd" ] && return
        cmd="${cmd^^}"
        era_move "$row" 3
        printf "${c_green}"
        case "$cmd" in
            TIME)
                printf "IKJ56650I TIME-$(mainframe_time)"
                ;;
            LISTCAT|LISTC)
                for ds in "${DATASETS[@]:0:5}"; do
                    printf "%s.%s" "$USERID" "$ds"
                    row=$((row+1)); era_move "$row" 3
                done; row=$((row-1))
                ;;
            STATUS|ST)
                printf "IKJ56693I NO BACKGROUND JOBS FOR USERID %s" "$USERID"
                ;;
            SEND*)
                printf "IKJ56700A MESSAGE SENT"
                ;;
            HELP)
                printf "AVAILABLE COMMANDS: TIME, LISTCAT, STATUS, SEND, HELP, LOGOFF"
                ;;
            LOGOFF)
                do_logoff; return ;;
            *)
                printf "IKJ56500I COMMAND %s NOT FOUND" "$cmd"
                ;;
        esac
        row=$((row+1))
        if [ "$row" -ge $((ROWS - 3)) ]; then
            row=7
            era_clear
            printf "${c_bright}"
            era_move 1 2; printf "ISPF Command Shell"
            printf "${c_green}"
            era_move 2 2; printf "%s" "$(era_repeat '─' 55)"
            era_move 3 3; printf "Enter TSO or CLIST commands below:"
            era_move 5 3; printf "===>"
        fi
    done
}

# --- Logoff ---
do_logoff() {
    era_clear
    printf "${c_green}"
    era_move 3 2
    printf "IKJ56470I %s LOGGED OFF TSO AT %s" "$USERID" "$(mainframe_time)"
    era_move 5 2
    printf "ISPF TERMINATED"
    era_move 7 2
    printf "IEF404I %s - ENDED" "$USERID"
    era_show_cursor
    sleep 2
}

# --- Main ---
main() {
    tso_login
    ispf_main
}

main
