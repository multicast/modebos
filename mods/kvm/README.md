<!-- SPDX-FileCopyrightText: 2025 Matej Kovac <matej.kovac+modebos@gmail.com> -->
<!-- SPDX-License-Identifier: GPL-3.0-or-later -->

# kvm

KVM/QEMU platform target: builds a GPT-partitioned disk image (btrfs root, separate ext4 `/var/log`, EFI boot), installs `grub-efi`/`linux-image-amd64` plus `qemu-guest-agent`, and produces both `.raw` and qcow2, compressed, outputs. Depends on [cloud](../cloud/README.md).

## Partition Schemes

The kvm mod supports selectable partitioning schemes via the `--param` CLI option.

### Default Scheme

Default partitioning (no argument required):

- GPT partition table
- `/` on btrfs `root` (1024MB–100%)
- `/var/log` on ext4 `varlog` (256MB–1024MB)
- `/boot/efi` on vfat `efi` (0%–256MB, boot flag)

```bash
python3 modebos minbase server cloud kvm
```

### Podman Scheme

Partitioning for Podman with dedicated `/var/lib/containers`:

- GPT partition table
- `/` on btrfs `root` (3072MB–100%)
- `/var/log` on ext4 `varlog` (256MB–1024MB)
- `/var/lib/containers` on btrfs `containers` (1024MB–3072MB)
- `/boot/efi` on vfat `efi` (0%–256MB, boot flag)

```bash
python3 modebos minbase server cloud kvm -p kvm:partition_scheme=podman
```

### Custom Schemes

Partition schemes are stored as complete debos recipes in `mods/kvm/partition-schemes/`. To add a new scheme:

1. Create a new YAML file: `mods/kvm/partition-schemes/<name>.yaml`
2. Include `architecture:` and `actions:` with an `image-partition` action
3. Use Go template variables: `{{ .suite }}`, `{{ .version }}`, `{{ .commit }}`, `{{ .architecture }}`
4. Select it with: `-p kvm:partition_scheme=<name>`
