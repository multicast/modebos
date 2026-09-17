#!/bin/bash

set -e

# Do not remove the files, just clear their contents
rm -f /etc/machine-id /etc/hostname /var/lib/dbus/machine-id
touch /etc/machine-id /etc/hostname
chown -R debian:debian /home/debian

rm -f \
  /var/log/alternatives.log \
  /var/log/bootstrap.log \
  /var/log/dpkg.log

rm -rf /var/cache/apt/archives/* \
  /var/lib/apt/lists/* \
  /var/log/apt/*

install -d -o root -g root -m 0755 /var/log
install -d -o root -g root -m 0755 /var/log/apt

test -n "$SOURCE_DATE_EPOCH" || exit 0
export TZ=UTC
find / -xdev -exec touch -h -d "@$SOURCE_DATE_EPOCH" -- {} +
