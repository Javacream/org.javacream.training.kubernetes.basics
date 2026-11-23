#!/usr/bin/env bash
# Runs as root from setup.sh; installs tools and cluster add-ons during initial provisioning.
set -euo pipefail
cd "$(dirname "$0")"
: "${TRAINING_USER:?}"
: "${TRAINING_HOME:?}"
export KUBECONFIG="$PWD/generated/kubeconfig.yaml"
HELM_VERSION="${HELM_VERSION:-v3.17.3}"
TRIVY_VERSION="${TRIVY_VERSION:-v0.76.2}"
GATEWAY_API_VERSION="${GATEWAY_API_VERSION:-v1.3.0}"
KPS_CHART_VERSION="${KPS_CHART_VERSION:-69.8.2}"

install_helm() {
  if command -v helm >/dev/null && helm version --short | grep -Fq "$HELM_VERSION"; then return; fi
  local arch tmp
  arch="$(dpkg --print-architecture)"
  case "$arch" in amd64|arm64) ;; *) echo "Unsupported architecture: $arch" >&2; exit 1;; esac
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' RETURN
  curl -fsSL --retry 3 "https://get.helm.sh/helm-${HELM_VERSION}-linux-${arch}.tar.gz" -o "$tmp/helm.tgz"
  tar -xzf "$tmp/helm.tgz" -C "$tmp"
  install -m 0755 "$tmp/linux-${arch}/helm" /usr/local/bin/helm
}

install_trivy() {
  if command -v trivy >/dev/null && trivy --version | grep -Fq "${TRIVY_VERSION#v}"; then return; fi
  local arch tmp
  arch="$(dpkg --print-architecture)"
  case "$arch" in amd64) arch=64bit;; arm64) arch=ARM64;; *) echo "Unsupported architecture" >&2; exit 1;; esac
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' RETURN
  curl -fsSL --retry 3 "https://github.com/aquasecurity/trivy/releases/download/${TRIVY_VERSION}/trivy_${TRIVY_VERSION#v}_Linux-${arch}.tar.gz" -o "$tmp/trivy.tgz"
  tar -xzf "$tmp/trivy.tgz" -C "$tmp" trivy
  install -m 0755 "$tmp/trivy" /usr/local/bin/trivy
}

install_helm
install_trivy
# Prepare vulnerability database for the normal training user during setup.
runuser -u "$TRAINING_USER" -- env HOME="$TRAINING_HOME" trivy image --download-db-only
echo "Installing Gateway API CRDs ${GATEWAY_API_VERSION} ..."
kubectl apply --server-side -f "https://github.com/kubernetes-sigs/gateway-api/releases/download/${GATEWAY_API_VERSION}/standard-install.yaml"
kubectl wait --for=condition=Established --timeout=180s crd/gatewayclasses.gateway.networking.k8s.io crd/gateways.gateway.networking.k8s.io crd/httproutes.gateway.networking.k8s.io
echo "Enabling the Kubernetes Gateway provider in bundled K3s Traefik ..."
kubectl apply -f addons/traefik-gateway-config.yaml
kubectl -n kube-system rollout status deployment/traefik --timeout=360s

echo "Installing monitoring through Helm ..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts --force-update
helm repo update prometheus-community
helm upgrade --install training-monitoring prometheus-community/kube-prometheus-stack \
  --version "$KPS_CHART_VERSION" --namespace monitoring --create-namespace \
  -f addons/monitoring-values.yaml --wait --timeout 12m
kubectl -n monitoring rollout status deployment/training-monitoring-grafana --timeout=300s
echo "Add-ons installed."
