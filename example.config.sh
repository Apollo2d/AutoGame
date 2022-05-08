#!/usr/bin/env bash

MASTER_TEAM=/home/kawhicurry/Code/Apollo/NewApolloBase/build/Apollo-exe/start.sh
export MASTER_TEAM

# cpu load limit
CORE=$(nproc)
LOAD_RATE=0.7
MAX_LOAD=$(echo "$CORE * $LOAD_RATE" | bc)
export CORE LOAD_RATE MAX_LOAD

# memory limit
MEMORY=$(free -t | awk '/Total/||/总量/ {print $2}')
MEM_RATE=0.6
MAX_MEM=$(echo "$MEMORY * $MEM_RATE" | bc)
export MEMRORY MEM_RATE MAX_MEM

# manual limit
MAX_RUNNING=5
export MAX_RUNNING

SLEEP_TIME=5 # seconds
export SLEEP_TIME

PEN_ONLY=false # true or false
export PEN_ONLY

PID_FILE=/tmp/autogame.pid
export PID_FILE
