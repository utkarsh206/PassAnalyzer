#!/bin/bash

RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
CYAN=$(tput setaf 6)
RESET=$(tput sgr0)

DICT="/usr/share/dict/words"

print_banner() {
echo "${CYAN}"
echo "╔══════════════════════════════╗"
echo "║        PassAnalyzer          ║"
echo "║  Advanced Password Auditor   ║"
echo "╚══════════════════════════════╝"
echo "${RESET}"
}

entropy_calc() {
pass="$1"
len=${#pass}
pool=0

[[ "$pass" =~ [a-z] ]] && pool=$((pool+26))
[[ "$pass" =~ [A-Z] ]] && pool=$((pool+26))
[[ "$pass" =~ [0-9] ]] && pool=$((pool+10))
[[ "$pass" =~ [^a-zA-Z0-9] ]] && pool=$((pool+32))

entropy=$(echo "$len * l($pool)/l(2)" | bc -l 2>/dev/null)
printf "%.2f" "$entropy"
}

check_dictionary() {
pass="$1"
if [[ -f "$DICT" ]]; then
grep -i -w "$pass" "$DICT" >/dev/null && echo "yes" || echo "no"
else
echo "no"
fi
}

pattern_check() {
pass="$1"
[[ "$pass" =~ (.)\1\1 ]] && echo "repeat" && return
[[ "$pass" =~ 123|abc|qwerty ]] && echo "sequence" && return
echo "clean"
}

score_calc() {
pass="$1"
score=0
len=${#pass}

(( len >= 8 )) && score=$((score+20))
(( len >= 12 )) && score=$((score+20))

[[ "$pass" =~ [a-z] ]] && score=$((score+10))
[[ "$pass" =~ [A-Z] ]] && score=$((score+10))
[[ "$pass" =~ [0-9] ]] && score=$((score+10))
[[ "$pass" =~ [^a-zA-Z0-9] ]] && score=$((score+20))

dict=$(check_dictionary "$pass")
[[ "$dict" == "yes" ]] && score=$((score-30))

pattern=$(pattern_check "$pass")
[[ "$pattern" != "clean" ]] && score=$((score-20))

(( score < 0 )) && score=0
(( score > 100 )) && score=100

echo $score
}

strength_label() {
score=$1
if (( score < 30 )); then echo "Weak"
elif (( score < 60 )); then echo "Medium"
elif (( score < 80 )); then echo "Strong"
else echo "Very Strong"
fi
}

bar() {
score=$1
filled=$((score/5))
empty=$((20-filled))

printf "["
for ((i=0;i<filled;i++)); do printf "#"; done
for ((i=0;i<empty;i++)); do printf "-"; done
printf "]"
}

analyze() {
pass="$1"

entropy=$(entropy_calc "$pass")
score=$(score_calc "$pass")
label=$(strength_label $score)

echo -e "${BLUE}Password:${RESET} $pass"
echo -e "${BLUE}Length:${RESET} ${#pass}"
echo -e "${BLUE}Entropy:${RESET} $entropy bits"
echo -e "${BLUE}Score:${RESET} $score/100 $(bar $score)"

if [[ "$label" == "Weak" ]]; then color=$RED
elif [[ "$label" == "Medium" ]]; then color=$YELLOW
else color=$GREEN
fi

echo -e "${BLUE}Strength:${RESET} ${color}$label${RESET}"
echo ""
}

print_banner

if [[ "$1" == "-p" ]]; then
analyze "$2"
else
read -s -p "Enter Password: " pass
echo ""
analyze "$pass"
fi
