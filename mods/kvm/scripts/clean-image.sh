#!/bin/bash

set -e

# Do not remove the files, just clear their contents
rm -f /etc/machine-id /etc/hostname /var/lib/dbus/machine-id
touch /etc/machine-id /etc/hostname
