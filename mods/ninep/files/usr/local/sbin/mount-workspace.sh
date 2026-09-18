#!/bin/bash
set -eu

MOUNT_POINT="/workspace"
TAG="workspace"
found=0

for _ in {1..10}; do
    for tag_file in /sys/bus/virtio/drivers/9pnet_virtio/virtio*/mount_tag; do
        [ -r "$tag_file" ] || continue
        if [ "$(cat "$tag_file")" = "$TAG" ]; then
            found=1
            break 2
        fi
    done
    sleep 0.5
done

if [ "$found" -eq 0 ]; then
    echo "mount-workspace: no 9p 'workspace' share was passed to this VM — /workspace is not mounted." >&2
    echo "mount-workspace: to share a host dir, start the VM with: -virtfs local,path=<host-dir>,mount_tag=workspace,security_model=none" >&2
    exit 0
fi

mkdir -p "$MOUNT_POINT"
if ! findmnt -t 9p "$MOUNT_POINT" >/dev/null 2>&1; then
    mount -t 9p -o trans=virtio,cache=none,version=9p2000.L "$TAG" "$MOUNT_POINT"
fi
