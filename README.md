# README #
![Girltalk](/images/E3kGRY7WEAoMgMS.jpg)

GirlTalk is a script for rapidly deploying reverse SSH tunnels to remotely positioned devices.

### Updates ###
* Added multi-user support
* Scripting options to allow fine-tuning & easier operation
* Girltalk now supports AWS C2 deployments with the -a option

### NOTE! ###
This tool is freely licensed but I do not take any responsibility for whatever you choose to do with this.
Therefore, only use this tool in association with systems and networks you have explicit permission to operate on!

### What is this repository for? ###

GirlTalk does not use any specialized tools, and utilizes the native functionality of OpenSSH to allow remotely positioned devices to connect back to operator-owned C2
infrastructure. This removes any ambiguity about connecting to infrastructure where a route is not easily accessible, such as when a device needs to be accessible behind
Network Address Translation (NAT).

### USAGE ###
Girltalk is currently compatible with the followin options:
Key/Cert Mode options:
  -a	Boolean option for keyed C2 infrastructure.
  -k    Full path of SSH key.

Password Mode options:
  -c    C2 host.
  -u	C2 username.
  -l    Local username to use.

usage:	 girltalk.sh -c <C2 hostname/IP> -l <local_username> -u <C2_username>
example: girltalk.sh -c host.aws.com -u ubuntu -l hatchetface -a -k ~/.ssh/amazon-keypair.pem

### How does it work? ###
Girltalk takes advantage of the standard functionality of openssh, but scripts out the process of orchestrating the connection between the "foothold" host to be deployed behind
NAT and the "C2" operators have easy ssh access through.
![example diagram](/images/diagram.png)

### How do I get set up? ###
Prior to running girltalk.sh, operators should have a domain name at hand to give to the script to enable the host to access it once it has been put into the NAT'd environment.
The easiest way to enable this is to create a dynDNS domain, and have the domain point to the infrastructure the operators intend to use.
The best way to use this script is to ensure that the C2 is available when the script is first run so that the hmu.sh file can be successfully transferred. This
functionality may change in a future release, but girltalk was build with this usecase in mind.

GirlTalk is a simple script that automates the reverse SSH tunnel setup process. The script has been developed and tested in Debian derivative environments, but can easily be
modified to work in alternative environments as well. Because GirlTalk is a bash script, it is highly portable and adaptable from build-to-build and runs almost entirely with
easy to port to native Unix installations.

To get started, run girltalk.sh on the host you wish to have call back to your C2. The script will prompt you when information is needed. Be sure to have your C2 login info
ready before starting girltalk.sh.

Girltalk will place an access script onto the C2 host (called 'hmu_user.sh'). Running this newly created script will transfer local ssh keys back to the foothold host and
immediately return a shell to the foothold.

Once the script is complete, reboot the foothold host. The script is tuned by default to establish a connection to the C2 after 100 seconds.

### Connecting to the deployable host ###
When girltalk.sh is done, a new script will be made available in the root directory of the C2 host called 'hmu.sh'. Run this script from the C2 host, input the password for
the account specified during girltalk runtime and you should have a shell on the remotely deployed foothold host without needing any unknown routing information from the foothold
host!

### Feature Roadmap ###
* Add support for new methods of reverse ssh (autossh) - Next up!
* Added user versatility
* Keysize customization
* RDP handling 
* multi-foothold handling
* Stability upgrades
* multi-foothold handling (Look out for news on ChurchInTheWild..coming soon!)
