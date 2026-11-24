# Node Exporter in Prometheus integrieren

Die mit Ansible installierten Node Exporter laufen außerhalb von Kubernetes-Pods. Der Prometheus Operator kann sie über eine ScrapeConfig mit statischen Targets einbinden.

## Voraussetzungen prüfen

```bash
kubectl get nodes -o wide
kubectl get crd scrapeconfigs.monitoring.coreos.com
kubectl get prometheus -n monitoring -o yaml
```

Die IP-Adressen können alternativ aus der Ausgabe des Ansible-Playbooks übernommen werden. Die Prometheus-Ressource muss ScrapeConfigs aus dem Namespace monitoring mit dem angegebenen Label auswählen (scrapeConfigSelector und scrapeConfigNamespaceSelector). Falls scrapeConfigSelector null ist, muss die Helm-Konfiguration zunächst entsprechend angepasst werden.

## ScrapeConfig erstellen

Die Datei `scrapeconfig.yaml` liegt bereits in diesem Verzeichnis und enthält die aktuellen Worker-IP-Adressen. Falls sich die IP-Adressen ändern, die Targets entsprechend anpassen.

```yaml
apiVersion: monitoring.coreos.com/v1alpha1
kind: ScrapeConfig
metadata:
  name: worker-node-exporters
  namespace: monitoring
  labels:
    release: training-monitoring
spec:
  scrapeInterval: 15s
  metricsPath: /metrics
  staticConfigs:
    - targets:
        - "172.18.0.4:9100"
      labels:
        worker: k3s-agent-1
    - targets:
        - "172.18.0.5:9100"
      labels:
        worker: k3s-agent-2
```

```bash
kubectl apply -f scrapeconfig.yaml
kubectl get scrapeconfigs -n monitoring
```

Der Operator aktualisiert die Prometheus-Konfiguration automatisch.

## Ergebnis überprüfen

```bash
kubectl get svc -n monitoring
kubectl -n monitoring port-forward svc/training-monitoring-kube-p-prometheus 9090:9090
```

Den tatsächlichen Service-Namen gegebenenfalls anpassen. Im Browser http://localhost:9090/targets öffnen. Beide Targets müssen nach einem Scrape UP anzeigen. Bei fehlenden Targets die Selektoren prüfen; bei DOWN die Fehlermeldung und die Netzwerk-Erreichbarkeit aus dem Cluster prüfen.

## PromQL

```promql
up{worker=~"k3s-agent-.*"}
node_load1{worker=~"k3s-agent-.*"}
node_memory_MemAvailable_bytes{worker=~"k3s-agent-.*"}
sum by (worker) (rate(node_cpu_seconds_total{mode!="idle",worker=~"k3s-agent-.*"}[1m]))
```

Die letzte Abfrage liefert die Anzahl ausgelasteter CPU-Kerne als Rate, keinen Prozentwert. Die Docker-basierten Worker teilen den Kernel des Hosts; die Metriken sind daher keine unabhängigen Worker-Ressourcenmessungen.

## Aufräumen

```bash
kubectl delete -f scrapeconfig.yaml
```

Die Node Exporter laufen weiter. Ihre Entfernung ist unabhängig von der Prometheus-Konfiguration.
