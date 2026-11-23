#!/usr/bin/env bash
# Destructive only within namespace training-validation. Intended to run as the training user.
set -euo pipefail
cd "$(dirname "$0")"
export KUBECONFIG="${KUBECONFIG:-$PWD/generated/kubeconfig.yaml}"
NS=training-validation
cleanup() { kubectl delete namespace "$NS" --ignore-not-found --wait=false >/dev/null 2>&1 || true; }
trap cleanup EXIT
pass() { printf 'PASS: %s\n' "$1"; }
check() { command -v "$1" >/dev/null || { echo "MISSING: $1" >&2; exit 1; }; }
for bin in kubectl docker podman ansible helm trivy curl; do check "$bin"; done
pass "Host tools"
kubectl wait --for=condition=Ready nodes --all --timeout=240s
[[ "$(kubectl get nodes --no-headers | wc -l)" -eq 3 ]] || { echo "Expected 3 nodes" >&2; exit 1; }
pass "Three Ready nodes"
ansible kubernetes -m ping | tee /tmp/training-ansible-ping.log
[[ "$(grep -c 'SUCCESS' /tmp/training-ansible-ping.log)" -eq 3 ]] || exit 1
pass "Ansible SSH"
helm -n monitoring status training-monitoring >/dev/null
kubectl -n monitoring rollout status deployment/training-monitoring-grafana --timeout=300s
kubectl -n monitoring get prometheus --no-headers | grep -q .
pass "Monitoring Helm release"
kubectl get crd gateways.gateway.networking.k8s.io >/dev/null
kubectl get gatewayclass >/dev/null 2>&1 || true
pass "Gateway API installed"
kubectl create namespace "$NS"
kubectl -n "$NS" create deployment web --image=nginx:stable --port=80
kubectl -n "$NS" rollout status deployment/web --timeout=240s
kubectl -n "$NS" expose deployment web --port=80 --target-port=80
kubectl -n "$NS" run curl --image=curlimages/curl:8.12.1 --restart=Never --command -- sleep 900
kubectl -n "$NS" wait --for=condition=Ready pod/curl --timeout=240s
kubectl -n "$NS" exec curl -- curl -fsS --max-time 15 http://web >/dev/null
pass "Deployment, DNS, ClusterIP"

kubectl -n "$NS" expose deployment web --name=web-nodeport --type=NodePort --port=80 --target-port=80
NODE_PORT="$(kubectl -n "$NS" get svc web-nodeport -o jsonpath='{.spec.ports[0].nodePort}')"
NODE_IP="$(kubectl get node k3s-server -o jsonpath='{.status.addresses[?(@.type=="InternalIP")].address}')"
kubectl -n "$NS" exec curl -- curl -fsS --max-time 15 "http://$NODE_IP:$NODE_PORT" >/dev/null
pass "NodePort from inside cluster"
[[ "$(kubectl -n kube-system get svc traefik -o jsonpath='{.spec.type}')" == LoadBalancer ]]
pass "K3s ServiceLB configured"
kubectl -n "$NS" apply -f - <<'POLICY'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-web
spec:
  podSelector:
    matchLabels:
      app: web
  policyTypes: [Ingress]
POLICY
sleep 8
if kubectl -n "$NS" exec curl -- curl -fsS --max-time 5 http://web >/dev/null 2>&1; then
  echo "FAIL: NetworkPolicy deny did not block traffic" >&2
  exit 1
fi
kubectl -n "$NS" delete networkpolicy deny-web
kubectl -n "$NS" exec curl -- curl -fsS --retry 6 --retry-delay 2 --max-time 10 http://web >/dev/null
pass "NetworkPolicy enforcement"

kubectl -n "$NS" apply -f - <<'YAML'
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: demo-data
spec:
  accessModes: [ReadWriteOnce]
  resources:
    requests:
      storage: 128Mi
---
apiVersion: v1
kind: Pod
metadata:
  name: volume-test
spec:
  containers:
  - name: writer
    image: busybox:1.36
    command: [sh, -c, "echo persistent >/data/probe; sleep 900"]
    volumeMounts:
    - name: data
      mountPath: /data
  volumes:
  - name: data
    persistentVolumeClaim:
      claimName: demo-data
YAML
kubectl -n "$NS" wait --for=condition=Ready pod/volume-test --timeout=240s
kubectl -n "$NS" exec volume-test -- cat /data/probe | grep -qx persistent
pass "PersistentVolumeClaim"
kubectl -n "$NS" create serviceaccount viewer
kubectl -n "$NS" create role pod-reader --verb=get,list --resource=pods
kubectl -n "$NS" create rolebinding viewer-binding --role=pod-reader --serviceaccount="$NS":viewer
kubectl auth can-i list pods --as="system:serviceaccount:$NS:viewer" -n "$NS" | grep -qx yes
kubectl auth can-i delete pods --as="system:serviceaccount:$NS:viewer" -n "$NS" | grep -qx no
pass "RBAC"
kubectl apply -f addons/gateway-smoke.yaml
kubectl -n "$NS" wait --for=jsonpath='{.status.conditions[?(@.type=="Accepted")].status}'=True gateway/training-gateway --timeout=180s
kubectl -n "$NS" wait --for=jsonpath='{.status.parents[0].conditions[?(@.type=="Accepted")].status}'=True httproute/training-route --timeout=180s
kubectl -n "$NS" exec curl -- curl -fsS --retry 8 --retry-delay 3 --max-time 10 -H "Host: training.test" http://traefik.kube-system.svc.cluster.local/ >/dev/null
pass "Gateway API controller accepts and serves HTTPRoute"
echo "PASS: automated integration smoke tests"
