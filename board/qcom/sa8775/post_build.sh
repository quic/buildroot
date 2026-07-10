#!/bin/bash

TARGETDIR=$1

# /dev/vda is now the root filesystem itself (mounted directly by the kernel
# via root=/dev/vda in board/qcom/sa8775/linux.fragment), so it must NOT also
# be listed here as a separate /mnt/persist mount -- that would double-mount
# the root device. Persistence comes for free: the whole root lives on the
# writable virtio-blk disk.
cat <<EOF >> "${TARGETDIR}/etc/fstab"
devpts   /dev/pts              devpts  gid=5,mode=620  0 0
debugfs  /sys/kernel/debug      debugfs  defaults  0 2
EOF

# Configure eth0 for QEMU user-mode networking (10.0.2.0/24, gateway 10.0.2.2).
cat <<EOF > "${TARGETDIR}/etc/network/interfaces"
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
EOF

# Dropbear's own install already creates /etc/dropbear as a symlink to
# /var/run/dropbear (populated at boot from tmpfs), so nothing to do here.
