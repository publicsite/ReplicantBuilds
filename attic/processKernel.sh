#!/bin/sh

REPLICANTDIR="$PWD/replicant-6.0" #you can change this

if [ ! -d kernelArchives ]; then
mkdir kernelArchives
fi

if [ "$1" != "" ] && [ -d "postmarketConfigs/$1" ]; then
akernel="$1"
else
while true; do
echo "TYPE YOUR KERNEL!\n$( cd postmarketConfigs; find . -mindepth 1 -maxdepth 1 -type d | cut -d / -f2 | sort )" | less
read akernel
if [ -d "postmarketConfigs/$akernel" ]; then
	echo "You chose $akernel"
	break
elif [ "$akernel" = "q" ]; then
	echo "User quit."
	exit 1
fi
done
fi

chmod +x postmarketConfigs/$akernel/APKBUILD

if [ ! -f "postmarketConfigs/$akernel/APKBUILD.old" ]; then
	cp -a postmarketConfigs/$akernel/APKBUILD postmarketConfigs/$akernel/APKBUILD.old
	sed -i "s#builddir=.*linux-.*##g" postmarketConfigs/$akernel/APKBUILD
	echo "" >> postmarketConfigs/$akernel/APKBUILD
	echo "echo \"\$source"\" >> postmarketConfigs/$akernel/APKBUILD
fi

sources="$(./postmarketConfigs/$akernel/APKBUILD)"

kernelroot=""
IFS="	
"
for line in $sources; do

	if [ "$line" != "" ]; then
		line="$(echo "$line" | sed 's/^[ \t]*//;s/[ \t]*$//')"
		theprefix="$( echo "$line" | cut -d : -f 1 )"
		if [ "$theprefix" = "https" ] || [ "$theprefix" = "http" ] | [ "$theprefix" = "git" ]; then
			extension="$( echo "$line" | rev | cut -d . -f 1 | rev )"
			thefilename="$( echo "$line" | rev | cut -d / -f 1 | rev )"
			noextension="$( echo "$thefilename" | cut -d . -f 1)"

			if [ "$extension" = "xz" ] || [ "$extension" = "gz" ] || [ "$extension" = "zip" ]; then
					
				if [ ! -f "./postmarketConfigs/$akernel/$line" ]; then
					if [ ! -f "kernelArchives/$thefilename" ]; then
						wget "$line" -O "kernelArchives/$thefilename"
						if [ "$?" -gt 0 ]; then
							rm "kernelArchives/$thefilename"
						fi
					fi
				fi

				if [ -d "kernelArchives/$noextension" ]; then
					rm -rf "kernelArchives/$noextension"
				fi

				mkdir "kernelArchives/$noextension"
				cd "kernelArchives/$noextension"
				tar -xf ../"$thefilename"
				if [ "$?" -gt 0 ]; then
					cd ../../
					rm -rf "kernelArchives/$noextension"
				else
					cd ../../
				fi

				if [ "$kernelroot" = "" ]; then
					kernelroot="$PWD/kernelArchives/$noextension"
				fi
			else
				if [ ! -d "kernelArchives/$noextension" ]; then
					git clone "$line" "kernelArchives/$noextension"
					if [ "$?" -gt 0 ]; then
						rm -rf "kernelArchives/$noextension"
					fi
				fi

				if [ "$kernelroot" = "" ]; then
					kernelroot="$PWD/kernelArchives/$noextension"
				fi
			fi
		fi
	fi
done

thepwd="$PWD"

cd "$kernelroot"

while true; do
	if [ -f README ]; then

		break
	else
		tosink="$(find .  -maxdepth 1 -mindepth 1 -type d | head -n 1)"
		if [ "$tosink" = "" ]; then
			break
		else
			cd "$tosink"
		fi
	fi
done

kernelroot="$PWD"

find "$thepwd/postmarketConfigs/$akernel" -type f -name "*.patch" | sort | while read line; do
patch -p1 < "$line"
done

#Disable optimization in some functions (similar bug to) https://code.fossencdi.org/kernel_samsung_smdk4412.git/commit/?h=replicant-6.0&id=698f3e8de2f0104dc80402ea151aae73b946a2d9
patch -p0 < $thepwd/patches/kernel/sched.c.patch
patch -p0 < $thepwd/patches/kernel/namei.c.patch

#https://patchwork.kernel.org/project/linux-fsdevel/patch/20221115040400.53712-1-hucool.lihua@huawei.com/
patch -p1 < $thepwd/patches/kernel/coredump.c.patch

patch -p1 < $thepwd/patches/kernel/headers_install.sh.patch

echo $PWD

cd arch

anarch=""
x86_64="n"

while true; do
echo "TYPE YOUR ARCHITECTURE!"
find . -maxdepth 1 -mindepth 1 -type d | cut -d / -f 2
echo "x86_64"
read anarch
	if [ -d "$anarch" ]; then
		break
	elif [ anarch = "x86_64" ]; then
		anarch="x86"
		x86_64="y"
	elif [ anarch = "q" ]; then
		exit 1
	fi
done

echo $anarch

linuxconfig="$(find "$thepwd/postmarketConfigs/$akernel" -type f -name "config-*" | head -n 1)"

cp -a "$linuxconfig" "$anarch/configs/"

#cp -a "$thepwd/postmarketConfigs/android-base.config" "$anarch/configs/"

cd ..

#we first merge the postmarketos config and the android-base config
ARCH=$anarch ./scripts/kconfig/merge_config.sh "arch/$anarch/configs/$(basename "$linuxconfig")" "kernel/configs/android-base.config" "kernel/configs/android-recommended.config"

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

#we then set some additional conditionals
#see https://android.googlesource.com/kernel/configs/+/refs/heads/master/android-6.1/android-base-conditional.xml
if [ "$anarch" = "arm" ]; then
	putInConfig "CONFIG_ARM" ".config"
	putInConfig "CONFIG_AEABI" ".config"
	putInConfig "CONFIG_CPU_SW_DOMAIN_PAN" ".config"
	takeFromConfig "CONFIG_DEVKMEM" ".config"
	takeFromConfig "CONFIG_OABI_COMPAT" ".config"
elif [ "$anarch" = "arm64" ]; then
	putInConfig "CONFIG_ARM64" ".config"
	putInConfig "CONFIG_ARM64_PAN" ".config"
	putInConfig "CONFIG_ARM64_SW_TTBR0_PAN" ".config"
	putInConfig "CONFIG_ARMV8_DEPRECATED" ".config"
	putInConfig "CONFIG_COMPAT" ".config"
	putInConfig "CONFIG_CP15_BARRIER_EMULATION" ".config"
	putInConfig "CONFIG_RANDOMIZE_BASE" ".config"
	putInConfig "CONFIG_SETEND_EMULATION" ".config"
	putInConfig "CONFIG_SHADOW_CALL_STACK" ".config"
	putInConfig "CONFIG_SWP_EMULATION" ".config"
	putInConfig "CONFIG_BPF_JIT_ALWAYS_ON" ".config"
	putInConfig "CONFIG_HAVE_MOVE_PMD" ".config"
	putInConfig "CONFIG_HAVE_MOVE_PUD" ".config"
	putInConfig "CONFIG_KFENCE" ".config"
	putInConfig "CONFIG_USERFAULTFD" ".config"
elif [ "$x86_64" = "n" ] && [ "$anarch" = "x86" ]; then
	putInConfig "CONFIG_X86" ".config"
	takeFromConfig "CONFIG_DEVKMEM" ".config"
	putInConfig "CONFIG_KFENCE" ".config"
	putInConfig "CONFIG_PAGE_TABLE_ISOLATION" ".config"
	putInConfig "CONFIG_RETPOLINE" ".config"
	putInConfig "CONFIG_HAVE_MOVE_PMD" ".config"
	putInConfig "CONFIG_HAVE_MOVE_PUD" ".config"
	putInConfig "CONFIG_RANDOMIZE_BASE" ".config"
	putInConfig "CONFIG_USERFAULTFD" ".config"
elif [ "$x86_64" = "y" ] && [ "$anarch" = "x86" ]; then
	putInConfig "CONFIG_X86_64" ".config"
	putInConfig "CONFIG_BPF_JIT_ALWAYS_ON" ".config"
fi

##kernel/sched/fair.c:6071:1: internal compiler error: in extract_constrain_insn, at recog.c:2246
##takeFromConfig "CONFIG_FAIR_GROUP_SCHED" ".config"

#putInConfig "CONFIG_SMP" ".config"
#putInConfig "CONFIG_USE_GENERIC_SMP_HELPERS" ".config"
#putInConfig "CONFIG_SMP_ON_UP" ".config"
#putInConfig "CONFIG_PM_SLEEP_SMP" ".config"

sed -i "s#CONFIG_INITRAMFS_SOURCE=\".*\"#CONFIG_INITRAMFS_SOURCE=\"\"#g" .config

mv .config "arch/$anarch/configs/$(basename "$linuxconfig").droid_defconfig"

##make ARCH=$anarch savedefconfig
##mv defconfig "arch/$anarch/configs/$(basename "$linuxconfig").droid_defconfig"

make distclean

##cp -a "arch/$anarch/configs/$(basename "$linuxconfig").droid_defconfig" .config

##make ARCH=$anarch olddefconfig

cd "$REPLICANTDIR"

mkdir -p kernel/postmarket

echo "Copying the kernel ..."
mv "$kernelroot" kernel/postmarket/$akernel

cd device

themessage=""

clear && clear

while true; do
echo "TYPE IN THE DEVICE TREE or TYPE QUIT TO EXIT."
echo "$themessage\n\nPlease choose a device tree to patch with this kernel, or press q then type quit to quit\n$(find -maxdepth 2 -mindepth 2 -type d | grep -v "./common" | cut -d / -f 2-)" | less
read devicetree
	if [ -d "$devicetree" ]; then

	#remove old kernel from lineage.dependencies
		readytodel=0
		thestart=0
		linenumber=0
IFS="
"
		for line in $(cat ${devicetree}/lineage.dependencies); do
			if [ "$(echo "$line" | sed 's/^[ \t]*//;s/[ \t]*$//'| cut -c 1-1)" = "{" ]; then
				thestart="$linenumber"
			fi
			if [ "$readytodel" = 1 ]; then
				if [ "$(echo "$line" | sed 's/^[ \t]*//;s/[ \t]*$//' | cut -c 1-1)" = "}" ]; then
					#remove the dependency on old kernel
					sed -i -e "${thestart},${linenumber}d" ${devicetree}/lineage.dependencies
					break
				fi
			fi
			if [ "$(echo $line | grep "\"target_path\": \".*kernel.*\"")" != "" ]; then
				readytodel=1
			fi
			linenumber="$(expr $linenumber + 1)"
		done
	
		if [ "${devicetree}" = "samsung/i9305" ]; then
			##cd "${REPLICANTDIR}/system/tools/dtbtool"
			##patch -p0 < "${REPLICANTDIR}/patches/exynos-dtbtool.patch"
			##cd "${REPLICANTDIR}"

			#thenewdefconfig="lineageos_i9305_defconfig"
			thenewdefconfig="$(basename "$linuxconfig").droid_defconfig"
			thenewdefconfigpath="${REPLICANTDIR}/kernel/postmarket/${akernel}/arch/$anarch/configs/${thenewdefconfig}"

			##cp -a "${REPLICANTDIR}/../patches/kernel/lineageos_i9305_defconfig" "${REPLICANTDIR}/kernel/postmarket/${akernel}/arch/$anarch/configs/lineageos_i9305_defconfig"

			#make selinux permissive on boot
			sed -i "s#CONFIG_CMDLINE=\".*\"#CONFIG_CMDLINE=\"console=ttySAC2,115200 consoleblank=0 androidboot.hardware=smdk4x12 androidboot.selinux=permissive\"#g" "$thenewdefconfigpath"
			
			#modem support
			putInConfig "CONFIG_USB_NET_QMI_WWAN" "$thenewdefconfigpath"
			putInConfig "CONFIG_USB_WDM" "$thenewdefconfigpath"

			#audio support
			putInConfig "CONFIG_GPIO_WM8994" "$thenewdefconfigpath"
			putInConfig "CONFIG_MFD_WM8994" "$thenewdefconfigpath"
			putInConfig "CONFIG_REGULATOR_WM8994" "$thenewdefconfigpath"
			putInConfig "CONFIG_SND_SOC_SAMSUNG_SMDK_WM8994" "$thenewdefconfigpath"
			putInConfig "CONFIG_SND_SOC_SMDK_WM8994_PCM" "$thenewdefconfigpath"
			putInConfig "CONFIG_SND_SOC_WM8994" "$thenewdefconfigpath"

			#LCD support
			putInConfig "CONFIG_FB_S5P" "$thenewdefconfigpath"
			putInConfig "CONFIG_FB_S5P_SPLASH_SCREEN" "$thenewdefconfigpath"
			putInConfig "CONFIG_FB_S5P_VSYNC_THREAD" "$thenewdefconfigpath"
			putInConfig "CONFIG_FB_S5P_VSYNC_SYSFS" "$thenewdefconfigpath"
			putInConfig "CONFIG_FB_S5P_DEFAULT_WINDOW" "$thenewdefconfigpath"
			putInConfig "CONFIG_FB_S5P_NR_BUFFERS" "$thenewdefconfigpath"
			putInConfig "CONFIG_VIDEO_SAMSUNG_MEMSIZE_FIMD" "$thenewdefconfigpath"
			putInConfig "CONFIG_FB_S5P_MDNIE" "$thenewdefconfigpath"
			putInConfig "CONFIG_FB_S5P_MIPI_DSIM" "$thenewdefconfigpath"
			putInConfig "CONFIG_FB_BGRA_ORDER" "$thenewdefconfigpath"
			putInConfig "CONFIG_FB_S5P_S6E8AA0" "$thenewdefconfigpath"
			putInConfig "CONFIG_S6E8AA0_AMS480GYXX" "$thenewdefconfigpath"
			putInConfig "CONFIG_BACKLIGHT_LCD_SUPPORT" "$thenewdefconfigpath"
			putInConfig "CONFIG_LCD_CLASS_DEVICE" "$thenewdefconfigpath"
			putInConfig "CONFIG_BACKLIGHT_CLASS_DEVICE" "$thenewdefconfigpath"
			putInConfig "CONFIG_SAMSUNG_DEV_BACKLIGHT" "$thenewdefconfigpath"
			putInConfig "CONFIG_AID_DIMMING" "$thenewdefconfigpath"
			putInConfig "CONFIG_LCD_FREQ_SWITCH" "$thenewdefconfigpath"

			#graphics support
			putInConfig "CONFIG_ION" "${thenewdefconfigpath}"
			putInConfig "CONFIG_ION_EXYNOS" "${thenewdefconfigpath}"
			putInConfig "CONFIG_ION_EXYNOS_CONTIGHEAP_SIZE" "${thenewdefconfigpath}" 71680

			#touchscreen
			putInConfig "CONFIG_TOUCHSCREEN_MELFAS" "${thenewdefconfigpath}"
			putInConfig "CONFIG_SEC_TOUCHSCREEN_DVFS_LOCK" "${thenewdefconfigpath}"
			putInConfig "CONFIG_SEC_TOUCHSCREEN_SURFACE_TOUCH" "${thenewdefconfigpath}"
			putInConfig "CONFIG_INPUT_GPIO" "${thenewdefconfigpath}"

			#adjust board.mk for new kernel
			sed -i "s#TARGET_KERNEL_SOURCE := .*#TARGET_KERNEL_SOURCE := kernel/postmarket/${akernel}#g" ${devicetree}/BoardConfig.mk
			sed -i "s#TARGET_KERNEL_CONFIG := .*#TARGET_KERNEL_CONFIG := ${thenewdefconfig}#g" ${devicetree}/BoardConfig.mk

			#make recovery.img smaller by merging with tinylinux config https://elinux.org/Kernel_Size_Tuning_Guide

			putInConfig "CONFIG_CORE_SMALL" "$thenewdefconfigpath"
			putInConfig "CONFIG_NET_SMALL" "$thenewdefconfigpath"
			putInConfig "CONFIG_KMALLOC_ACCOUNTING" "$thenewdefconfigpath"
			putInConfig "CONFIG_AUDIT_BOOTMEM" "$thenewdefconfigpath"
			putInConfig "CONFIG_DEPRECATE_INLINES" "$thenewdefconfigpath"
			takeFromConfig "CONFIG_PRINTK" "$thenewdefconfigpath"
			takeFromConfig "CONFIG_BUG" "$thenewdefconfigpath"
			takeFromConfig "CONFIG_ELF_CORE" "$thenewdefconfigpath"
			takeFromConfig "CONFIG_PROC_KCORE" "$thenewdefconfigpath"
			takeFromConfig "CONFIG_AIO" "$thenewdefconfigpath"
			takeFromConfig "CONFIG_XATTR" "$thenewdefconfigpath"
			takeFromConfig "CONFIG_FILE_LOCKING" "$thenewdefconfigpath"
			takeFromConfig "CONFIG_DIRECTIO" "$thenewdefconfigpath"

			takeFromConfig "CONFIG_KALLSYMS" "$thenewdefconfigpath"
			takeFromConfig "CONFIG_SHMEM" "$thenewdefconfigpath"
			takeFromConfig "CONFIG_SYSV_IPC" "$thenewdefconfigpath"
			takeFromConfig "CONFIG_POSIX_MQUEUE" "$thenewdefconfigpath"
			takeFromConfig "CONFIG_SYSCTL" "$thenewdefconfigpath"

			putInConfig "CONFIG_CC_OPTIMIZE_FOR_SIZE" "$thenewdefconfigpath"
			putInConfig "CONFIG_IOSCHED_AS" "$thenewdefconfigpath"
			takeFromConfig "CONFIG_IOSCHED_CFQ" "$thenewdefconfigpath"
			takeFromConfig "CONFIG_IDE" "$thenewdefconfigpath"
			takeFromConfig "CONFIG_SCSI" "$thenewdefconfigpath"

			putInConfig "CONFIG_OPTIMIZE_INLINING" "$thenewdefconfigpath"
			putInConfig "CONFIG_SLOB" "$thenewdefconfigpath"
			takeFromConfig "CONFIG_SLAB" "$thenewdefconfigpath"
			takeFromConfig "CONFIG_SLUB" "$thenewdefconfigpath"

			#use XZ compression to make image even smaller
			takeFromConfig "CONFIG_INITRAMFS_COMPRESSION_GZIP" "$thenewdefconfigpath"
			takeFromConfig "CONFIG_INITRAMFS_COMPRESSION_BZIP2" "$thenewdefconfigpath"
			takeFromConfig "CONFIG_INITRAMFS_COMPRESSION_LZO" "$thenewdefconfigpath"
			takeFromConfig "CONFIG_INITRAMFS_COMPRESSION_LZ4" "$thenewdefconfigpath"
			takeFromConfig "CONFIG_INITRAMFS_COMPRESSION_ZSTD" "$thenewdefconfigpath"
			takeFromConfig "CONFIG_INITRAMFS_COMPRESSION_NONE" "$thenewdefconfigpath"
			putInConfig "CONFIG_INITRAMFS_COMPRESSION_XZ" "$thenewdefconfigpath"

			takeFromConfig "CONFIG_KERNEL_GZIP" "$thenewdefconfigpath"
			takeFromConfig "CONFIG_KERNEL_LZMA" "$thenewdefconfigpath"
			takeFromConfig "CONFIG_KERNEL_LZO" "$thenewdefconfigpath"
			takeFromConfig "CONFIG_KERNEL_LZ4" "$thenewdefconfigpath"
			putInConfig "CONFIG_KERNEL_XZ" "$thenewdefconfigpath"
		else
			#adjust board.mk for new kernel
			sed -i "s#TARGET_KERNEL_SOURCE := .*#TARGET_KERNEL_SOURCE := kernel/postmarket/${akernel}#g" ${devicetree}/BoardConfig.mk
			sed -i "s#TARGET_KERNEL_CONFIG := .*#TARGET_KERNEL_CONFIG := $(basename "$linuxconfig").droid_defconfig#g" ${devicetree}/BoardConfig.mk
		fi

		themessage="DEVICE TREE: $devicetree PATCHED!"

		echo "$themessage"

	elif [ "$devicetree" = "quit" ]; then
		echo "ALL DONE. THANKS"
		exit
	fi
done