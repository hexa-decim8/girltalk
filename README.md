# README

GirlTalk is a script for rapidly deploying reverse SSH tunnels to remotely positioned devices.

### What is this repository for?

GirlTalk does not use any specialized tools, and utilizes the native functionality of OpenSSH to allow remotely positioned devices to connect back to operator-owned C2 infrastructure. This removes any ambiguity about connecting to infrastructure where a route is not easily accessible.

### How do I get set up? ###
GirlTalk is a simple script that automates the reverse SSH tunnel process. The script has been developed and tested in Debian derivative environments, but can easily be modified to work in alternative environments as well. Because GirlTalk is a bash script, it is highly portable and adaptable from build-to-build and runs almost entirely with natively installed Unix installations.

To get started, run girltalk.sh on the host you wish to have call back to your C2. The script will prompt you when information is needed. Be sure to have your C2 login info
ready before starting girltalk.sh

Once the script is complete, reboot the deployable host. The script is tuned by default to establish a connection to the C2 after 100 seconds.

### Connecting to the deployable host ###
When girltalk.sh is done, a new script will be made available in the root directory of the C2 host called 'hmu.sh'. Run this script from the C2 host, input the password for
the account specified during girltalk runtime and you should have a shell on the remotely deployed host without needing any unknown routing information from the deployable
host!
