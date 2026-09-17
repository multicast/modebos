<!-- SPDX-FileCopyrightText: 2025 Matej Kovac <matej.kovac+modebos@gmail.com> -->
<!-- SPDX-License-Identifier: GPL-3.0-or-later -->

# qemunet

Static network configuration for QEMU user-mode networking: overlays config that fixes the guest to the standard 10.0.2.15 address so networking works out of the box in `qemu-system` with SLIRP. Depends on [systemd](../systemd/README.md) and [kvm](../kvm/README.md).
