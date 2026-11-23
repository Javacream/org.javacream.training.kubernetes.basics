#!/usr/bin/env bash
set -euo pipefail

if [[ ${EUID} -eq 0 ]]; then
  echo "Bitte als normaler Ubuntu-Benutzer ausführen." >&2
  exit 1
fi

cd "$(dirname "$0")"
. ./host-ip.sh
if [[ -z "${HOST_IP:-}" && -f .env ]]; then
  HOST_IP="$(sed -n 's/^HOST_IP=//p' .env | head -n 1)"
fi
detect_host_ip
KUBECTL=(kubectl)
NODE_PORT=30080

echo "NGINX-Deployment und NodePort-Service erstellen ..."
"${KUBECTL[@]}" apply -f - <<'YAML'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
        - name: nginx
          image: nginx:stable
          ports:
            - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: nginx
spec:
  type: NodePort
  selector:
    app: nginx
  ports:
    - port: 80
      targetPort: 80
      nodePort: 30080
YAML

echo "Auf das NGINX-Deployment warten ..."
"${KUBECTL[@]}" rollout status deployment/nginx --timeout=180s
"${KUBECTL[@]}" get deployment nginx
"${KUBECTL[@]}" get pods -l app=nginx -o wide
"${KUBECTL[@]}" get service nginx

echo "HTTP-Test: http://${HOST_IP}:${NODE_PORT}"
curl --fail --silent --show-error --retry 12 --retry-delay 5 --retry-connrefused \
  --max-time 10 -o /dev/null "http://${HOST_IP}:${NODE_PORT}/"
echo "NGINX ist über http://${HOST_IP}:${NODE_PORT}/ erreichbar."
