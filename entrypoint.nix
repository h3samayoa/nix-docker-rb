{ pkgs }:

pkgs.writeScriptBin "entrypoint.sh" ''
  #!/bin/sh
  set -e

  if [ -z "$1" ] then
    echo "Usage $0 <ssh-public-key>"
    exit 1
  fi

  mkdir -p /root/.ssh
  echo "$1": > /root/.ssh/authorized_keys
  chmod 600 /root/.ssh/authorized_keys

  exec /root/.nix-profile/bin/sshd -De
''