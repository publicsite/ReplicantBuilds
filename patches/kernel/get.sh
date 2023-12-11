#!/bin/sh

cd "$(dirname $0)"

if [ ! -f "lineageos_i9305_defconfig" ]; then
	wget "https://git.replicant.us/contrib/scintill/kernel_samsung_smdk4412/plain/arch/arm/configs/lineageos_i9305_defconfig?h=replicant-6.0" -O lineageos_i9305_defconfig
	if [ $? -gt 0 ]; then
		if [ -f "lineageos_i9305_defconfig" ]; then
			rm "lineageos_i9305_defconfig"
		fi
	fi
fi
