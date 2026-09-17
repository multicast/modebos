<!-- SPDX-FileCopyrightText: 2025 Matej Kovac <matej.kovac+modebos@gmail.com> -->
<!-- SPDX-License-Identifier: GPL-3.0-or-later -->

# minbase

Base layer for every image: installs a minimal Debian package set (`adduser`, `udev`, `less`, `locales`, `zstd`), refreshes the apt index, and generates the `en_US.UTF-8` locale. All other mods depend on it, directly or transitively.
