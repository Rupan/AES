#!/bin/bash

# https://en.wikipedia.org/wiki/List_of_ARM_microarchitectures
# https://developer.arm.com/open-source/gnu-toolchain/gnu-rm/downloads

# TODO:
#  * Figure out -mfloat-abi={soft|softfp|hard} for arm-none-eabi-gcc
#      https://embeddedartistry.com/blog/2017/10/9/r1q7pksku2q3gww9rpqef0dnskphtc
#  * Investigate arm-linux-gnueabi-gcc and arm-linux-gnueabihf-gcc
# Linker script: https://forum.osdev.org/viewtopic.php?f=1&t=18333
rm -f *.o
arm-none-eabi-gcc -DHAVE_MACHINE_ENDIAN -march=armv5tej -mcpu=arm926ej-s -O2 -g -c \
  -nostdlib -nostartfiles -nodefaultlibs -fno-builtin -ffreestanding -DNDEBUG \
  aescrypt.c aeskey.c aestab.c aes_modes.c memcpy.c
arm-none-eabi-ld -r aescrypt.o aeskey.o aes_modes.o aestab.o -o aes.o

# arm-none-eabi-ld -e 0x100000 -Ttext 0x100000 aescrypt.o aeskey.o aes_modes.o aestab.o -o aes.out

arm-none-eabi-ld -T aes-flat.lds -o aes.elf aescrypt.o aeskey.o aes_modes.o aestab.o memcpy.o

# size -A -d aes.elf
# arm-none-eabi-readelf -e aes.elf

arm-none-eabi-objcopy -j .text -j .rodata -O binary aes.elf aes.bin
