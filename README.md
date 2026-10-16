<!-- SPDX-FileCopyrightText: 2025 Matej Kovac <matej.kovac+modebos@gmail.com> -->
<!-- SPDX-License-Identifier: GPL-3.0-or-later -->

# MoDebOs

Modular Debian OS Builder - `modebos` - is a Python-based tool that generates [debos](https://github.com/go-debos/debos) recipes on-the-fly to build Debian images. It uses a modular approach where different configurations are encapsulated in "mods" that can be composed together to create custom images.

`modebos` orchestrates the build process by:

- Resolving mod dependencies
- Generating debos shim files
- Building target image artifacts by executing `debos`

## Usage

```sh
./modebos [mods...] [targets...]
```

Positional arguments are mod names that must match `mods/*` directory names exactly. Any mod whose `meta.yaml` sets `type: target` is built as an image target; the `rootfs` target is always built first. Comma-separated mod names are NOT accepted - pass each mod separately.

### Options

- `-m, --list-mods` — list available mods and exit (note: this is NOT a mods flag)
- `-t, --list-targets` — list target mods and exit
- `-n, --dry-run` — resolve mods and generate shims without running debos
- `--reproducible` — keep the VERSION-dated snapshot.debian.org source list in the resulting image (requires a clean working tree; without it the image is repointed at the rolling upstream deb.debian.org mirror)
- `-v, --verbose` — print generated shims and stream debos output
- `-o, --output DIR` — artifact output directory (default `./artifacts`)
- `-s, --suite NAME` — Debian suite (default `testing`)
- `-a, --arch NAME` — architecture (default `amd64`)
- `-p, --param TARGET:KEY=VALUE` — pass target-specific parameter (e.g., `-p kvm:partition_scheme=podman`)
- `-h, --help` — show usage

With no arguments, help is printed and the run aborts. Unknown mod names abort with the list of available mods.

### Examples

```sh
# List available mods
./modebos --list-mods

# Build rootfs with selected mods
./modebos minbase server rootfs

# Build KVM image (builds rootfs first)
./modebos minbase server cloud kvm

# Build KVM image with Podman partitioning scheme
./modebos minbase server cloud kvm -p kvm:partition_scheme=podman

# Build OCI container image
./modebos minbase server oci

# Dry-run: resolve deps + generate shims, no debos execution
./modebos --dry-run -v minbase server kvm
```

### How it works

`modebos` resolves all mod dependencies (aborting on circular dependencies and `breaks` conflicts), generates a self-contained debos "shim" recipe per target, and runs `debos` to produce the artifacts. The `rootfs` target is built first and every other target layers on top of that same rootfs.

Mod concepts, the dependency/conflict model, and artifact naming are documented in [`mods/README.md`](mods/README.md) — read it before composing your own mods.

## Build Artifacts

Generated files are placed in `./artifacts/` by default:

- Root filesystem tarballs (`*.tar.gz`), consumed by every other target as its base layer
- Target images, e.g. KVM `.raw`/`.img` files and OCI container archives (`*.tar.gz`)
- Shim YAML recipes, kept for debugging, plus a `.yaml.log` per build

`debos` runs with its scratch space backed by a sparse `12G` disk image under `artifacts/scratch/`, so builds are bounded by the artifact directory's filesystem rather than the fakemachine's RAM.

`artifacts/` is git-ignored. Filenames follow the scheme documented in [`mods/README.md`](mods/README.md#artifact-naming).

## Running an Image Locally

Building with the [`qemunet`](mods/qemunet/README.md) mod and the [`kvm`](mods/kvm/README.md) target produces a bootable qcow2 image configured for QEMU user-mode (SLIRP) networking. Run it with the `qemu.sh` helper in the repo root:

```sh
# Build a KVM image with QEMU user-mode networking (rootfs builds automatically)
./modebos qemunet kvm

# Boot the produced qcow2 (writes go to a temporary overlay, not the artifact)
./qemu.sh artifacts/modebos-<version>-qemunet-kvm[-<commit>].qcow2
```

`qemu.sh` starts `qemu-system-x86_64` with KVM, forwards guest SSH to a free host port, and removes the copy-on-write overlay on exit — the built image is never modified. It prints the SSH command to use, typically `ssh -p <port> debian@localhost`.

Optional arguments and environment:

- `./qemu.sh <qcow2> <mount-tag> [shared-dir]` — share a host directory into the guest over 9p, using `<shared-dir>` (default: the current directory) mounted under `<mount-tag>`. With no tag, an empty scratch share is mounted; the [`lab`](mods/lab/README.md) mod auto-mounts whatever tag it finds.
- `VM_CPU` (default `2`), `VM_MEMORY` in GB (default `1`), `SSH_PORT` (default: a free port).

Running requires host virtualization (KVM) and OVMF firmware at `/usr/share/qemu/OVMF.fd`.

## Modules

Mods are composable configurations that define targets and the content of the resulting images. The complete guide — how a build works, targets, `include`/`breaks` dependencies, and how artifacts get their names — plus the catalog of available mods, lives in [`mods/README.md`](mods/README.md).

## Verification Without a Privileged Host

`modebos` uses `mmdebstrap`, which needs root capabilities (`CAP_SYS_ADMIN`). In containers without them (or on CI), full builds fail at the rootfs stage. Recipes can be validated instead:

```sh
# Lint recipes (Go-template aware; plain yamllint chokes on {{ }})
python3 scripts/yamllint_check.py --strict -c .yamllint.yaml mods/oci/target.yaml

# Resolve mods + render shims
./modebos --dry-run -v minbase server kvm

# Validate one rendered shim with debos (use the filename printed above)
debos --dry-run -v -t rootfs:test.tar.gz artifacts/<shim-from-dry-run>.yaml
```

Full builds require a privileged environment, e.g. `docker run --cap-add=SYS_ADMIN`.

## Reproducible Builds

Version metadata comes from `VERSION`, a single ISO date (`YYYY-MM-DD`) at the repository root: `version` is that date as `YYYYMMDD`, and `commit` is the short git hash — or `wip` when the working tree is dirty. `SOURCE_DATE_EPOCH` is set to midnight UTC of the `VERSION` date and is used to make timestamps in the produced images reproducible.

Build-time APT sources are always pinned to the `snapshot.debian.org` archive for the `VERSION` date, written as an apt 2.7+ deb822 `.sources` file. By default the resulting image is then repointed at the rolling upstream `deb.debian.org` mirror, so it stays updatable; the build itself still packages against the pinned snapshot. Reproducibility therefore depends only on the `VERSION` date and the snapshot archive, not on the commit time.

Passing `--reproducible` keeps the snapshot-pinned source list in the resulting image as well. This requires a clean working tree: with a dirty tree a warning is printed on stderr and the flag is dropped — the image is built with rolling sources instead, so reproducibility is never silently claimed.

Every image also records its provenance in the standard `/etc/os-release` file, appended after the distribution's own fields:

```ini
MODEBOS_NAME="Modebos <PRETTY_NAME>"
MODEBOS_VERSION="<YYYY-MM-DD>"
MODEBOS_REPRODUCIBLE="<YYYYMMDD>T000000Z"
```

`<PRETTY_NAME>` is the base distribution's own `PRETTY_NAME` copied literally. `MODEBOS_VERSION` is the raw `VERSION` file content. `MODEBOS_REPRODUCIBLE` names the `snapshot.debian.org` timestamp the build was pinned to and is present only for reproducible builds; `MODEBOS_NAME` carries the `Reproducible` marker (`Modebos Reproducible <PRETTY_NAME>`) to match.

## Developer Notes

Developer-oriented guidance (mod layout, debos template quirks, pre-commit stages, verification loop) lives in `AGENTS.md`.
