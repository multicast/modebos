<!-- SPDX-FileCopyrightText: 2025 Matej Kovac <matej.kovac+modebos@gmail.com> -->
<!-- SPDX-License-Identifier: GPL-3.0-or-later -->

# Mods

Every configuration is a mod in its own directory under `mods/<name>/`. The mod name is the directory name, and other mods reference it by that name in `include`/`breaks`. Mod names must NOT contain `-`, because they appear in dash-joined artifact filenames. Any mod whose `meta.yaml` sets `type: target` is an image target built by `modebos`.

## How a build works

Two kinds of mods exist: **targets** produce image artifacts, and everything else contributes configuration to the image those targets produce. You name the mods you want on the command line; modebos resolves them, builds a rootfs once, then produces one artifact per target:

```bash
python3 modebos qemunet kvm        # one rootfs tarball + one KVM image
python3 modebos server oci         # one rootfs tarball + one OCI container image
```

### `rootfs` is always built

`rootfs` is a special target and the foundation of every build: modebos automatically appends it to the command line, even when you don't name it (`modebos kvm` behaves as if you'd typed `modebos kvm rootfs`). Its `target.yaml` runs `mmdebstrap` to create a clean Debian base tarball from the configured suite/arch.

Every other target — `kvm`, `oci`, or any future one — does **not** bootstrap a filesystem itself. Its shim starts by `unpack`-ing the rootfs artifact, whose name it gets via the `{{ .rootfs }}` template variable (supplied with `-t rootfs:...`), then layers the target's own recipe on top. So:

- `rootfs` is built **first**, always, exactly once per invocation.
- every other target consumes that same rootfs tarball as its base layer.
- the rootfs target name is hard-coded — it cannot be renamed or removed.

List targets and mods with:

```bash
python3 modebos --list-mods       # -m
python3 modebos --list-targets    # -t
```

### Targets (what gets produced)

| Target | Artifact |
|--------|----------|
| [rootfs](rootfs/README.md) | Bootstraps the base Debian tarball every other target unpacks. Built first, always. |
| [kvm](kvm/README.md) | KVM/QEMU platform image (disk image + kernel) |
| [oci](oci/README.md) | OCI container image (importable into e.g. `podman`) |

## Mods (what ends up inside the image)

Non-target mods are the actual content: packages, systemd units, scripts, files. Their recipes determine what is present in the final image. A mod participates at one or more stages of the build, depending on which recipe files it ships in its directory:

- `in-rootfs.yaml` — applied while the rootfs is still being constructed (package installs, `chroot: true` steps). Content here is baked into the rootfs tarball and therefore inherited by *every* target.
- `in-target.yaml` — applied after the rootfs is unpacked into a target image (overlays, per-image tweaks). Runs only for non-rootfs targets.
- both — a mod can provide **both** files and so have an effect at both stages. For example [systemd](systemd/README.md) configures systemd in-rootfs and ships additional units at target time.

A mod with neither file (e.g. [prod](prod/README.md)) is a pure marker: it exists to express dependencies/conflicts and influence artifact naming, not image content.

### Dependencies: `include`

`include:` lists the mods this one needs. Dependencies are resolved recursively (depth-first), **dependencies first**, so `minbase` always appears before the mods that build on it. Depending on another mod pulls in *all* of its recipe files at every stage it participates in — `include` is not stage-specific.

An `include` may name a target (e.g. `qemunet` includes `kvm`), which is how a mod can require its configuration only make sense on images of that platform. Circular dependencies abort the build.

### Conflicts: `breaks`

`breaks:` lists mods that must not coexist in one build. If any mod (directly or transitively) is present along with something it breaks, the build **aborts with a conflict error**. Examples:

- `prod` breaks `qemunet` and `lab` — marking a build as production-ready is incompatible with the lab/QEMU-networking conveniences.
- `lab` breaks `prod` (symmetric).

`breaks` is checked against the entire resolved set — you can trigger it by naming either side of the pair.

## Artifact naming

Every artifact (and its debos shim) is named

```text
<suite>-<target>-<mods>-<version>-<commit>.yaml
```

e.g. `trixie-kvm-qemunet-20260917-e51bb5d.yaml` for `modebos qemunet kvm`.

- `suite`, `version`, `commit` — Debian suite, build date `YYYYMMDD`, and short git hash (`wip` while the tree is dirty).
- `target` — the target mod producing the artifact (`rootfs`, `kvm`, `oci`).
- `mods` — **not** the raw command line. modebos computes, per target, the minimal set of mods you actually asked for: the resolved dependency chain, minus anything that is pulled in as a (transitive) dependency of something else you named, plus the current target. This is the "Minimal[x]" line in the build output.
  - targets are never part of the mods label (the target already has its own slot).
  - mods with `label: false` (like `prod`) are excluded, so they act as markers that don't appear in filenames.
  - when the label is empty, the `mods` section is omitted entirely (`trixie-rootfs-20260917-e51bb5d.tar.gz`).
  - multiple mods are comma-joined, and the dash-split parts are `suite`, `target`, `mods`, `version`, `commit` — hence no `-` may appear inside a mod name.

With `modebos --dry-run -v ...` you can inspect the exact filenames, the rendered shim, and the `-t mods:` and `-t rootfs:` variables before committing to a real build.

## Mod reference

| Mod | Type | Description | Links |
|-----|------|-------------|-------|
| [minbase](minbase/README.md) | mod | Base layer; depended on by everything | |
| [systemd](systemd/README.md) | mod | Systemd components and configuration | includes [minbase](minbase/README.md) |
| [server](server/README.md) | mod | Server packages (systemd, ssh, networking) | includes [systemd](systemd/README.md) |
| [cloud](cloud/README.md) | mod | Cloud guest tools (cloud-init, qemu-guest-agent) | includes [server](server/README.md) |
| [gactions](gactions/README.md) | mod | GitHub Actions runner tools | includes [systemd](systemd/README.md), [cloud](cloud/README.md), [kvm](kvm/README.md) |
| [qemunet](qemunet/README.md) | mod | Static network config for QEMU user-mode networking | includes [systemd](systemd/README.md), [kvm](kvm/README.md) |
| [lab](lab/README.md) | mod | Lab environment (9p mount detection, boot.sh) | includes [kvm](kvm/README.md); breaks [prod](prod/README.md) |
| [prod](prod/README.md) | mod | Production-build marker (`label: false`) | breaks [qemunet](qemunet/README.md), [lab](lab/README.md) |
| [rootfs](rootfs/README.md) | target | Root filesystem tarball target | includes [minbase](minbase/README.md) |
| [kvm](kvm/README.md) | target | KVM/QEMU platform image target | includes [cloud](cloud/README.md) |
| [oci](oci/README.md) | target | OCI container image target | includes [minbase](minbase/README.md) |
