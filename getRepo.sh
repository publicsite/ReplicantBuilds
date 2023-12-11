#!/bin/sh

cd "$(dirname "$0")"

wget "https://ftp.osuosl.org/pub/replicant/build-tools/repo/28-01-2021/sz1lkq3ryr5iv6amy6f3d2pziks27g28-tarball-pack.tar.xz"
if [ "$(sha512sum sz1lkq3ryr5iv6amy6f3d2pziks27g28-tarball-pack.tar.xz | cut -d " " -f 1)" != "def3c0b3ae2305d695b57d8d1f2fa8acfaf9b7c9c0f668c129a2bfe2652c24a8f2f8167d95f0d71a72d04601daac2b626bfecfae8e7833c812d912d95fd61a5a" ]; then
	printf "UHOH, BAD CHECKSUM\n"
	exit
fi

sudo tar xf sz1lkq3ryr5iv6amy6f3d2pziks27g28-tarball-pack.tar.xz -C /
