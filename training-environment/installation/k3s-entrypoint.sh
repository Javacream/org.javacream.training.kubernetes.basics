#!/usr/bin/env bash
set -euo pipefail
install -d -m 0700 -o ansible -g ansible /home/ansible/.ssh
install -m 0600 -o ansible -g ansible /etc/training/ansible.pub /home/ansible/.ssh/authorized_keys
mkdir -p /run/sshd
ssh-keygen -A
/usr/sbin/sshd
exec /usr/local/bin/k3s "$@"
