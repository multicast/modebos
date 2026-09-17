---
name: modebos-mods
description: How to create or update a modebos mod. Use when adding a new mod under mods/, editing an existing mod (meta.yaml, in-rootfs.yaml, in-target.yaml, target.yaml, files/), wiring include/breaks dependencies, or naming artifacts.
---

# Creating and Updating modebos Mods

A mod is a directory under `mods/<name>/` that contributes recipe steps to a
debos build. Each mod's content belongs to a build **stage**. User-facing
concepts (build flow, naming, `include`/`breaks`) live in `mods/README.md`;
shim internals live in `references/recipe-mechanics.md` and load only when you
debug a rendered shim or edit modebos's shim generator.

## Workflow

### 1. Pick the stage

Rootfs is always built first; every other target unpacks that same rootfs
artifact. Your mod participates at one or both stages:

- `in-rootfs.yaml` — runs while the rootfs is built (package installs,
  `chroot: true` steps). Baked in for every target.
- `in-target.yaml` — runs after the rootfs is unpacked into a target image
  (overlays, per-image tweaks). Non-rootfs targets only.
- `target.yaml` — targets only; the main debos template for the image format.

Done when every file you plan to ship has a stage: both (`systemd`), one, or
neither (`prod` is a pure marker).

### 2. Scaffold `mods/<name>/meta.yaml`

```yaml
description: "One line describing what the mod provides"
type: mod            # or "target" for rootfs/kvm/oci-style output formats
include: [dep1, dep2]  # resolved recursively, dependencies first
breaks: [conflict]     # mutual exclusion; any conflict aborts the build
label: true           # optional; false keeps the mod out of artifact filenames
```

Name rules:

- No `-` in the name — artifact/shim filenames are dash-joined, so a dash
  breaks parsing (`qemu-net` became `qemunet`).
- `label: false` for marker mods that must not appear in filenames.

Done when the mod dir holds a `meta.yaml` matching the schema and the name has
no dash. The strict yamllint check is in step 5.

### 3. Add the recipe files

Base a new recipe on the existing mods, not memory: `minbase/in-rootfs.yaml`
(package + chroot steps), `cloud/in-target.yaml` (overlay), and
`lab/in-target.yaml` (apt + overlay + chroot) are good references.

```yaml
# in-rootfs.yaml
architecture: amd64
actions:
  - action: apt
    packages:
      - example-package
  - action: run
    chroot: true
    command: systemctl enable example.service
```

```yaml
# in-target.yaml — files/ is the overlay source, relative to the mod dir
architecture: amd64
actions:
  - action: overlay
    source: files
```

For overlays, drop content into `mods/<name>/files/`, keeping the exact target
paths under it (`files/etc/example.conf` lands at `/etc/example.conf`). A
target mod additionally ships `target.yaml` as its main debos template and may
itself have `in-*.yaml` steps.

Done when each recipe file is written and passes the strict yamllint check in
step 5.

### 4. Wire dependencies

- `include` anything required to function. Resolution is recursive,
  dependencies first, and **not stage-specific** — depending on a mod pulls in
  all of its recipe files at every stage it participates in.
- `include` may name a target as platform gating (`qemunet` includes `kvm`).
- `breaks` aborts the build if both sides end up in the resolved set, even
  transitively. Declare on one side (or both, like `lab`/`prod`).
- A mod's `include` of a target does NOT add the target to the built set — it
  is built only when named on the command line or depended on by a built mod.

Done when a dry run resolves in the intended order with no conflict:

```bash
python3 modebos --dry-run -v <your-mod> <target>
```

### 5. Verify without a privileged host

Full builds need `CAP_SYS_ADMIN` (mmdebstrap) and fail at the rootfs stage in
containers. Validate without one. `requirements.txt` is only `PyYAML`; the
manual yamllint step also needs `pip install yamllint`.

```bash
python3 scripts/yamllint_check.py --strict -c .yamllint.yaml mods/<name>/<recipe>.yaml
python3 modebos --dry-run -v <your-mod> <target>   # render shims, print filenames
debos --dry-run -v -t rootfs:test.tar.gz artifacts/<shim-from-dry-run>.yaml
```

When validating a rendered shim with debos, supply only `rootfs` via `-t` — it
is not in the shim's `variables:` block.

Check the dry-run output for: the "Minimal[target]" label your mod gets (that
is what lands in artifact names), a sane resolution order, and the
`-t mods:` / `-t rootfs:` variables on the debos command line.

Done when the dry run prints the expected `Minimal[target]` label and debos
dry-validates the shim without error.

## Updating an existing mod

- Re-run the dry run with the mod's dependents (`gactions`, `server`, ...) to
  confirm resolution order and names still hold.
- A `label: false` change or a new `breaks` entry shows up as an artifact-name
  change or a build abort — deliberate.

## Recipe mechanics

Debugging a rendered shim or editing modebos's shim generator? Read
`references/recipe-mechanics.md` for Go-template variables, shim structure,
generator internals, and `-t` variables.
