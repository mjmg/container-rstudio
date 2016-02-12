#!/bin/bash

# Make sure to add the following entry in /etc/default/grub:
#GRUB_CMDLINE_LINUX="cgroup_enable=memory swapaccount=1"



# Name
NAME="rstudio-server"

# CPU options
CPU_SHARES="8"
CPU_SETS="0-$[$CPU_SHARES-1]"
CPU_MEMS="0"
MEM="24g"

# Ports
PORT_PUB=9000
PORT_DOCKER=8080

# Volumes
VOL="/home"
VOL_PERM="rw"



# Prepare docker
#docker info
#docker pull ubuntu

# HACK Workaround: needed to get infrastructure stuff outside of docker context to work
#PWD="$(pwd)"
#mkdir -p etc
#alias cp='cp'
#cp -r -f /etc/ldap.conf etc/ldap.conf
#cp -r -f /etc/ldap etc/ldap
#cp -r -f /etc/pam.d etc/pam.d
#cp -r -f /etc/nsswitch.conf etc/nsswitch.conf
#su -c "cp -r -f /etc/nslcd.conf etc/nslcd.conf"
#su -c "chmod 666 etc/nslcd.conf"
#mkdir -p etc/ssl/certs
#cp -r -f /etc/ssl/certs/I* etc/ssl/certs/

# Build docker
docker build --rm=true --cpu-shares=$CPU_SHARES --cpuset-cpus=$CPU_SETS --cpuset-mems=$CPU_MEMS --memory=$MEM --tag=$NAME .

# Run docker
docker run --publish=${PORT_PUB}:${PORT_DOCKER} --log-driver=syslog --volume="${VOL}:${VOL}:${VOL_PERM}" --cpu-shares=$CPU_SHARES --cpuset-cpus=$CPU_SETS --cpuset-mems=$CPU_MEMS --memory=$MEM --name="${NAME}-run" -i -t -d $NAME



# Detach/Attach docker
# detach: CTRL-P + CTRL-Q

# Start and attach docker (you can also use docker start -ai instead)
#docker start ${NAME}-run
#docker attach ${NAME}-run

# Start shell inside running docker
#docker exec -i -t ${NAME}-run /bin/bash

# Start failed container with different entrypoint
#docker run -ti --entrypoint=/bin/bash ${NAME}-run

# Commit changes locally
#docker commit ${NAME}-run

# Show docker container and images
#docker ps -a
#docker images

# Delete container and image
#docker rm ${NAME}-run
#docker rmi ${NAME}

