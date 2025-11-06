#!/bin/bash

OLD_UMASK="$(umask)"
umask 0022

cd "$(dirname "$0")"

printf "This will require ~140GB\n"

#sudo apt-get build-dep gcc binutils llvm-defaults

#Got the following errors on apt-get install
#E: Unable to locate package libemma-java
#E: Unable to locate package libandroidsdk-ddmlib-java
#E: Unable to locate package ca-cacert
#E: Unable to locate package zlib1g-dev:i386
#E: Unable to locate package libandroidsdk-sdklib-java
#E: Unable to locate package eclipse-jdt
#E: Unable to locate package libgradle-android-plugin-java

#sudo apt-get install kmod bash gcc-arm-none-eabi cmake python-dev swig ant bc proguard maven-debian-helper libasm4-java libguava-java libnb-platform18-java libnb-org-openide-util-java libmaven-source-plugin-java libfreemarker-java libmaven-javadoc-plugin-java curl gawk libgmp3-dev libmpfr-dev libmpc-dev git-core gperf libncurses-dev squashfs-tools pngcrush zip zlib1g-dev lzma libc6-dev-i386 g++-multilib lib32z1-dev lib32readline-dev lib32ncurses5-dev xsltproc python-mako schedtool gradle dirmngr android-sdk-build-tools android-sdk-platform-23 aapt lzop rsync

#wget "https://ftp.osuosl.org/pub/replicant/build-tools/repo/28-01-2021/sz1lkq3ryr5iv6amy6f3d2pziks27g28-tarball-pack.tar.xz"
#if [ "$(sha512sum sz1lkq3ryr5iv6amy6f3d2pziks27g28-tarball-pack.tar.xz | cut -d " " -f 1)" != "def3c0b3ae2305d695b57d8d1f2fa8acfaf9b7c9c0f668c129a2bfe2652c24a8f2f8167d95f0d71a72d04601daac2b626bfecfae8e7833c812d912d95fd61a5a" ]; then
#	printf "UHOH, BAD CHECKSUM\n"
#	exit
#fi

sudo tar xf sz1lkq3ryr5iv6amy6f3d2pziks27g28-tarball-pack.tar.xz -C /

source /usr/local/bin/repo-env.sh

mkdir replicant-6.0
cd replicant-6.0
#git config --global user.email "dontcall@me.com"
#git config --global user.name "Absolutely Anonymous"

repo init -u https://git.replicant.us/contrib/scintill/manifest.git -b replicant-6.0
repo sync

#get fdroid prebuilt apps
gpg --keyserver keys.gnupg.net --recv-key 37D2C98789D8311948394E3E41E7044E1DBA2E89
vendor/replicant/get-prebuilts

cd replicant-6.0/device/samsung/i9305

#these patches were created with "diff -du"
#from the instructions at https://redmine.replicant.us/issues/1958
patch -p0 < ../../../../patches/init.target.rc.patch
patch -p0 < ../../../../patches/ueventd.smdk4x12.rc.patch
patch -p0 < ../../../../patches/i9305.mk.patch
patch -p0 < ../../../../patches/file_contexts.patch

cp ../../../../patches/dbus.te selinux/dbus.te
cp ../../../../patches/file.te selinux/file.te
cp ../../../../patches/ofono.te selinux/ofono.te
cp ../../../../patches/radio.te selinux/radio.te
cp ../../../../patches/mdm9k.te selinux/mdm9k-efsd.te

cd ../../../external/sepolicy

#I'm not really sure if this patch is needed.
#If you check dmesg, you find out that SELinux looks to be blocking some stuff.
#I mean, not just the stuff in this patch ...
#... but idk, it's what I did ...
# so ...
patch -p0 < ../../../patches/init.te.patch

umask "${OLD_UMASK}"

