#!/usr/bin/env bash
set -euo pipefail
if [[ ${EUID} -ne 0 ]]; then echo "Bitte sudo ./reset.sh verwenden" >&2; exit 1; fi
cd "$(dirname "$0")"
echo "ACHTUNG: Compose-Cluster, Rancher und ihre persistenten Docker-Volumes werden gelöscht."
echo "Auch die generierte Kubeconfig und der K3s-Token werden gelöscht."
read -r -p "Zum Fortfahren RESET eingeben: " confirmation
[[ "$confirmation" == RESET ]] || { echo "Abgebrochen."; exit 0; }
if [[ -f .env ]]; then
  docker compose down -v --remove-orphans
else
  echo "Keine Compose-.env vorhanden; Compose-Reset übersprungen."
fi
rm -f generated/kubeconfig.yaml .env
echo "Compose-Reset abgeschlossen. Der SSH-Schlüssel bleibt für Ansible erhalten."
