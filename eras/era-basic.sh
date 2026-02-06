#!/usr/bin/env bash
# era-basic.sh - Universal BASIC interpreter covering 9 home computers
# Usage: ./era-basic.sh [apple2|pet|trs80|c64|spectrum|bbc|amstrad|msx|atari800]
# Compatible with bash 3.2+ (macOS default)

source "$(dirname "$0")/era-lib.sh"
era_setup_traps

# ---------------------------------------------------------------------------
# Portable helpers (bash 3.2 lacks ${var^^} and declare -A)
# ---------------------------------------------------------------------------
upper() { echo "$1" | tr '[:lower:]' '[:upper:]'; }

# Key-value store using flat indexed arrays + linear scan
# Usage: kv_set STORE key value / kv_get STORE key / kv_del STORE key / kv_keys STORE
# STORE is a name prefix; data lives in ${STORE_K[@]} and ${STORE_V[@]}

_kv_idx() {
    local store="$1" key="$2"
    eval "local n=\${#${store}_K[@]}"
    local i
    for (( i=0; i<n; i++ )); do
        eval "local k=\${${store}_K[$i]}"
        if [[ "$k" == "$key" ]]; then echo "$i"; return 0; fi
    done
    return 1
}
kv_set() {
    local store="$1" key="$2" val="$3"
    local idx
    if idx=$(_kv_idx "$store" "$key"); then
        eval "${store}_V[$idx]=\"\$val\""
    else
        eval "${store}_K+=(\"\$key\")"
        eval "${store}_V+=(\"\$val\")"
    fi
}
kv_get() {
    local store="$1" key="$2" default="${3:-}"
    local idx
    if idx=$(_kv_idx "$store" "$key"); then
        eval "echo \"\${${store}_V[$idx]}\""
    else
        echo "$default"
    fi
}
kv_del() {
    local store="$1" key="$2"
    local idx
    if idx=$(_kv_idx "$store" "$key"); then
        eval "unset ${store}_K[$idx]; unset ${store}_V[$idx]"
        eval "${store}_K=(\"\${${store}_K[@]}\")"
        eval "${store}_V=(\"\${${store}_V[@]}\")"
    fi
}
kv_keys() {
    local store="$1"
    eval "echo \"\${${store}_K[*]}\""
}
kv_clear() {
    local store="$1"
    eval "${store}_K=(); ${store}_V=()"
}

# ---------------------------------------------------------------------------
# Era configuration
# ---------------------------------------------------------------------------
ERA="${1:-${MATRIX_ERA:-c64}}"

# Spectrum keyword map
SPEC_K=(P G I L R N C F T S D O)
SPEC_V=("PRINT " "GOTO " "INPUT " "LET " "RUN" "NEW" "CLS" "FOR " "THEN " "STOP" "DIM " "GOSUB ")
spec_keyword() {
    local ch="$1" i
    for (( i=0; i<${#SPEC_K[@]}; i++ )); do
        if [[ "${SPEC_K[$i]}" == "$ch" ]]; then echo "${SPEC_V[$i]}"; return 0; fi
    done
    return 1
}

show_boot() {
    clear
    case "$ERA" in
        apple2)   echo "APPLE ]["; echo "*APPLE II BASIC*"; echo ;;
        pet)      echo; echo "*** COMMODORE BASIC ***"; echo; echo "31743 BYTES FREE"; echo; echo "READY." ;;
        trs80)    echo "RADIO SHACK LEVEL II BASIC"; echo; echo "READY"; echo ;;
        c64)      echo; echo "    **** COMMODORE 64 BASIC V2 ****"
                  echo; echo " 64K RAM SYSTEM  38911 BASIC BYTES FREE"; echo; echo "READY." ;;
        spectrum) echo "(c) 1982 Sinclair Research Ltd"; echo ;;
        bbc)      echo "BBC Computer 32K"; echo "Acorn DFS"; echo; echo "BASIC"; echo ;;
        amstrad)  echo "Amstrad 64K Microcomputer  (v1)"; echo
                  echo "Locomotive BASIC 1.0"; echo; echo "Ready" ;;
        msx)      echo "MSX BASIC version 1.0"; echo "Copyright 1983 by Microsoft"
                  echo "28815 Bytes free"; echo "Ok" ;;
        atari800) echo "READY" ;;
    esac
}

get_prompt() {
    case "$ERA" in
        apple2)   printf '] ' ;;
        pet|c64)  printf '' ;;
        trs80)    printf '> ' ;;
        bbc)      printf '>' ;;
        *)        printf '' ;;
    esac
}

print_ready() {
    case "$ERA" in
        pet|c64)   echo "READY." ;;
        trs80)     echo "READY" ;;
        bbc)       echo ">" ;;
        amstrad)   echo "Ready" ;;
        msx)       echo "Ok" ;;
        atari800)  echo "READY" ;;
    esac
}

era_is_upper() { [[ "$ERA" == "apple2" || "$ERA" == "trs80" ]]; }
to_upper() {
    if era_is_upper; then upper "$1"; else echo "$1"; fi
}

# ---------------------------------------------------------------------------
# Program storage and variables
# ---------------------------------------------------------------------------
# PROG: line-numbered program (kv store: key=line_number, value=source)
PROG_K=(); PROG_V=()
# NUMV: numeric variables A-Z
NUMV_K=(); NUMV_V=()
# STRV: string variables A$-Z$
STRV_K=(); STRV_V=()

FOR_STACK=()   # entries: "var|limit|step|return_line"
GOSUB_STACK=() # return line numbers
RUNNING=0
BREAK_REQ=0
CUR_LINE=0
GOTO_TGT=""
SAVE_FILE="/tmp/basic_save_$$.bas"

handle_break() { [[ $RUNNING -eq 1 ]] && BREAK_REQ=1; }
trap handle_break INT

sorted_lines() {
    local keys; keys=$(kv_keys PROG)
    echo "$keys" | tr ' ' '\n' | sort -n
}

get_nvar() { kv_get NUMV "$(upper "$1")" 0; }
set_nvar() { kv_set NUMV "$(upper "$1")" "$2"; }
get_svar() { kv_get STRV "$(upper "$1")" ""; }
set_svar() { kv_set STRV "$(upper "$1")" "$2"; }

# ---------------------------------------------------------------------------
# Precompiled regex patterns
# ---------------------------------------------------------------------------
RE_STR_LIT='^"(.*)"$'
RE_NUM_LIT='^-?[0-9]+\.?[0-9]*$'
RE_STR_VAR='^([A-Z])\$$'
RE_NUM_VAR='^[A-Z]$'
RE_FN_INT='INT\(([^)]+)\)'
RE_FN_RND='RND\(([^)]+)\)'
RE_FN_ABS='ABS\(([^)]+)\)'
RE_FN_LEN='LEN\(([^)]+)\)'
RE_FN_ASC='ASC\(([^)]+)\)'
RE_FN_LEFT='LEFT\$\(([^,]+),([^)]+)\)'
RE_FN_RIGHT='RIGHT\$\(([^,]+),([^)]+)\)'
RE_FN_MID='MID\$\(([^,]+),([^,]+),([^)]+)\)'
RE_FN_CHR='CHR\$\(([^)]+)\)'
RE_FN_TAB='TAB\(([^)]+)\)'
RE_FN_SPC='SPC\(([^)]+)\)'
RE_LINE='^([0-9]+)[[:space:]]*(.*)'
RE_LET_STR='^(LET[[:space:]]+)?([A-Z])\$[[:space:]]*=[[:space:]]*(.*)'
RE_LET_NUM='^(LET[[:space:]]+)?([A-Z])[[:space:]]*=[[:space:]]*(.*)'
RE_INPUT='^INPUT[[:space:]]+(.*)'
RE_INPUT_P='^"([^"]*)";(.*)'
RE_INPUT_P2='^"([^"]*)",(.*)'
RE_GOTO='^GOTO[[:space:]]*([0-9]+)'
RE_GOSUB='^GOSUB[[:space:]]*([0-9]+)'
RE_FOR='^FOR[[:space:]]+([A-Z])[[:space:]]*=[[:space:]]*(.*)[[:space:]]+TO[[:space:]]+([-0-9.+*/A-Z[:space:]]+)([[:space:]]+STEP[[:space:]]+(.*))?'
RE_NEXT='^NEXT[[:space:]]*([A-Z])?'
RE_IF='^IF[[:space:]]+(.*)[[:space:]]+THEN[[:space:]]*(.*)'
RE_DIGITS='^[0-9]+$'

# ---------------------------------------------------------------------------
# Expression evaluator
# ---------------------------------------------------------------------------
trim() {
    local v="$1"
    v="${v#"${v%%[![:space:]]*}"}"
    v="${v%"${v##*[![:space:]]}"}"
    echo "$v"
}

# Evaluate expression expected to be string
eval_string_expr() {
    local expr; expr=$(trim "$1")
    if [[ "$expr" =~ $RE_STR_LIT ]]; then echo "${BASH_REMATCH[1]}"; return; fi
    if [[ "$expr" =~ $RE_STR_VAR ]]; then get_svar "${BASH_REMATCH[1]}\$"; return; fi
    # String concatenation: split on + outside quotes
    local parts=() buf="" in_q=0 i ch
    for (( i=0; i<${#expr}; i++ )); do
        ch="${expr:$i:1}"
        if [[ "$ch" == '"' ]]; then (( in_q = !in_q )); buf+="$ch"
        elif [[ "$ch" == '+' && $in_q -eq 0 ]]; then parts+=("$buf"); buf=""
        else buf+="$ch"; fi
    done
    parts+=("$buf")
    local result="" part
    for part in "${parts[@]}"; do
        part=$(trim "$part")
        if [[ "$part" =~ $RE_STR_LIT ]]; then result+="${BASH_REMATCH[1]}"
        elif [[ "$part" =~ $RE_STR_VAR ]]; then result+="$(get_svar "${BASH_REMATCH[1]}\$")"
        else result+="$part"; fi
    done
    echo "$result"
}

# Full expression evaluator - returns "N:value" or "S:value"
eval_expr() {
    local expr; expr=$(trim "$1")
    [[ -z "$expr" ]] && { echo "N:0"; return; }
    if [[ "$expr" =~ $RE_STR_LIT ]]; then echo "S:${BASH_REMATCH[1]}"; return; fi
    if [[ "$expr" =~ $RE_STR_VAR ]]; then echo "S:$(get_svar "${BASH_REMATCH[1]}\$")"; return; fi
    # String functions returning strings
    if [[ "$expr" =~ $RE_FN_LEFT ]]; then
        local s="${BASH_REMATCH[1]}" n="${BASH_REMATCH[2]}" sv nv
        sv=$(eval_string_expr "$s"); nv=$(eval_num_expr "$n")
        nv=$(awk "BEGIN{printf\"%d\",$nv}"); echo "S:${sv:0:$nv}"; return; fi
    if [[ "$expr" =~ $RE_FN_RIGHT ]]; then
        local s="${BASH_REMATCH[1]}" n="${BASH_REMATCH[2]}" sv nv
        sv=$(eval_string_expr "$s"); nv=$(eval_num_expr "$n")
        nv=$(awk "BEGIN{printf\"%d\",$nv}"); echo "S:${sv: -$nv}"; return; fi
    if [[ "$expr" =~ $RE_FN_MID ]]; then
        local s="${BASH_REMATCH[1]}" st="${BASH_REMATCH[2]}" ln="${BASH_REMATCH[3]}" sv stv lnv
        sv=$(eval_string_expr "$s")
        stv=$(awk "BEGIN{printf\"%d\",$(eval_num_expr "$st")}")
        lnv=$(awk "BEGIN{printf\"%d\",$(eval_num_expr "$ln")}")
        echo "S:${sv:$((stv-1)):$lnv}"; return; fi
    if [[ "$expr" =~ $RE_FN_CHR ]]; then
        local v; v=$(eval_num_expr "${BASH_REMATCH[1]}")
        v=$(awk "BEGIN{printf\"%d\",$v}")
        local ch; ch=$(printf "\\$(printf '%03o' "$v")")
        echo "S:$ch"; return; fi
    if [[ "$expr" =~ $RE_FN_TAB ]]; then
        local v; v=$(eval_num_expr "${BASH_REMATCH[1]}")
        v=$(awk "BEGIN{printf\"%d\",$v}")
        printf -v spaces '%*s' "$v" ''; echo "S:$spaces"; return; fi
    if [[ "$expr" =~ $RE_FN_SPC ]]; then
        local v; v=$(eval_num_expr "${BASH_REMATCH[1]}")
        v=$(awk "BEGIN{printf\"%d\",$v}")
        printf -v spaces '%*s' "$v" ''; echo "S:$spaces"; return; fi

    # Check for string content
    if [[ "$expr" == *'"'* ]] || [[ "$expr" == *'$'* ]]; then
        local result; result=$(eval_string_expr "$expr" 2>/dev/null)
        if [[ $? -eq 0 && -n "$result" ]]; then echo "S:$result"; return; fi
    fi

    # Numeric functions - substitute innermost first
    local prev=""
    while [[ "$expr" != "$prev" ]]; do
        prev="$expr"
        if [[ "$expr" =~ $RE_FN_INT ]]; then
            local inner="${BASH_REMATCH[1]}" v iv
            v=$(eval_num_expr "$inner"); iv=$(awk "BEGIN{printf\"%d\",$v}")
            expr="${expr/INT\($inner\)/$iv}"; fi
        if [[ "$expr" =~ $RE_FN_RND ]]; then
            local inner="${BASH_REMATCH[1]}" rv
            rv=$(awk "BEGIN{srand();printf\"%.6f\",rand()}")
            expr="${expr/RND\($inner\)/$rv}"; fi
        if [[ "$expr" =~ $RE_FN_ABS ]]; then
            local inner="${BASH_REMATCH[1]}" v av
            v=$(eval_num_expr "$inner")
            av=$(awk "BEGIN{v=$v;printf\"%g\",(v<0?-v:v)}")
            expr="${expr/ABS\($inner\)/$av}"; fi
        if [[ "$expr" =~ $RE_FN_LEN ]]; then
            local inner="${BASH_REMATCH[1]}" sv lv
            sv=$(eval_string_expr "$inner"); lv=${#sv}
            expr="${expr/LEN\($inner\)/$lv}"; fi
        if [[ "$expr" =~ $RE_FN_ASC ]]; then
            local inner="${BASH_REMATCH[1]}" sv av
            sv=$(eval_string_expr "$inner"); av=$(printf '%d' "'${sv:0:1}")
            expr="${expr/ASC\($inner\)/$av}"; fi
    done

    # Substitute numeric variables A-Z
    local mathexpr="$expr" var
    for var in Z Y X W V U T S R Q P O N M L K J I H G F E D C B A; do
        if [[ "$mathexpr" == *"$var"* ]]; then
            local val; val=$(get_nvar "$var")
            mathexpr="${mathexpr//$var/$val}"
        fi
    done
    mathexpr="${mathexpr//<>/!=}"
    local result
    result=$(awk "BEGIN{printf\"%g\",($mathexpr)}" 2>/dev/null)
    if [[ $? -ne 0 || -z "$result" ]]; then echo "N:0"; else echo "N:$result"; fi
}

eval_num_expr() { local r; r=$(eval_expr "$1"); echo "${r#N:}"; }

eval_condition() {
    local cond="$1"
    local re_scmp='^(.*"[^"]*".*|.*[A-Z]\$)(=|<>|<=|>=|<|>)(.*)'
    if [[ "$cond" =~ $re_scmp ]]; then
        local left op right
        left=$(eval_string_expr "${BASH_REMATCH[1]}")
        op="${BASH_REMATCH[2]}"; right=$(eval_string_expr "${BASH_REMATCH[3]}")
        case "$op" in
            '=')  [[ "$left" == "$right" ]] && echo 1 || echo 0 ;;
            '<>') [[ "$left" != "$right" ]] && echo 1 || echo 0 ;;
            *)    echo 0 ;;
        esac
        return
    fi
    local result; result=$(eval_num_expr "$cond")
    [[ "$result" != "0" ]] && echo 1 || echo 0
}

# ---------------------------------------------------------------------------
# Error reporting
# ---------------------------------------------------------------------------
basic_error() {
    if [[ $RUNNING -eq 1 ]]; then echo "?$1  IN $CUR_LINE"
    else echo "?$1"; fi
}

# ---------------------------------------------------------------------------
# Execute a single BASIC statement
# ---------------------------------------------------------------------------
exec_stmt() {
    local stmt; stmt=$(trim "$1")
    [[ -z "$stmt" ]] && return
    local up; up=$(upper "$stmt")

    # REM
    [[ "$up" == REM* ]] && return

    # PRINT
    if [[ "$up" == "PRINT" ]] || [[ "$up" == PRINT[[:space:]]* ]]; then
        local args=""
        if [[ ${#stmt} -gt 5 ]]; then args=$(trim "${stmt:5}"); fi
        if [[ -z "$args" ]]; then echo; return; fi
        local output="" trailing=1 buf="" in_q=0 i ch
        for (( i=0; i<${#args}; i++ )); do
            ch="${args:$i:1}"
            if [[ "$ch" == '"' ]]; then (( in_q = !in_q )); buf+="$ch"
            elif [[ "$ch" == ';' && $in_q -eq 0 ]]; then
                local r; r=$(eval_expr "$buf"); output+="${r#[NS]:}"; buf=""; trailing=0
            elif [[ "$ch" == ',' && $in_q -eq 0 ]]; then
                local r; r=$(eval_expr "$buf"); output+="${r#[NS]:}"
                local col=${#output} nxt=$(( ((${#output}/14)+1)*14 ))
                local pad; printf -v pad '%*s' "$(( nxt - col ))" ''
                output+="$pad"; buf=""; trailing=0
            else buf+="$ch"; fi
        done
        if [[ -n "$buf" ]]; then
            local r; r=$(eval_expr "$buf"); output+="${r#[NS]:}"; trailing=1
        fi
        if [[ $trailing -eq 1 ]]; then echo "$output"; else printf '%s' "$output"; fi
        return
    fi

    # LET string: A$="..."
    if [[ "$up" =~ $RE_LET_STR ]]; then
        set_svar "${BASH_REMATCH[2]}\$" "$(eval_string_expr "${BASH_REMATCH[3]}")"; return; fi
    # LET numeric: A=expr
    if [[ "$up" =~ $RE_LET_NUM ]]; then
        set_nvar "${BASH_REMATCH[2]}" "$(eval_num_expr "${BASH_REMATCH[3]}")"; return; fi

    # INPUT
    if [[ "$up" =~ $RE_INPUT ]]; then
        local rest; rest=$(trim "${stmt:6}")
        local pstr="? "
        if [[ "$rest" =~ $RE_INPUT_P ]] || [[ "$rest" =~ $RE_INPUT_P2 ]]; then
            pstr="${BASH_REMATCH[1]}"; rest=$(trim "${BASH_REMATCH[2]}")
        fi
        local vn; vn=$(upper "$rest")
        local iv
        read -rep "$pstr" iv
        if [[ "$vn" =~ $RE_STR_VAR ]]; then set_svar "${BASH_REMATCH[1]}\$" "$iv"
        elif [[ "$vn" =~ $RE_NUM_VAR ]]; then
            set_nvar "$vn" "$(awk "BEGIN{printf\"%g\",$iv+0}" 2>/dev/null || echo 0)"
        else basic_error "SYNTAX ERROR"; fi
        return
    fi

    # GOTO
    if [[ "$up" =~ $RE_GOTO ]]; then GOTO_TGT="${BASH_REMATCH[1]}"; return; fi

    # GOSUB
    if [[ "$up" =~ $RE_GOSUB ]]; then
        GOSUB_STACK+=("$CUR_LINE"); GOTO_TGT="${BASH_REMATCH[1]}"; return; fi

    # RETURN
    if [[ "$up" == "RETURN" ]]; then
        if [[ ${#GOSUB_STACK[@]} -eq 0 ]]; then basic_error "RETURN WITHOUT GOSUB"; return; fi
        local ri=$(( ${#GOSUB_STACK[@]} - 1 ))
        local rl="${GOSUB_STACK[$ri]}"
        unset "GOSUB_STACK[$ri]"
        GOSUB_STACK=("${GOSUB_STACK[@]}")
        GOTO_TGT="RETURN:$rl"; return
    fi

    # FOR
    if [[ "$up" =~ $RE_FOR ]]; then
        local var="${BASH_REMATCH[1]}" se="${BASH_REMATCH[2]}" ee="${BASH_REMATCH[3]}" ste="${BASH_REMATCH[5]:-1}"
        set_nvar "$var" "$(eval_num_expr "$se")"
        local lim stp; lim=$(eval_num_expr "$ee"); stp=$(eval_num_expr "$ste")
        FOR_STACK+=("$var|$lim|$stp|$CUR_LINE"); return
    fi

    # NEXT
    if [[ "$up" =~ $RE_NEXT ]]; then
        local nv="${BASH_REMATCH[1]}"
        if [[ ${#FOR_STACK[@]} -eq 0 ]]; then basic_error "NEXT WITHOUT FOR"; return; fi
        local ti=$(( ${#FOR_STACK[@]} - 1 ))
        local top="${FOR_STACK[$ti]}"
        IFS='|' read -r fvar flim fstp fln <<< "$top"
        if [[ -n "$nv" && "$nv" != "$fvar" ]]; then basic_error "NEXT WITHOUT FOR"; return; fi
        local cur; cur=$(get_nvar "$fvar")
        local nw; nw=$(awk "BEGIN{printf\"%g\",$cur+$fstp}")
        set_nvar "$fvar" "$nw"
        local df; df=$(awk "BEGIN{if($fstp>0&&$nw>$flim)print 1;else if($fstp<0&&$nw<$flim)print 1;else print 0}")
        if [[ "$df" == "1" ]]; then
            unset "FOR_STACK[$ti]"; FOR_STACK=("${FOR_STACK[@]}")
        else
            GOTO_TGT="FOR:$fln"
        fi
        return
    fi

    # IF ... THEN
    if [[ "$up" =~ $RE_IF ]]; then
        local tp; tp=$(awk -v s="$up" 'BEGIN{q=0;n=length(s);for(i=1;i<=n;i++){c=substr(s,i,1);if(c=="\"")q=!q;if(!q&&substr(s,i,5)==" THEN"){print i;exit}};print -1}')
        if [[ "$tp" -lt 0 ]]; then basic_error "SYNTAX ERROR"; return; fi
        local rc="${stmt:3:$((tp-4))}" rt="${stmt:$((tp+4))}"
        rc=$(trim "$rc"); rt=$(trim "$rt")
        local cv; cv=$(eval_condition "$rc")
        if [[ "$cv" == "1" ]]; then
            if [[ "$rt" =~ $RE_DIGITS ]]; then GOTO_TGT="$rt"; else exec_stmt "$rt"; fi
        fi
        return
    fi

    # END / STOP
    if [[ "$up" == "END" || "$up" == "STOP" ]]; then RUNNING=0; return; fi
    # CLS / CLR
    if [[ "$up" == "CLS" || "$up" == "CLR" ]]; then clear; return; fi
    # NEW
    if [[ "$up" == "NEW" ]]; then
        kv_clear PROG; kv_clear NUMV; kv_clear STRV; FOR_STACK=(); GOSUB_STACK=(); return; fi

    basic_error "SYNTAX ERROR"
}

# ---------------------------------------------------------------------------
# RUN
# ---------------------------------------------------------------------------
run_program() {
    RUNNING=1; BREAK_REQ=0; FOR_STACK=(); GOSUB_STACK=(); GOTO_TGT=""
    local lines_arr=()
    while IFS= read -r ln; do [[ -n "$ln" ]] && lines_arr+=("$ln"); done < <(sorted_lines)
    [[ ${#lines_arr[@]} -eq 0 ]] && { RUNNING=0; return; }
    local idx=0
    while [[ $idx -lt ${#lines_arr[@]} && $RUNNING -eq 1 ]]; do
        if [[ $BREAK_REQ -eq 1 ]]; then echo; echo "BREAK IN ${lines_arr[$idx]}"; RUNNING=0; return; fi
        CUR_LINE="${lines_arr[$idx]}"
        local src; src=$(kv_get PROG "$CUR_LINE")
        GOTO_TGT=""
        # Split on : outside quotes
        local stmts=() buf="" iq=0 j ch
        for (( j=0; j<${#src}; j++ )); do
            ch="${src:$j:1}"
            if [[ "$ch" == '"' ]]; then (( iq=!iq )); buf+="$ch"
            elif [[ "$ch" == ':' && $iq -eq 0 ]]; then stmts+=("$buf"); buf=""
            else buf+="$ch"; fi
        done
        stmts+=("$buf")
        for s in "${stmts[@]}"; do
            exec_stmt "$s"
            [[ $RUNNING -eq 0 ]] && break
            if [[ -n "$GOTO_TGT" ]]; then
                if [[ "$GOTO_TGT" == RETURN:* ]]; then
                    local ret="${GOTO_TGT#RETURN:}"
                    for (( k=0; k<${#lines_arr[@]}; k++ )); do
                        if [[ "${lines_arr[$k]}" == "$ret" ]]; then idx=$((k+1)); break 2; fi
                    done
                elif [[ "$GOTO_TGT" == FOR:* ]]; then
                    local fl="${GOTO_TGT#FOR:}"
                    for (( k=0; k<${#lines_arr[@]}; k++ )); do
                        if [[ "${lines_arr[$k]}" == "$fl" ]]; then idx=$((k+1)); break 2; fi
                    done
                else
                    local found=0
                    for (( k=0; k<${#lines_arr[@]}; k++ )); do
                        if [[ "${lines_arr[$k]}" == "$GOTO_TGT" ]]; then idx=$k; found=1; break 2; fi
                    done
                    [[ $found -eq 0 ]] && { basic_error "UNDEF'D STATEMENT"; RUNNING=0; break; }
                fi
            fi
        done
        [[ -z "$GOTO_TGT" ]] && (( idx++ ))
    done
    RUNNING=0
}

# ---------------------------------------------------------------------------
# LIST
# ---------------------------------------------------------------------------
list_program() {
    while IFS= read -r ln; do
        [[ -n "$ln" ]] && echo "$ln $(kv_get PROG "$ln")"
    done < <(sorted_lines)
}

# ---------------------------------------------------------------------------
# Sample programs
# ---------------------------------------------------------------------------
load_sample() {
    local name; name=$(upper "$1")
    kv_clear PROG
    case "$name" in
        HELLO)
            kv_set PROG 10 'PRINT "HELLO WORLD"'; kv_set PROG 20 'END'
            echo "LOADED: HELLO" ;;
        COUNT)
            kv_set PROG 10 'FOR I=1 TO 10'; kv_set PROG 20 'PRINT I'
            kv_set PROG 30 'NEXT I'; kv_set PROG 40 'END'
            echo "LOADED: COUNT" ;;
        GUESS)
            kv_set PROG 10 'LET N=INT(RND(1)*100)+1'
            kv_set PROG 20 'PRINT "GUESS A NUMBER (1-100)"'
            kv_set PROG 30 'INPUT "YOUR GUESS? ";G'
            kv_set PROG 40 'LET T=T+1'
            kv_set PROG 50 'IF G=N THEN 100'
            kv_set PROG 60 'IF G<N THEN PRINT "TOO LOW"'
            kv_set PROG 70 'IF G>N THEN PRINT "TOO HIGH"'
            kv_set PROG 80 'GOTO 30'
            kv_set PROG 100 'PRINT "CORRECT IN ";T;" TRIES!"'
            kv_set PROG 110 'END'
            echo "LOADED: GUESS" ;;
        BANNER)
            kv_set PROG 10 'PRINT "  ****  "'; kv_set PROG 20 'PRINT " *    * "'
            kv_set PROG 30 'PRINT " *      "'; kv_set PROG 40 'PRINT " *      "'
            kv_set PROG 50 'PRINT " *    * "'; kv_set PROG 60 'PRINT "  ****  "'
            kv_set PROG 70 'PRINT'; kv_set PROG 80 'PRINT " COMMODORE "'
            kv_set PROG 90 'PRINT "   BASIC   "'; kv_set PROG 100 'END'
            echo "LOADED: BANNER" ;;
        *) basic_error "FILE NOT FOUND" ;;
    esac
}

save_program() {
    local fname="${1:-$SAVE_FILE}"
    > "$fname"
    while IFS= read -r ln; do
        [[ -n "$ln" ]] && echo "$ln $(kv_get PROG "$ln")" >> "$fname"
    done < <(sorted_lines)
    echo "SAVED"
}

load_file() {
    local fname="$1"
    [[ ! -f "$fname" ]] && { basic_error "FILE NOT FOUND"; return; }
    kv_clear PROG
    while IFS= read -r line; do
        if [[ "$line" =~ $RE_LINE ]]; then
            kv_set PROG "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}"
        fi
    done < "$fname"
    echo "LOADED"
}

# ---------------------------------------------------------------------------
# Process one line of input
# ---------------------------------------------------------------------------
process_input() {
    local line; line=$(to_upper "$1")
    # Spectrum keyword expansion: single-letter shortcut at start of command line
    # Only expand if the line is exactly 1 char or does not already begin with the keyword
    if [[ "$ERA" == "spectrum" && -n "$line" ]]; then
        local first="${line:0:1}" kw
        local re_notnum='^[^0-9]'
        if kw=$(spec_keyword "$first") && [[ "$line" =~ $re_notnum ]]; then
            local kw_trimmed; kw_trimmed=$(trim "$kw")
            local line_up; line_up=$(upper "$line")
            if [[ "$line_up" != "$kw_trimmed"* ]]; then
                line="${kw}${line:1}"
            fi
        fi
    fi
    [[ -z "$line" ]] && return
    # Line number + statement
    if [[ "$line" =~ $RE_LINE ]]; then
        local lnum="${BASH_REMATCH[1]}" body="${BASH_REMATCH[2]}"
        if [[ -z "$body" ]]; then kv_del PROG "$lnum"; else kv_set PROG "$lnum" "$body"; fi
        return
    fi
    local cmd="${line%% *}"
    case "$cmd" in
        RUN)  run_program; print_ready ;;
        LIST) list_program ;;
        NEW)  kv_clear PROG; kv_clear NUMV; kv_clear STRV; FOR_STACK=(); GOSUB_STACK=(); print_ready ;;
        CLR|CLS) clear ;;
        SAVE)
            local arg; arg=$(trim "${line#SAVE}"); arg="${arg//\"/}"
            if [[ -n "$arg" ]]; then save_program "/tmp/basic_${arg}.bas"; else save_program; fi ;;
        LOAD)
            local arg; arg=$(trim "${line#LOAD}"); arg="${arg//\"/}"
            if [[ -z "$arg" ]]; then load_file "$SAVE_FILE"
            elif [[ -f "/tmp/basic_${arg}.bas" ]]; then load_file "/tmp/basic_${arg}.bas"
            else load_sample "$arg"; fi
            print_ready ;;
        BYE|QUIT|EXIT|SYSTEM) echo "BYE"; exit 0 ;;
        *) exec_stmt "$line" ;;
    esac
}

# ---------------------------------------------------------------------------
# Main loop
# ---------------------------------------------------------------------------
show_boot

while true; do
    local_prompt=$(get_prompt)
    if ! line=$(era_readline "$local_prompt"); then echo; exit 0; fi
    process_input "$line"
done
