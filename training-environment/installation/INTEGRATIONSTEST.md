# Integrationstest – Thales Kubernetes-Grundlagen

Basis: hochgeladene Agenda „Einführung in Kubernetes – Grundlagen“ (22.10.2026), 12 Blöcke.

## Grundsatz
Das Setup muss alle Werkzeuge und Add-ons vor dem ersten Schulungstag installieren.
Das technische Skript `integration-test.sh` läuft nach dem Setup automatisch; es arbeitet in
einem separaten Namespace und entfernt seine Testressourcen mit einem Trap.
Es überprüft nicht die gesamte didaktische Qualität und ersetzt keinen manuellen Probelauf.

## Technische Abnahmekriterien
- Drei Kubernetes-Nodes `Ready`, `kubectl` mit Benutzer-Kubeconfig
- Podman, Ansible-Inventar, Helm und Trivy vorhanden
- K3s-StorageClass und CSI/Storage-Funktion über einen gebundenen PVC und einen lesenden Pod
- Deployment, ClusterIP-Service und DNS funktionieren; NodePort und LoadBalancer separat prüfen
- Gateway API CRDs und GatewayClass vorhanden, HTTPRoute wird akzeptiert
- Prometheus und Grafana laufen, Helm-Release vorhanden
- RBAC mit ServiceAccount und RoleBinding wird über `kubectl auth can-i` geprüft
- Ein NetworkPolicy-Deny-Test muss die tatsächliche Netzwerkisolierung nachweisen
- Logs, Events und Rollout-Status sind abrufbar

## Manuelle Prüfmatrix der Agenda
| Block | Praxis / Prüfschritt | Erfolgskriterium |
| --- | --- | --- |
| 1 Container und Ansible | Podman-Container starten, Ansible `ping` auf alle Nodes | Beides ohne sudo möglich |
| 2 Architektur | Nodes und System-Pods untersuchen | Control Plane, Agents, K3s-Komponenten erklärbar |
| 3 kubectl/YAML | Namespace, Labels und Pod aus Manifest erstellen | Ressource und Labels sichtbar |
| 4 Pods | Pod mit Requests/Limits starten und löschen | Lifecycle und Status nachvollziehbar |
| 5 Deployments | Replikas skalieren, Pod löschen | Controller stellt Sollzustand wieder her |
| 6 Netzwerk | ClusterIP, NodePort, LoadBalancer, DNS, Gateway/HTTPRoute | Interne und externe HTTP-Tests erfolgreich |
| 7 Konfiguration/Storage | ConfigMap, Secret, PVC und Pod mit Volume | Daten nach Pod-Neustart vorhanden |
| 8 Updates | Image-Update, Rollout und Rollback | Alte Version wiederherstellbar |
| 9 Scheduling | NodeSelector, Taint/Toleration und Ressourcenmangel | Pod-Platzierung und Pending-Events erklärbar |
| 10 Helm | Chart installieren, Werte ändern, Release zurücksetzen | Release-Historie und Revision sichtbar |
| 11 Diagnose/Monitoring | Defektes Image, Probe-Fehler, Logs, Prometheus/Grafana | Fehlerursache erkennbar, Metriken verfügbar |
| 12 Sicherheit | RBAC, NetworkPolicy, Trivy Image-Scan | Berechtigungen und Deny überprüfbar, Scan-Ergebnis interpretierbar |

## Wichtige Einschränkungen
- Drei Container-Nodes auf einem Host sind **keine Hochverfügbarkeit**.
- K3s Local Path Provisioner ist **kein CSI-Treiber**; für diese Agenda ist nur
  persistente Speicherung gefordert, kein separater CSI-Treiber.
- Der Trivy-Scan benötigt beim ersten Scan ggf. Netzwerkzugriff auf die Vulnerability-Datenbank.
- Die Gateway-Implementierung von Traefik und die externe Erreichbarkeit müssen auf der
  tatsächlichen VM getestet werden.
- Helm-Chart-Versionen sind im Provisioning festgelegt; Versionsupdates separat testen.
- `training-monitoring-grafana` wird nur innerhalb des Clusters veröffentlicht.
  Zugang bei Bedarf über `kubectl -n monitoring port-forward svc/training-monitoring-grafana 3000:80`.
- Für die Schulungs-VM mindestens 4 vCPU, 12 GiB RAM und 35 GiB freien Speicher einplanen;
  die tatsächliche Dimensionierung durch Lasttest validieren.

## Abnahme
Nach `sudo ./setup.sh` muss `integration-test.sh` erfolgreich sein. Danach den
vollständigen manuellen Probelauf mit dem gleichen VM-Image durchführen, das die
Teilnehmenden erhalten. Testergebnis, Versionen und VM-Ressourcen protokollieren.
