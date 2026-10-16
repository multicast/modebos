<!-- SPDX-FileCopyrightText: 2025 Matej Kovac <matej.kovac+modebos@gmail.com> -->
<!-- SPDX-License-Identifier: GPL-3.0-or-later -->

# rootfs

Root filesystem tarball target: cleans the image for reproducibility, generates manifest/env/dpkg-selections files next to the artifact, and packs the whole tree into `suite-rootfs-...-tar.gz`. Depends on [minbase](../minbase/README.md) and [debian](../debian/README.md).

APT sources inside the build are pinned to the snapshot.debian.org archive for the date in the repository-root `VERSION` file. Before packing, this target repoints the image at the rolling `deb.debian.org` mirror — unless the build was run with `--reproducible` on a clean tree, in which case the pinned source list is kept in the artifact.

The target also appends modebos provenance to `/etc/os-release`: `MODEBOS_NAME`, `MODEBOS_VERSION`, and — for reproducible builds — `MODEBOS_REPRODUCIBLE`. See the [reproducible builds](../../README.md#reproducible-builds) section of the top-level README.
