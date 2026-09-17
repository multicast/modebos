<!-- SPDX-FileCopyrightText: 2025 Matej Kovac <matej.kovac+modebos@gmail.com> -->
<!-- SPDX-License-Identifier: GPL-3.0-or-later -->

# systemd

Systemd-based initial configuration: installs `systemd`, `resolved`, `timesyncd`, `udev` and the systemd NSS modules; creates `/run/systemd/network`, enables `systemd-networkd`/`systemd-resolved`, and runs a networking setup script on target builds.
