#!/usr/bin/env bash
# era-boot.sh - Display era-appropriate boot sequence and optionally launch interactive mode
# Called from shell integration when MATRIX_ERA is set

source "$(dirname "$0")/era-lib.sh"
era_setup_traps

ERA="${1:-$(era_name)}"
[ -z "$ERA" ] && exit 0

ERAS_DIR="$(dirname "$0")"
INTERACTIVE=$(read_matrix_conf "MATRIX_ERA_INTERACTIVE" "false")

# --- Boot messages for each era ---

boot_enigma() {
    echo ""
    slow_type "ENIGMA CHIFFRIERMASCHINE" 0.06
    echo ""
    slow_type "Wehrmachtmodell M3" 0.05
    echo ""
    echo "Rotoren eingesetzt. Bereit."
    echo ""
}

boot_colossus() {
    echo ""
    slow_type "COLOSSUS Mk 2" 0.06
    echo ""
    slow_type "GOVERNMENT CODE AND CYPHER SCHOOL" 0.04
    echo ""
    slow_type "BLETCHLEY PARK - STATION X" 0.04
    echo ""
    echo "Tape loaded. 5,000 chars/sec."
    echo "Ready for frequency analysis."
    echo ""
}

boot_punchcard() {
    echo ""
    echo "╔══════════════════════════════════════╗"
    echo "║        IBM 029 KEYPUNCH              ║"
    echo "║        Card Punch Unit               ║"
    echo "╠══════════════════════════════════════╣"
    echo "║  POWER ON                            ║"
    echo "║  HOPPER: LOADED                      ║"
    echo "║  STACKER: EMPTY                      ║"
    echo "║  READY                               ║"
    echo "╚══════════════════════════════════════╝"
    echo ""
}

boot_teletype() {
    slow_type "ASR-33 TELETYPE" 0.1
    echo ""
    slow_type "MODEL 33 - 110 BAUD" 0.1
    echo ""
    slow_type "READY" 0.1
    echo ""
    echo ""
}

boot_lineprinter() {
    echo ""
    echo "IBM 1403 LINE PRINTER"
    echo "CHAIN: STANDARD 48-CHARACTER"
    echo "SPEED: 1100 LINES/MIN"
    echo "FORMS: LOADED (GREENBAR 14-7/8 x 11)"
    echo ""
    echo "READY"
    echo ""
}

boot_ibm3270() {
    clear
    echo ""
    echo ""
    echo "                    IBM 3278 DISPLAY STATION"
    echo ""
    echo ""
    echo "                    SYSTEM AVAILABLE"
    echo ""
    echo ""
    echo "                    IKJ56700A ENTER USERID -"
    echo ""
}

boot_system360() {
    echo ""
    slow_type "IBM SYSTEM/360 MODEL 65" 0.04
    echo ""
    slow_type "IPL FROM 0190" 0.04
    echo ""
    slow_type "OS/360 MVT RELEASE 21.8" 0.04
    echo ""
    echo "IEA101A SPECIFY SYSTEM PARAMETERS FOR RELEASE 21.8"
    echo "IEE600I REPLY 00 - GONE"
    echo "IEE136I LOCAL: TIME ZONE=E, DATE=$(date +%Y.%j)"
    echo "IEF677I WARNING MESSAGE(S) FOR JOB STARTUP   ISSUED"
    echo "SYSTEM READY"
    echo ""
}

boot_pdp8() {
    echo ""
    echo "  ┌─────────────────────────────────┐"
    echo "  │   DIGITAL EQUIPMENT CORPORATION  │"
    echo "  │         PDP-8/E                  │"
    echo "  │                                  │"
    echo "  │   CORE: 4K WORDS (12-BIT)       │"
    echo "  │   READY                          │"
    echo "  └─────────────────────────────────┘"
    echo ""
    echo "  Toggle switches to enter program."
    echo ""
}

boot_vt100() {
    # VT100 self-test
    printf "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE"
    sleep 0.3
    clear
    echo ""
    echo "VT100 SELF-TEST OK"
    echo ""
    echo "DEC VT100"
    echo "FIRMWARE VERSION 2.0"
    echo ""
    slow_type "Connecting to host..." 0.05
    echo ""
    sleep 0.3
    echo ""
    echo "4.2 BSD UNIX #3: $(date +'%a %b %d %H:%M:%S %Z %Y')"
    echo ""
    echo "Welcome to the PDP-11/70"
    echo ""
}

boot_vt220() {
    echo ""
    echo "VT220 OK"
    echo ""
    echo "DEC VT220"
    echo "FIRMWARE VERSION 2.3"
    echo ""
    slow_type "Connecting..." 0.05
    echo ""
    sleep 0.3
    echo ""
    echo "VAX/VMS V4.7  $(date +'%a %d-%b-%Y %H:%M')"
    echo ""
    echo "    Welcome to VAX/VMS"
    echo ""
}

boot_altair() {
    echo ""
    echo "  ╔═══════════════════════════════════════╗"
    echo "  ║   MITS ALTAIR 8800                    ║"
    echo "  ║   8080 CPU @ 2 MHz                    ║"
    echo "  ║   256 BYTES RAM                       ║"
    echo "  ║                                       ║"
    echo "  ║   FRONT PANEL ACTIVE                  ║"
    echo "  ╚═══════════════════════════════════════╝"
    echo ""
    echo "  Toggle switches to enter program."
    echo ""
}

boot_apple2() {
    clear
    echo ""
    echo "APPLE ]["
    echo ""
    echo "*APPLE II BASIC*"
    echo ""
    echo "]"
}

boot_pet() {
    clear
    echo ""
    echo "*** COMMODORE BASIC ***"
    echo ""
    echo " 31743 BYTES FREE"
    echo ""
    echo "READY."
}

boot_trs80() {
    clear
    echo ""
    echo "RADIO SHACK LEVEL II BASIC"
    echo ""
    echo "MEMORY SIZE?"
    sleep 0.5
    echo ""
    echo "16383 BYTES FREE"
    echo ""
    echo "READY"
    echo ">"
}

boot_c64() {
    clear
    echo ""
    echo "    **** COMMODORE 64 BASIC V2 ****"
    echo ""
    echo " 64K RAM SYSTEM  38911 BASIC BYTES FREE"
    echo ""
    echo "READY."
}

boot_spectrum() {
    clear
    echo ""
    echo "  (c) 1982 Sinclair Research Ltd"
    echo ""
    echo ""
}

boot_bbc() {
    clear
    echo ""
    echo "BBC Computer 32K"
    echo ""
    echo "Acorn DFS"
    echo ""
    echo "BASIC"
    echo ""
    echo ">"
}

boot_amstrad() {
    clear
    echo "Amstrad 64K Microcomputer  (v1)"
    echo ""
    echo "(c)1984 Amstrad Consumer Electronics plc"
    echo "         and Locomotive Software Ltd."
    echo ""
    echo "BASIC 1.0"
    echo ""
    echo "Ready"
}

boot_msx() {
    clear
    echo ""
    echo "MSX BASIC version 1.0"
    echo "Copyright 1983 by Microsoft"
    echo ""
    echo "28815 Bytes free"
    echo ""
    echo "Ok"
}

boot_atari800() {
    clear
    echo ""
    echo "READY"
}

boot_amiga() {
    clear
    echo ""
    echo "AmigaDOS V3.1"
    echo ""
    echo "Workbench 3.1"
    echo "Copyright (c) 1985-1994 Commodore-Amiga, Inc."
    echo "All Rights Reserved."
    echo ""
    echo "1.RAM:> "
}

boot_ibmmda() {
    clear
    echo ""
    echo "The IBM Personal Computer DOS"
    echo "Version 3.30 (C)Copyright International Business Machines Corp 1981, 1987"
    echo "             (C)Copyright Microsoft Corp 1981, 1986"
    echo ""
    echo "C:\\>"
}

boot_ibmcga() {
    clear
    echo ""
    echo "The IBM Personal Computer DOS"
    echo "Version 3.30 (C)Copyright International Business Machines Corp 1981, 1987"
    echo "             (C)Copyright Microsoft Corp 1981, 1986"
    echo ""
    echo "C:\\>"
}

boot_dos() {
    clear
    echo ""
    echo "Starting MS-DOS..."
    echo ""
    sleep 0.3
    echo "HIMEM is testing extended memory...done."
    echo ""
    echo "MS-DOS Version 6.22"
    echo "(C)Copyright Microsoft Corp 1981-1994."
    echo ""
    echo "C:\\>"
}

boot_solaris() {
    echo ""
    slow_type "ok boot disk" 0.06
    echo ""
    sleep 0.3
    echo "SunOS Release 5.6 Version Generic [UNIX(R) System V Release 4.0]"
    echo "Copyright (c) 1983-1997, Sun Microsystems, Inc."
    echo ""
    echo "$(hostname 2>/dev/null || echo sunbox) console login: "
}

boot_irix() {
    echo ""
    echo "IRIX Release 6.5 IP30"
    echo "Copyright 1987-1998 Silicon Graphics, Inc. All Rights Reserved."
    echo ""
    echo "System: octane"
    echo "$(date)"
    echo ""
}

boot_next() {
    echo ""
    echo "NeXTSTEP Release 3.3"
    echo "Copyright (c) 1995 NeXT Computer, Inc."
    echo ""
    echo "Checking disk..."
    sleep 0.3
    echo "Starting network..."
    sleep 0.2
    echo "Starting Window Server..."
    sleep 0.3
    echo ""
}

boot_bbs() {
    echo ""
    slow_type "ATDT 555-0199" 0.08
    echo ""
    sleep 0.5
    echo "RING..."
    sleep 0.5
    echo "RING..."
    sleep 0.3
    echo ""
    echo "CONNECT 14400/ARQ/V.32bis/LAPM"
    echo ""
    sleep 0.5
}

boot_linux() {
    echo ""
    echo "LILO boot: linux"
    sleep 0.3
    echo "Loading linux..."
    sleep 0.3
    echo "Linux version 2.0.36 (root@linux) (gcc 2.7.2.3) #1 Tue Dec 29 13:11:09 EST 1998"
    echo "Console: colour VGA+ 80x25, 1 virtual console (max 63)"
    echo "Calibrating delay loop.. 53.04 BogoMIPS"
    echo "Memory: 62756k/65536k available (720k kernel code, 384k reserved, 1676k data)"
    echo "Checking 386/387 coupling... OK, FPU using exception 16 error reporting."
    echo "Checking 'hlt' instruction... OK."
    echo "Serial driver version 4.27 with no serial options enabled"
    echo "eth0: 3Com 3c905 Boomerang 100baseTx at 0x6100, 00:60:08:a4:3c:db, IRQ 10"
    echo "Partition check: hda: hda1 hda2"
    echo ""
    sleep 0.3
    echo ""
    echo "Welcome to Slackware Linux 3.6"
    echo ""
}

boot_win98() {
    clear
    echo ""
    echo "Starting Windows 98..."
    echo ""
    sleep 0.5
    echo ""
    echo "Microsoft(R) Windows 98"
    echo "   (C)Copyright Microsoft Corp 1981-1999."
    echo ""
    echo "C:\\WINDOWS>"
}

# --- Dispatch ---

case "$ERA" in
    enigma)       boot_enigma ;;
    colossus)     boot_colossus ;;
    punchcard)    boot_punchcard ;;
    teletype)     boot_teletype ;;
    lineprinter)  boot_lineprinter ;;
    ibm3270)      boot_ibm3270 ;;
    system360)    boot_system360 ;;
    pdp8)         boot_pdp8 ;;
    vt100)        boot_vt100 ;;
    vt220)        boot_vt220 ;;
    altair)       boot_altair ;;
    apple2)       boot_apple2 ;;
    pet)          boot_pet ;;
    trs80)        boot_trs80 ;;
    c64)          boot_c64 ;;
    spectrum)     boot_spectrum ;;
    bbc)          boot_bbc ;;
    amstrad)      boot_amstrad ;;
    msx)          boot_msx ;;
    atari800)     boot_atari800 ;;
    amiga)        boot_amiga ;;
    ibmmda)       boot_ibmmda ;;
    ibmcga)       boot_ibmcga ;;
    dos)          boot_dos ;;
    solaris)      boot_solaris ;;
    irix)         boot_irix ;;
    next)         boot_next ;;
    bbs)          boot_bbs ;;
    linux)        boot_linux ;;
    win98)        boot_win98 ;;
    *)            echo "Unknown era: $ERA"; exit 1 ;;
esac

# --- Optionally launch interactive script ---

if [ "$INTERACTIVE" = "true" ]; then
    case "$ERA" in
        punchcard)                exec "$ERAS_DIR/era-punchcard.sh" ;;
        enigma)                   exec "$ERAS_DIR/era-enigma.sh" ;;
        teletype)                 exec "$ERAS_DIR/era-teletype.sh" ;;
        ibm3270)                  exec "$ERAS_DIR/era-3270.sh" ;;
        pdp8)                     exec "$ERAS_DIR/era-frontpanel.sh" "pdp8" ;;
        altair)                   exec "$ERAS_DIR/era-frontpanel.sh" "altair" ;;
        vt100|vt220|solaris|irix|next|amiga|linux)
                                  exec "$ERAS_DIR/era-unix.sh" "$ERA" ;;
        apple2|pet|trs80|c64|spectrum|bbc|amstrad|msx|atari800)
                                  exec "$ERAS_DIR/era-basic.sh" "$ERA" ;;
        ibmmda|ibmcga|dos|win98)  exec "$ERAS_DIR/era-dos.sh" "$ERA" ;;
        bbs)                      exec "$ERAS_DIR/era-bbs.sh" ;;
    esac
fi
