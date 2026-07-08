#!/bin/sh
#
# Minimal external-initrd init for the Hexagon QEMU "virt" board.
#
# The kernel no longer embeds the full buildroot rootfs (that used to bloat
# vmlinux and required a fragile relink dance -- see build-buildroot.sh).
# Instead the full rootfs lives on a *persistent* virtio-blk disk (/dev/vda,
# ext2) and this tiny initramfs does just enough to hand off to it:
#   1. mount the pseudo-filesystems it needs to find the disk,
#   2. wait for /dev/vda to appear,
#   3. mount it, and
#   4. switch_root into it and exec the real /sbin/init.
#
# switch_root (not pivot_root) is the correct primitive here: the initramfs
# root is a rootfs/tmpfs that pivot_root cannot operate on; switch_root frees
# the initramfs and moves the mount at /mnt to / in one step.
#
# This script is assembled into initrd.cpio as /init; the kernel command line
# (board/qcom/sa8775/linux.fragment) selects it via rdinit=/init.

BB=/bin/busybox

# devtmpfs is NOT auto-mounted for an initramfs (CONFIG_DEVTMPFS_MOUNT only
# applies to the real root), so mount it ourselves to get /dev/vda.
$BB mount -t proc     proc /proc 2>/dev/null
$BB mount -t sysfs    sys  /sys  2>/dev/null
$BB mount -t devtmpfs dev  /dev  2>/dev/null

echo "[initrd] waiting for virtio-blk root device /dev/vda ..."
i=0
while [ ! -b /dev/vda ] && [ "$i" -lt 30 ]; do
	$BB sleep 1
	i=$((i + 1))
done

if [ ! -b /dev/vda ]; then
	echo "[initrd] ERROR: /dev/vda never appeared; dropping to a shell" >&2
	exec $BB sh
fi

if ! $BB mount -t ext2 -o rw /dev/vda /mnt; then
	echo "[initrd] ERROR: failed to mount /dev/vda (ext2) on /mnt; dropping to a shell" >&2
	exec $BB sh
fi

if [ ! -x /mnt/sbin/init ]; then
	echo "[initrd] ERROR: /mnt/sbin/init missing on the persistent root; dropping to a shell" >&2
	exec $BB sh
fi

echo "[initrd] switching root to /dev/vda"
exec $BB switch_root /mnt /sbin/init
