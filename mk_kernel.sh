#!/bin/bash

set -e

EXEC_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

while getopts b:r: flag
do
    case "${flag}" in
        b) BRANCH=${OPTARG};;
    esac
done

if [ -z "$BRANCH" ]; 
then
    echo ">>> PLEASE SET BRANCH NAME OF KERNEL VERSION WITH -b flag"
    echo ">>> Ex: ./mk_kernel -b 4.14"
    echo
    echo ">>> ENTER req ARGUMENT IN ORDER TO INSTALL REQUIREMENTS"
    echo ">>> Ex: ./mk_kernel req"
    echo
    echo ">>> ENTER show_req ARGUMENT IN ORDER TO SHOW REQUIREMENTS"
    echo ">>> Ex: ./mk_kernel show_req"
    exit 1
fi

if [ "$1" == "show_req" ]; 
then $EXEC_DIR/
$EXEC_DIR/
    echo ">>>>>>>>>>>>>>>>>>>>>> INSTALLING REQUIREMENTS"
    echo "sudo apt install crossbuild-essential-arm64 \
    bison \
    flex  
    device-tree-compiler \
    pkg-config \
    ncurses-dev \
    libssl-dev -y"
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
    libssl-dev -y
    exit 1
fi

git clone --depth 1 --branch rpi-${BRANCH}.y https://github.com/raspberrypi/linux.git ${BRANCH}_kernel

sudo make -C $EXEC_DIR/${BRANCH}_kernel ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- O=$EXEC_DIR/${BRANCH}_bo bcmrpi3_defconfig
sudo make -C $EXEC_DIR/${BRANCH}_kernel ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- O=$EXEC_DIR/${BRANCH}_bo -j4
