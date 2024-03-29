#!/usr/bin/env bash

BASE_DIR="$(dirname "$(readlink -f "$0")")"
# BIN_DIR="$BASE_DIR/bin"
source "$BASE_DIR/config.sh"

# Help menu
function help {
	cat <<EOF
Usage:
./start_game.sh -l [team_start_script] -r [team_start_script]
EOF
}

while getopts "kl:r:p:" opt; do
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

if [ -x "$LEFT" ]; then
	if [ -x "$RIGHT" ]; then
		# Find available port
		while [[ -n "$(lsof -i:$PORT)" &&
		-n "$(lsof -i:$((PORT + 1)))" &&
		-n "$(lsof -i:$((PORT + 2)))" &&
		PORT -lt $MAX_PORT ]]; do
			PORT=$((PORT + 3))
		done
		if [ $PORT -ge $MAX_PORT ]; then
			echo "no avilable port"
			return 254
		fi
		SERVER_PORT_ARG="server::port=$PORT server::olcoach_port=$((PORT + 2)) server::coach_port=$((PORT + 1))"

		# Prepare the log_dir
		LOG_DIR="$BASE_DIR/log/$(date +%Y%m%d%H%M%S)"
		mkdir -p "$LOG_DIR"

		# General arguments
		MODE_ARG="server::auto_mode=on"
		MODE_ARG="$MODE_ARG CSVSaver::save=on"
		MODE_ARG="$MODE_ARG server::text_log_dir=$LOG_DIR"
		MODE_ARG="$MODE_ARG server::game_log_dir=$LOG_DIR"

		# Check penalty mode
		if [ $PEN_ONLY = true ]; then
			PEN_ARG="server::half_time=1"
			PEN_ARG="server::nr_normal_halfs=1 $PEN_ARG"
			PEN_ARG="server::extra_half_time=0 $PEN_ARG"
			PEN_ARG="server::nr_extra_halfs=0 $PEN_ARG"
			PEN_ARG="server::penalty_shoot_outs=on $PEN_ARG"
		fi

		if [ $DEBUG = true ]; then

			if grep -qi log-dir "$LEFT"; then
				DEBUG_ARG_LEFT="--debug --log-dir $LOG_DIR"
			fi
			if grep -qi log-dir "$RIGHT"; then
				DEBUG_ARG_RIGHT="--debug --log-dir $LOG_DIR"
			fi
		fi

		cd "$BASE_DIR" || exit 255
		rcssserver $MODE_ARG $SERVER_PORT_ARG $PEN_ARG &>"$LOG_DIR/server.log" &
		if [ -n "$MONITOR" ]; then
			$MONITOR --server-port $PORT --auto-quit-mode true &>"$LOG_DIR/monitor.log" &
		fi
		echo $$ >>"$PID_FILE"
		sleep 1
		if [ "$LEFT" = "$RIGHT" ]; then
			NAME_ARG="-t same_team"
		fi
		cd "$(dirname "$LEFT")" || exit 255
		$LEFT -p $PORT $DEBUG_ARG_LEFT &>"$LOG_DIR/left.log" &
		cd "$(dirname "$RIGHT")" || exit 255
		$RIGHT -p $PORT $DEBUG_ARG_RIGHT $NAME_ARG &>"$LOG_DIR/right.log" &
		exit 0
	else
		echo "Cannot run Left:$LEFT"
		help
		exit 255
	fi
else
	echo "Cannot run Right:$RIGHT"
	help
	exit 255
fi
