<!-- SPDX-FileCopyrightText: 2025 Matej Kovac <matej.kovac+modebos@gmail.com> -->
<!-- SPDX-License-Identifier: GPL-3.0-or-later -->

# debian

Creates the default `debian` user (`adduser --gecos debian --disabled-password`, password `debian`, member of `sudo`) and deploys its home overlay (`/home/debian/.ssh/authorized_keys`). Runs in-rootfs immediately after [minbase](../minbase/README.md), before any mod that drops files into the home directory, so `adduser` sees a clean home.
