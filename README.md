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

### Dependency Resolution

When mods are specified, `modebos` resolves all dependencies recursively. It detects circular dependencies and `breaks` conflicts and stops the build if any are found.

Dependency resolution determines the minimal set of mods required to satisfy the command-line set; that minimal set is used as part of the artifact name.

### Shim Generation

For each target, a "shim" YAML file is generated that:

- Combines all resolved mods' recipes into a single debos file
- Sets template variables (suite, architecture, version)
- Includes an `mmdebstrap` action for the rootfs target or an `unpack` action for other targets

### Debos Execution

Each generated shim file is passed to debos to generate the artifact. The rootfs is built first; each additional target uses the given target mod plus the minimal mod set to produce uniquely named artifacts.

## Build Artifacts

Generated files are placed in `./artifacts/` by default:

- Root filesystem tarballs (`suite-rootfs-[mods]-[version]-[commit].tar.gz`)
- Target images, e.g. KVM `.raw`/`.img` files and OCI container archives (`suite-oci-[mods]-...-tar.gz`)
- Shim YAML files, kept for debugging, plus a `.yaml.log` per build

`artifacts/` is git-ignored.

## Modules (`mods/` directory)

Each configuration is a "mod" in its own directory under `mods/`. The mod name is the directory name and other mods reference it by that name in `include`/`breaks`. Mod names must NOT contain `-`, because they appear in dash-joined artifact filenames and a dash would break downstream parsing.

The complete catalog of mods (with per-mod descriptions) lives in [`mods/README.md`](mods/README.md). A mod consists of:

- [`meta.yaml`](../mods/minbase/meta.yaml) - metadata: `description`, `type` (`mod` or `target`), `include` (dependencies), `breaks` (mutual exclusion), `label` (whether the name appears in artifact filenames)
- `in-rootfs.yaml` - debos recipe applied during rootfs builds
- `in-target.yaml` - debos recipe applied during target builds (e.g. overlays)
- `target.yaml` - main debos template for target mods (kvm, oci, ...)
- `files/` - optional overlay content, mounted via `action: overlay` with `source: files`

### Feature modules

- Provide packages, configurations, or scripts regardless of the image format
- Current mods: `minbase`, `systemd`, `server`, `cloud`, `gactions`, `qemunet`, `lab`, `prod`
- Contribute to rootfs builds via `in-rootfs.yaml` and to target builds via `in-target.yaml`

### Target modules

- Define output formats (rootfs tarball, KVM image, OCI container image)
- Current mods: `rootfs`, `kvm`, `oci`
- Provide a `target.yaml` that serves as the main debos template; may also contribute `in-rootfs.yaml`/`in-target.yaml` steps

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
