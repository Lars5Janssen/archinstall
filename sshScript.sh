#! /bin/bash

SETHOSTNAME=$3
USERNAME=$2

scp transferredskript01.sh root@1:/root
scp transferredskript02.sh root@1:/root
scp basePackages.txt root@1:/root
scp userspace.txt root@$1:/root

ssh root@$1 "SETHOSTNAME=$SETHOSTNAME && USERNAME=$USERNAME && chmod +x transferredskript01.sh && chmod +x transferredskript02.sh"
ssh root@$1 "SETHOSTNAME=$SETHOSTNAME && USERNAME=$USERNAME && ./transferredskript01.sh" 
scp root@$1:/mnt/home/"$USERNAME"/.ssh/id_ed25519.pub .
gh ssh-key add --title $HOSTNAME id_ed25519.pub
ssh root@$1 "SETHOSTNAME=$SETHOSTNAME && USERNAME=$USERNAME && ./transferredskript02.sh"
