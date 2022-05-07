#!/usr/bin/env bash

BASE_DIR="$(dirname "$(readlink -f "$0")")"

if [ -f "$BASE_DIR/config.sh" ]; then
  source "$BASE_DIR/config.sh"
else
  echo "Cannot find $BASE_DIR/config.sh. Generate one now. Modified it before running"
  cp "$BASE_DIR/example.config.sh" "$BASE_DIR/config.sh"
  exit 253
fi

declare -a TEAMS

cd "$BASE_DIR" || exit 255

# TODO：使用信号一进行热重载
i=0
function get_team {
  local dirs
  dirs=$1
  for dir in "$dirs"/*; do
    if [ -d "$dir" ]; then
      if [ -x "$dir/start.sh" ]; then
        TEAMS[i]="$dir/start.sh"
        i=$((++i))
      else
        get_team "$dir"
      fi
    fi
  done
}

function get_start {
  # Start game
  while true; do
    for ((i = 0; i < ${#TEAMS[@]}; ++i)); do
      LOAD="$(uptime | grep -o 'average:.*' | awk '{print $2}' | sed 's/,//g')"
      USED_MEM="$(free -t | awk '/Total/||/总量/ {print $3}')"
      RUNNING="$(pgrep -c rcssserver)"
      echo -ne "\rCurrent/Limit Load: $LOAD/$MAX_LOAD Memory:$USED_MEM/$MAX_MEM Running:$RUNNING/$MAX_RUNNING"
      if [[ ("$(echo "$LOAD < $MAX_LOAD" | bc)" -eq 1) && ("$(echo "$USED_MEM < $MAX_MEM" | bc)" -eq 1) && ("$(echo "$RUNNING < $MAX_RUNNING" | bc)" -eq 1) ]]; then
        echo -ne "\r                                                                                                                    \r"
        echo -ne "Start game with ${TEAMS[i]}\n"
        "$BASE_DIR"/1vs1.sh -l "$MASTER_TEAM" -r "${TEAMS[i]}"
      else
        sleep $SLEEP_TIME
        continue
      fi
    done
  done
}

get_team "$BASE_DIR/bin"
if [ -z "${TEAMS[0]}" ]; then
  echo "Teams is empty"
  exit 254
fi
# echo "${TEAMS[@]}"
get_start
