# Kubernetes – Grundlagen und Praxis

**Seminardauer:** 3 Tage, 12 Unterrichtseinheiten à 90 Minuten  
**Branch:** `training`

Dieses Repository enthält die Ressourcen für das Standardtraining **Kubernetes – Grundlagen und Praxis**. Die Teilnehmenden lernen, containerisierte Anwendungen in Kubernetes bereitzustellen, zu verwalten und zu betreiben.

## Trainingsumgebung

Das Seminar findet in einer vorbereiteten virtuellen Umgebung mit einem funktionsfähigen Kubernetes-Cluster statt. Eine Clusterinstallation ist nicht Teil des Trainings.

- **Rancher:** grafische Verwaltung und Untersuchung von Clustern, Workloads und Kubernetes-Ressourcen
- **kubectl:** Arbeit mit Kubernetes-Ressourcen über die Kommandozeile
- **Helm:** Installation und Verwaltung paketierter Kubernetes-Anwendungen
- **Podman und Ansible:** ergänzende Werkzeuge für den Einstieg in Container und Automatisierung

Die konkrete Cluster-Topologie, Softwareversionen und Zugangswege werden vor der Durchführung festgelegt. Zugangsdaten werden nicht im Repository gespeichert.

Eine ausführlichere Beschreibung mit Einstiegsschritten steht in [training-environment/README.md](training-environment/README.md).

## Aufbau der Unterrichtseinheiten

Jede der zwölf Unterrichtseinheiten besitzt ein eigenes Verzeichnis unter [Resources](Resources/). Der Verzeichnisname beginnt mit der Blocknummer und bezeichnet das Thema.

- `README.md`: Lerngegenstand, Beschreibung der Beispiele, Vorgehen und Hinweise
- `src/`: Quellcode, Shell-Skripte, Kubernetes-YAML-Manifeste und weitere Konfigurationen

Die Dateien sind ein **Ausgangsgerüst** für die weitere Entwicklung des Trainerleitfadens, des Handouts und der Übungen. Sie stellen noch keinen vollständig getesteten Übungssatz dar.

## Unterrichtseinheiten

1. [Container-Grundlagen und Automatisierung](Resources/01-container-grundlagen/)
2. [Kubernetes-Architektur und Konzepte](Resources/02-architektur/)
3. [Kubernetes-Werkzeuge und Ressourcen](Resources/03-kubectl-yaml/)
4. [Pods und Container in Kubernetes](Resources/04-pods/)
5. [Deployments und Anwendungen bereitstellen](Resources/05-deployments/)
6. [Netzwerk und Services](Resources/06-netzwerk-services/)
7. [Konfiguration und persistente Speicherung](Resources/07-konfiguration-speicherung/)
8. [Anwendungen aktualisieren und skalieren](Resources/08-updates-skalierung/)
9. [Ressourcenverwaltung, Scheduling und Verfügbarkeit](Resources/09-scheduling/)
10. [Helm und Automatisierung](Resources/10-helm/)
11. [Diagnose, Debugging und Monitoring](Resources/11-diagnose-monitoring/)
12. [Kubernetes-Sicherheit und betriebliche Anforderungen](Resources/12-sicherheit/)

## Erste Schritte

```bash
kubectl config current-context
kubectl cluster-info
kubectl get nodes
```

Anschließend Rancher öffnen und den verbundenen Cluster prüfen. Die Beispiele werden blockweise aus den jeweiligen `src/`-Verzeichnissen ausgeführt. Vor Änderungen am Cluster stets Kontext und Namespace kontrollieren.
