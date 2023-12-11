#!/bin/sh

REPLICANTURL="https://git.replicant.us/replicant"

cd "$(dirname $0)"

if [ ! -f "OWNERS" ]; then
	wget ${REPLICANTURL}/toolchain_gcc/plain/OWNERS -O OWNERS
	if [ $? -gt 0 ]; then
		if [ -f "OWNERS" ]; then
			rm "OWNERS"
		fi
	fi
fi

if [ ! -f "README.md" ]; then
	wget ${REPLICANTURL}/toolchain_gcc/plain/README.md -O README.md
	if [ $? -gt 0 ]; then
		if [ -f "README.md" ]; then
			rm "README.md"
		fi
	fi
fi

if [ ! -f "README.version" ]; then
	wget ${REPLICANTURL}/toolchain_gcc/plain/README.version -O README.version
	if [ $? -gt 0 ]; then
		if [ -f "README.version" ]; then
			rm "README.version"
		fi
	fi
fi

if [ ! -f "build-gcc.sh" ]; then
	wget ${REPLICANTURL}/toolchain_gcc/plain/build-gcc.sh -O build-gcc.sh
	chmod +x build-gcc.sh
		if [ $? -gt 0 ]; then
		if [ -f "build-gcc.sh" ]; then
			rm "build-gcc.sh"
		fi
	fi
fi

if [ ! -f "build.py" ]; then
	wget ${REPLICANTURL}/toolchain_gcc/plain/build.py -O build.py
	if [ $? -gt 0 ]; then
		if [ -f "build.py" ]; then
			rm "build.py"
		fi
	fi
fi

if [ ! -f "compiler_wrapper" ]; then
	wget ${REPLICANTURL}/toolchain_gcc/plain/compiler_wrapper -O compiler_wrapper
	if [ $? -gt 0 ]; then
		if [ -f "compiler_wrapper" ]; then
			rm "compiler_wrapper"
		fi
	fi
fi

if [ ! -f "update-prebuilts.py" ]; then
	wget ${REPLICANTURL}/toolchain_gcc/plain/update-prebuilts.py -O update-prebuilts.py
	if [ $? -gt 0 ]; then
		if [ -f "update-prebuilts.py" ]; then
			rm "update-prebuilts.py"
		fi
	fi
fi