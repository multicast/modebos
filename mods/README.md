<!-- SPDX-FileCopyrightText: 2025 Matej Kovac <matej.kovac+modebos@gmail.com> -->
<!-- SPDX-License-Identifier: GPL-3.0-or-later -->

# Mods

Every configuration is a mod in its own directory under `mods/<name>/`. The mod name is the directory name, and other mods reference it by that name in `include`/`breaks`. Mod names must NOT contain `-`, because they appear in dash-joined artifact filenames. Any mod whose `meta.yaml` sets `type: target` is an image target built by `modebos`.

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
