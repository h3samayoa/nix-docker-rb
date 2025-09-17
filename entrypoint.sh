#!/usr/bin/env bash
set -e

echo "$1" > /root/.ssh/authorized_keys

sshd=$(readlink -f $(which sshd))
exec $sshd -D -e