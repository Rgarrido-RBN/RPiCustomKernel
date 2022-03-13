#!/bin/bash

set -e

EXEC_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

while getopts b:r: flag
do
    case "${flag}" in
        b) BRANCH=${OPTARG};;
        r) SHOW_REQ=1;;
    esac
done

if [ "$1" == "help" ];
then
    echo ">>> PLEASE SET BRANCH NAME OF KERNEL VERSION WITH -b flag"
    echo ">>> Ex: ./mk_kernel -b 4.14.y"
    echo
    echo ">>> ENTER req ARGUMENT IN ORDER TO INSTALL REQUIREMENTS"
    echo ">>> Ex: ./mk_kernel req"
    echo
    echo ">>> ENTER show_req ARGUMENT IN ORDER TO SHOW REQUIREMENTS"
    echo ">>> Ex: ./mk_kernel show_req"
    exit 1
fi

if [ "$1" == "req" ]; 
then $EXEC_DIR/
$EXEC_DIR/
    echo ">>>>>>>>>>>>>>>>>>>>>> INSTALLING REQUIREMENTS"
    sudo apt install crossbuild-essential-arm64 \
    bison \
    flex  
    device-tree-compiler \
    pkg-config \
    ncurses-dev \
    libssl-dev \ 
    git -y \
    exit 1
fi

if [ -z "$BRANCH" ]; 
then 
    echo "PLEASE SET BRANCH NAME OF KERNEL VERSION WITH -b flag"
    echo "Ex: ./mk_kernel -b rpi-5.15.y"
    exit 1
fi

# Prerare directory where kernel will be built
read -p '>>> Set destination dir for kernel source code: ' KERNEL_SOURCES
read -p '>>> Now please set destination dir for kernel building files: ' DEST_DIR

git clone --depth 1 --branch $BRANCH https://github.com/raspberrypi/linux.git $KERNEL_SOURCES

sudo make -C $EXEC_DIR/$KERNEL_SOURCES ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- O=$EXEC_DIR/$DEST_DIR bcmrpi3_defconfig
sudo make -C $EXEC_DIR/$KERNEL_SOURCES ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- O=$EXEC_DIR/$DEST_DIR -j4
