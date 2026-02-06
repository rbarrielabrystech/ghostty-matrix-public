#!/usr/bin/env bash
# era-unix.sh - Classic Unix Shell Simulator
# Authentic VT100, VT220, Solaris, IRIX, NeXT, Amiga, early Linux experiences.
source "$(dirname "$0")/era-lib.sh"
era_setup_traps

ERA="${1:-${MATRIX_ERA:-vt100}}"

# --- Per-Era Configuration ---
declare -A ERA_HOST ERA_MOTD ERA_UNAME ERA_PROMPT
ERA_HOST[vt100]="pdp11";   ERA_HOST[vt220]="vax780";  ERA_HOST[solaris]="sunbox"
ERA_HOST[irix]="octane";   ERA_HOST[next]="next";      ERA_HOST[amiga]="amiga"
ERA_HOST[linux]="linux"

ERA_MOTD[vt100]="4.2 BSD UNIX #3: Sat Apr 1 1978
Welcome to the PDP-11/70"
ERA_MOTD[vt220]="VAX/VMS V4.7  Mon 14-Jan-1985 09:15"
ERA_MOTD[solaris]="SunOS 5.6       Generic        January 1998"
ERA_MOTD[irix]="IRIX Release 6.5 IP30
Silicon Graphics, Inc."
ERA_MOTD[next]="NeXTSTEP Release 3.3
Copyright (c) 1995 NeXT Computer, Inc."
ERA_MOTD[amiga]="AmigaDOS V3.1
Workbench 3.1"
ERA_MOTD[linux]="Linux 2.0.36 (linux) (ttyp0)
Welcome to Slackware Linux 3.6"

ERA_UNAME[vt100]="BSD 4.2"
ERA_UNAME[vt220]="VAX/VMS 4.7"
ERA_UNAME[solaris]="SunOS sunbox 5.6 Generic sun4u sparc SUNW,Ultra-2"
ERA_UNAME[irix]="IRIX64 octane 6.5 07151432 IP30"
ERA_UNAME[next]="NeXTStep 3.3"
ERA_UNAME[amiga]="AmigaOS 3.1"
ERA_UNAME[linux]="Linux linux 2.0.36 #1 Tue Dec 29 13:11:09 EST 1998 i586"

ERA_PROMPT[vt100]="% "
ERA_PROMPT[vt220]='$ '
ERA_PROMPT[solaris]="sunbox% "
ERA_PROMPT[irix]="octane% "
ERA_PROMPT[next]="next:~> "
ERA_PROMPT[amiga]="1.RAM:> "
ERA_PROMPT[linux]="user@linux:~\$ "

HOSTNAME="${ERA_HOST[$ERA]:-pdp11}"
MOTD="${ERA_MOTD[$ERA]:-${ERA_MOTD[vt100]}}"
UNAME="${ERA_UNAME[$ERA]:-${ERA_UNAME[vt100]}}"
PS_PROMPT="${ERA_PROMPT[$ERA]:-% }"
CWD="/home/user"

# --- Virtual Filesystem ---
declare -A FS_FILES FS_PERMS FS_SIZES FS_DATES FS_CONTENT FS_DIRS
fs_init() {
    local d; for d in / /home /home/user /etc /usr /usr/bin /tmp /var /var/log; do
        FS_DIRS["$d"]=1
    done
    _mkfile /etc/passwd   "-rw-r--r--" 284 "Jan  5  1998" \
"root:x:0:0:root:/root:/bin/sh
daemon:x:1:1:daemon:/usr/sbin:/bin/false
bin:x:2:2:bin:/bin:/bin/false
user:x:1000:100:System User:/home/user:/bin/sh
nobody:x:65534:65534:nobody:/nonexistent:/bin/false"
    _mkfile /etc/motd     "-rw-r--r--"  96 "Jan  5  1998" "$MOTD"
    _mkfile /etc/hosts    "-rw-r--r--"  74 "Jan  5  1998" \
"127.0.0.1       localhost
${HOSTNAME}     ${HOSTNAME}.localdomain"
    _mkfile /home/user/.profile "-rw-r--r--" 120 "Jan  5  1998" \
"PATH=/usr/bin:/bin:/usr/local/bin
export PATH
TERM=vt100
export TERM"
    _mkfile /var/log/messages "-rw-r-----" 2048 "Jan  6  1998" \
"Jan  6 08:15:01 ${HOSTNAME} syslogd: restart
Jan  6 08:15:02 ${HOSTNAME} kernel: console login
Jan  6 08:17:44 ${HOSTNAME} login: LOGIN ON ttyp0 BY user"
    _mkfile /usr/bin/sh    "-rwxr-xr-x" 45056 "Jan  1  1998" ""
    _mkfile /usr/bin/ls    "-rwxr-xr-x" 24576 "Jan  1  1998" ""
    _mkfile /usr/bin/cat   "-rwxr-xr-x" 12288 "Jan  1  1998" ""
    _mkfile /tmp/.X0-lock  "-rw-r--r--"    11 "Jan  6  1998" ""
}
_mkfile() { FS_FILES["$1"]=1; FS_PERMS["$1"]="$2"; FS_SIZES["$1"]="$3"; FS_DATES["$1"]="$4"; FS_CONTENT["$1"]="$5"; }

# --- Path Resolution ---
resolve_path() {
    local p="$1"
    [[ -z "$p" ]] && { echo "$CWD"; return; }
    [[ "$p" != /* ]] && p="${CWD%/}/$p"
    # Normalise . and ..
    local -a parts=() segs=()
    local oldIFS="$IFS"
    IFS=/; read -ra segs <<< "$p"
    IFS="$oldIFS"
    local s; for s in "${segs[@]}"; do
        case "$s" in
            ""|.) ;;
            ..) (( ${#parts[@]} > 0 )) && unset 'parts[${#parts[@]}-1]' ;;
            *)  parts+=("$s") ;;
        esac
    done
    local out="/"
    if (( ${#parts[@]} )); then
        out=""
        local part; for part in "${parts[@]}"; do out="${out}/${part}"; done
    fi
    echo "$out"
}

# --- Commands ---
cmd_ls() {
    local flag="" target=""
    while [[ $# -gt 0 ]]; do
        case "$1" in -la|-l|-a) flag="$1";; *) target="$1";; esac; shift
    done
    target=$(resolve_path "${target:-$CWD}")
    [[ -z "${FS_DIRS[$target]}" ]] && { echo "ls: ${target}: No such file or directory"; return; }
    local prefix="${target%/}/"; [[ "$target" == "/" ]] && prefix="/"
    if [[ "$flag" == "-la" || "$flag" == "-l" ]]; then
        echo "total $(( RANDOM % 20 + 4 ))"
        local k; for k in "${!FS_FILES[@]}"; do
            local dir="${k%/*}"; [[ -z "$dir" ]] && dir="/"
            [[ "$dir" == "$target" || ("$target" == "/" && "$dir" == "") ]] || continue
            printf "%s 1 root root %6d %s %s\n" "${FS_PERMS[$k]}" "${FS_SIZES[$k]}" "${FS_DATES[$k]}" "${k##*/}"
        done
        for k in "${!FS_DIRS[@]}"; do
            [[ "$k" == "$target" ]] && continue
            local par="${k%/*}"; [[ -z "$par" ]] && par="/"
            [[ "$par" == "$target" ]] || continue
            printf "drwxr-xr-x 2 root root   512 Jan  5  1998 %s\n" "${k##*/}"
        done
    else
        local items=()
        local k; for k in "${!FS_FILES[@]}"; do
            local dir="${k%/*}"; [[ -z "$dir" ]] && dir="/"
            [[ "$dir" == "$target" || ("$target" == "/" && "$dir" == "") ]] || continue
            items+=("${k##*/}")
        done
        for k in "${!FS_DIRS[@]}"; do
            [[ "$k" == "$target" ]] && continue
            local par="${k%/*}"; [[ -z "$par" ]] && par="/"
            [[ "$par" == "$target" ]] || continue
            items+=("${k##*/}/")
        done
        local i; for i in "${items[@]}"; do printf "%s  " "$i"; done
        [[ ${#items[@]} -gt 0 ]] && echo ""
    fi
}

cmd_cat() {
    local f; f=$(resolve_path "$1")
    if [[ -n "${FS_CONTENT[$f]}" ]]; then echo "${FS_CONTENT[$f]}"
    elif [[ -n "${FS_FILES[$f]}" ]]; then echo "cat: ${1}: Binary file"
    else echo "cat: ${1}: No such file or directory"; fi
}

cmd_cd() {
    local t; t=$(resolve_path "${1:-/home/user}")
    [[ -n "${FS_DIRS[$t]}" ]] && CWD="$t" || echo "cd: ${1}: No such file or directory"
}

cmd_who() {
    printf "%-10s %-8s %s\n" "user" "ttyp0" "Jan  6 08:17"
    printf "%-10s %-8s %s\n" "root" "console" "Jan  5 23:55"
    printf "%-10s %-8s %s\n" "daemon" "ttyp1" "Jan  6 00:01"
}

cmd_date() { echo "Tue Jan  6 09:42:17 EST 1998"; }

cmd_uname() {
    [[ "$1" == "-a" ]] && echo "$UNAME" || echo "${UNAME%% *}"
}

cmd_man() {
    [[ -z "$1" ]] && { echo "What manual page do you want?"; return; }
    case "$1" in
        ls)    echo "LS(1)"; echo "NAME"; echo "     ls - list directory contents"; echo "SYNOPSIS"; echo "     ls [-la] [file ...]";;
        cat)   echo "CAT(1)"; echo "NAME"; echo "     cat - concatenate and print files"; echo "SYNOPSIS"; echo "     cat [file ...]";;
        cd)    echo "CD(1)"; echo "NAME"; echo "     cd - change working directory"; echo "SYNOPSIS"; echo "     cd [directory]";;
        ps)    echo "PS(1)"; echo "NAME"; echo "     ps - report process status"; echo "SYNOPSIS"; echo "     ps [-ef]";;
        *)     echo "No manual entry for ${1}.";;
    esac
}

cmd_ps() {
    if [[ "$1" == "-ef" ]]; then
        printf "%-8s %5s %5s  ? %8s %s\n" "UID" "PID" "PPID" "TIME" "CMD"
        printf "%-8s %5d %5d  ? %8s %s\n" "root" 1 0 "0:03" "init"
        printf "%-8s %5d %5d  ? %8s %s\n" "root" 2 1 "0:00" "syslogd"
        printf "%-8s %5d %5d  ? %8s %s\n" "root" 38 1 "0:01" "cron"
        printf "%-8s %5d %5d  ? %8s %s\n" "root" 54 1 "0:00" "inetd"
        printf "%-8s %5d %5d  ? %8s %s\n" "user" 187 1 "0:00" "-sh"
        printf "%-8s %5d %5d  ? %8s %s\n" "user" 203 187 "0:00" "ps -ef"
    else
        printf "%5s %-8s %8s %s\n" "PID" "TTY" "TIME" "CMD"
        printf "%5d %-8s %8s %s\n" 187 "ttyp0" "0:00" "-sh"
        printf "%5d %-8s %8s %s\n" 204 "ttyp0" "0:00" "ps"
    fi
}

cmd_df() {
    if [[ "$1" == "-h" ]]; then
        echo "Filesystem      Size  Used Avail Use% Mounted on"
        echo "/dev/sd0a       500M  312M  188M  63% /"
        echo "/dev/sd0g       1.2G  478M  722M  40% /usr"
        echo "swap            128M   12M  116M  10% /tmp"
    else
        echo "Filesystem  1K-blocks    Used   Avail Capacity Mounted on"
        echo "/dev/sd0a      512000  319488  192512    62%   /"
        echo "/dev/sd0g     1258291  489472  738819    40%   /usr"
        echo "swap           131072   12288  118784     9%   /tmp"
    fi
}

cmd_uptime() { echo " 9:42am  up 12 days,  3:27,  3 users,  load average: 0.15, 0.08, 0.02"; }
cmd_hostname() { echo "$HOSTNAME"; }

# --- Boot Sequence ---
do_boot() {
    clear
    case "$ERA" in
        solaris)
            echo "SunOS Release 5.6 Version Generic [UNIX(R) System V Release 4.0]"
            echo "Copyright (c) 1983-1997, Sun Microsystems, Inc."
            echo ""; sleep 0.4 ;;
        linux)
            echo "LILO boot:"; sleep 0.3; echo "Loading linux..."
            sleep 0.3
            echo "Linux version 2.0.36 (root@linux) (gcc 2.7.2.3) #1 Tue Dec 29 13:11:09 EST 1998"
            echo "Console: colour VGA+ 80x25"
            echo "Calibrating delay loop.. ok - 53.04 BogoMIPS"
            echo "Memory: 14904k/16384k available (680k kernel code, 384k reserved, 416k data)"
            echo "Checking 386/387 coupling... Ok, fpu using exception 16 error reporting."
            echo "Serial driver version 4.13 with no serial options enabled"
            sleep 0.5; echo "" ;;
        amiga)
            echo "AmigaDOS V3.1"; echo "Workbench 3.1"
            echo "Copyright (c) 1985-1994 Commodore-Amiga, Inc."; echo ""
            sleep 0.4 ;;
        *) ;;
    esac
}

# --- Login ---
do_login() {
    local user_input
    printf "%s login: " "$HOSTNAME"; read -r user_input
    printf "Password: "; read -rs _; echo ""
    echo ""
    echo "Last login: Mon Jan  5 23:55:04 on ttyp0"
    echo "${MOTD}"
    echo ""
}

# --- Main Loop ---
main() {
    fs_init; do_boot; do_login
    while true; do
        local line
        IFS= read -rep "$PS_PROMPT" line || break
        [[ -z "$line" ]] && continue
        # Amiga alias: DIR -> ls
        [[ "$ERA" == "amiga" ]] && [[ "$(_upper "$line")" == DIR* ]] && line="ls${line:3}"
        local cmd args; read -r cmd args <<< "$line"
        local -a argv; read -ra argv <<< "$args"
        case "$cmd" in
            ls)       cmd_ls "${argv[@]}" ;;
            cat)      cmd_cat "${argv[0]}" ;;
            cd)       cmd_cd "${argv[0]}" ;;
            pwd)      echo "$CWD" ;;
            who)      cmd_who ;;
            date)     cmd_date ;;
            uname)    cmd_uname "${argv[0]}" ;;
            man)      cmd_man "${argv[0]}" ;;
            ps)       cmd_ps "${argv[0]}" ;;
            df)       cmd_df "${argv[0]}" ;;
            uptime)   cmd_uptime ;;
            hostname) cmd_hostname ;;
            echo)     echo "$args" ;;
            clear)    clear ;;
            exit|logout) break ;;
            *)        echo "${cmd}: Command not found." ;;
        esac
    done
}
main
