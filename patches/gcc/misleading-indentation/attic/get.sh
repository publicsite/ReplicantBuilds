#!/bin/sh

cd "$(dirname $0)"

if [ ! -f "parser.c" ]; then
	wget "https://gcc.gnu.org/git/?p=gcc.git;a=blob_plain;f=gcc/cp/parser.c;h=4d6b479b4970918a96cb2a6864136984f382b146;hb=1a46d358050cf6964df0d8ceaffafd0cc88539b2" -O parser.c
	if [ $? -gt 0 ]; then
		if [ -f "parser.c" ]; then
			rm "parser.c"
		fi
	fi
fi

if [ ! -f "parser.h" ]; then
	wget "https://gcc.gnu.org/git/?p=gcc.git;a=blob_plain;f=gcc/cp/parser.h;hb=1a46d358050cf6964df0d8ceaffafd0cc88539b2" -O parser.h
	if [ $? -gt 0 ]; then
		if [ -f "parser.h" ]; then
			rm "parser.h"
		fi
	fi
fi

if [ ! -f "c-parser.c" ]; then
	wget "https://gcc.gnu.org/git/?p=gcc.git;a=blob_plain;f=gcc/c/c-parser.c;h=024dbd2af8a3a6c88d33c51bcffa9d599f9e92b0;hb=1a46d358050cf6964df0d8ceaffafd0cc88539b2" -O c-parser.c
	if [ $? -gt 0 ]; then
		if [ -f "c-parser.c" ]; then
			rm "c-parser.c"
		fi
	fi
fi