#!/bin/bash
set -e

##################################################################################
## AUTHOR : Emmanuel ZIDEL-CAUFFET - Zidmann (emmanuel.zidel@gmail.com)
##################################################################################
## This script will be used to manage the proxy
##################################################################################
## 2021/04/23 - First release of the script
##################################################################################

##################################################################################
# Beginning of the script - definition of the variables
##################################################################################
SCRIPT_VERSION="0.0.1"

cat << "EOF"
   ______   ____      _    _   _   ____   
  /  ___/  / __ \    | |  | | (_) |  _ \  
  \ \     / /  \ \   | |  | | | | | | \ \ 
   \ \    | |  | |   | |  | | | | | | | | 
 ___\ \   \ \__/  \  | |__| | | | | |_/ / 
/_____/    \____/\_\  \____/  |_| |____/  

EOF

cat << EOF
Squid Proxy docker
https://github.com/Zidmann/MyProxyDocker
===================================================
EOF

# Analysis of the path and the names
DIRNAME="$(dirname "$(readlink -f "$0")")"
SCRIPT_NAME="$(basename "$(readlink -f "$0")")"

GITHUB_BASE_URL="https://raw.githubusercontent.com/Zidmann/MyProxyDocker/master"
PROXYVERSION="0.0.1"

COMMAND=$1
if [ "$COMMAND" == "" ]
then
	echo
	echo "Usage : $0 <COMMAND> [OUTPUT]"
	exit 0
fi

# Check if the user has not a root effective ID
if [ "$EUID" == "0" ]
then
	echo "[-] The user has root effective ID and for safety the script will be stopped"
	exit 1
fi;

OUTPUT=${2:-"${DIRNAME}/data"}

SCRIPTS_DIR="$OUTPUT/scripts"
DOCKER_DIR="$OUTPUT/docker"

SCRIPT_PATH="$DIRNAME/$SCRIPT_NAME"
RUN_PATH="$SCRIPTS_DIR/run.sh"
DOCKERCOMPOSE_PATH="$DOCKER_DIR/docker-compose.yml"

# Functions
function get_file_by_http(){
	local FILE=$1
	local URL=$2
	local EXECUTABLE=$3

	local DIR
	DIR="$(dirname "$FILE")"

	if [ ! -d "$DIR" ]
	then
		mkdir "$DIR"
	fi

	local NOW
	NOW=$(date '+%Y%m%d-%H%M%S')
	if curl -s -w "http_code %{http_code}" -o "$FILE.$NOW" "$URL" | grep -q "^http_code 20[0-9]"
	then
		mv "$FILE.$NOW" "$FILE"
		if [ "$EXECUTABLE" == "yes" ]
		then
			chmod u+x "$FILE"
		fi
	else
		rm -f "$FILE.$NOW"
	fi
}

function download_self() {
	local SCRIPT=$1
	local URL=$2
	get_file_by_http "$SCRIPT" "$URL/scripts/$SCRIPT_NAME" "yes"
}

function download_compose_file(){
	local FILE=$1
	local URL=$2
	get_file_by_http "$FILE" "$URL/docker/docker-compose.yml" "no"
}

function download_run_file() {
	local RUN=$1
	local URL=$2
	get_file_by_http "$RUN" "$URL/scripts/run.sh" "yes"
}

function check_directory_exists() {
	local EXIST=$1
	local DIR=$2
	local MESSAGE=$3
	local ERROR

	if [[ "$EXIST" == "yes" ]] && [[ -d "$DIR" ]]
	then
		ERROR=1
	elif [[ "$EXIST" == "no" ]] && [[ ! -d "$DIR" ]]
	then
		ERROR=1
	else
		ERROR=0
	fi

	if [ "$ERROR" != "0" ]
	then
		echo "$MESSAGE"
		exit 1
	fi
}

function print_command_list() {
	cat << EOT
Available commands:
	install
	start
	restart
	stop
	update
	updaterun
	updateself
	updateconf
	logrotate
	help
EOT
}

# Printing the versions of the different components
echo
echo "$SCRIPT_NAME version $SCRIPT_VERSION"
docker --version
docker-compose --version
echo ""
echo "==================================================="

# Commands
case "$COMMAND" in
	"install")
		check_directory_exists "yes" "$OUTPUT/docker" "Looks like Squid is already installed at $OUTPUT."
		mkdir -p "$OUTPUT"
		download_run_file "$RUN_PATH" "$GITHUB_BASE_URL"
		download_compose_file "$DOCKERCOMPOSE_PATH" "$GITHUB_BASE_URL"
		"$SCRIPTS_DIR/run.sh" install "$OUTPUT" "$PROXYVERSION"
		;;
	"start" | "restart")
		check_directory_exists "no"  "$OUTPUT" "Cannot find a Squid installation at $OUTPUT."
		"$SCRIPTS_DIR/run.sh" restart "$OUTPUT" "$PROXYVERSION"
		;;
	"stop")
		check_directory_exists "no"  "$OUTPUT" "Cannot find a Squid installation at $OUTPUT."
		"$SCRIPTS_DIR/run.sh" stop "$OUTPUT" "$PROXYVERSION"
		;;
	"update")
		check_directory_exists "no"  "$OUTPUT" "Cannot find a Squid installation at $OUTPUT."
		download_run_file "$RUN_PATH" "$GITHUB_BASE_URL"
		"$SCRIPTS_DIR/run.sh" update "$OUTPUT" "$PROXYVERSION"
		;;
	"updateconf")
		check_directory_exists "no"  "$OUTPUT" "Cannot find a Squid installation at $OUTPUT."
		"$SCRIPTS_DIR/run.sh" update "$OUTPUT" "$PROXYVERSION"
		;;
	"updaterun")
		check_directory_exists "no"  "$OUTPUT" "Cannot find a Squid installation at $OUTPUT."
		download_run_file "$RUN_PATH" "$GITHUB_BASE_URL"
		;;
	"updateself")
		download_self "$SCRIPT_PATH" "$GITHUB_BASE_URL" && echo "Updated self." && exit
		;;
	"logrotate")
		check_directory_exists "no"  "$OUTPUT" "Cannot find a Squid installation at $OUTPUT."
		"$SCRIPTS_DIR/run.sh" logrotate "$OUTPUT" "$PROXYVERSION"
		;;
	"help")
		print_command_list
		;;
	*)
		echo "Unknown command."
		echo
		print_command_list
esac
