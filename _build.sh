#!/bin/bash

# Name
NAME="rstudio"

# CPU options
CPU_SHARES="--cpu-shares=8"
CPU_SETS="--cpuset-cpus=0-$[$CPU_SHARES-1]"
CPU_MEMS="--cpuset-mems=0"
MEM="--memory=24g"



# Prepare docker
#docker info
#docker pull ubuntu

# Build docker
docker build --rm=true $CPU_SHARES $CPU_SETS $CPU_MEMS $MEM --tag=$NAME .

