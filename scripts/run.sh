#!/bin/bash
set -e

##################################################################################
## AUTHOR : Emmanuel ZIDEL-CAUFFET - Zidmann (emmanuel.zidel@gmail.com)
##################################################################################
## This script will be used to manage the Squid environment (container/files/...)
##################################################################################
## 2021/04/24 - First release of the script
##################################################################################

##################################################################################
# Beginning of the script - definition of the variables
##################################################################################

COMMAND=$1
OUTPUT_DIR=$2
PROXYVERSION=$3
if [[ "$COMMAND" == "" ]] || [[ "$OUTPUT" == "" ]] || [[ "$PROXYVERSION" == "" ]] 
then
	echo
	echo "Usage : $0 <COMMAND> <OUTPUT_DIR> <PROXYVERSION>"
	exit 0
fi

CHECK_PATTERN=$(echo "$PROXYVERSION" | grep -c "^[0-9]\+.[0-9]\+.[0-9]\+$")
if [ "$CHECK_PATTERN" == "0" ]
then
	echo
	echo "The proxy version pattern must be <MAJOR>.<MINOR>.<CORRECTION>"
	exit 1
fi

#Check if the user is not root
if [ "$EUID" == "0" ]
then
	echo "[-] The user is root and for safety the script will be stopped"
	exit 1
fi;

ENV_DIR="$OUTPUT_DIR/env"
ENV_FILE="$ENV_DIR/uid.env"
DOCKER_DIR="$OUTPUT_DIR/docker"

# Defining the environment file if it is not the case
HAS_UID=$(grep -c "^LOCAL_UID=" "$ENV_FILE" 2>/dev/null)
HAS_GID=$(grep -c"^LOCAL_GID=" "$ENV_FILE" 2>/dev/null)
if [[ "$HAS_UID" != "0" || "$HAS_GID" != "0" ]]
then
	LUID=$(id -u "$USER")
	LUID="LOCAL_UID=$LUID"
	[ "$LUID" == "LOCAL_UID=0" ] && LUID="LOCAL_UID=65534"

	LGID=$(id -g "$USER")
	LGID="LOCAL_GID=$LGID"
	[ "$LGID" == "LOCAL_GID=0" ] && LGID="LOCAL_GID=65534"

	mkdir -p "$ENV_DIR"
	echo $LUID >  "$ENV_FILE"
	echo $LGID >> "$ENV_FILE"
fi

# Definition of the functions
function create_dir() {
	if [ ! -d "${OUTPUT_DIR}/$1" ]
	then
		echo "Creating directory $OUTPUT_DIR/$1"
		mkdir -p "$OUTPUT_DIR/$1"
	fi
}

function docker_compose_files() {
	if [ -f "${DOCKER_DIR}/docker-compose.override.yml" ]
	then
		export COMPOSE_FILE="$DOCKER_DIR/docker-compose.yml:$DOCKER_DIR/docker-compose.override.yml"
	else
		export COMPOSE_FILE="$DOCKER_DIR/docker-compose.yml"
	fi
	export COMPOSE_HTTP_TIMEOUT="300"
}

function docker_compose_down() {
	docker_compose_files
	if [ "$(docker-compose ps | wc -l)" -gt 2 ]; then
		docker-compose down
	fi
}

function docker_compose_pull() {
	docker_compose_files
	docker-compose pull
}

function create_volumes() {
	create_dir "cache"
	create_dir "conf"
	create_dir "log"
}

function docker_compose_up() {
	docker_compose_files
	create_volumes
	docker-compose up -d
}

function docker_pull() {
	docker pull "zidmann/squid:$PROXYVERSION"
}

function squid_log_rotate() {
	docker exec -it squid  "su - squid -c \"\"$(which squid)\" -k rotate\""
}

# Commands
case "$COMMAND" in
	"install")    
   		docker_pull
		;;
	"start" | "restart"| "update")
		docker_compose_down
		docker_compose_pull
		docker_compose_up
		;;
	"stop")
		docker_compose_down
		;;
	"logrotate")
		;;
esac
