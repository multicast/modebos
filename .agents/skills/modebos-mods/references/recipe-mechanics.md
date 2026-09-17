# Recipe mechanics (shim internals)

On-demand reference for debugging a rendered shim or editing modebos's shim
generator. Not needed for the normal create-a-mod workflow in `SKILL.md`.

## Rendered shims

- Recipes are Go templates (`{{ ... }}`). `.suite`, `.architecture`,
  `.version`, `.commit`, `.mods`, `.rootfs` are seeded from `-t` flags plus the
  shim's `variables:` block.
- Rootfs shims embed an `mmdebstrap` action. Target shims start with `unpack`
  of the rootfs artifact, then include each resolved mod's `in-target.yaml`,
  then the target's own `target.yaml`.
- The resolved mod list is computed once and shared by all targets; each
  target's artifact label ("Minimal[target]") is the minimized non-target mod
  set the user named — the resolved chain minus anything pulled in only as a
  dependency, minus targets. The rootfs is built once and skipped if its
  `.tar.gz` already exists in the output dir.
- The debos command line carries `-t mods:<names>` and `-t rootfs:<artifact>`
  (rootfs not in the shim's `variables:` block); `--dry-run -v` prints both.

## Editing the shim generator

- Shims are assembled with Python f-strings in the write-shim functions near
  the top of the `modebos` script. Find them by grepping the file for
  `mmdebstrap`, `unpack`, and `-t` — locations drift.
- To emit a literal `{{ .suite }}` from inside an f-string, concatenate a
  brace-half string (e.g. `"{{\n"`) or Python collapses the braces.
- Generated recipe includes sit at 2-space indent inside the shim's `actions:`
  list.
