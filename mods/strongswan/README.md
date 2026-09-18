# Mod: strongswan

A dedicated VM running a StrongSwan IPsec client.

## What it provides

- StrongSwan and IPsec packages (strongswan, strongswan-pki, charon, extra plugins)
- IP forwarding enabled and persisted via `/etc/sysctl.d/99-ipsec.conf`

## Dependencies

Requires `kvm` → `cloud` → `server` → `systemd` → `minbase`.

## Usage

Build the image:

```bash
./modebos strongswan
```

## IPsec configuration

This mod installs the software only. Continue with your IPsec configuration (`swanctl.conf`, certificates, private keys)

Then reload with `swanctl --load-all` and bring up the connection with `swanctl --initiate --child my-conn`.
