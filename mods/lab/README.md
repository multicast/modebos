<!-- SPDX-FileCopyrightText: 2025 Matej Kovac <matej.kovac+modebos@gmail.com> -->
<!-- SPDX-License-Identifier: GPL-3.0-or-later -->

# lab

Interactive lab environment: installs dev/ops tooling (`aptitude`, `bash-completion`, `curl`), ships a `9p-boot` service that auto-detects the 9p mount tag and mounts it at `/mnt/nine`, then runs `boot.sh` if present. Depends on [kvm](../kvm/README.md); conflicts with [prod](../prod/README.md).
