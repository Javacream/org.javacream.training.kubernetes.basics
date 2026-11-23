#!/usr/bin/env bash
set -euo pipefail

if [[ ${EUID} -eq 0 ]]; then
  echo "Bitte als normaler Ubuntu-Benutzer ausführen." >&2
  exit 1
fi

# Das Skript wird bewusst getrennt von setup.sh ausgeführt,
# nachdem Ranchers Ersteinrichtung im Browser abgeschlossen wurde.
cd "$(dirname "$0")"
. ./host-ip.sh
if [[ -z "${HOST_IP:-}" && -f .env ]]; then
  HOST_IP="$(sed -n 's/^HOST_IP=//p' .env | head -n 1)"
fi
detect_host_ip
export RANCHER_URL="${RANCHER_URL:-https://${HOST_IP}:8443}"
export RANCHER_USER="${RANCHER_USER:-admin}"
export RANCHER_PASSWORD="${RANCHER_PASSWORD:-javacream}"
export CLUSTER_NAME="${CLUSTER_NAME:-training-thales}"

python3 - <<'PY'
import os
import subprocess
import sys
import time
from urllib.parse import urljoin, urlparse

import requests
import urllib3

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

base = os.environ["RANCHER_URL"].rstrip("/")
name = os.environ["CLUSTER_NAME"]
session = requests.Session()
session.verify = False  # Selbstsigniertes Rancher-Zertifikat (nur Trainingsumgebung)
session.trust_env = False

def api(method, path, **kwargs):
    response = session.request(method, urljoin(base + "/", path.lstrip("/")),
                               timeout=30, **kwargs)
    if not response.ok:
        raise RuntimeError(f"Rancher API {method} {path}: HTTP {response.status_code}: "
                           f"{response.text[:350]}")
    return response.json()

try:
    print(f"Rancher-Anmeldung: {base}")
    login = api("POST", "/v3-public/localProviders/local?action=login",
                json={"username": os.environ["RANCHER_USER"],
                      "password": os.environ["RANCHER_PASSWORD"]})
    token = login["token"]
    session.headers.update({"Authorization": f"Bearer {token}"})

    clusters = api("GET", "/v3/clusters").get("data", [])
    matches = [cluster for cluster in clusters if cluster.get("name") == name]
    if len(matches) > 1:
        raise RuntimeError(f"Mehrere Rancher-Cluster mit Namen {name} gefunden.")
    if matches:
        cluster_id = matches[0]["id"]
        print(f"Vorhandenen Rancher-Cluster verwenden: {name} ({cluster_id})")
    else:
        cluster = api("POST", "/v3/clusters",
                      json={"type": "cluster", "name": name, "import": True})
        cluster_id = cluster["id"]
        print(f"Rancher-Cluster angelegt: {name} ({cluster_id})")

    manifest_url = None
    for attempt in range(36):
        registrations = api("GET", "/v3/clusterregistrationtokens",
                            params={"clusterId": cluster_id}).get("data", [])
        if not registrations:
            if attempt == 0:
                print("Warte auf Ranchers Cluster-Namespace und Registrierungstoken ...")
            response = session.post(
                urljoin(base + "/", "v3/clusterregistrationtokens"),
                json={"type": "clusterRegistrationToken", "clusterId": cluster_id},
                timeout=30)
            if response.status_code == 404 and "namespaces" in response.text and "not found" in response.text:
                pass  # Rancher erstellt den Namespace asynchron
            elif not response.ok:
                raise RuntimeError(
                    "Registrierungstoken konnte nicht erstellt werden: "
                    + str(response.status_code) + " " + response.text[:250])
        manifest_url = next((item.get("manifestUrl") for item in registrations
                             if item.get("manifestUrl")), None)
        if manifest_url:
            break
        time.sleep(10)
    if not manifest_url:
        raise RuntimeError("Rancher hat innerhalb von sechs Minuten keine Manifest-URL bereitgestellt.")

    manifest_url = urljoin(base + "/", manifest_url)
    # Token-URL niemals ausgeben; sie ermöglicht die Registrierung am Cluster.
    if urlparse(manifest_url).netloc != urlparse(base).netloc:
        raise RuntimeError("Die Manifest-URL verweist auf einen anderen Host/Port. "
                           "Bitte die Rancher Server URL kontrollieren.")

    manifest = None
    for attempt in range(36):
        response = session.get(manifest_url, timeout=30)
        if response.ok and "apiVersion:" in response.text:
            manifest = response.text
            break
        if attempt == 0:
            print("Auf fertiges Registrierungsmanifest warten ...")
        time.sleep(10)
    if not manifest:
        raise RuntimeError("Registrierungsmanifest nach sechs Minuten nicht abrufbar. "
                           "Rancher-Ersteinrichtung und Server-URL prüfen.")

    print("Registrierungsmanifest auf K3s anwenden ...")
    subprocess.run(["kubectl", "apply", "-f", "-"],
                   input=manifest, text=True, check=True)
    print("Auf Rancher-Agent warten ...")
    subprocess.run(["kubectl", "-n", "cattle-system",
                    "rollout", "status", "deployment/cattle-cluster-agent",
                    "--timeout=300s"], check=True)
    print(f"Cluster {name} registriert. Status 'Active' ggf. nach kurzer Wartezeit in Rancher prüfen.")
except (requests.RequestException, RuntimeError, KeyError,
        subprocess.CalledProcessError) as exc:
    print(f"FEHLER: {exc}", file=sys.stderr)
    sys.exit(1)
PY
