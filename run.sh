#!/bin/bash

set -ex

base=/hdd2/dumps/Samsung/SM-A515F_XEF/
base=/hdd2/dumps/Samsung/SM-G781U

cp $base/recovery.img .
off=$(grep -ab -o SEANDROIDENFORCE recovery.img |tail -n 1 |cut -d : -f 1)
dd if=recovery.img of=r.img bs=4k count=$off iflag=count_bytes

cp $base/boot.img .
off=$(grep -ab -o SEANDROIDENFORCE boot.img |tail -n 1 |cut -d : -f 1)
dd if=boot.img of=b.img bs=4k count=$off iflag=count_bytes

if [ ! -f phh.pem ];then
    openssl genrsa -f4 -out phh.pem 4096
fi

rm -Rf d
(
mkdir d
cd d
~phh/Downloads/magisk/x86/magiskboot unpack ../r.img
~phh/Downloads/magisk/x86/magiskboot cpio ramdisk.cpio extract
# Reverse fastbootd ENG mode check
#~phh/Downloads/magisk/x86/magiskboot hexpatch system/bin/recovery e10313aaf40300aa6ecc009420010034 e10313aaf40300aa6ecc0094 20 01 00 35
~phh/Downloads/magisk/x86/magiskboot hexpatch system/bin/recovery 3ad3009420010034 3ad3009420010035
~phh/Downloads/magisk/x86/magiskboot cpio ramdisk.cpio 'add 0755 system/bin/recovery system/bin/recovery'
~phh/Downloads/magisk/x86/magiskboot repack ../r.img new-boot.img
cp new-boot.img ../r.img
)

/build2/AOSP-11.0/out/host/linux-x86/bin/avbtool extract_public_key --key phh.pem --output phh.pub.bin
/build2/AOSP-11.0/out/host/linux-x86/bin/avbtool add_hash_footer --partition_name recovery --partition_size 82694144 --image r.img --key phh.pem --algorithm SHA256_RSA4096

# boot.img MUST NOT be signed
# recovery.img MUST be signed
