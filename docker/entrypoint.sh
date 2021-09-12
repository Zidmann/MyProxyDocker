#!/bin/bash
set -e

#######################################################################################
## STEP 1 - DEFINE THE GLOBAL VARIABLES
#######################################################################################
# Definition of the entrypoint version
SCRIPT_VERSION="0.0.1"

# Definition of the user and group name or id which will be used
USERNAME="squid"
GROUPNAME="squid"
LUID=${LOCAL_UID:-0}
LGID=${LOCAL_GID:-0}

#######################################################################################
## STEP 2 - SECURE THE USER AND GROUP OF THE PROCESS TO AVOID ROOT USER
#######################################################################################
# Prevent from having a root user by stepping down to nobody user
if [ "$LUID" == "0" ]
then
	LUID=$(id -u nobody)
	if [ "$LUID" == "0" ]
	then
		echo "[-] No non-root id user found to switch"
		exit 1
	fi
fi

# Prevent from having a root group by stepping down to nobody group
if [ "$LGID" == "0" ]
then
	LGID=$(id -g nobody)
	if [ "$LGID" == "0" ]
	then
		echo "[-] No non-root id group found to switch"
		exit 1
	fi
fi

#######################################################################################
## STEP 3 - CHANGE THE PERMISSION WITH THE FILES AND DIRECTORIES MOUNTED WITH VOLUMES
#######################################################################################
# Definition of the function to set permission
set_permissions() {
	local USER=$1
	local GROUP=$2
	local PERMISSION=$3
	shift 3
	local DATAPATH=$*

	if [ -d "$DATAPATH" ]
	then
		echo "[i] Preparing $DATAPATH directory"
		mkdir -p "$DATAPATH"
		chown -R "$USER":"$GROUP" "$DATAPATH"
		chmod -R "$PERMISSION" "$DATAPATH"	
	elif [ -f "$DATAPATH" ]
	then
		echo "[i] Preparing $DATAPATH file"
		touch "$DATAPATH"
		chown "$USER":"$GROUP" "$DATAPATH"
		chmod "$PERMISSION" "$DATAPATH"	
	fi
}

echo "--------------------------------------------------------------"
echo "[i] Launching SCRIPT_VERSION=$SCRIPT_VERSION entrypoint script"

echo "--------------------------------------------------------------"
echo "[i] Changing the volume file and directories owner, group and permission"
set_permissions "$USERNAME" "$GROUPNAME" "600" "/etc/squid/squid.conf"
set_permissions "$USERNAME" "$GROUPNAME" "700" "/var/spool/squid"
set_permissions "$USERNAME" "$GROUPNAME" "700" "/var/log/squid"

#######################################################################################
## STEP 4 - SWITCH FROM THE PREVIOUS UID AND GID TO THE NEW UID/GUID GIVEN
#######################################################################################
echo "--------------------------------------------------------------"
OLD_UID=$(id -u "$USERNAME")
echo "[i] Moving the $USERNAME UID from $OLD_UID to $LUID for $USERNAME user"
if [ "$OLD_UID" == "$LUID" ]
then
	echo " -> Not necessary"
else
	usermod -u "$LUID" "$USERNAME"
fi

OLD_GID=$(id -g "$GROUPNAME")
echo "[i] Moving the $USERNAME GID from $OLD_GID to $LGID"
if [ "$OLD_GID" == "$LGID" ]
then
	echo " -> Not necessary"
else
	groupmod -g "$LGID" "$GROUPNAME"
fi

echo "--------------------------------------------------------------"
echo "[i] Finding and changing the remaining files or directories for $GROUPNAME group"
if [ "$OLD_UID" == "$LUID" ]
then
	echo " -> UID changes not necessary"
else
	find / -user  "$OLD_UID" ! -path "/proc/*" -exec chown -h "$USERNAME" {} \;
fi

if [ "$OLD_GID" == "$LGID" ]
then
	echo " -> GID changes not necessary"
else
	find / -group "$OLD_GID" ! -path "/proc/*" -exec chgrp -h "$GROUPNAME" {} \;
fi

echo "--------------------------------------------------------------"
echo "[i] Giving permission to /run directory for all users and groups"
chmod a+rwx "/run"

#######################################################################################
## STEP 5 - DEFINE THE SHELL FOR THE SQUID USER
#######################################################################################
echo "--------------------------------------------------------------"
echo "[i] Setting a shell for $USERNAME"
chsh -s /bin/bash "$USERNAME"

#######################################################################################
## STEP 6 - FINALLY LAUNCH THE SQUID PROXY
#######################################################################################
echo "--------------------------------------------------------------"
echo "[i] Starting squid proxy..."
su - "$USERNAME" -c "\"$(which squid)\" -NYCd 1"

