#!/bin/bash -ex

RPIUSER=${USER}
HOSTNAME=${RPIUSER}-pi

USE_NETWORK_MANAGER=yes

WIFINETWORK=wifiname
WIFIPASSWORD=wifipassword


WRKDIR=$(pwd)/
NPROC=$(nproc)
if [ ! -n "${KERNEL}" ]; then
    export KERNEL=kernel8
fi


# Clone sources
if [ ! -d firmware ]; then
    git clone --depth 1 https://github.com/raspberrypi/firmware.git
fi

if [ ! -d linux ]; then
    git clone --depth 1 --branch rpi-4.14.y https://github.com/raspberrypi/linux.git
fi

# Download Ubuntu Base file system (https://wiki.ubuntu.com/Base)
ROOTFSURL=http://cdimage.ubuntu.com/ubuntu-base/releases/20.04.4/release/
if [ "${KERNEL}" == "kernel8" ]; then
    ROOTFS=ubuntu-base-20.04.4-base-arm64.tar.gz
else
    ROOTFS=ubuntu-base-20.04.4-base-armhf.tar.gz
fi
if [ ! -s ${ROOTFS} ]; then
    curl -OLf ${ROOTFSURL}${ROOTFS} #also with wget if prefered
fi


if [ "${KERNEL}" == "kernel8" ]; then
    # Build 64-bit Raspberry Pi 3 kernel
    if [ ! -s ${WRKDIR}linux/arch/arm64/boot/Image ]; then
        cd ${WRKDIR}linux
        make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- bcmrpi3_defconfig
        # Uncomment the following line if you wish to change the kernel configuration
        #make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- menuconfig
        echo "Building kernel. This takes a while. To monitor progress, open a new terminal and use \"tail -f buildoutput.log\""
        make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- -j ${NPROC} > ${WRKDIR}buildoutput.log 2> ${WRKDIR}buildoutput2.log
        cd ${WRKDIR}
    fi
else
    # Build 32-bit Raspberry Pi 2 kernel
    if [ ! -s ${WRKDIR}linux/arch/arm/boot/zImage ]; then
        cd ${WRKDIR}linux
        make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- bcm2709_defconfig
        # Uncomment the following line if you wish to change the kernel configuration
        #make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- menuconfig
        echo "Building kernel. This takes a while. To monitor progress, open a new terminal and use \"tail -f buildoutput.log\"" make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- zImage modules dtbs -j ${NPROC} > ${WRKDIR}buildoutput.log 2> ${WRKDIR}buildoutput2.log
        cd ${WRKDIR}
    fi
fi

######### INIT VARIABLES ########
MNTRAMDISK=/mnt/ramdisk/
MNTROOTFS=/mnt/rpi-arm64-rootfs/
MNTBOOT=${MNTROOTFS}boot/
IMGFILE=${MNTRAMDISK}rpi64.img

LOOPDEVS=$(sudo kpartx -avs ${IMGFILE} | awk '{print $3}')
LOOPDEVBOOT=/dev/mapper/$(echo ${LOOPDEVS} | awk '{print $1}')
LOOPDEVROOTFS=/dev/mapper/$(echo ${LOOPDEVS} | awk '{print $2}')
######### FINISH VARIABLES ########

cd ${WRKDIR}
sudo sync
sudo umount ${MNTROOTFS}proc || true
sudo umount ${MNTROOTFS}dev/pts || true
sudo umount ${MNTROOTFS}dev || true
sudo umount ${MNTROOTFS}sys || true
sudo umount ${MNTROOTFS}tmp || true
sudo umount ${MNTBOOT} || true
sudo umount ${MNTROOTFS} || true
sudo kpartx -dvs ${IMGFILE} || true
sudo rmdir ${MNTROOTFS} || true
mv ${IMGFILE} . || true
sudo umount ${MNTRAMDISK} || true
sudo rmdir ${MNTRAMDISK} || true