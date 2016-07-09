#!/bin/bash
export KERNELDIR=`readlink -f .`
export RAMFS_SOURCE=`readlink -f $KERNELDIR/recovery`
export PARTITION_SIZE=67108864

echo "kerneldir = $KERNELDIR"
echo "ramfs_source = $RAMFS_SOURCE"

RAMFS_TMP="/tmp/arter97-op3-recovery"

echo "ramfs_tmp = $RAMFS_TMP"
cd $KERNELDIR

if [ "${1}" = "skip" ] ; then
	echo "Skipping Compilation"
else
	echo "Compiling kernel"
	cp defconfig .config
	make "$@" || exit 1
fi

echo "Building new ramdisk"
#remove previous ramfs files
rm -rf '$RAMFS_TMP'*
rm -rf $RAMFS_TMP
rm -rf $RAMFS_TMP.cpio
#copy ramfs files to tmp directory
cp -ax $RAMFS_SOURCE $RAMFS_TMP
cd $RAMFS_TMP

find . -name '*.sh' -exec chmod 755 {} \;

$KERNELDIR/ramdisk_fix_permissions.sh 2>/dev/null

#clear git repositories in ramfs
find . -name .git -exec rm -rf {} \;
find . -name EMPTY_DIRECTORY -exec rm -rf {} \;
cd $KERNELDIR
rm -rf $RAMFS_TMP/tmp/*

cd $RAMFS_TMP
find . | fakeroot cpio -H newc -o | gzip -9 > $RAMFS_TMP.cpio.gz
ls -lh $RAMFS_TMP.cpio.gz
cd $KERNELDIR

echo "Making new boot image"
gcc -w -s -pipe -O2 -Itools/libmincrypt -o tools/mkbootimg/mkbootimg tools/libmincrypt/*.c tools/mkbootimg/mkbootimg.c
tools/mkbootimg/mkbootimg --kernel $KERNELDIR/arch/arm64/boot/Image.gz-dtb --ramdisk $RAMFS_TMP.cpio.gz --cmdline 'androidboot.hardware=qcom user_debug=31 msm_rtb.filter=0x237 ehci-hcd.park=3 lpm_levels.sleep_disabled=1 cma=32M@0-0xffffffff' --base 0x80000000 --pagesize 4096 --ramdisk_offset 0x02200000 --tags_offset 0x02000000 --second_offset 0x00f00000 -o $KERNELDIR/recovery.img
GENERATED_SIZE=$(stat -c %s recovery.img)
if [[ $GENERATED_SIZE -gt $PARTITION_SIZE ]]; then
	echo "recovery.img size larger than partition size!" 1>&2
	exit 1
fi

echo "done"
ls -al recovery.img
echo ""
