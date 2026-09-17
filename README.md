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
- `-v, --verbose` — print generated shims and stream debos output
- `-o, --output DIR` — artifact output directory (default `./artifacts`)
- `-s, --suite NAME` — Debian suite (default `trixie`)
- `-a, --arch NAME` — architecture (default `amd64`)
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

`artifacts/` is git-ignored. Filenames follow the scheme documented in [`mods/README.md`](mods/README.md#artifact-naming).

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

Version metadata is derived from git: `version` is the last commit's date (`YYYYMMDD`), `commit` is the short hash - or `wip` when the working tree is dirty. `SOURCE_DATE_EPOCH` is exported and used to make timestamps in produced images reproducible.

When the working tree is clean, `modebos` pins the package mirror to a snapshot.debian.org archive for a reproducible package set.

## Developer Notes

Developer-oriented guidance (mod layout, debos template quirks, pre-commit stages, verification loop) lives in `AGENTS.md`.
