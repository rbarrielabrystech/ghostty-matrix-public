#!/usr/bin/env bash
# era-dos.sh - DOS Prompt Simulator (IBM PC DOS / MS-DOS / Windows 98)
source "$(dirname "$0")/era-lib.sh"
era_setup_traps
ERA="${1:-${MATRIX_ERA:-dos}}"

# Virtual filesystem: parallel arrays (bash 3.x compatible)
declare -a FS_PATHS=() FS_SIZES=() FS_DATES=() FS_TYPES=()  # type: d=dir, f=file
declare -a FS_BODIES=()  # content for viewable files (empty string for most)
CWD="C:\\" DRIVE="C:"

fs_add() {  # fs_add <path> <type> <size> <date> [content]
    local i=${#FS_PATHS[@]}
    FS_PATHS[$i]="$1"; FS_TYPES[$i]="$2"; FS_SIZES[$i]="$3"
    FS_DATES[$i]="$4"; FS_BODIES[$i]="${5:-}"
}
fs_find() {  # fs_find <path> -> index or "" if not found
    local p="$1" i
    for (( i=0; i<${#FS_PATHS[@]}; i++ )); do
        [[ "${FS_PATHS[$i]}" == "$p" ]] && echo "$i" && return
    done
    echo ""
}
fs_rm() {  # remove entry by index (mark empty)
    local i="$1"; FS_PATHS[$i]=""; FS_TYPES[$i]=""
}
fs_is_dir() { local i; i=$(fs_find "$1"); [[ -n "$i" && "${FS_TYPES[$i]}" == "d" ]]; }
fs_is_file() { local i; i=$(fs_find "$1"); [[ -n "$i" && "${FS_TYPES[$i]}" == "f" ]]; }

fs_init() {
    local d="01-15-94  12:00p"
    fs_add "C:\\"        d 0 "$d"
    fs_add "C:\\DOS"     d 0 "$d"
    fs_add "C:\\WINDOWS" d 0 "$d"
    fs_add "C:\\GAMES"   d 0 "$d"
    fs_add "C:\\UTILS"   d 0 "$d"
    fs_add "C:\\AUTOEXEC.BAT" f 156   "$d" '@ECHO OFF
PROMPT $P$G
PATH C:\DOS;C:\WINDOWS;C:\UTILS
SET TEMP=C:\TEMP
LH C:\DOS\DOSKEY.COM'
    fs_add "C:\\CONFIG.SYS"   f 128   "$d" 'DEVICE=C:\DOS\HIMEM.SYS
DEVICE=C:\DOS\EMM386.EXE NOEMS
DOS=HIGH,UMB
FILES=40
BUFFERS=20'
    fs_add "C:\\COMMAND.COM"  f 54645 "$d"
    fs_add "C:\\IO.SYS"       f 40566 "$d"
    fs_add "C:\\MSDOS.SYS"    f 38138 "$d"
    fs_add "C:\\DOS\\EDIT.COM"    f 413    "$d"
    fs_add "C:\\DOS\\FORMAT.COM"  f 22974  "$d"
    fs_add "C:\\DOS\\FDISK.EXE"   f 29336  "$d"
    fs_add "C:\\DOS\\HIMEM.SYS"   f 29136  "$d"
    fs_add "C:\\DOS\\EMM386.EXE"  f 120926 "$d"
    fs_add "C:\\DOS\\DOSKEY.COM"  f 5883   "$d"
    fs_add "C:\\DOS\\MEM.EXE"     f 32502  "$d"
    fs_add "C:\\DOS\\CHKDSK.EXE"  f 12241  "$d"
    fs_add "C:\\DOS\\XCOPY.EXE"   f 15804  "$d"
    fs_add "C:\\GAMES\\DOOM.EXE"   f 266689 "12-10-93   6:00p"
    fs_add "C:\\GAMES\\WOLF3D.EXE" f 218945 "05-05-92   3:00p"
    fs_add "C:\\GAMES\\PRINCE.EXE" f 122880 "10-03-89   1:00p"
}

resolve_path() {
    local input; input=$(echo "$1" | tr 'a-z/' 'A-Z\\')
    [[ "$input" == "\\" || "$input" == "$DRIVE\\" ]] && echo "$DRIVE\\" && return
    [[ "$input" == "${DRIVE}:"* && "$input" != "${DRIVE}\\"* ]] && input="${DRIVE}\\${input#${DRIVE}:}"
    [[ "$input" == [A-Z]:\\ ]] && echo "$input" && return
    [[ "$input" == [A-Z]:\\* ]] && echo "$input" && return
    [[ "$input" == \\* ]] && echo "${DRIVE}${input}" && return
    local base="$CWD" oldIFS="$IFS" part
    IFS=$'\\'
    for part in $input; do
        [[ -z "$part" ]] && continue
        if [[ "$part" == ".." ]]; then
            [[ "$base" != "$DRIVE\\" ]] && base="${base%\\*}"
            [[ "$base" == "$DRIVE" ]] && base="$DRIVE\\"
        else
            [[ "$base" == "$DRIVE\\" ]] && base="${base}${part}" || base="${base}\\${part}"
        fi
    done
    IFS="$oldIFS"
    echo "$base"
}

fmt_num() {
    local s="$1" r="" c=0 i
    for (( i=${#s}-1; i>=0; i-- )); do
        (( c > 0 && c % 3 == 0 )) && r=",$r"
        r="${s:$i:1}$r"; c=$(( c + 1 ))
    done
    echo "$r"
}

# Get parent directory of a path
fs_parent() {
    local p="${1%\\*}"
    [[ "$p" == "${DRIVE}" || "$p" == "$1" ]] && echo "$DRIVE\\" || echo "$p"
}

cmd_ver() {
    echo ""
    case "$ERA" in
        ibmmda|ibmcga) echo "IBM Personal Computer DOS Version 3.30" ;;
        dos)           echo "MS-DOS Version 6.22" ;;
        win98)         echo "Windows 98 [Version 4.10.2222]" ;;
        *)             echo "MS-DOS Version 5.0" ;;
    esac; echo ""
}

cmd_dir() {
    local target="${1:-$CWD}"; [[ -n "$1" ]] && target=$(resolve_path "$1")
    fs_is_dir "$target" || { echo "Invalid directory"; return; }
    echo ""; echo " Volume in drive ${DRIVE:0:1} is MSDOS"
    echo " Volume Serial Number is 1A2B-3C4D"; echo " Directory of ${target}"; echo ""
    local fc=0 tb=0 dc=0 i
    for (( i=0; i<${#FS_PATHS[@]}; i++ )); do
        [[ -z "${FS_PATHS[$i]}" || "${FS_PATHS[$i]}" == "$target" ]] && continue
        local par; par=$(fs_parent "${FS_PATHS[$i]}")
        [[ "$par" != "$target" ]] && continue
        local name="${FS_PATHS[$i]##*\\}"
        if [[ "${FS_TYPES[$i]}" == "d" ]]; then
            printf "%-8s     <DIR>        %s\n" "$name" "${FS_DATES[$i]}"
            dc=$((dc+1))
        else
            local nm="${name%.*}" ext="${name##*.}"
            [[ "$name" == "$ext" ]] && ext=""
            printf "%-8s %-3s %10s %s\n" "$nm" "$ext" "$(fmt_num "${FS_SIZES[$i]}")" "${FS_DATES[$i]}"
            fc=$((fc+1)); tb=$((tb+FS_SIZES[$i]))
        fi
    done
    printf "      %d file(s)    %12s bytes\n" "$fc" "$(fmt_num $tb)"
    printf "      %d dir(s)     %12s bytes free\n\n" "$dc" "$(fmt_num 524288000)"
}

cmd_type() {
    local t; t=$(resolve_path "$1")
    local idx; idx=$(fs_find "$t")
    if [[ -z "$idx" ]]; then echo "File not found - $(echo "$1" | tr 'a-z' 'A-Z')"
    elif [[ -n "${FS_BODIES[$idx]}" ]]; then echo "${FS_BODIES[$idx]}"
    else echo "Unable to display binary file."; fi
}

cmd_cd() {
    [[ -z "$1" ]] && echo "$CWD" && return
    local t; t=$(resolve_path "$1")
    fs_is_dir "$t" && CWD="$t" || echo "Invalid directory"
}

cmd_copy() {
    local s d; s=$(resolve_path "$1"); d=$(resolve_path "$2")
    local si; si=$(fs_find "$s")
    if [[ -n "$si" && "${FS_TYPES[$si]}" == "f" ]]; then
        fs_add "$d" f "${FS_SIZES[$si]}" "${FS_DATES[$si]}" "${FS_BODIES[$si]}"
        echo "        1 file(s) copied"
    else echo "File not found - $(echo "$1" | tr 'a-z' 'A-Z')"; fi
}

cmd_del() {
    local t; t=$(resolve_path "$1")
    local idx; idx=$(fs_find "$t")
    [[ -n "$idx" && "${FS_TYPES[$idx]}" == "f" ]] && fs_rm "$idx" || echo "File Not Found"
}

cmd_ren() {
    local old; old=$(resolve_path "$1")
    local idx; idx=$(fs_find "$old")
    if [[ -n "$idx" && "${FS_TYPES[$idx]}" == "f" ]]; then
        local dir; dir=$(fs_parent "$old")
        local new_name; new_name=$(echo "$2" | tr 'a-z' 'A-Z')
        local np; [[ "$dir" == "$DRIVE\\" ]] && np="${dir}${new_name}" || np="${dir}\\${new_name}"
        fs_add "$np" f "${FS_SIZES[$idx]}" "${FS_DATES[$idx]}" "${FS_BODIES[$idx]}"
        fs_rm "$idx"
    else echo "File Not Found"; fi
}

cmd_mkdir() {
    local t; t=$(resolve_path "$1")
    fs_is_dir "$t" && echo "Unable to create directory" || fs_add "$t" d 0 "01-15-94  12:00p"
}

cmd_rmdir() {
    local t; t=$(resolve_path "$1")
    local idx; idx=$(fs_find "$t")
    [[ -z "$idx" || "${FS_TYPES[$idx]}" != "d" || "$t" == "$DRIVE\\" ]] && echo "Invalid directory" && return
    local i
    for (( i=0; i<${#FS_PATHS[@]}; i++ )); do
        [[ -z "${FS_PATHS[$i]}" || "$i" == "$idx" ]] && continue
        local par; par=$(fs_parent "${FS_PATHS[$i]}")
        [[ "$par" == "$t" ]] && echo "Directory not empty" && return
    done
    fs_rm "$idx"
}

cmd_mem() {
    cat <<'EOF'

Memory Type        Total  =    Used  +    Free
----------------  -------      -----      -----
Conventional        640K        62K       578K
Upper                 0K         0K         0K
Reserved              0K         0K         0K
Extended (XMS)   15,360K     1,024K    14,336K
----------------  -------      -----      -----
Total memory     16,000K     1,086K    14,914K

Total under 1 MB    640K        62K       578K

Largest executable program size       578K (591,856 bytes)
Largest free upper memory block          0K       (0 bytes)
MS-DOS is resident in the high memory area.

EOF
}

cmd_tree() {
    local root="${1:-$CWD}"; [[ -n "$1" ]] && root=$(resolve_path "$1")
    echo "Directory PATH listing for Volume MSDOS"
    echo "Volume Serial Number is 1A2B-3C4D"; echo "${root}"
    _tree_r "$root" ""
}
_tree_r() {
    local parent="$1" pfx="$2" i
    local -a children=()
    for (( i=0; i<${#FS_PATHS[@]}; i++ )); do
        [[ -z "${FS_PATHS[$i]}" || "${FS_TYPES[$i]}" != "d" || "${FS_PATHS[$i]}" == "$parent" ]] && continue
        local par; par=$(fs_parent "${FS_PATHS[$i]}")
        [[ "$par" == "$parent" ]] && children[${#children[@]}]="${FS_PATHS[$i]}"
    done
    local n=${#children[@]} ci=0
    for child in "${children[@]}"; do
        ci=$((ci+1))
        echo "${pfx}+---${child##*\\}"
        (( ci == n )) && _tree_r "$child" "${pfx}    " || _tree_r "$child" "${pfx}|   "
    done
}

cmd_help() {
    cat <<'EOF'

CD       Displays or changes the current directory.
CLS      Clears the screen.
COPY     Copies one file to another location.
DATE     Displays the date.
DEL      Deletes one or more files.
DIR      Displays a list of files and subdirectories.
ECHO     Displays messages.
EXIT     Quits the command interpreter.
HELP     Provides Help information for commands.
MEM      Displays the amount of free and used memory.
MKDIR    Creates a directory.
REN      Renames a file.
RMDIR    Removes a directory.
TIME     Displays the system time.
TREE     Graphically displays the directory structure.
TYPE     Displays the contents of a text file.
VER      Displays the DOS version.

EOF
}

boot_message() {
    clear
    case "$ERA" in
        ibmmda|ibmcga)
            echo ""; echo "The IBM Personal Computer DOS"
            echo "Version 3.30 (C)Copyright IBM Corp 1981, 1987"
            echo "(C)Copyright Microsoft Corp 1981, 1986"; echo "" ;;
        dos)
            echo ""; echo "Starting MS-DOS..."; echo ""
            echo "HIMEM is testing extended memory...done."; echo ""
            echo "MS-DOS Version 6.22"
            echo "(C)Copyright Microsoft Corp 1981-1994."; echo "" ;;
        win98)
            echo ""; echo "Microsoft(R) Windows 98"
            echo "   (C)Copyright Microsoft Corp 1981-1999."; echo "" ;;
        *)
            echo ""; echo "MS-DOS Version 5.0"
            echo "(C)Copyright Microsoft Corp 1981-1991."; echo "" ;;
    esac
    sleep 0.5
}

main() {
    fs_init; boot_message
    while true; do
        local line; IFS= read -rep "${CWD}>" line || break
        [[ -z "$line" ]] && continue
        local cmd arg1 arg2 rest; read -r cmd arg1 arg2 rest <<< "$line"
        cmd=$(echo "$cmd" | tr 'a-z' 'A-Z')
        if [[ "$cmd" =~ ^([A-Z]):$ ]]; then
            local dl="${BASH_REMATCH[1]}"
            if [[ "$dl" == "C" ]]; then DRIVE="C:"
            else echo ""; echo "Not ready reading drive ${dl}"; echo "Abort, Retry, Fail?"; echo ""; fi
            continue
        fi
        case "$cmd" in
            DIR)        cmd_dir "$arg1" ;;
            CD|CHDIR)   cmd_cd "$arg1" ;;
            TYPE)       cmd_type "$arg1" ;;
            COPY)       cmd_copy "$arg1" "$arg2" ;;
            DEL|ERASE)  cmd_del "$arg1" ;;
            REN|RENAME) cmd_ren "$arg1" "$arg2" ;;
            MKDIR|MD)   cmd_mkdir "$arg1" ;;
            RMDIR|RD)   cmd_rmdir "$arg1" ;;
            CLS)        clear ;;
            VER)        cmd_ver ;;
            DATE)       echo "Current date is $(date '+%a %m-%d-%Y')" ;;
            TIME)       echo "Current time is $(date '+%T')" ;;
            MEM)        cmd_mem ;;
            TREE)       cmd_tree "$arg1" ;;
            HELP)       cmd_help ;;
            ECHO)       echo "${arg1} ${arg2} ${rest}" ;;
            EXIT)       break ;;
            "")         ;;
            *)          echo "Bad command or file name" ;;
        esac
    done
}

main
