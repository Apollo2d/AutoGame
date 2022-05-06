#!/usr/bin/env bash

MASTER_TEAM=/home/kawhicurry/Code/Apollo/NewApolloBase/build/Apollo-exe/start.sh

# cpu load limit
CORE=$(nproc)
LOAD_RATE=0.7
MAX_LOAD=$(echo "$CORE * $LOAD_RATE" | bc)

# memory limit
MEMORY=$(free -t | awk '/Total/||/总量/ {print $2}')
MEM_RATE=0.6
MAX_MEM=$(echo "$MEMORY * $MEM_RATE" | bc)

# manual limit
MAX_RUN=5

SLEEP_TIME=5 # seconds

BASE_DIR="$(dirname "$(readlink -f "$0")")"
BIN_DIR="$BASE_DIR/bin"

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
      LOAD="$(uptime | awk '{print $10}' | sed 's/,//g')"
      USED_MEM="$(free -t | awk '/Total/||/总量]/ {print $3}')"
      RUNNING="$(pgrep -c rcssserver)"
      echo -ne "\rCurrent Load: $LOAD/$MAX_LOAD/$CORE Current Memory:$USED_MEM/$MAX_MEM/$MEMORY"
      if [[ ("$(echo "$LOAD < $MAX_LOAD" | bc)" -eq 1) && ("$(echo "$USED_MEM < $MAX_MEM" | bc)" -eq 1) && ("$(echo "$RUNNING < $MAX_RUN" | bc)" -eq 1) ]]; then
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

get_team "$BIN_DIR"

if [ -z "${TEAMS[0]}" ]; then
  echo "Teams is empty"
  exit 254
fi
# echo "${TEAMS[@]}"
get_start
