#!/bin/bash

cd "$(dirname "$0")"

if [ -f 1.txt ]; then
rm 1.txt
fi

if [ -f 2.txt ]; then
rm 2.txt
fi

if [ -f 3.txt ]; then
rm 3.txt
fi

thepwd="$PWD"

#export JAVA_HOME=/Sources/java-se-7u75-ri
#export JRE_HOME=${JAVA_HOME}/jre
#export CLASSPATH=.:${JAVA_HOME}/lib:${JRE_HOME}/lib:${JRE_HOME}/lib/amd64:${JRE_HOME}/lib/amd64/jli
#export LD_LIBRARY_PATH="${JAVA_HOME}/lib:${JRE_HOME}/lib:${JRE_HOME}/lib/amd64:${JRE_HOME}/lib/amd64/jli:${LD_LIBRARY_PATH}"
#export PATH=${JAVA_HOME}/bin:$PATH

cd $thepwd/replicant-6.0

####==================================

##stop build from asking for tools.jar, non-existant on later jdks
##sed -i "345,350d" build/core/config.mk

##remove check for javac version
#sed -i "123,134d" build/core/main.mk
##source 1.5 is no longer supported
#sed -i "s#-source 1.5#-source 1.6#g" build/core/combo/javac.mk
#sed -i "s#-target 1.5#-bootclasspath \"${thepwd}/classpath-0.93/lib/glibj.zip\" -target 1.8#g" build/core/combo/javac.mk

####===================================

#increase stack size for java
sed -i "s#-Xmx256m#-Xmx256m -J-Xss10M#" build/core/combo/javac.mk
sed -i "s#-Xmx512M#-Xmx512M -J-Xss10M#" build/core/combo/javac.mk

#####============================================

####IGNORE THIS BLOCK
####javadoc doesn't work because of clashes on 4.2
####futhermore, much of the javadoc api is to become deprecated
####sed -i "s#javadoc \\\#echo javadoc \\\#g" build/core/droiddoc.mk
####the removal of javadoc causes apicheck to fail, so we remove that too
####sed -i "s#APICHECK := \$(HOST_OUT_EXECUTABLES)/apicheck\$(HOST_EXECUTABLE_SUFFIX)#APICHECK := echo#g" build/core/config.mk
####sed -i "s#\$(APICHECK) ##g" build/core/definitions.mk

##fix defined perl error
##sed -i "s#defined##g" kernel/samsung/crespo/kernel/timeconst.pl

##mv external/guava/guava/src/com/google/common/base/Splitter.java external/guava/guava/src/com/google/common/base/Splitter.java.old
##wget https://raw.githubusercontent.com/CyanogenMod/android_external_guava/cm-13.0/guava/src/com/google/common/base/Splitter.java -O external/guava/guava/src/com/google/common/base/Splitter.java

##mv libcore/luni/src/main/java/java/util/EnumMap.java libcore/luni/src/main/java/java/util/EnumMap.java.old
##wget https://git.replicant.us/replicant/libcore/plain/luni/src/main/java/java/util/EnumMap.java -O libcore/luni/src/main/java/java/util/EnumMap.java

###not sure if this is needed, but gets rid of a warning nether-the-less
##mv kernel/samsung/crespo/scripts/depmod.sh kernel/samsung/crespo/scripts/depmod.sh.old
##wget https://git.replicant.us/replicant-next/kernel_replicant_linux/plain/scripts/depmod.sh -O kernel/samsung/crespo/scripts/depmod.sh
##chmod +x kernel/samsung/crespo/scripts/depmod.sh

###This file causes an error, and seems to be removed in replicant 6.0, so we do the same here
##mv libcore/luni/src/main/java/java/lang/Daemons.java libcore/luni/src/main/java/java/lang/Daemons.java.old

##mv external/guava/guava/src/com/google/common/collect/BstRangeOps.java external/guava/guava/src/com/google/common/collect/BstRangeOps.java.old
##mv external/guava/guava/src/com/google/common/collect/TreeMultiset.java external/guava/guava/src/com/google/common/collect/TreeMultiset.java.old
##wget https://raw.githubusercontent.com/CyanogenMod/android_external_guava/cm-13.0/guava/src/com/google/common/collect/TreeMultiset.java -O external/guava/guava/src/com/google/common/collect/TreeMultiset.java
##wget https://raw.githubusercontent.com/CyanogenMod/android_external_guava/cm-13.0/guava/src/com/google/common/collect/CollectPreconditions.java -O external/guava/guava/src/com/google/common/collect/CollectPreconditions.java
##mv external/guava/guava/src/com/google/common/collect/GeneralRange.java external/guava/guava/src/com/google/common/collect/GeneralRange.java.old
##wget https://raw.githubusercontent.com/CyanogenMod/android_external_guava/cm-13.0/guava/src/com/google/common/collect/GeneralRange.java -O external/guava/guava/src/com/google/common/collect/GeneralRange.java

##mv libcore/dalvik/src/main/java/dalvik/system/Zygote.java libcore/dalvik/src/main/java/dalvik/system/Zygote.java.old

##mv libcore/luni/src/main/java/java/util/Objects.java libcore/luni/src/main/java/java/util/Objects.java.old
##wget https://git.replicant.us/replicant/libcore/plain/luni/src/main/java/java/util/Objects.java -O libcore/luni/src/main/java/java/util/Objects.java

##extdirs is not allowed in java 11
##sed -i "s#-extdirs \"\" ##g" build/core/definitions.mk

###java 11 doesn't have boot-class-path so we change it to -classpath in base_rules.mk ... we also get rid of it in droiddoc.mk
##cp build/core/droiddoc.mk build/core/droiddoc.mk.old
##sed -i "58,62d" build/core/droiddoc.mk
##sed -i "s#\$(addprefix -bootclasspath ,\$(PRIVATE_BOOTCLASSPATH))##g" build/core/droiddoc.mk
##sed -i "s#-J-Xbootclasspath/a:/Applications/jprofiler5/bin/agent.jar##g" build/core/droiddoc.mk
##cp build/core/base_rules.mk build/core/base_rules.mk.old
##sed -i "s# -bootclasspath \$(call java-lib-files,core)# -classpath \$(call java-lib-files,core)#g" build/core/base_rules.mk
##sed -i "s# -bootclasspath \$(call java-lib-files,android_stubs_current)# -classpath \$(call java-lib-files,android_stubs_current)#g" build/core/base_rules.mk
##sed -i "s# -bootclasspath \$(call java-lib-files,sdk_v\$(LOCAL_SDK_VERSION))# -classpath \$(call java-lib-files,sdk_v\$(LOCAL_SDK_VERSION))#g" build/core/base_rules.mk
##sed -i "s# -bootclasspath \$(call java-lib-files,core-hostdex,\$(LOCAL_IS_HOST_MODULE))# -classpath \$(call java-lib-files,core-hostdex,\$(LOCAL_IS_HOST_MODULE))#g" build/core/base_rules.mk

#mv build/core/find-jdk-tools-jar.sh build/core/find-jdk-tools-jar.sh.old
#printf '#!/bin/sh\n' > build/core/find-jdk-tools-jar.sh
#printf 'echo %s/classpath-0.93/tools/tools.zip\n' "${thepwd}" >> build/core/find-jdk-tools-jar.sh
#chmod +x build/core/find-jdk-tools-jar.sh

###===================

#For a clean build
make clean

#First, the toolchain needs to be built
./vendor/replicant/build-toolchain

##build sources
. build/envsetup.sh
lunch replicant_i9305-userdebug

##start the build
#parallel_tasks=$(echo "$(grep 'processor' /proc/cpuinfo | wc -l ) + 1" | bc)
#make -j$parallel_tasks bacon
parallel_tasks="1"

#see definitions.mk
#see javac.mk
#see TARGET_linux-arm.mk

##/replicant-4.2/out/target/product/crespo/recovery.img
make -j$parallel_tasks recoveryimage 2>&1 | tee "${thepwd}/1.txt"
##replicant-4.2/out/target/product/crespo/boot.img
make -j$parallel_tasks bootimage 2>&1 | tee "${thepwd}/2.txt"
make -j$parallel_tasks systemimage 2>&1 | tee "${thepwd}/3.txt"

#to sign the images
#./vendor/replicant/sign-build i9305
