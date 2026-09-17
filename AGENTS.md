# AGENTS.md - Development Guide

## Project Overview

`modebos` (Python) composes Debian images from reusable "mods". It resolves mod dependencies, generates a debos "shim" recipe, and runs `debos` to produce artifacts into `./artifacts/` by default. Each mod lives in `mods/<name>/` and is identified by the **directory name**.

## Documentation Layout

- `README.md` — user docs for `modebos`: CLI usage/options, build artifacts, verification loop, reproducible builds.
- `mods/README.md` — user docs about **mods**: how a build works (rootfs always built, targets, what mods contribute), `include`/`breaks`, artifact naming, and the mod catalog.
- `.agents/skills/modebos-mods/SKILL.md` — contributor guide for **creating/updating mods**: scaffolding, recipe files, wiring, verification, and debos/recipe internals.
- This file — contributor notes on the *tool* itself (CLI, git/versioning, pre-commit, environment). What the readmes or the mods skill cover is not repeated here.

## Running the Builder

Usage, options, and examples live in `README.md`. Dev-only gotchas:

- `--dry-run` still writes shims to `artifacts/` and prints them with `-v`; a real build additionally keeps `.yaml` logs.
- Without `CAP_SYS_ADMIN` (containers, CI), mmdebstrap fails at the rootfs stage; full builds require a privileged environment. See the README's verification section.

## Verification Loop

The commands are in `README.md` under "Verification Without a Privileged Host". Environment notes not in the README:

- `requirements.txt` is only `PyYAML`; the manual yamllint step also needs `pip install yamllint`.
- When validating a rendered shim with debos, only `rootfs` needs supplying via `-t` — it is not in the shim's `variables:` block.

## Git Info and Versioning

- `version` = last commit's date as `YYYYMMDD`; `commit` = short hash (from `git log -1 --format=%ct`).
- A dirty working tree changes `commit` to `wip` — expect `-<date>-wip` in artifact names; it also suppresses snapshot.debian.org mirroring (reproducibility is only guaranteed from a clean tree).
- `SOURCE_DATE_EPOCH` is derived from the git commit and exported for reproducibility. `mods/rootfs/scripts/clean-image.sh` clears machine-id/hostname, apt caches, and logs, then rewrites all mtimes to it.

## Pre-commit

`default_stages: [pre-commit]` applies to **all** hooks, so `mypy --strict --ignore-missing-imports` and bandit (`--recursive`, `.bandit.yaml`) run on every commit alongside the fast auto-fixers (black `--line-length=123`, ruff `--fix`, Go-template-aware yamllint, markdownlint `--fix`, shellcheck `--severity=style -e SC1090`, JSON/TOML/XML checks). No pre-push hook is installed by default.

Run them without committing:

```bash
pre-commit run --all-files                        # everything, incl. mypy + bandit
pre-commit run --hook-stage pre-push mypy bandit  # slow checks only
```

There is no unit-test suite — `tests/` is absent (hook exclusions for it are defensive leftovers). The dry-run loop in the README is the actual test surface. Expect no CI workflows (`.github/` is absent); pre-commit is the only automated gate.
