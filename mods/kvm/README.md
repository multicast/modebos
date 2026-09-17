<!-- SPDX-FileCopyrightText: 2025 Matej Kovac <matej.kovac+modebos@gmail.com> -->
<!-- SPDX-License-Identifier: GPL-3.0-or-later -->

# kvm

KVM/QEMU platform target: builds a GPT-partitioned disk image (btrfs root, separate ext4 `/var/log`, EFI boot), installs `grub-efi`/`linux-image-amd64` plus `qemu-guest-agent`, and produces both `.raw` and qcow2, compressed, outputs. Depends on [cloud](../cloud/README.md).
