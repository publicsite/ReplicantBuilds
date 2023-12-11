#!/bin/sh

cd "$(dirname "$0")"

if [ "$1" = "before" ]; then
	sudo /usr/sbin/chroot squashfs-root mknod /dev/null c 1 3
	sudo /usr/sbin/chroot squashfs-root chmod 666 /dev/null
	sudo /usr/sbin/chroot squashfs-root mknod -m 444 /dev/random c 1 8
	sudo /usr/sbin/chroot squashfs-root mknod -m 444 /dev/urandom c 1 9
	sudo /usr/sbin/chroot squashfs-root mkdir -v /dev/pts
	sudo /usr/sbin/chroot squashfs-root mount -vt devpts -o gid=4,mode=620 none /dev/pts
	sudo /usr/sbin/chroot squashfs-root mount proc /proc -t proc

	sudo mount --bind /dev/shm "squashfs-root/dev/shm"
elif [ "$1" = "after" ]; then
	sudo /usr/sbin/chroot squashfs-root umount /dev/pts
	sudo /usr/sbin/chroot squashfs-root umount /proc
	sudo umount squashfs-root/dev/shm
fi