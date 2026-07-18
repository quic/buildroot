#!/bin/bash

# Buildroot's linux.mk only installs one kernel image format to
# BINARIES_DIR (selected via the BR2_LINUX_KERNEL_* choice, here
# vmlinux.bin for qemu). The unstripped ELF vmlinux is still produced
# by the kernel build but never copied out; grab it too since it's
# needed for symbolicated debugging (gdb, addr2line) against the same
# build that produced vmlinux.bin.

set -e

IMAGES_DIR="$1"
BUILD_DIR="$(dirname "${IMAGES_DIR}")/build"

# Stale build directories from earlier BR2_LINUX_KERNEL_CUSTOM_REPO_VERSION
# values (e.g. linux-hexagon-qemu-boot-14-july-2026) can linger alongside the
# current one, so picking the alphabetically-first 'linux-*' match is not
# reliable -- pick the one whose vmlinux was built most recently instead.
LINUX_DIR=$(find "${BUILD_DIR}" -maxdepth 1 -name 'linux-*' -type d -exec test -f '{}/vmlinux' ';' -printf '%T@ %p\n' | sort -rn | head -n1 | cut -d' ' -f2-)

if [[ -n "${LINUX_DIR}" && -f "${LINUX_DIR}/vmlinux" ]]; then
	cp -a "${LINUX_DIR}/vmlinux" "${IMAGES_DIR}/vmlinux"
fi
