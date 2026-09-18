#!/usr/bin/env bash
set -euo pipefail

if [ $# -lt 1 ]; then
    echo "Usage: $0 <qcow2-file> [mount-tag [shared-dir]]"
    echo "  If mount-tag is given, shared-dir (default: .) is shared into the VM via 9p."
    echo "  If mount-tag is omitted, no shared directory is mounted."
    echo "  Set VM_CPU (default: 2), VM_MEMORY in GB (default: 1), SSH_PORT (default: auto)."
    exit 1
fi

case "$1" in
    -h|--help)
        echo "Usage: $0 <qcow2-file> [mount-tag [shared-dir]]"
        echo "  If mount-tag is given, shared-dir (default: .) is shared into the VM via 9p."
        echo "  If mount-tag is omitted, no shared directory is mounted."
        echo "  Set VM_CPU (default: 2), VM_MEMORY in GB (default: 1), SSH_PORT (default: auto)."
        exit 0
        ;;
esac

BASE="$(realpath "$1")"
TAG="${2:-}"
SHARE="${3:-}"

if [ ! -f "$BASE" ]; then
    echo "Error: file not found: $BASE"
    exit 1
fi

SNAP="$(mktemp "${BASE%.qcow2}-snap.XXXXXX.qcow2")"
SNAP_ESC="${SNAP//,/,,}"
TMPDIR_shared=""

cleanup() {
    if [ -f "$SNAP" ]; then
        rm -f "$SNAP"
        echo "Removed snapshot: $SNAP"
    fi
    if [ -n "$TMPDIR_shared" ] && [ -d "$TMPDIR_shared" ]; then
        rmdir "$TMPDIR_shared" 2>/dev/null && echo "Removed temp dir: $TMPDIR_shared"
    fi
}
trap cleanup EXIT

VIRTFS=()
if [ -n "$TAG" ]; then
    if [ -z "$SHARE" ]; then
        SHARE="."
    fi
    SHARE="$(realpath "$SHARE")"
    SHARE_ESC="${SHARE//,/,,}"
    VIRTFS=(-virtfs "local,path=$SHARE_ESC,mount_tag=$TAG,security_model=none")
else
    TMPDIR_shared="$(mktemp -d /tmp/qemu-share.XXXXXX)"
    VIRTFS=(-virtfs "local,path=$TMPDIR_shared,mount_tag=scratch,security_model=none")
fi

VM_CPU="${VM_CPU:-2}"
VM_MEMORY="${VM_MEMORY:-1}"
SSH_PORT="${SSH_PORT:-$(python3 -c "import socket; s=socket.socket(); s.bind(('',0)); print(s.getsockname()[1])" 2>/dev/null || echo 2222)}"

echo "Creating snapshot: $SNAP"
qemu-img create -f qcow2 -b "$BASE" -F qcow2 "$SNAP"

echo "Starting VM..."
echo "SSH: ssh -p $SSH_PORT debian@localhost"
qemu-system-x86_64 -accel kvm -cpu host -smp "$VM_CPU" -m "${VM_MEMORY}G" \
    -bios /usr/share/qemu/OVMF.fd \
    -netdev user,id=net0,hostfwd=tcp::"${SSH_PORT}"-:22 -device virtio-net-pci,netdev=net0 \
    -serial stdio \
    "${VIRTFS[@]}" \
    -drive format=qcow2,file="$SNAP_ESC"

echo "VM exited."
