#!/bin/bash

cd "$(dirname "$0")"

thepwd="$PWD"

apt-get update
dpkg --add-architecture i386 ; apt-get update
apt-get build-dep gcc binutils llvm-defaults
apt-get install bash gcc-arm-none-eabi cmake python-dev swig ant bc proguard maven-debian-helper libemma-java libasm4-java libguava-java libnb-platform18-java libnb-org-openide-util-java libandroidsdk-ddmlib-java libmaven-source-plugin-java libfreemarker-java libmaven-javadoc-plugin-java ca-cacert curl gawk libgmp3-dev libmpfr-dev libmpc-dev git-core gperf libncurses-dev squashfs-tools pngcrush zip zlib1g-dev lzma libc6-dev-i386 g++-multilib lib32z1-dev lib32readline-dev lib32ncurses5-dev zlib1g-dev:i386 xsltproc python-mako schedtool gradle dirmngr libandroidsdk-sdklib-java eclipse-jdt libgradle-android-plugin-java android-sdk-build-tools android-sdk-platform-23 aapt lzop rsync

#wget https://download.java.net/openjdk/jdk7u75/ri/openjdk-7u75-b13-linux-x64-18_dec_2014.tar.gz
#tar xvf openjdk-7u75-b13-linux-x64-18_dec_2014.tar.gz

#make some symlinks, required for debian 9
cd /usr/bin
ln -s /bin/grep ./
ln -s /bin/mkdir ./
ln -s /bin/sed ./

#https://redmine.replicant.us/issues/1761
apt-get install locales
dpkg-reconfigure locales

cd "$thepwd"

su - live -c "$thepwd/build-4.2.sh"
