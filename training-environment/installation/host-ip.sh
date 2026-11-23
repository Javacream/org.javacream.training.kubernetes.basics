#!/usr/bin/env bash
# Wird von setup.sh und den Test-/Import-Skripten eingebunden.
detect_host_ip() {
  local candidate iface
  if [[ -n "${HOST_IP:-}" ]]; then
    candidate="$HOST_IP"
  else
    candidate="$(ip -4 route get 1.1.1.1 2>/dev/null | awk '{for (i=1;i<=NF;i++) if ($i=="src") {print $(i+1); exit}}')"
    if [[ -z "$candidate" ]]; then
      iface="$(ip -4 route show default | awk 'NR==1 {for (i=1;i<=NF;i++) if ($i=="dev") {print $(i+1); exit}}')"
      if [[ -n "$iface" ]]; then
        candidate="$(ip -4 -o addr show dev "$iface" scope global | awk 'NR==1 {split($4,a,"/");print a[1]}')"
      fi
    fi
  fi
  if ! python3 - "$candidate" <<'PY'
import ipaddress
import sys
try:
    ip = ipaddress.IPv4Address(sys.argv[1])
    assert not (ip.is_loopback or ip.is_link_local or ip.is_multicast or ip.is_unspecified)
except (ValueError, AssertionError):
    sys.exit(1)
PY
  then
    echo "FEHLER: Keine geeignete Host-IPv4 gefunden. Bitte HOST_IP explizit setzen." >&2
    return 1
  fi
  HOST_IP="$candidate"
  export HOST_IP
}
