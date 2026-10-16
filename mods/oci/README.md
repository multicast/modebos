<!-- SPDX-FileCopyrightText: 2025 Matej Kovac <matej.kovac+modebos@gmail.com> -->
<!-- SPDX-License-Identifier: GPL-3.0-or-later -->

# oci

OCI container image target: takes the build rootfs and emits a reproducible OCI image archive (digest-verified blobs, `os-release` metadata, normalized timestamps/modes), shipped as `suite-oci-...-tar.gz`. Depends on [minbase](../minbase/README.md).

This target rewrites `/etc/os-release` and appends the same modebos provenance fields as [rootfs](../rootfs/README.md): `MODEBOS_NAME`, `MODEBOS_VERSION`, and — for reproducible builds — `MODEBOS_REPRODUCIBLE`.

## Loading the artifact into a container runtime

The artifact (e.g. `modebos-20260916-oci.tar.gz`) is an OCI image archive. Import it and run a container with a single command in one step:

```sh
podman load < modebos-20260916-oci.tar.gz
podman run --rm modebos-20260916-oci echo hello world
```

The image is tagged with the archive's basename (minus the extension); substitute the actual artifact name from your build.
