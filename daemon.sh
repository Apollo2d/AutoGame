#!/usr/bin/env bash

BASE_DIR="$(dirname "$(readlink -f "$0")")"

# get configurations
if [ -f "$BASE_DIR/config.sh" ]; then
  source "$BASE_DIR/config.sh"
else
  echo "Cannot find $BASE_DIR/config.sh. Generate one now. Modified it before running"
  cp "$BASE_DIR/example.config.sh" "$BASE_DIR/config.sh"
  exit 253
fi

cd "$BASE_DIR" || exit 255

trap "" HUP

function get_team {
  echo 123
}

while :; do
  echo "1"
  sleep 10
done
