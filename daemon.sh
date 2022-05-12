#!/usr/bin/env bash

BASE_DIR="$(dirname "$(readlink -f "$0")")"
BIN_DIR="$BASE_DIR/bin"

cd "$BASE_DIR" || exit 255

declare -a server_list
declare -a team_list
declare -i end start
end=0
start=0

function add_log {
  echo -e "$(date) Daemon: $*" >>"$LOG_FILE"
}

function show_team {
  add_log "server_list" "${server_list[@]}"
}

function get_conf {
  # get configurations
  if [ -f "$BASE_DIR/config.sh" ]; then
    source "$BASE_DIR/config.sh"
  else
    add_log "Cannot find $BASE_DIR/config.sh. Generate one now. Modified it before running"
    cp "$BASE_DIR/example.config.sh" "$BASE_DIR/config.sh"
    get_stop 253
  fi
  # get team
  team_list=($(find "$BIN_DIR" -name "start.sh"))
}

function get_limit {
  load="$(uptime | grep -o 'average:.*' | awk '{print $2}' | sed 's/,//g')"
  used_mem="$(free -t | awk '/Total/||/总量/ {print $3}')"
  # running="$(pgrep -c rcssserver)"
  running="${#server_list[@]}"
  # if [ $((COUNT - running)) -ge "$MAX_RUN_TOTAL" ]; then
  #   add_log "Finished all $MAX_RUN_TOTAL games"
  #   exit 0
  # fi
  if [ "$(echo "$load >= $MAX_LOAD" | bc)" -eq 1 ]; then
    add_log "Restricted by load: $load/$MAX_LOAD"
    return 1
  elif [ "$(echo "$used_mem >= $MAX_MEM" | bc)" -eq 1 ]; then
    add_log "Restricted by mem: $used_mem/$MAX_MEM"
    return 2
  elif [ "$(echo "$running >= $MAX_RUNNING" | bc)" -eq 1 ]; then
    add_log "Restricted by running: $running/$MAX_RUNNING"
    return 3
  else
    add_log "Not restricted. Conditions:load:$load mem:$used_mem running:$running"
    return 0
  fi
}

# 255 directory not exist
# 254 file not exist
# 253 lost configuration file
# 252 duplicate daemon
# 251 lock lost
function get_stop {
  status="$1"
  shift
  if [ -n "$*" ]; then
    add_log "$*"
  fi
  if [ "$status" -eq 0 ]; then
    for i in "${!server_list[@]}"; do
      add_log "kill ${server_list[$i]} with HUP"
      kill -INT "${server_list[$i]}"
    done
  else
    for i in "${!server_list[@]}"; do
      add_log "kill ${server_list[$i]} with INT"
      kill -INT "${server_list[$i]}"
    done
    if [ "$status" -eq 251 ]; then
      add_log "Lock is removed!"
    elif [ "$status" -eq 252 ]; then
      add_log "Another daemon is running"
    fi
  fi
  if [ "$status" -ne 251 ]; then
    rm "$LOCK_FILE"
  fi

  add_log "Daemon is stopped"
  exit "$status"
}

function get_loop {
  killall rcssserver
  while :; do
    for ((i = 0; i < ${#team_list[@]}; ++i)); do
      if [ ! -e "$LOCK_FILE" ]; then
        get_stop 251
      fi

      if get_limit; then
        "$BASE_DIR/worker.sh" "$MASTER_TEAM" "${team_list[$i]}" $PEN_ONLY $DEBUG &
        server_list[$start]=$!
        ((start++))
        sleep 1
      else
        #for ((j = 0; j <= ; j++)); do
        for j in "${!server_list[@]}"; do
          if [ ! -e "/proc/${server_list[$j]}" ]; then
            unset "server_list[$j]"
          fi
        done
        start=${#server_list[@]}
        sleep 5
        continue
      fi
    done
  done
}

if [ -e "$LOCK_FILE" ]; then
  echo "Another daemon is running"
  get_stop 252
else
  echo "New daemon start"
fi

get_conf

trap "get_conf" USR1
trap "get_stop 0" INT HUP
trap "show_team" USR2

daemon_pid=$$
echo "$daemon_pid" >"$LOCK_FILE"
get_loop &>>"$LOG_FILE"

wait
