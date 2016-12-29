#!/bin/bash
if [ ! "${1}" = "skip" ] ; then
	./build_clean.sh
	./build_kernel.sh "$@" || exit 1
	./build_recovery.sh "$@" || exit 1
fi

if [ -e boot.img ] ; then
	rm arter97-kernel-"$(cat version)".zip 2>/dev/null
	cp boot.img kernelzip/boot.img
	cd kernelzip/
	7z a -mx9 arter97-kernel-"$(cat ../version)"-tmp.zip *
	zipalign -v 4 arter97-kernel-"$(cat ../version)"-tmp.zip ../arter97-kernel-"$(cat ../version)"-"$(date +%F | sed s@-@@g)".zip
	rm arter97-kernel-"$(cat ../version)"-tmp.zip
	cd ..
	ls -al arter97-kernel-"$(cat version)"-"$(date +%F | sed s@-@@g)".zip
	rm kernelzip/boot.img
fi

if [ -e recovery.img ] ; then
	rm arter97-recovery-"$(cat version)"-twrp_"$(cat version_recovery | awk '{print $1}')".zip 2>/dev/null
	cp recovery.img recoveryzip/
	cd recoveryzip/
	7z a -mx9 arter97-recovery-"$(cat ../version)"-twrp_"$(cat ../version_recovery | awk '{print $1}')"-tmp.zip *
	zipalign -v 4 arter97-recovery-"$(cat ../version)"-twrp_"$(cat ../version_recovery | awk '{print $1}')"-tmp.zip ../arter97-recovery-"$(cat ../version)"-twrp_"$(cat ../version_recovery | awk '{print $1}')".zip
	rm arter97-recovery-"$(cat ../version)"-twrp_"$(cat ../version_recovery | awk '{print $1}')"-tmp.zip
	cd ..
	ls -al arter97-recovery-"$(cat version)"-twrp_"$(cat version_recovery | awk '{print $1}')".zip
	rm recoveryzip/recovery.img
fi
