#!/bin/bash

# https://en.wikipedia.org/wiki/List_of_ARM_microarchitectures
# https://developer.arm.com/open-source/gnu-toolchain/gnu-rm/downloads

rm -f *.o
arm-none-eabi-gcc -DHAVE_MACHINE_ENDIAN -march=armv5tej -mcpu=arm926ej-s -O2 -g -c \
  -nostdlib -ffreestanding -DNDEBUG aescrypt.c aeskey.c aestab.c aes_modes.c
arm-none-eabi-ld -r aescrypt.o aeskey.o aes_modes.o aestab.o -o aes.o
