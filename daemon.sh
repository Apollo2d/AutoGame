#!/usr/bin/env bash

BASE_DIR="$(dirname "$(readlink -f "$0")")"
BIN_DIR="$BASE_DIR/bin"

cd "$BASE_DIR" || exit 255

declare -a server_list
declare -a team_list
declare -i count
count=0

function add_log {
  echo -e "$(date) Daemon: $*" >>"$LOG_FILE"
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

  if [ -z "${server_list[*]}" ]; then
    kill -INT "${server_list[@]}"
  fi

  case "$status" in
  255)
    add_log "Directory $* not exist"
    rm -f "$LOCK_FILE"
    ;;
  254)
    add_log "File $* not exist"
    rm -f "$LOCK_FILE"
    ;;
  253)
    add_log "Configfile not exist"
    rm -f "$LOCK_FILE"
    ;;
  252) add_log "Another daemon is running" ;;
  251)
    add_log "Lock problem $*"
    rm -f "$LOCK_FILE"
    ;;
  0)
    add_log "Normal exit"
    rm -f "$LOCK_FILE"
    ;;
  *)
    add_log "$*"
    ;;
  esac

  add_log "Daemon is stopped"
  exit "$status"
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
  # running="${#server_list[@]}"
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

function get_loop {
  killall rcssserver
  add_log "Daemon start"
  while :; do
    for ((i = 0; i < ${#team_list[@]}; ++i)); do
      if [ ! -e "$LOCK_FILE" ]; then
        get_stop 251 "Lock lost"
      fi

      running=0
      for j in "${!server_list[@]}"; do
        if [ -e "/proc/${server_list[$j]}" ]; then
          ((running++))
        else
          unset "server_list[$j]"
        fi
      done

      if get_limit; then
        "$BASE_DIR/worker.sh" "$MASTER_TEAM" "${team_list[$i]}" $PEN_ONLY $DEBUG &
        server_list[$count]=$!
        ((count++))
        sleep 1
      else
        sleep 5
        continue
      fi

    done
  done
}

get_conf

if [ -e "$LOCK_FILE" ]; then
  if [ -e "/proc$(cat "$LOCK_FILE")" ]; then
    echo "Another daemon is running"
    get_stop 252
  else
    echo "Can't find daemon, remove lock now"
    get_stop 251 "Can't find daemon"
  fi
else
  echo "New daemon start"
  daemon_pid=$$
  if [ ! -e "$LOG_FILE" ]; then
    touch "$LOG_FILE"
  fi
  echo "$daemon_pid" >"$LOCK_FILE"
fi

trap "get_stop 0" INT
trap "get_conf" USR1
trap "show_team" USR2

get_loop &>>"$LOG_FILE"
