set -e
EXEC_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
VERSION=20.04.4
# sudo su
sudo echo "/dev/mmcblk0p2	/	ext4	defaults,noatime	0	1" >> $EXEC_DIR/rootfs/$VERSION/etc/fstab

# sudo mount -t proc proc $(pwd)/rootfs/proc/
# sudo mount -t sysfs sys $(pwd)/rootfs/sys/
# sudo mount -o bind /dev $(pwd)/rootfs/dev/
# sudo chroot $(pwd)/rootfs
