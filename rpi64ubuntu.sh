#!/bin/bash -ex

# This script generates a 64-bit kernel and minimal 64-bit Ubuntu 18.04 rootfs for the Raspberry Pi 3 based on the Ubuntu Base release (https://wiki.ubuntu.com/Base).
# Requires a recent version of Ubuntu to run this build script.  8 GB RAM or more is recommended, and 5GB - 10GB free disk space.
# Optionally, a 32-bit kernel may be built for the Raspberry Pi 2 by exporting KERNEL=kernel7 before running the script.
# This script is a little bit like https://github.com/RPi-Distro/pi-gen but for Ubuntu instead of Raspbian.


# User name and host name may be customized in the following lines.
# Locale settings and user password are prompted for towards the end of the script.
# The script also copies your .profile and .bashrc to the image.
RPIUSER=${USER}
HOSTNAME=${RPIUSER}-pi


# When the script is finished, flash to SD card with (for example):
# $ umount /dev/sdX1
# $ umount /dev/sdX2
# $ sudo dd if=rpi64.img of=/dev/sdX bs=8M
# $ sync
# The rootfs partition is only 2GB, so you may wish to expand it after flashing with gparted or similar. In fact this is required before installing a desktop environment.


# How to install a desktop environment:
# $ sudo apt-get install xubuntu-desktop
# You could also try kubuntu-desktop at your own risk, but it's very slow
# Apparently the lubuntu-desktop package isn't provided by the Ubuntu 16.10+ repositories for aarch64.


# Specify here if you'd like to use NetworkManager to configure network interfaces.
# It is recommended to set this to yes for two reasons:
#     1. Ethernet and wifi will work out of the box without any extra hoops to jump through.
#     2. If you plan to install a desktop environment then you'll be able to configure the network from the GUI.
# Use nmcli to connect to a wifi network from the terminal:
# $ nmcli device wifi rescan
# $ nmcli device wifi list
# $ nmcli device wifi connect MyWifiName password MyWifiPassword
# Replace MyWifiName and MyWifiPassword with your wifi network credentials.
# However, if you still prefer to use /etc/network/interfaces to configure your networking, then comment out this line.
USE_NETWORK_MANAGER=yes

# If you decide to use /etc/network/interfaces, then getting ethernet to work requires editing the interface name in /etc/network/interfaces (not applicable if USE_NETWORK_MANAGER=yes) since the MAC address is encoded in the interface name.
# A script is provided in the home directory to automatically correct the interface name.
# $ ./fixeth.sh
# $ sudo reboot

# If you decide to use /etc/network/interfaces, then you may optionally pre-configure wireless network credentials here (not applicable if USE_NETWORK_MANAGER=yes).
# Comment this out if you don't want to pre-configure wifi credentials.
WIFINETWORK=wifiname
WIFIPASSWORD=wifipassword


# Known issue: audio doesn't work.

# Known issue: after a desktop environment is installed, and the cups-filters package is installed, it will fail to load some kernel modules (lp, ppdev, parport_pc).
# https://www.raspberrypi.org/forums/viewtopic.php?f=28&t=143806
# To squelch the failed to find modules warning, do this in a terminal: 
# $ sudo rm /etc/modules-load.d/cups-filters.conf
# $ sudo touch /etc/modules-load.d/cups-filters.conf



WRKDIR=$(pwd)/
NPROC=$(nproc)
if [ ! -n "${KERNEL}" ]; then
    export KERNEL=kernel8
fi


# Install pre-requisites
sudo apt-get install qemu-utils kpartx git curl gcc-aarch64-linux-gnu g++-aarch64-linux-gnu pkg-config-aarch64-linux-gnu gcc-arm-linux-gnueabihf g++-arm-linux-gnueabihf pkg-config-arm-linux-gnueabihf qemu-user-static binfmt-support parted bc libncurses5-dev wpasupplicant


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
    curl -OLf ${ROOTFSURL}${ROOTFS}
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
        echo "Building kernel. This takes a while. To monitor progress, open a new terminal and use \"tail -f buildoutput.log\""
        make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- zImage modules dtbs -j ${NPROC} > ${WRKDIR}buildoutput.log 2> ${WRKDIR}buildoutput2.log
        cd ${WRKDIR}
    fi
fi


MNTRAMDISK=/mnt/ramdisk/
MNTROOTFS=/mnt/rpi-arm64-rootfs/
MNTBOOT=${MNTROOTFS}boot/
IMGFILE=${MNTRAMDISK}rpi64.img

finish () {
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
}

trap finish EXIT

sudo mkdir -p ${MNTRAMDISK}
sudo mount -t tmpfs -o size=3g tmpfs ${MNTRAMDISK}

qemu-img create ${IMGFILE} 2G
parted ${IMGFILE} --script -- mklabel msdos
parted ${IMGFILE} --script -- mkpart primary fat32 2048s 264191s
parted ${IMGFILE} --script -- mkpart primary ext4 264192s -1s

LOOPDEVS=$(sudo kpartx -avs ${IMGFILE} | awk '{print $3}')
LOOPDEVBOOT=/dev/mapper/$(echo ${LOOPDEVS} | awk '{print $1}')
LOOPDEVROOTFS=/dev/mapper/$(echo ${LOOPDEVS} | awk '{print $2}')

sudo mkfs.vfat ${LOOPDEVBOOT}
sudo mkfs.ext4 ${LOOPDEVROOTFS}

sudo fatlabel ${LOOPDEVBOOT} BOOT
sudo e2label ${LOOPDEVROOTFS} RpiUbuntu

sudo mkdir -p ${MNTROOTFS}
sudo mount ${LOOPDEVROOTFS} ${MNTROOTFS}

sudo tar -C ${MNTROOTFS} -xf ${ROOTFS}

sudo mount ${LOOPDEVBOOT} ${MNTBOOT}

sudo mount -o bind /proc ${MNTROOTFS}proc
sudo mount -o bind /dev ${MNTROOTFS}dev
sudo mount -o bind /dev/pts ${MNTROOTFS}dev/pts
sudo mount -o bind /sys ${MNTROOTFS}sys
sudo mount -o bind /tmp ${MNTROOTFS}tmp


if [ "${KERNEL}" == "kernel8" ]; then
    sudo cp `which qemu-aarch64-static` ${MNTROOTFS}usr/bin/
else
    sudo cp `which qemu-arm-static` ${MNTROOTFS}usr/bin/
fi


# Copy Raspberry Pi firmware files and config to boot partition
sudo cp ${WRKDIR}firmware/boot/bootcode.bin ${WRKDIR}firmware/boot/fixup*.dat ${WRKDIR}firmware/boot/start*.elf ${MNTBOOT}

cat > tmp-rpi64-script-generated-config.txt <<EOF
disable_overscan=1
#dtparam=audio=on
EOF
echo "kernel=${KERNEL}.img" >> tmp-rpi64-script-generated-config.txt
sudo cp tmp-rpi64-script-generated-config.txt ${MNTBOOT}config.txt
rm tmp-rpi64-script-generated-config.txt


# Copy kernel and DT to boot partition and install modules
# https://www.raspberrypi.org/documentation/linux/kernel/building.md
# https://devsidestory.com/build-a-64-bit-kernel-for-your-raspberry-pi-3/
if [ "${KERNEL}" == "kernel8" ]; then
    sudo cp ${WRKDIR}linux/arch/arm64/boot/Image ${MNTBOOT}${KERNEL}.img
    sudo cp ${WRKDIR}linux/arch/arm64/boot/dts/broadcom/bcm2710-rpi-3-b.dtb ${MNTBOOT}
    cd ${WRKDIR}linux
    sudo make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- INSTALL_MOD_PATH=${MNTROOTFS} modules_install > ${WRKDIR}modules_install.log
    cd ${WRKDIR}
else
    sudo ${WRKDIR}linux/scripts/mkknlimg ${WRKDIR}linux/arch/arm/boot/zImage ${MNTBOOT}${KERNEL}.img
    sudo cp ${WRKDIR}linux/arch/arm/boot/dts/*.dtb ${MNTBOOT}
    cd ${WRKDIR}linux
    sudo make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- INSTALL_MOD_PATH=${MNTROOTFS} modules_install > ${WRKDIR}modules_install.log
    cd ${WRKDIR}
fi


# Random useful command for finding out what package a file belongs to: $ dpkg-query -S /sbin/init


# /etc/resolv.conf is required for internet connectivity in chroot. It will get overwritten by dhcp, so don't get too attached to it.
sudo chroot ${MNTROOTFS} bash -c 'echo "nameserver 8.8.8.8" > /etc/resolv.conf'


sudo sed -i -e "s/# deb /deb /" ${MNTROOTFS}etc/apt/sources.list
sudo chroot ${MNTROOTFS} apt-get update
# Install the dialog package and others first to squelch some warnings
sudo chroot ${MNTROOTFS} apt-get -y install dialog apt-utils
sudo chroot ${MNTROOTFS} apt-get -y upgrade
# There are probably more packages in the following list than what is absolutely minimally necessary, but whatever you do don't get rid of systemd-sysv otherwise the system won't boot
sudo chroot ${MNTROOTFS} apt-get -y install systemd systemd-sysv sysvinit-utils sudo udev rsyslog kmod util-linux sed language-pack-en netbase dnsutils ifupdown isc-dhcp-client isc-dhcp-common less vim net-tools iproute2 iputils-ping libnss-mdns iw software-properties-common ethtool dmsetup hostname iptables logrotate lsb-base lsb-release plymouth psmisc tar tcpd usbutils wireless-regdb wireless-tools wpasupplicant wget ftp nano curl rsync build-essential telnet parted patch bash-completion linux-firmware
if [ "${USE_NETWORK_MANAGER}" == "yes" ]; then
    sudo chroot ${MNTROOTFS} apt-get -y install network-manager resolvconf
fi

# Must be run after linux-firmware is installed
cd ${MNTROOTFS}lib/firmware/brcm
sudo curl -OLf https://github.com/RPi-Distro/firmware-nonfree/raw/master/brcm/brcmfmac43430-sdio.txt
cd ${WRKDIR}

# Install packages requiring user input last
sudo chroot ${MNTROOTFS} apt-get -y install tzdata kbd

# /etc/hostname
echo ${HOSTNAME} > tmp-rpi64-script-generated-hostname
sudo cp tmp-rpi64-script-generated-hostname ${MNTROOTFS}etc/hostname
rm tmp-rpi64-script-generated-hostname

# /etc/hosts
cat > tmp-rpi64-script-generated-hosts <<EOF
127.0.0.1	localhost

# The following lines are desirable for IPv6 capable hosts
::1		ip6-localhost ip6-loopback
fe00::0		ip6-localnet
ff00::0		ip6-mcastprefix
ff02::1		ip6-allnodes
ff02::2		ip6-allrouters

EOF
echo -e "127.0.1.1\t${HOSTNAME}" >> tmp-rpi64-script-generated-hosts
sudo cp tmp-rpi64-script-generated-hosts ${MNTROOTFS}etc/hosts
rm tmp-rpi64-script-generated-hosts

# /etc/fstab
cat > tmp-rpi64-script-generated-fstab <<EOF
proc            /proc           proc    defaults          0       0
/dev/mmcblk0p1  /boot           vfat    defaults          0       2
/dev/mmcblk0p2  /               ext4    defaults,noatime  0       1
EOF
sudo cp tmp-rpi64-script-generated-fstab ${MNTROOTFS}etc/fstab
rm tmp-rpi64-script-generated-fstab

# User account setup
sudo chroot ${MNTROOTFS} useradd -s /bin/bash -G adm,sudo -m ${RPIUSER}
# Setting the password requires user input
sudo chroot ${MNTROOTFS} passwd ${RPIUSER}


if [ "${USE_NETWORK_MANAGER}" == "yes" ]; then
    # Workaround for https://bugs.launchpad.net/ubuntu/+source/network-manager/+bug/1638842
    sudo chroot ${MNTROOTFS} rm /usr/lib/NetworkManager/conf.d/10-globally-managed-devices.conf
    sudo chroot ${MNTROOTFS} touch /usr/lib/NetworkManager/conf.d/10-globally-managed-devices.conf
else # !USE_NETWORK_MANAGER

    # /etc/network/interfaces
    cat > tmp-rpi64-script-generated-interfaces <<EOF
# interfaces(5) file used by ifup(8) and ifdown(8)

# Please note that this file is written to be used with dhcpcd
# For static IP, consult /etc/dhcpcd.conf and 'man dhcpcd.conf'

# Include files from /etc/network/interfaces.d:
source-directory /etc/network/interfaces.d

auto lo
iface lo inet loopback

#auto eth0
#iface eth0 inet dhcp

# Replace enxMACADDR with your adapter name, found by "dmesg | grep smsc95xx | grep renamed"
auto enxMACADDR
iface enxMACADDR inet dhcp
# http://askubuntu.com/questions/826438/eth0-bridge-created-for-some-reason
# https://ubuntuforums.org/archive/index.php/t-2331364.html

allow-hotplug wlan0
auto wlan0
iface wlan0 inet dhcp
    wpa-conf /etc/wpa_supplicant/wpa_supplicant.conf

allow-hotplug wlan1
auto wlan1
iface wlan1 inet dhcp
    wpa-conf /etc/wpa_supplicant/wpa_supplicant.conf
EOF
    sudo mkdir -p ${MNTROOTFS}etc/network/
    sudo cp tmp-rpi64-script-generated-interfaces ${MNTROOTFS}etc/network/interfaces
    rm tmp-rpi64-script-generated-interfaces
    sudo chmod 0600 ${MNTROOTFS}etc/network/interfaces

    # Don't wait forever and a day for the network to come online
    if [ -s ${MNTROOTFS}lib/systemd/system/networking.service ]; then
        sudo sed -i -e "s/TimeoutStartSec=5min/TimeoutStartSec=5sec/" ${MNTROOTFS}lib/systemd/system/networking.service
    fi
    if [ -s ${MNTROOTFS}lib/systemd/system/ifup@.service ]; then
        sudo bash -c "echo \"TimeoutStopSec=5s\" >> ${MNTROOTFS}lib/systemd/system/ifup@.service"
    fi

    # /etc/wpa_supplicant/wpa_supplicant.conf
    # TODO: change country to united states
    cat > tmp-rpi64-script-generated-wpa_supplicant.conf <<EOF
country=GB
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1
EOF
    if [ -n "${WIFINETWORK}" ]; then
        wpa_passphrase ${WIFINETWORK} ${WIFIPASSWORD} >> tmp-rpi64-script-generated-wpa_supplicant.conf
    fi
    sudo mkdir -p ${MNTROOTFS}etc/wpa_supplicant/
    sudo cp tmp-rpi64-script-generated-wpa_supplicant.conf ${MNTROOTFS}etc/wpa_supplicant/wpa_supplicant.conf
    rm tmp-rpi64-script-generated-wpa_supplicant.conf
    sudo chmod 0600 ${MNTROOTFS}etc/wpa_supplicant/wpa_supplicant.conf

    # ~/fixeth.sh
    cat > tmp-rpi64-script-generated-fixeth.sh <<EOF
#!/bin/bash -ex
ADAPTERNAME=\$(dmesg | grep smsc95xx | grep renamed | awk '{print \$5}' | sed "s/://")
if [ -n "\${ADAPTERNAME}" ]; then
    sudo sed -i -e "s/enxMACADDR/\${ADAPTERNAME}/" /etc/network/interfaces
else
    echo "Error: interface name not found"
fi
EOF
    sudo cp tmp-rpi64-script-generated-fixeth.sh ${MNTROOTFS}home/${RPIUSER}/fixeth.sh
    rm tmp-rpi64-script-generated-fixeth.sh
    sudo chmod +x ${MNTROOTFS}home/${RPIUSER}/fixeth.sh

fi # !USE_NETWORK_MANAGER
