# Hostinfo – Load-Balancing-Demonstration

Das Image `javacream/hostinfo:1.0-lb` basiert auf NGINX. Beim Containerstart erzeugt `hostinfo.sh` eine HTML-Seite mit Hostname, Betriebssystem, Distribution, Kernel und Architektur. Der Hostname entspricht in Kubernetes standardmäßig dem Pod-Namen.

## Server-Verhalten

Für die Demonstration werden zwei Optimierungen bewusst deaktiviert:

- `keepalive_timeout 0;`: NGINX schließt die HTTP/1.x-Verbindung nach der Antwort. Neue TCP-Verbindungen können vom Kubernetes-Service anderen Pods zugeordnet werden.
- `add_header Cache-Control "no-store" always;`: Antworten sollen nicht im Browser-Cache gespeichert werden. Bereits gespeicherte Antworten gegebenenfalls einmal mit Shift + Reload umgehen.

Ein Kubernetes-TCP-Service verteilt Verbindungen, nicht einzelne HTTP-Requests. Ein Wechsel des Pods bei jedem Reload ist nicht garantiert. Die Einstellungen sind für die Schulung gedacht, nicht als allgemeine Produktionskonfiguration.

## Build und Veröffentlichung

```bash
docker compose build
docker compose push
```

Lokaler Test: `docker compose up -d`, anschließend http://localhost:9090 öffnen. Mit `curl -I http://localhost:9090` lassen sich die Antwortheader prüfen.
