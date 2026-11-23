# Kubernetes-Trainingsumgebung

Trainingsumgebung für das Seminar **„Einführung in Kubernetes – Grundlagen“** auf einer Ubuntu-24.04-VM.

Docker Compose betreibt **Rancher** und einen **K3s-Cluster mit drei Nodes** (ein Server, zwei Agents). Die K3s-Nodes laufen als privilegierte Ubuntu-basierte Container. Ansible, Podman, kubectl, Helm und Trivy stehen auf dem Ubuntu-Host bereit. Im Cluster werden Gateway API mit Traefik sowie Prometheus und Grafana eingerichtet.

## Voraussetzungen

- Ubuntu 24.04 mit Docker und Docker-Compose-Plugin
- Internetzugriff während der Installation
- Richtwert: mindestens 4 vCPU, 12 GiB RAM, 35 GiB freier Speicher
- Ausführung durch einen regulären Ubuntu-Benutzer mit sudo-Berechtigung

## Dateien

| Datei / Verzeichnis | Aufgabe |
| --- | --- |
| `setup.sh` | Einstiegspunkt für Installation und initialen Integrationstest |
| `site.yml` | Ansible-Playbook zur Einrichtung des Hosts und zum Start des Clusters |
| `docker-compose.yml` | Rancher, K3s-Server, zwei K3s-Agents, Netzwerke und Volumes |
| `Dockerfile.k3s-ansible` | Container-Image der K3s-Nodes mit SSH, Python und Ansible-Benutzer |
| `k3s-entrypoint.sh` | Start von SSH und K3s innerhalb der Node-Container |
| `host-ip.sh` | Ermittlung der Host-IP |
| `inventory.ini` / `ansible.cfg` | Ansible-Zugriff auf die drei K3s-Nodes |
| `provision-addons.sh` | Installation von Helm, Trivy, Gateway API und Monitoring |
| `addons/` | Konfiguration von Traefik, Monitoring und Gateway-Testressourcen |
| `integration-test.sh` | Automatisierter technischer Funktionstest |
| `INTEGRATIONSTEST.md` | Abnahmeplan für alle zwölf Seminarblöcke |
| `import-cluster.sh` | Separater Import des K3s-Clusters in Rancher |
| `test-deployment.sh` | NGINX-Testdeployment mit NodePort 30080 |
| `reset.sh` | Löschen der Compose-Umgebung und ihrer Volumes |
| `.env` / `generated/` | Beim Setup erzeugte Konfiguration, Schlüsselmaterial und Kubeconfig; nicht versioniert |

## Installation

Die folgenden Befehle werden auf der Ubuntu-VM ausgeführt:

```bash
git pull
cd training-environment/installation
sudo ./setup.sh
```

Falls die Host-IP nicht automatisch ermittelt werden soll:

```bash
sudo HOST_IP=10.160.1.86 ./setup.sh
```

Das Setup richtet den K3s-Cluster, die Host-Werkzeuge und die Add-ons ein und startet anschließend den automatisierten Integrationstest. Der Rancher-Clusterimport erfolgt **nicht** automatisch.

Bei einem bereits laufenden nativen K3s-Dienst bricht das Setup ab. Die Migration einer älteren Installation muss vorher separat erfolgen.

## Cluster prüfen

Nach erfolgreichem Setup und gegebenenfalls erneuter Anmeldung:

```bash
kubectl get nodes -o wide
docker compose ps
ansible kubernetes -m ping
helm list -n monitoring
```

Der technische Integrationstest lässt sich erneut ausführen:

```bash
bash ./integration-test.sh
```

Die vollständige Prüfmatrix steht in [INTEGRATIONSTEST.md](INTEGRATIONSTEST.md).

## K3s in Rancher importieren

1. Rancher unter `https://<HOST-IP>:8443` öffnen.
2. Bei der Ersteinrichtung mit `admin` / `javacream` anmelden und die Rancher-Server-URL bestätigen.
3. Auf der Ubuntu-VM den Import starten:

```bash
./import-cluster.sh
```

Das Skript registriert den K3s-Cluster in Rancher unter dem Namen `training-thales`. Bei einer bestehenden Rancher-Installation kann das zuvor festgelegte Admin-Passwort gelten.

## NGINX-Funktionstest

```bash
./test-deployment.sh
```

Der Test erstellt ein NGINX-Deployment und einen NodePort-Service. Die Anwendung ist anschließend unter `http://<HOST-IP>:30080/` vorgesehen.

## Monitoring

Grafana über einen lokalen Port-Forward öffnen:

```bash
kubectl -n monitoring port-forward svc/training-monitoring-grafana 3000:80
```

Adresse: `http://localhost:3000` — Benutzer `admin`, initiales Passwort `training-grafana`.

## Ports

| Dienst | Host-Port |
| --- | --- |
| Rancher HTTP / HTTPS | 8080 / 8443 |
| Kubernetes API | 6443 |
| Traefik HTTP / HTTPS | 80 / 443 |
| NGINX-Test | 30080 |
| SSH K3s-Server | 127.0.0.1:2201 |
| SSH K3s-Agent 1 | 127.0.0.1:2202 |
| SSH K3s-Agent 2 | 127.0.0.1:2203 |

## Umgebung zurücksetzen

```bash
sudo ./reset.sh
```

Nach Bestätigung mit `RESET` werden die Compose-Container, ihre persistenten Volumes, die `.env` und die generierte Kubeconfig entfernt. **Dabei gehen die Cluster- und Rancher-Daten verloren.**

## Status und Grenzen

Die aktuelle Compose-Architektur und die neuen Add-ons sind im Repository hinterlegt, aber noch **nicht vollständig auf der Ziel-VM getestet**. Die K3s-Nodes teilen sich denselben Ubuntu-Host und bilden deshalb keine echte Host-Hochverfügbarkeit. Die Konfiguration und die festgelegten Trainingspasswörter sind ausschließlich für eine isolierte Schulungsumgebung vorgesehen.
