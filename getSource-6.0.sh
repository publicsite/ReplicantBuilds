#!/bin/bash

putInConfig(){
if [ "${3}" = "" ]; then 
	theresult="y"
else
	theresult="${3}"
fi
	if [ "$(grep "^${1}=n" ${2})" != "" ]; then
		sed -i "s/${1}=n/${1}=${theresult}/g" ${2}
	elif [ "$(grep "^# ${1} is not set" ${2})" != "" ]; then
		sed -i "s/# ${1} is not set/${1}=${theresult}/g" "${2}"
	elif [ "$(grep "^${1}=m" ${2})" != "" ]; then
		sed -i "s/${1}=m/${1}=${theresult}/g" "${2}"
	elif [ "$(grep "^${1}=${theresult}" ${2})" = "" ]; then
		echo "${1}=${theresult}" >> "${2}"
	fi
}


takeFromConfig(){
	if [ "$(grep "^${1}=y" ${2})" != "" ]; then
		sed -i "s/${1}=y/${1}=n/g" ${2}
	elif [ "$(grep "^# ${1} is not set" ${2})" != "" ]; then
		sed -i "s/# ${1} is not set/${1}=n/g" "${2}"
	elif [ "$(grep "^${1}=m" ${2})" != "" ]; then
		sed -i "s/${1}=n/${1}=y/g" "${2}"
	elif [ "$(grep "^${1}=n" ${2})" = "" ]; then
		echo "${1}=n" >> "${2}"
	fi
}

cd "$(dirname "$0")"

thepwd="${PWD}"

REPLICANTDIR="${PWD}/replicant-6.0"

printf "This will require ~140GB\n"

#starts here

#use system certificates
export REQUESTS_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt

source /usr/local/bin/repo-env.sh

mkdir replicant-6.0
cd replicant-6.0

git config --global user.email "dontcall@me.com"
git config --global user.name "Absolutely Anonymous"

git clone https://git.replicant.us/contrib/scintill/manifest.git -b replicant-6.0 manifest

cd manifest

#fix broken links in manifest
patch -p0 < ../../patches/scintill-default.xml.patch

thedir="$PWD"
git init
git add default.xml
git commit -m "My local manifest"
cd ..
repo init -u "${thedir}" -b replicant-6.0
repo sync

#get fdroid prebuilt apps
gpg --keyserver hkp://pgp.rediris.es --recv-key 37D2C98789D8311948394E3E41E7044E1DBA2E89
vendor/replicant/get-prebuilts

#i9305 patches {
	thenewdefconfig="replicant_defconfig"
	thenewdefconfigpath="${REPLICANTDIR}/kernel/replicant/linux/arch/arm/configs/${thenewdefconfig}"

	#make selinux permissive on boot
	sed -i "s#CONFIG_CMDLINE=\".*\"#CONFIG_CMDLINE=\"console=ttySAC2,115200 consoleblank=0 androidboot.hardware=smdk4x12 androidboot.selinux=permissive\"#g" "$thenewdefconfigpath"

	#modem support
	putInConfig "CONFIG_USB_NET_QMI_WWAN" "$thenewdefconfigpath"
	putInConfig "CONFIG_USB_WDM" "$thenewdefconfigpath"

	cd "${REPLICANTDIR}/kernel/replicant/linux"

	#Disable optimization in some functions (similar bug to) https://code.fossencdi.org/kernel_samsung_smdk4412.git/commit/?h=replicant-6.0&id=698f3e8de2f0104dc80402ea151aae73b946a2d9
	patch -p0 < $thepwd/patches/kernel/sched.c.patch
	###patch -p0 < $thepwd/patches/kernel/namei.c.patch

	###https://patchwork.kernel.org/project/linux-fsdevel/patch/20221115040400.53712-1-hucool.lihua@huawei.com/
	##patch -p1 < $thepwd/patches/kernel/coredump.c.patch

	patch -p1 < $thepwd/patches/kernel/headers_install.sh.patch


	cd "${REPLICANTDIR}/device/samsung/i9305"

	#adjust board.mk for replicant-next kernel
	sed -i "s#TARGET_KERNEL_SOURCE := .*#TARGET_KERNEL_SOURCE := kernel/replicant/linux#g" "${REPLICANTDIR}/device/samsung/i9305/BoardConfig.mk"
	sed -i "s#TARGET_KERNEL_CONFIG := .*#TARGET_KERNEL_CONFIG := ${thenewdefconfig}#g" "${REPLICANTDIR}/device/samsung/i9305/BoardConfig.mk"

	##these patches were created with "diff -du"
	##from the instructions at https://redmine.replicant.us/issues/1958
	patch -p0 < ../../../../patches/init.target.rc.patch
	patch -p0 < ../../../../patches/ueventd.smdk4x12.rc.patch
	patch -p0 < ../../../../patches/i9305.mk.patch
	patch -p0 < ../../../../patches/file_contexts.patch
	patch -p0 < ../../../../patches/lineage.dependencies.patch

	cp ../../../../patches/dbus.te selinux/dbus.te
	cp ../../../../patches/file.te selinux/file.te
	cp ../../../../patches/ofono.te selinux/ofono.te
	cp ../../../../patches/radio.te selinux/radio.te
	cp ../../../../patches/mdm9k.te selinux/mdm9k-efsd.te

	cd ../../../../
#i9305 patches }

	cd "${REPLICANTDIR}"

#generic (scintill) replicant 6.0 patches {

	#fix tinyalsa error {
		cd "${REPLICANTDIR}/external/tinyalsa"
		patch -p0 < ../../../patches/external_tinyalsa_pcm.c.patch
	#fix tinyalsa error }

	#https://android.googlesource.com/platform/bionic/+/6f88821e5dc4894dc2905cbe53ae21c782354f38%5E%21/ {
		cd "${REPLICANTDIR}/bionic"
		patch -p0 < ../../patches/uchar.h.patch
	#https://android.googlesource.com/platform/bionic/+/6f88821e5dc4894dc2905cbe53ae21c782354f38%5E%21/ }

#generic (scintill) replicant 6.0 patches }