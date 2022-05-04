#!/usr/bin/env bash

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
  p)
    PORT=$OPTARG
    ;;
  *)
    echo "No that argument $OPTARG"
    ;;
  esac
done

if [[ -x $LEFT && -x $RIGHT ]]; then
  if [ -n "$PORT" ]; then
    PORT_ARG="server::port=$PORT server::olcoach_port=$((PORT + 2)) server::coach_port=$((PORT + 1))"
  fi

  rcssserver server::auto_mode=on "$PORT_ARG" CSVSaver::save=on 2>>./1.log 1>/dev/null &

  if [ "$LEFT" = "$RIGHT" ]; then
    NAME_LEFT=left
    NAME_RIGHT=right
  fi

  $LEFT -t $NAME_LEFT &>/dev/null &
  $RIGHT -t $NAME_RIGHT &>/dev/null &

else
  help
  exit 255
fi
