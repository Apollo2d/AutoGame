#!/usr/bin/env bash

# TODO: more flags is needed
# TODO: document the necessary configuration

if [ $# -lt 4 ]; then
  cat <<EOF
Need at least 4 arguments
arg1: left team start.sh
arg2: right team start.sh
arg3: penalty only flag
arg4: debug flag
arg5: other options
EOF
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
    echo "Cannot find $BASE_DIR/config.sh. Generate one now. Modified it before running"
    cp "$BASE_DIR/example.config.sh" "$BASE_DIR/config.sh"
    exit 253
  fi
}

function get_team_conf {
  if [ -f "$1" ]; then
    left_team=$(dirname "$(readlink -f "$1")")
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
    echo "Cannot find left team: $1"
    exit 255
  fi
  if [ -f "$2" ]; then
    right_team=$(dirname "$(readlink -f "$2")")
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
    echo "Cannot find right team: $2"
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
  rcssserver $server_args &>$LOG_DIR/server.log &

  server_pid=$!
  sleep 1
  if [ "$left_team_name" = "$right_team_name" ]; then
    cd "$BASE_DIR" || exit 255
    right_team_name="$right_team_name-2"
  fi

  {
    cd "$left_team" || exit 255
    # deal with librcsc
    if [ -n "$(find "$left_team" -name "librcsc.so")" ]; then
      LD_LIBRARY_PATH=.
      export LD_LIBRARY_PATH
    fi
    for ((i = 1; i <= 12; ++i)); do
      case $i in
      1)
        $left_player -g $left_player_args -t $left_team_name &>$LOG_DIR/$left_team_name-$i.out.log &
        ;;
      12)
        $left_coach $left_coach_args -t $left_team_name &>$LOG_DIR/$left_team_name-coach.out.log &
        ;;
      *)
        $left_player $left_player_args -t $left_team_name &>$LOG_DIR/$left_team_name-$i.out.log &
        ;;
      esac
      left_pid[$i]=$!
    done
    unset LD_LIBRARY_PATH
  }

  {
    # deal with librcsc
    if [ -n "$(find "$right_team" -name "librcsc.so")" ]; then
      cd "$right_team" || exit 255
      export LD_LIBRARY_PATH=.
      echo $LD_LIBRARY_PATH
    fi
    for ((i = 1; i <= 12; ++i)); do
      case $i in
      1)
        $right_player -g $right_player_args -t $right_team_name &>$LOG_DIR/$right_team_name-$i.out.log &
        ;;
      12)
        $right_coach $right_coach_args -t $right_team_name &>$LOG_DIR/$right_team_name-coach.out.log &
        ;;
      *)
        $right_player $right_player_args -t $right_team_name &>$LOG_DIR/$right_team_name-$i.out.log &
        ;;
      esac
      right_pid[$i]=$!
    done
    unset LD_LIBRARY_PATH
  }
}

function get_check {
  sleep 5
  for pid in "${left_pid[@]}"; do
    echo $pid
  done
  for pid in "${right_pid[@]}"; do
    echo 123
  done
  wait $server_pid
  exit 0
}

get_team_conf "$1" "$2"
get_server_conf "$3" "$4"
get_start
get_check
