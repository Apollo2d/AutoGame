#!/usr/bin/env bash
# set -x
# TODO: more flags is needed
# TODO: document the necessary configuration
LD_LIBRARY_PATH=".:./lib"
export LD_LIBRARY_PATH

function add_log {
  echo -e "$(date) Worker: $*" >>"$LOG_FILE"
}

if [ $# -lt 4 ]; then
  cat <<EOF
Need at least 4 arguments
arg1: left team start.sh
arg2: right team start.sh
arg3: penalty only flag
arg4: debug flag
EOF
  # arg5: other options
  exit 254
fi

BASE_DIR="$(dirname "$(readlink -f "$0")")"
LOG_DIR="$BASE_DIR/log/$(date +%Y%m%d%H%M%S)"
mkdir -p "$LOG_DIR"

# get configurations
function get_conf {
  if [ -f "$BASE_DIR/config.sh" ]; then
    source "$BASE_DIR/config.sh"
  else
    add_log "Cannot find $BASE_DIR/config.sh. Generate one now. Modified it before running"
    cp "$BASE_DIR/example.config.sh" "$BASE_DIR/config.sh"
    exit 253
  fi
}

function get_team_conf {
  # Random side
  if [ $((RANDOM % 2)) -eq 0 ]; then
    left=$1
    right=$2
  else
    left=$2
    right=$1
  fi

  # get necessary team information
  if [ -f "$left" ]; then
    left_team=$(dirname "$(readlink -f "$left")")
    left_team_name=$(basename "$left_team")
    left_player=$(find "$left_team" -iname "*player")
    left_player_config=$(find "$left_team" -iname "player.conf")
    left_coach=$(find "$left_team" -iname "*coach")
    left_coach_config=$(find "$left_team" -iname "*coach.conf")
    left_config_dir=$(find "$left_team" -iname "formations-dt")
    # server arguments
    left_player_args="--player-config $left_player_config --config_dir $left_config_dir"
    left_coach_args="--coach-config $left_coach_config --use_team_graphic on"
  else
    add_log "Cannot find left team: $1"
    exit 255
  fi
  if [ -f "$right" ]; then
    right_team=$(dirname "$(readlink -f "$right")")
    right_team_name=$(basename "$right_team")
    right_player=$(find "$right_team" -iname "*player")
    right_player_config=$(find "$right_team" -iname "player.conf")
    right_coach=$(find "$right_team" -iname "*coach")
    right_coach_config=$(find "$right_team" -iname "*coach.conf")
    right_config_dir=$(find "$right_team" -iname "formations-dt")
    # server arguments
    right_player_args="--player-config $right_player_config --config_dir $right_config_dir"
    right_coach_args="--coach-config $right_coach_config --use_team_graphic on"
  else
    add_log "Cannot find right team: $2"
    exit 255
  fi
}

function get_server_conf {
  server_args="server::auto_mode=on"
  server_args="$server_args CSVSaver::save=on"
  server_args="$server_args server::text_log_dir=$LOG_DIR"
  server_args="$server_args server::game_log_dir=$LOG_DIR"
  if [ "$1" = true ]; then
    server_args="server::half_time=1 $server_args"
    server_args="server::nr_normal_halfs=1 $server_args"
    server_args="server::extra_half_time=0 $server_args"
    server_args="server::nr_extra_halfs=0 $server_args"
    server_args="server::penalty_shoot_outs=on $server_args"
  fi
  if [ "$2" = true ]; then
    left_player_args="--debug --log_dir $LOG_DIR $left_player_args"
    left_coach_args="--debug --log_dir $LOG_DIR $left_coach_args"
    right_player_args="--debug --log_dir $LOG_DIR $right_player_args"
    right_coach_args="--debug --log_dir $LOG_DIR $right_coach_args"
  fi
  port=6000
  while [[ -n "$(lsof -i:$port)" &&
  -n "$(lsof -i:$((port + 1)))" &&
  -n "$(lsof -i:$((port + 2)))" ]]; do
    port=$((port + 3))
  done
  server_args="server::port=$port $server_args"
  server_args="server::olcoach_port=$((port + 2)) $server_args"
  server_args="server::coach_port=$((port + 1)) $server_args"
  left_player_args="-p $port $left_player_args"
  left_coach_args="-p $((port + 2)) $left_coach_args"
  right_player_args="-p $port $right_player_args"
  right_coach_args="-p $((port + 2)) $right_player_args"
}

function get_start {
  cd "$LOG_DIR" || exit 255
  rcssserver $server_args &>$LOG_DIR/server.log &
  server_pid=$!
  sleep 1
  if [ "$left_team_name" = "$right_team_name" ]; then
    cd "$BASE_DIR" || exit 255
    right_team_name="$right_team_name-2"
  fi

  {
    cd "$left_team" || exit 255
    for ((i = 1; i <= 12; ++i)); do
      case $i in
      1)
        $left_player -g $left_player_args -t $left_team_name &>$LOG_DIR/$left_team_name-player-$i.out.log &
        ;;
      12)
        $left_coach $left_coach_args -t $left_team_name &>$LOG_DIR/$left_team_name-coach.out.log &
        ;;
      *)
        $left_player $left_player_args -t $left_team_name &>$LOG_DIR/$left_team_name-player-$i.out.log &
        ;;
      esac
      left_pid[$i]=$!
    done
  }

  {
    cd "$right_team" || exit 255
    for ((i = 0; i < 12; ++i)); do
      case $i in
      1)
        $right_player -g $right_player_args -t $right_team_name &>$LOG_DIR/$right_team_name-player-$i.out.log &
        ;;
      12)
        $right_coach $right_coach_args -t $right_team_name &>$LOG_DIR/$right_team_name-coach.out.log &
        ;;
      *)
        $right_player $right_player_args -t $right_team_name &>$LOG_DIR/$right_team_name-player-$i.out.log &
        ;;
      esac
      right_pid[$i]=$!
    done
  }
}

function get_stop {
  # kill -INT "${left_pid[@]}"
  set -x
  add_log "$left_team_name VS $right_team_name in port: $port [Interupted]"
  kill -INT "${left_pid[@]}" "${right_pid[@]}"
  kill -INT "$server_pid"
  exit "$1"
}

function get_check {
  sleep 5
  local count
  count=1
  for pid in "${left_pid[@]}" "${right_pid[@]}"; do
    if [ ! -e "/proc/$pid" ]; then
      if [ $count -gt 12 ]; then
        side=$right_team_name
      else
        side=$left_team_name
      fi
      if [ $((count % 12)) -eq 0 ]; then
        info="coach"
      else
        info="player-$((count % 12))"
      fi
      add_log "Error: $side $info didn't work"
      add_log "Please check $LOG_DIR/$side-$info.out.log"
    fi
    ((++count))
  done
  add_log "$left_team_name VS $right_team_name in port: $port [Start]"

}

# trap signal

trap "get_stop 0" HUP INT

get_team_conf "$1" "$2"
get_server_conf "$3" "$4"
get_start
get_check

wait $server_pid

add_log "$left_team_name VS $right_team_name in port: $port [Finished]"
