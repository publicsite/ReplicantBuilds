#!/bin/sh
#wget "http://cdimage.debian.org/cdimage/archive/9.13.0-live/amd64/iso-hybrid/debian-live-9.13.0-amd64-xfce.iso" -O "debian-live-9.13.0-amd64-xfce.iso"
mkdir isomountpoint
sudo mount -o loop "debian-live-9.13.0-amd64-xfce.iso" isomountpoint
sudo unsquashfs isomountpoint/live/filesystem.squashfs
sudo umount isomountpoint
rmdir isomountpoint
sudo mkdir squashfs-root/Sources

#cp -a getSource-4.2.sh squashfs-root/Sources/
#cp -a do-4.2.sh squashfs-root/Sources/
#cp -a build-4.2.sh squashfs-root/Sources/

sudo cp -a getSource-6.0.sh squashfs-root/Sources/
sudo cp -a do-6.0.sh squashfs-root/Sources/
sudo cp -a build-6.0.sh squashfs-root/Sources/
sudo cp -a getPostmarketConfigs.sh squashfs-root/Sources/
###sudo cp -a processKernel squashfs-root/Sources

sudo cp -a /etc/resolv.conf squashfs-root/etc/
sudo mkdir -p squashfs-root/run/connman
sudo cp -a squashfs-root/run/connman/resolv.conf squashfs-root/run/connman/


sudo cp -a patches squashfs-root/Sources/
sudo cp -a getSourceDeps.sh squashfs-root/Sources/
sudo cp -a getRepo.sh squashfs-root/Sources/

#prepare chroot
./mountunmount.sh "before"

	#copy our certificates to chroot as debian 9 certs are outdated
	sudo /usr/sbin/chroot squashfs-root /Sources/getSourceDeps.sh
	sudo rm -rf squashfs-root/usr/share/ca-certificates
	sudo rm squashfs-root/etc/ca-certificates.conf
	sudo cp -a /usr/share/ca-certificates squashfs-root/usr/share/
	sudo cp -a /etc/ca-certificates.conf squashfs-root/etc/
	sudo rm -rf squashfs-root/etc/ssl/certs
	sudo cp -a /etc/ssl/certs squashfs-root/etc/ssl/certs
	sudo /usr/sbin/chroot squashfs-root /usr/sbin/update-ca-certificates

	#allow sudo for live user
	echo 'live ALL=(ALL) NOPASSWD: ALL' | sudo tee squashfs-root/etc/sudoers

	printf "SET THE PASSWORD AS \"live\"\n"
	sudo /usr/sbin/chroot squashfs-root /usr/sbin/adduser live
	sudo /usr/sbin/chroot squashfs-root /usr/sbin/usermod -aG sudo live
	sudo /usr/sbin/chroot squashfs-root sed -i "s&#deb-src http://deb.debian.org/debian/ stretch main&deb-src http://deb.debian.org/debian/ stretch main&g" /etc/apt/sources.list

	#set owner of scripts to "live"
	sudo /usr/sbin/chroot squashfs-root chown -R live:live /Sources

	#get the repo command
	sudo /usr/sbin/chroot --userspec=live:live squashfs-root /Sources/getRepo.sh

	#this is where the business happens
	#sudo /usr/sbin/chroot --userspec=live:live squashfs-root /Sources/getSource-4.2.sh
	#sudo /usr/sbin/chroot --userspec=live:live squashfs-root /Sources/do-4.2.sh
	#sudo /usr/sbin/chroot --userspec=live:live squashfs-root /Sources/getSource-6.0.sh
	#sudo /usr/sbin/chroot --userspec=live:live squashfs-root /Sources/do-6.0.sh

#tidy up
#./mountunmount.sh "after"