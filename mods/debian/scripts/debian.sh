#!/bin/bash
set -Eueo pipefail

echo "I: create user"
adduser --gecos debian --disabled-password debian

echo "I: set user password"
echo "debian:debian" | chpasswd
adduser debian sudo
