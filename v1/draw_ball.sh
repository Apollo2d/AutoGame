#!/usr/bin/env bash
if [ $# -eq 0 ]; then
  cat <<EOF
Usage ./draw.sh [rcg file] [option]
EOF
  exit 1
fi

while getopts "bp:" option; do
  case $option in
  b)
    TYPE_ARG="ball"
    ;;
  p)
    TYPE_ARG="players[$OPTARG]"
    ;;
  *) ;;
  esac
done

shift $((OPTIND - 1))

sed '1d' "$1" | jq -r ".[]|select(.type == \"show\").$TYPE_ARG|\"\(.x),\(.y)\"" | gnuplot -p heatmap.gp -e "set title \"$ARG\""
