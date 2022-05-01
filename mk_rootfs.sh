#!/bin/bash
set -e
EXEC_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
export ARCH=arm64

while getopts d:v:k: flag
do
    case "${flag}" in
        d) DISTRO=${OPTARG};;
        v) VERSION=${OPTARG};;
        k) KERNEL=${OPTARG};;
    esac
done

if [ $DISTRO == "ubuntu" ];
then
    wget https://cdimage.ubuntu.com/ubuntu-base/releases/$VERSION/release/ubuntu-base-$VERSION-base-$ARCH.tar.gz
    mkdir -p rootfs/$VERSION
    # Install kernel modules on the rootfs already built
    sudo tar xzvf ubuntu-base-$VERSION-base-arm64.tar.gz -C $EXEC_DIR/rootfs/$VERSION
    sudo make -C $EXEC_DIR/${KERNEL}_kernel ARCH=$ARCH CROSS_COMPILE=aarch64-linux-gnu- O=$EXEC_DIR/${KERNEL}_bo/ modules_install INSTALL_MOD_PATH=$EXEC_DIR/rootfs/$VERSION

    # Remove unnecessary files from building and installation
    sudo find $EXEC_DIR/rootfs/$VERSION -name build | xargs sudo rm -rf
    sudo find $EXEC_DIR/rootfs/$VERSION -name source | xargs sudo rm -rf

    # Add qemu in order to correct chroot rootfs already created
    sudo cp -av /usr/bin/qemu-aarch64-static $EXEC_DIR/rootfs/$VERSION/usr/bin
    sudo cp -av /run/systemd/resolve/stub-resolv.conf $EXEC_DIR/rootfs/$VERSION/etc/resolv.conf

    sudo echo "/dev/mmcblk0p2	/	ext4	defaults,noatime	0	1" >> $EXEC_DIR/rootfs/$VERSION/etc/fstab
fi

