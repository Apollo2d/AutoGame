#!/usr/bin/env bash
#set -x

BASE_DIR="$(dirname "$(readlink -f "$0")")"
cd "$BASE_DIR" || exit 255

# get configurations
if [ -f "$BASE_DIR/config.sh" ]; then
  source "$BASE_DIR/config.sh"
else
  add_log "Cannot find $BASE_DIR/config.sh. Generate one now. Modified it before running"
  cp "$BASE_DIR/example.config.sh" "$BASE_DIR/config.sh"
  exit 253
fi

function add_log {
  echo -e "$(date) Manager: $*"
}

if [[ -e "$LOCK_FILE" && -e "/proc/$daemon_pid" ]]; then
  daemon_pid="$(cat "$LOCK_FILE")"
else
  echo "Daemon is not running"
  exit 250
fi

# 用getopt重写
while getopts "chks:" opt; do
  case $opt in
  c)
    if [ -e "$LOG_FILE" ]; then
      rm "$LOG_FILE"
    fi
    exit 0
    ;;
  h)
    cat <<EOF
./manager.sh [-option] [arguments]
Options:
-c -- clean logfile
-h -- show help
-k -- kill daemon
-s -- send signal
Signals:
reload -- reload the configuration
EOF
    ;;
  k)
    if [ "$daemon_pid" -gt 0 ]; then
      kill -INT "-$daemon_pid"
      add_log "Kill daemon"
      exit 0
    else
      add_log "Daemon didn't exist. Remove lock: $LOCK_FILE" >&2
      rm "$LOCK_FILE"
      exit 254
    fi
    exit 0
    ;;
  s)
    if [ "$daemon_pid" -gt 0 ]; then
      if [ "$OPTARG" = "reload" ]; then
        kill -USR1 "$daemon_pid"
        add_log "Reload"
        exit 0
      elif [ "$OPTARG" = "show" ]; then
        kill -USR2 "$daemon_pid"
        add_log "Show"
        exit 0
      else
        add_log "Unrecognized signal"
        exit 253
      fi
    else
      add_log "Daemon didn't exist." >&2
      exit 254
    fi
    ;;
  *) ;;
  esac
done
