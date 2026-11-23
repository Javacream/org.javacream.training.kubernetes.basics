# Monitoring mit Prometheus und Grafana

Die Trainingsumgebung installiert das Helm-Chart `kube-prometheus-stack` (Release `training-monitoring`, Namespace `monitoring`). Die Konfiguration steht unter `training-environment/installation/addons/monitoring-values.yaml`.

## Installierte Produkte

- **Prometheus** sammelt und speichert Zeitreihen-Metriken und bietet mit PromQL eine Abfragesprache sowie eine eigene Weboberfläche. In der Trainingskonfiguration werden Metriken sechs Stunden aufbewahrt.
- **Grafana** stellt die gesammelten Metriken in Dashboards dar; Prometheus wird vom Chart als Datenquelle eingerichtet.
- **Prometheus Operator** verwaltet Prometheus und die zugehörigen Kubernetes-Ressourcen, insbesondere die Konfiguration der Scrape-Targets.
- **kube-state-metrics** stellt Informationen über den Zustand von Kubernetes-Objekten (z. B. Pods, Deployments und Nodes) als Metriken bereit.

Der **Node Exporter** ist deaktiviert, weil dessen Host-Mounts in den Docker-basierten K3s-Nodes Probleme mit der Mount Propagation verursachen. Alertmanager, etcd-, Controller-Manager- und Scheduler-Monitoring sind ebenfalls deaktiviert.

## Installation und Container prüfen

```bash
helm list -n monitoring
kubectl get pods -n monitoring
kubectl get pods -n monitoring -o wide
kubectl get deployments,statefulsets,daemonsets -n monitoring
```

Die Pods von Grafana, Prometheus Operator und kube-state-metrics werden durch Deployments verwaltet; Prometheus wird über einen StatefulSet betrieben. Für Details und Fehlermeldungen:

```bash
kubectl describe pod -n monitoring <POD-NAME>
kubectl get events -n monitoring --sort-by=.lastTimestamp
```

Der Pod-Name wird aus der Spalte `NAME` von `kubectl get pods -n monitoring` übernommen.

## Weboberflächen über Port-Forwarding

Ein Port-Forwarding ist ein **laufender Prozess im Terminal**. Solange es aktiv ist, bleibt das betreffende Terminal durch diesen Prozess belegt. Für Grafana und Prometheus werden deshalb zwei Terminals benötigt. Mit `Strg+C` lässt sich das jeweilige Port-Forwarding beenden.

**Grafana:**

```bash
kubectl -n monitoring port-forward svc/training-monitoring-grafana 3000:80
```

Auf der VM: http://localhost:3000 — Benutzer `admin`, initiales Passwort `training-grafana`.

**Prometheus:**

```bash
kubectl -n monitoring port-forward svc/training-monitoring-kube-p-prometheus 9090:9090
```

Auf der VM: http://localhost:9090. Falls der Prometheus-Service abweichend heißt, den Namen mit `kubectl get svc -n monitoring` ermitteln.

Die Port-Forwardings binden standardmäßig an `localhost` der VM. Für den Zugriff vom eigenen Rechner kann ein SSH-Tunnel verwendet werden, z. B. `ssh -L 9090:localhost:9090 <USER>@<VM-IP>`.

## Scraping: Konfiguration und `up`

Prometheus fragt Metrik-Endpunkte regelmäßig über HTTP ab (*Scraping*). Der Prometheus Operator erzeugt die Scrape-Konfiguration aus Kubernetes-Ressourcen wie `ServiceMonitor` und `PodMonitor`. Das Helm-Chart legt hierfür bereits Monitore an. Die Trainingsdatei `monitoring-values.yaml` ergänzt bzw. deaktiviert einzelne Komponenten; sie enthält keine eigenen zusätzlichen Scrape-Jobs.

Die tatsächlichen Targets sind in der Prometheus-Oberfläche unter **Status → Targets** sichtbar. In der Abfrageoberfläche zeigt

```promql
up
```

für **jede konfigurierte Target-Instanz** an, ob der letzte Scrape erfolgreich war: `1` = erfolgreich, `0` = fehlgeschlagen. `up` ist **kein Verzeichnis aller Pods oder Container**. Ein Pod ohne konfigurierten Scrape-Endpunkt erscheint dort nicht.

Typische Targets des installierten Stacks sind:

| Target / Komponente | Warum erscheint sie in `up`? |
| --- | --- |
| Kubernetes API-Server | Stellt Metriken zur Kubernetes-API bereit; der Stack konfiguriert einen entsprechenden Scrape-Job. |
| Kubelet auf den K3s-Nodes | Liefert Node-/Kubelet- und Container-Metriken; bei drei Nodes können mehrere Targets erscheinen. |
| kube-state-metrics | Exportiert Zustandsmetriken zu Kubernetes-Ressourcen. |
| Prometheus | Überwacht seinen eigenen Metrik-Endpunkt. |
| Prometheus Operator | Stellt eigene Betriebsmetriken bereit und wird vom Chart überwacht. |

Welche dieser Targets tatsächlich angezeigt werden und erfolgreich sind, hängt von den im K3s-Cluster erreichbaren Endpunkten und den vom Chart erzeugten Monitoren ab. **Grafana muss nicht als eigenes `up`-Target erscheinen**, obwohl sein Pod läuft: Die Grafana-Weboberfläche allein ist kein Nachweis für einen eingerichteten Prometheus-Scrape.

**Nicht erwartet:** Node Exporter, etcd, kube-controller-manager und kube-scheduler, da diese in der Trainingskonfiguration deaktiviert sind.

Zur Kontrolle der vom Operator verwalteten Monitore:

```bash
kubectl get servicemonitors,podmonitors -A
```

Nützliche PromQL-Beispiele:

```promql
up
```

```promql
count by (job) (up)
```

```promql
kube_pod_info
```

`count by (job) (up)` zählt konfigurierte Targets je Job, **unabhängig davon, ob deren letzter Scrape erfolgreich war**. Für die Zahl erfolgreicher Targets je Job:

```promql
sum by (job) (up)
```
