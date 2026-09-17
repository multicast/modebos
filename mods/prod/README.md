<!-- SPDX-FileCopyrightText: 2025 Matej Kovac <matej.kovac+modebos@gmail.com> -->
<!-- SPDX-License-Identifier: GPL-3.0-or-later -->

# prod

Production-build marker. It carries no recipe files and sets `label: false`, so it never appears in artifact filenames; it exists only to conflict with the dev-only mods [qemunet](../qemunet/README.md) and [lab](../lab/README.md), aborting any build that mixes a production output with lab tooling.
