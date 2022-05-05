#!/usr/bin/env bash

PORT=6000
MAX_PORT=6300

BASE_DIR="$(dirname "$(readlink -f "$0")")"
# BIN_DIR="$BASE_DIR/bin"

LOG_DIR="$BASE_DIR/log/$(date +%Y%m%d%H%M%S)"
mkdir -p "$LOG_DIR"

# Help menu
function help {
  cat <<EOF
Usage:
./start_game.sh -l [team_start_script] -r [team_start_script]
EOF
}

while getopts "l:r:p:" opt; do
  case $opt in
  l)
    LEFT=$OPTARG
    ;;
  r)
    RIGHT=$OPTARG
    ;;
  *)
    echo "No that argument $OPTARG"
    ;;
  esac
done

if [[ -x $LEFT && -x $RIGHT ]]; then
  # Find available port
  while [[ -n "$(lsof -i:$PORT)" && PORT -lt $MAX_PORT ]]; do
    PORT=$((PORT + 3))
  done
  if [ $PORT -ge $MAX_PORT ]; then
    echo "no avilable port"
    return 254
  fi

  SERVER_PORT_ARG="server::port=$PORT server::olcoach_port=$((PORT + 2)) server::coach_port=$((PORT + 1))"
  MODE_ARG="server::auto_mode=on CSVSaver::save=on server::text_log_dir=$LOG_DIR server::game_log_dir=$LOG_DIR"

  cd "$BASE_DIR" || exit 255
  rcssserver $MODE_ARG $SERVER_PORT_ARG 2>>/dev/null 1>/dev/null &
  sleep 1

  if [ "$LEFT" = "$RIGHT" ]; then
    NAME_ARG="-t same_team"
  fi
  cd "$(dirname "$LEFT")" || exit 255
  $LEFT -p $PORT 2>/dev/null 1>/dev/null &
  cd "$(dirname "$RIGHT")" || exit 255
  $RIGHT -p $PORT $NAME_ARG 2>/dev/null 1>/dev/null &
else
  help
  exit 255
fi
