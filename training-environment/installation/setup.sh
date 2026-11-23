#!/usr/bin/env bash
set -euo pipefail
if [[ ${EUID} -ne 0 ]]; then echo "Bitte sudo ./setup.sh verwenden" >&2; exit 1; fi
cd "$(dirname "$0")"
. ./host-ip.sh
detect_host_ip
echo "Ermittelte Host-IP: ${HOST_IP}"

TRAINING_USER="${TRAINING_USER:-${SUDO_USER:-}}"
if [[ -z "$TRAINING_USER" || "$TRAINING_USER" == root ]] || ! id "$TRAINING_USER" >/dev/null 2>&1; then
  echo "FEHLER: Bitte als normaler Ubuntu-Benutzer mit sudo ./setup.sh starten (oder TRAINING_USER angeben)." >&2
  exit 1
fi
export TRAINING_USER HOST_IP
TRAINING_HOME="$(getent passwd "$TRAINING_USER" | cut -d: -f6)"
export TRAINING_HOME
echo "Trainingsbenutzer: ${TRAINING_USER} (${TRAINING_HOME})"

if command -v k3s >/dev/null 2>&1 && systemctl is-active --quiet k3s; then
  echo "FEHLER: Natives K3s läuft noch. Vor dem Compose-Setup alten Cluster bewusst entfernen." >&2
  exit 1
fi
apt-get update
apt-get install -y ansible python3-requests python3-cryptography
if ! ansible-galaxy collection list community.crypto 2>/dev/null | grep -Eq '^community[.]crypto[[:space:]]'; then
  ansible-galaxy collection install community.crypto
fi
if ! command -v docker >/dev/null 2>&1 || ! docker compose version >/dev/null 2>&1; then
  echo "FEHLER: Docker mit Compose-Plugin muss installiert sein." >&2
  exit 1
fi

# Vorhandenen SSH-Schlüssel der bisherigen Root-Installation übernehmen.
# Damit bleiben die bereits in den K3s-Nodes hinterlegten authorized_keys gültig.
install -d -m 0700 -o "$TRAINING_USER" -g "$(id -gn "$TRAINING_USER")" "$TRAINING_HOME/.ssh"
if [[ ! -e "$TRAINING_HOME/.ssh/k3s_training" && -f /root/.ssh/k3s_training ]]; then
  install -m 0600 -o "$TRAINING_USER" -g "$(id -gn "$TRAINING_USER")" /root/.ssh/k3s_training "$TRAINING_HOME/.ssh/k3s_training"
  if [[ -f /root/.ssh/k3s_training.pub ]]; then
    install -m 0644 -o "$TRAINING_USER" -g "$(id -gn "$TRAINING_USER")" /root/.ssh/k3s_training.pub "$TRAINING_HOME/.ssh/k3s_training.pub"
  fi
fi
ansible-playbook -i localhost, site.yml

# Add-ons gehören zum initialen Setup, nicht zu manuellen Nachinstallationen.
bash ./provision-addons.sh

# Test als regulärer Trainingsbenutzer: gleiche Berechtigungen wie im Seminar.
runuser -u "$TRAINING_USER" -- env HOME="$TRAINING_HOME" KUBECONFIG="$PWD/generated/kubeconfig.yaml" bash ./integration-test.sh
echo
echo "Rancher: https://${HOST_IP}:8443"
echo "Kubernetes: kubectl get nodes"
echo "Ansible: ansible kubernetes -m ping"
if ! id -nG "$TRAINING_USER" | tr ' ' '\n' | grep -qx docker; then
  echo "Hinweis: Docker-Gruppenzugehörigkeit prüfen."
fi
echo "Falls die Docker-Gruppe neu zugewiesen wurde: bitte neu anmelden (oder newgrp docker)."
