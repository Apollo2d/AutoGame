#!/usr/bin/env bash

PORT=6000
MAX_PORT=6300
BASE_DIR="$(dirname "$(readlink -f "$0")")"
BIN_DIR="$BASE_DIR/bin"

REMOTE_DIR="https://archive.robocup.info/"
REMOTE_DIR="https://archive.robocup.info/Soccer/Simulation/2D/binaries/RoboCup/"
declare -a TEAMS

cd -q "$BASE_DIR" || exit 255

function get_team() {
  curl "$REMOTE_DIR/Soccer/Simulation/2D/binaries/RoboCup/" | grep -oP '(?<=alt="folder"/></td><td class="fb-n"><a href=")([\s\S]*?)(?=">)'
  # curl $url | grep -oP '(?<=file"/></td><td class="fb-n"><a href=")(([\s\S])*?)\.tar\.gz'
}

# TODO：使用信号一进行热重载
function get_team {
  i=0
  for dir in $BIN_DIR/*; do
    if [[ -d $dir && -x $dir/start.sh ]]; then
      TEAMS[i]="$dir/start.sh"
      i=$((++i))
    fi
  done
  echo "${TEAMS[@]}"
}

# Find available port
function get_port {
  while [[ -z "$(lsof -i:$PORT)" && PORT -lt $MAX_PORT ]]; do
    echo $PORT
    PORT=$((PORT + 3))
  done
  if [ $PORT -ge $MAX_PORT ]; then
    echo "no avilable port"
    return 254
  fi
}
