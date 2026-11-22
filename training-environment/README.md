# Trainingsumgebung – Kubernetes Grundlagen und Praxis

## Rahmen

Standardtraining mit 3 Tagen und 12 Unterrichtseinheiten à 90 Minuten. Der Branch `training` enthält die Ausgangsbasis für die Schulung.

## Infrastruktur und Werkzeuge

- Eine vorbereitete virtuelle Trainingsumgebung stellt einen lauffähigen Kubernetes-Cluster bereit; eine Clusterinstallation ist nicht Teil der Übungen.
- **Rancher** ist die grafische Oberfläche für Cluster, Workloads, Konfiguration und Diagnose.
- **kubectl** und **Helm** sind für CLI-Übungen verfügbar.
- Für die Container- und Automatisierungseinführung stehen **Podman** und **Ansible** bereit.
- Versionen, Cluster-Topologie, VM-Zugang und Rancher-URL werden vor der konkreten Durchführung festgelegt und getestet. Zugangsdaten gehören nicht in dieses Repository.

## Einstieg

1. In die bereitgestellte Trainings-VM einloggen und Rancher über die mitgeteilte URL öffnen.
2. Im Terminal `kubectl config current-context`, `kubectl cluster-info` und `kubectl get nodes` ausführen.
3. Den Namespace mit `kubectl apply -f Resources/03-kubectl-yaml/src/namespace.yaml` anlegen.
4. Die Beispiele der Unterrichtseinheiten in der vorgesehenen Reihenfolge bearbeiten. Bei YAML-Dateien `kubectl apply -f <datei>` verwenden.
5. Nicht mehr benötigte Übungsressourcen gezielt mit `kubectl delete -f <datei>` entfernen.

## Struktur

Jede Einheit liegt in `Resources/<nummer>-<thema>/`. Die jeweilige `README.md` erläutert Ziele, Inhalt, Beispiel und Vorgehen. Im Unterverzeichnis `src/` liegen Programme, Manifeste, Skripte und Konfigurationen. Die ersten Dateien bilden ein **Grundgerüst**, noch keinen vollständig ausgearbeiteten Übungssatz.

- [1. Container-Grundlagen und Automatisierung](../Resources/01-container-grundlagen/README.md)
- [2. Kubernetes-Architektur und Konzepte](../Resources/02-architektur/README.md)
- [3. Kubernetes-Werkzeuge und Ressourcen](../Resources/03-kubectl-yaml/README.md)
- [4. Pods und Container in Kubernetes](../Resources/04-pods/README.md)
- [5. Deployments und Anwendungen bereitstellen](../Resources/05-deployments/README.md)
- [6. Netzwerk und Services](../Resources/06-netzwerk-services/README.md)
- [7. Konfiguration und persistente Speicherung](../Resources/07-konfiguration-speicherung/README.md)
- [8. Anwendungen aktualisieren und skalieren](../Resources/08-updates-skalierung/README.md)
- [9. Ressourcenverwaltung, Scheduling und Verfügbarkeit](../Resources/09-scheduling/README.md)
- [10. Helm und Automatisierung](../Resources/10-helm/README.md)
- [11. Diagnose, Debugging und Monitoring](../Resources/11-diagnose-monitoring/README.md)
- [12. Kubernetes-Sicherheit und betriebliche Anforderungen](../Resources/12-sicherheit/README.md)

Die Blöcke 6, 8 und 11 setzen teilweise Ressourcen aus Block 5 voraus. Vor jedem Kubernetes-Kommando den aktiven Kontext und Namespace kontrollieren.
