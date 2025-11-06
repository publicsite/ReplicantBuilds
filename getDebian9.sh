#!/bin/sh

OLD_UMASK="$(umask)"
umask 0022

wget "http://cdimage.debian.org/cdimage/archive/9.13.0-live/amd64/iso-hybrid/debian-live-9.13.0-amd64-xfce.iso" -O "debian-live-9.13.0-amd64-xfce.iso"
mkdir isomountpoint
sudo mount -o loop "debian-live-9.13.0-amd64-xfce.iso" isomountpoint
unsquashfs isomountpoint/live/filesystem.squashfs
sudo umount isomountpoint
rmdir isomountpoint
mkdir squashfs-root/Sources
cp -a getSource-4.2 squashfs-root/Sources/
cp -a do-4.2.sh squashfs-root/Sources/
cp -a build-4.2.sh squashfs-root/Sources/
cp -a getSource-6.0 squashfs-root/Sources/
cp -a do-6.0.sh squashfs-root/Sources/
cp -a build-6.0.sh squashfs-root/Sources/
cp -a /etc/resolv.conf squashfs-root/etc/
cp -a patches squashfs-root/Sources/
printf "SET THE PASSWORD AS \"live\"\n"
sudo chroot squashfs-root adduser live
sudo chroot usermod -aG sudo live
sudo chroot squashfs-root sed -i "s&#deb-src http://deb.debian.org/debian/ stretch main&deb-src http://deb.debian.org/debian/ stretch main&g" /etc/apt/sources.list

sudo chroot /Sources/getSource-4.2.sh squashfs-root
sudo chroot /Sources/do-4.2.sh squashfs-root
sudo chroot /Sources/getSource-6.0.sh squashfs-root
sudo chroot /Sources/do-6.0.sh squashfs-root

umask "${OLD_UMASK}"
