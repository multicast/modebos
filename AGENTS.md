# AGENTS.md - Development Guide

## Project Overview

`modebos` (Python) composes Debian images from reusable "mods". It resolves mod dependencies, generates a debos "shim" recipe, and runs `debos` to produce artifacts into `./artifacts/` by default. Each mod lives in `mods/<name>/` and is identified by the **directory name**.

## Documentation Layout

- `README.md` — user docs for `modebos`: CLI usage/options, build artifacts, verification loop, reproducible builds.
- `mods/README.md` — user docs about **mods**: how a build works (rootfs always built, targets, what mods contribute), `include`/`breaks`, artifact naming, and the mod catalog.
- `.agents/skills/modebos-mods/SKILL.md` — contributor guide for **creating/updating mods**: scaffolding, recipe files, wiring, verification.
- This file — contributor notes on the *tool* itself (CLI, shim internals, git/versioning, pre-commit, environment). What the readmes or the mods skill cover is not repeated here.

## Running the Builder

Usage, options, and examples live in `README.md`. Dev-only gotchas:

- `--dry-run` still writes shims to `artifacts/` and prints them with `-v`; a real build additionally keeps `.yaml` logs.
- Without `CAP_SYS_ADMIN` (containers, CI), mmdebstrap fails at the rootfs stage; full builds require a privileged environment. See the README's verification section.

## Shim Recipes

- Shims are Go templates. `.suite`, `.architecture`, `.version`, `.commit`, `.mods` come from `-t` flags plus the shim's `variables:` block; `.rootfs` is supplied only via `-t`, and `.reproducible` only via `-t reproducible:true|false`.
- A rootfs shim embeds an `mmdebstrap` pinned to the VERSION snapshot mirror, then writes the deb822 `.sources` file and runs `apt-get update`. Target shims start by `unpack`-ing the rootfs artifact, then include each resolved mod's `in-target.yaml`, then the target's own `target.yaml`.
- Shims are assembled with Python f-strings in the write-shim functions of `modebos`. To emit a literal `{{ .suite }}` from an f-string, concatenate a brace-half string (e.g. `"{{\n"`). Generated recipe includes sit at 2-space indent inside `actions:`.
- A mod that adds its own apt source must use a deb822 `.sources` file and must not re-create `/etc/apt/sources.list`.

## Verification Loop

The commands are in `README.md` under "Verification Without a Privileged Host". Environment notes not in the README:

- `requirements.txt` is only `PyYAML`; the manual yamllint step also needs `pip install yamllint`.
- When validating a rendered shim with debos, only `rootfs` needs supplying via `-t` — it is not in the shim's `variables:` block.

## Version and Reproducibility

- `VERSION` (repo root, a single ISO date `YYYY-MM-DD`) is the strict source of truth: `version` = that date as `YYYYMMDD`, and the build-time APT mirror is pinned to `snapshot.debian.org/archive/debian/<YYYYMMDD>T000000Z/` (apt 2.7+ deb822 `.sources`) by a step in the rootfs shim. `commit` = short git hash, or `wip` when the tree is dirty.
- `mods/rootfs/target.yaml` repoints the resulting image at the rolling `deb.debian.org` mirror before packing, unless `--reproducible` is given (that recipe reads the `reproducible` debos variable, passed by `DebosRunner`).
- `--reproducible` requires a clean tree; on a dirty tree it is dropped with a warning. `SOURCE_DATE_EPOCH` = midnight UTC of the `VERSION` date — not the commit time. `mods/rootfs/scripts/clean-image.sh` clears machine-id/hostname, apt caches, and logs, then rewrites all mtimes to it.

## Pre-commit

`default_stages: [pre-commit]` applies to **all** hooks, so `mypy --strict --ignore-missing-imports` and bandit (`--recursive`, `.bandit.yaml`) run on every commit alongside the fast auto-fixers (black `--line-length=123`, ruff `--fix`, Go-template-aware yamllint, markdownlint `--fix`, shellcheck `--severity=style -e SC1090`, JSON/TOML/XML checks). No pre-push hook is installed by default.

Run them without committing:

```bash
pre-commit run --all-files                        # everything, incl. mypy + bandit
pre-commit run --hook-stage pre-push mypy bandit  # slow checks only
```

There is no unit-test suite — `tests/` is absent (hook exclusions for it are defensive leftovers). The dry-run loop in the README is the actual test surface. Expect no CI workflows (`.github/` is absent); pre-commit is the only automated gate.
