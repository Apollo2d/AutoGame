#!/usr/bin/env bash
# A small web crawler

REMOTE_DIR="https://archive.robocup.info"
BASE_DIR="$(dirname "$(readlink -f "$0")")"
BIN_DIR="$BASE_DIR/bin"
SKIP=1

# get files in day1,2021
RANGE=/2021/Day3
# get all files in 2021
# RANGE=/2021
# get all files since 1996
# RANGE=/

if [ ! -d "$BIN_DIR" ]; then
  mkdir -p "$BIN_DIR"
fi

function get {
  local url
  url=$1
  if [ "$(curl "$REMOTE_DIR/$url/" | grep -o BIN | wc -l)" -gt 0 ]; then
    local team_urls
    team_urls="$(curl "$REMOTE_DIR/$url/" | grep -oP '(?<=alt="file"/></td><td class="fb-n"><a href="/)(([\s\S])*?)(?=">)')"
    for team_url in $team_urls; do
      local bin
      bin="${team_url##*RoboCup/}"
      if [[ -e $BASE_DIR/$bin && SKIP -gt 0 ]]; then
        continue
      fi
      local dir
      dir="${bin%/*}"
      if [ ! -d "$BIN_DIR/$dir" ]; then
        mkdir -p "$BIN_DIR/$dir"
      fi
      cd "$BIN_DIR/$dir" || exit 255
      echo "Getting $REMOTE_DIR/$team_url/ to $BIN_DIR/$dir"
      curl -O "$REMOTE_DIR/$team_url"
    done
  else
    local folder_urls
    folder_urls="$(curl "$REMOTE_DIR/$url/" | grep -oP '(?<=alt="folder"/></td><td class="fb-n"><a href="/)([\s\S]*?)(?=/">)')"
    for folder_url in $folder_urls; do
      get "$folder_url"
    done
  fi
}

function extract {
  local dir
  dir=$1
  cd "$dir" || exit 255
  for file in "$dir"/*; do
    if [ -d "$file" ]; then
      extract "$file"
    elif [[ -f $file && ${file%%.tar.gz} != "$file" ]]; then
      tar -xvzf "$file"
      rm "$file"
    fi
  done
}

get "Soccer/Simulation/2D/binaries/RoboCup$RANGE" 2>/dev/null
extract "$BIN_DIR"
