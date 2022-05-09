#!/usr/bin/env bash
# set -x
PID_FILE=test.data1

while read -r pid || [[ -n $pid ]]; do
  if [ ! -e "/proc/$pid" ]; then
    sed -i "/${pid}/d" $PID_FILE
  fi
done <"$PID_FILE"
