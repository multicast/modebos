#!/bin/bash
set -eu

MOUNT_POINT="/mnt/nine"

# Detect the 9p mount tag passed on the qemu command line
# (-virtfs local,...,mount_tag=<tag>); the kernel exposes it at
# /sys/bus/virtio/drivers/9pnet_virtio/virtio<n>/mount_tag
MOUNT_TAG="${MOUNT_TAG:-}"
if [ -z "$MOUNT_TAG" ]; then
    for tag_file in /sys/bus/virtio/drivers/9pnet_virtio/virtio*/mount_tag; do
        [ -r "$tag_file" ] || continue
        MOUNT_TAG="$(cat "$tag_file")"
        [ -n "$MOUNT_TAG" ] && break
    done
fi
MOUNT_TAG="${MOUNT_TAG:-nine}"

mkdir -p "$MOUNT_POINT"

# Idempotent mount: do nothing when the 9p filesystem is already mounted.
# cache=none so boot.sh edits on the host are visible without remounting.
if ! findmnt -t 9p "$MOUNT_POINT" >/dev/null 2>&1; then
    mount -t 9p -o trans=virtio,cache=none "$MOUNT_TAG" "$MOUNT_POINT"
fi

boot_script="$MOUNT_POINT/boot.sh"
if [ -x "$boot_script" ]; then
    "$boot_script"
elif [ -f "$boot_script" ]; then
    bash "$boot_script"
fi
