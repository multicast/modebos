# Mod: ninep

Provides a systemd service that mounts `/workspace` from the host via 9p.

## How it works

A `mount-workspace.service` oneshot is installed and enabled. On boot it waits up to about five seconds for the virtio-9p device, then mounts the `workspace` tag at `/workspace`. If no share was passed, it logs a kind message and continues without mounting.

The host must expose the share. With libvirt, add a filesystem device to the domain XML with `mount_tag=workspace`.

## Mount tag

The tag is `workspace`, handled by `mount-workspace.service`. Override by editing the overlay.

## Dependencies

Requires the `kvm` target (virtio kernel modules).
