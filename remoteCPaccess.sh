#!/bin/bash

### sets up port tunnel to allow remote adminsitation of a CrashPlan instance 

## Vars
ladminName='tester'
ladminPass='password'
hostIP="$1"

if [ -z $1 ]; then
	echo "Requires target host's IP as argument."
	exit 2
fi 

function restoreLocal {
	#Kill the CP app if running
	CPappPID=$(ps -ax | grep CrashPlan | grep -v grep | grep '/Applications/CrashPlan.app/Contents/MacOS/CrashPlan'$ | awk '{print $1}' | xargs)
	if [ $(echo "$CPappPID" | wc -l | xargs) -eq 1 ]; then
		#kill it
		kill $CPappPID
	fi
	#restore the local CP app settings
	rm "/Library/Application Support/CrashPlan/.ui_info"
	mv "/Library/Application Support/CrashPlan/.ui_info.local" "/Library/Application Support/CrashPlan/.ui_info"
	echo "Local settings restored"
	tunnelRunningPID=$(ps -ax | grep "4200:localhost:4243" | grep -v grep | awk '{print $1}')
	if [ $(echo "$tunnelRunningPID" | wc -l | xargs) -eq 1 ]; then
	#kill the tunnel
	kill $tunnelRunningPID
	echo "Killed SSH tunnel with PID $tunnelRunningPID"
	else
	echo "No SSH tunnel open"
	fi
}

## Main

# Get key info from target
authInfoRaw=$(sshpass -p "$ladminPass" ssh -o StrictHostKeyChecking=no "$ladminName"@"$hostIP" 'cat /Library/Application\ Support/CrashPlan/.ui_info')
# Get just the parts we need
authInfoHash=$(echo "$authInfoRaw" | awk -F ',' '{print $2}')
authString="4200,$authInfoHash,127.0.0.1"

# Change things on the local machine, making a backup of our local settings
cp "/Library/Application Support/CrashPlan/.ui_info" "/Library/Application Support/CrashPlan/.ui_info.local"
echo "$authString" > "/Library/Application Support/CrashPlan/.ui_info"

# start forwarding the ports and open the app
open /Applications/CrashPlan.app  ## Open the app first since the tunnel doesn't want to run in a background process
sshpass -p "$ladminPass" ssh -fN -o StrictHostKeyChecking=no -L 4200:localhost:4243 "$ladminName"@"$hostIP" 

#Leave a prompt to finish when done
read -rsp $'Press any key to close the connection\n' -n1 key

#make sure we fix our local setup when done
trap restoreLocal EXIT

