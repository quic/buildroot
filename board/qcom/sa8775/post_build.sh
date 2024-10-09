#!/bin/bash

TARGETDIR=$1

cat <<EOF >> "${TARGETDIR}/etc/fstab"
devpts   /dev/pts              devpts  gid=5,mode=620  0 0
/dev/vda /mnt/persist ext2 defaults 0 0
debugfs  /sys/kernel/debug      debugfs  defaults  0 2
EOF
