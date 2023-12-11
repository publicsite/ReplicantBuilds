#!/bin/sh

export PATH="$PATH:/usr/local/sbin:/usr/sbin:/sbin"

apt-get update
apt-get install ca-cacert git dirmngr

#for merging kernel configs
apt-get flex bison

