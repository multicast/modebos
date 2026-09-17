<!-- SPDX-FileCopyrightText: 2025 Matej Kovac <matej.kovac+modebos@gmail.com> -->
<!-- SPDX-License-Identifier: GPL-3.0-or-later -->

# rootfs

Root filesystem tarball target: creates the default user with its overlay home, cleans the image for reproducibility, generates manifest/env/dpkg-selections files next to the artifact, and packs the whole tree into `suite-rootfs-...-tar.gz`. Depends on [minbase](../minbase/README.md).
