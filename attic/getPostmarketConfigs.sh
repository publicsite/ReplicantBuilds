#!/bin/sh

#We download all the kernel configs from postmarketos
#for each, it contains a kernel config, relevant patches and download location of linux archive
#the download location is stored in the APKBUILD

if [ -d postmarketConfigs ]; then
	while true; do
		echo "Would you like to redownload the postmarket kernel configs?"
		read yesno
		if [ "$yesno" = "yes" ]; then
			rm -rf postmarketConfigs
			break
		elif [ "$yesno" = "no" ]; then
			exit 1
		fi
	done
fi

mkdir postmarketConfigs
git clone https://gitlab.com/postmarketOS/pmaports.git
find pmaports -type d -name "linux-*" -exec mv {} postmarketConfigs/ \;
rm -rf pmaports

wget https://android.googlesource.com/kernel/configs/+/refs/heads/master/android-6.1/android-base.config?format=TEXT -O postmarketConfigs/base64

cd postmarketConfigs

cat base64 | base64 -d > android-base.config

rm base64

cd ..