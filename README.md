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

The intent behind GirlTalk is to utilize as much native functionality as possible for creating reverse SSH tunnels.
By using native functionality, we can simplify the deployment of droppable devices. A side effect of this is that Girltalk is easily auditable.
Girltalk will give operators a route to a deivce that is not easily accessible, such as when a device is behind Network Address Translation (NAT).

### USAGE ###
Girltalk is currently compatible with the following options:
Key/Cert Mode options:
  -a	Boolean option for keyed C2 infrastructure (This option has been tested with AWS as the C2)
  -k    Full path of SSH key

Password Mode options:
  -c    C2 host
  -u	C2 username
  -l    Local username to use

usage:	 girltalk.sh -c <C2 hostname/IP> -l <local_username> -u <C2_username>
example: girltalk.sh -c host.aws.com -u ubuntu -l hatchetface -a -k ~/.ssh/amazon-keypair.pem

### How does it work? ###
Girltalk takes advantage of the standard functionality of openssh, but scripts out the process of orchestrating the connection between the "foothold" host to be deployed behind
NAT and the control infrastructure operators have configued.
![example diagram](/images/diagram.png)

### How do I get set up? ###
To get started, run girltalk.sh on the host you wish to have call back to your C2. Select all appropriate flags and include relevant info for contacting the C2 server.
If you have an AWS server acting as your C2, you should make sure that the -a option is selected.

Girltalk will place an access script onto the C2 host called 'hmu_user.sh'. Running this newly created script will transfer local ssh keys back to the foothold host and
immediately return a shell for the foothold device.

### Connecting to the deployable host ###
When girltalk.sh is done, a new script will be made available in the root directory of the C2 host called 'hmu.sh'. Run this script from the C2 host, input the password for
the account specified during girltalk runtime and you should have a shell on the remotely deployed foothold host without needing any unknown routing information from the foothold
host!

### Feature Roadmap ###
* Add support for new methods of reverse ssh (will add greater stability with autossh) - Next up!
* Added user versatility
* Keysize customization
* multi-foothold handling (Look out for news on ChurchInTheWild..coming soon!)
