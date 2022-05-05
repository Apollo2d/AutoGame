# AutoGame
## by kawhicurry in NJUPT in 2022/5/5

# TLDR

1. Download team files `*.tar.gz` into `autogame/bin` ( by directly run `crawler.sh` )
2. Check configuration in `Nvs1.sh` and `1vs1.sh`
3. Run `./Nvs1.sh`
4. Check result in `rcssserver.csv` and log in `log/`

# Introduction

This is a series of tools aiming to test your team automatically and efficiently.

You can get the latest version of teams from [Robocup](https://archive.robocup.info/Soccer/Simulation/2D/), and have games with them. After
the game, you will get a detailed report about the behavior of your team.

# Configure

## Get teams
You need to prepare the binaries of your opponents at first.
The location is set with variable `BIN_DIR` in `Nvs1.sh` with default value `bin/`

You can get your own binaries or download it online. We prepared a tool that help you get the latest version of teams from [Robocup](https://archive.robocup.info/Soccer/Simulation/2D/) by using script `crawler.sh`.
A range should be specified before using it.

The scripts will detect your `start.sh` script during running. You need to make sure all `start.sh` are executable and support specifying the port with argument `-p`.

## Check variables
A set of variables is set in `Nvs1.sh` and `1vs1.sh`.

```bash
# Nvs1.sh
# specify your home team
MASTER_TEAM=/home/kawhicurry/Code/Apollo/NewApolloBase/build/Apollo-exe/start.sh

# cpu load limit
CORE=$(nproc)
LOAD_RATE=0.7
MAX_LOAD=$(echo "$CORE * $LOAD_RATE" | bc)

# memory limit
MEMORY=$(free -t | awk '/Total/ {print $2}')
MEM_RATE=0.6
MAX_MEM=$(echo "$MEMORY * $MEM_RATE" | bc)

# manual limit
MAX_RUN=5 # The max number of server

SLEEP_TIME=5 # The poll time
BIN_DIR="$BASE_DIR/bin" # The location of your binary team
```

```bash
# 1vs1.sh
# available port range
# every time rcssserver using 3 sequence port
PORT=6000
MAX_PORT=6300
LOG_DIR="$BASE_DIR/log/$(date +%Y%m%d%H%M%S)"
```

## Start the game
running `./Nvs1.sh`

Press \[Ctrl+C\] to stop at any time.

The information shows above indicates:
```
Current load:[current load]/[lower load to run]/[max load(the core of your computer)]
Current memory:[current memory]/[lower memory to run]/[max memory]
```

## Using monitor
When games are running, you can use your monitor to connect them with particular port.

A example here:
```bash
rcssmonitor --server-port 6003
```
The server using 3 sequence ports every time.So the port should be `$PORT+3*k`.

The `$PORT` is defined in `1vs1.sh`, k is a integer.

## Collect information
Since we've enable `CSVSave` in `1vs1.sh`, a `rcssserver.csv` which records the scores will appear in this directory.

The log file will be saved into $LOG_DIR which default value if log/

TODO: adding support of `loganalyzer3`

# FAQ

1. How does crawler works?

It search and downloads teams binary from <https://archive.robocup.info/Soccer/Simulation/2D/binaries/RoboCup/> into `bin/` and extract those ends with `.tar.gz`

You can configure it by yourself.


