#!/bin/sh
wget "http://cdimage.debian.org/cdimage/archive/9.13.0-live/amd64/iso-hybrid/debian-live-9.13.0-amd64-xfce.iso" -O "debian-live-9.13.0-amd64-xfce.iso"
mkdir isomountpoint
sudo mount -o loop "debian-live-9.13.0-amd64-xfce.iso" isomountpoint
unsquashfs isomountpoint/live/filesystem.squashfs
sudo umount isomountpoint
rmdir isomountpoint
mkdir squashfs-root/Sources
mv replicant-4.2 squashfs-root/Sources/
cp -a do.sh squashfs-root/Sources/
cp -a userBuild.sh squashfs-root/Sources/
cp -a /etc/resolv.conf squashfs-root/etc/
printf "SET THE PASSWORD AS \"live\"\n"
sudo chroot squashfs-root adduser live
sudo chroot usermod -aG sudo live
sudo chroot squashfs-root sed -i "s&#deb-src http://deb.debian.org/debian/ stretch main&deb-src http://deb.debian.org/debian/ stretch main&g" /etc/apt/sources.list
sudo chroot /Sources/do.sh squashfs-root
