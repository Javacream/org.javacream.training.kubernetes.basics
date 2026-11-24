# Node Exporter mit Ansible installieren

## Ziel

Auf allen drei Kubernetes-Nodes wird Node Exporter über SSH installiert und als Linux-Prozess gestartet. Die Metriken werden zunächst direkt über HTTP abgerufen. Später werden die Endpunkte in Prometheus als Scrape-Targets konfiguriert.

## Playbook ausführen

Aus diesem Verzeichnis das bereits vorhandene Inventory verwenden:

```bash
ansible-playbook -i ../inventory.ini playbook.yml
```

Das Playbook verwendet `hosts: all` und adressiert `k3s-server`, `k3s-agent-1` und `k3s-agent-2`. Die SSH-Verbindung und sudo-Berechtigungen stammen aus dem Inventory.

Die Nodes basieren auf Ubuntu und laufen als Docker-Container ohne systemd. Deshalb wird das Ubuntu-Paket `prometheus-node-exporter` installiert und der Prozess mit `nohup` gestartet. Die automatische Dienstaktivierung bei der Paketinstallation wird unterdrückt. Für die Übung werden nur CPU-, Speicher-, Load- und Uname-Collector aktiviert.

## Ergebnis überprüfen

Das Playbook gibt abschließend die URLs der drei Metrik-Endpunkte aus. Die IP-Adressen werden über Ansible Facts (`default_ipv4.address`) ermittelt.

Alternativ können die Netzwerk-Facts auch mit einem Ad-hoc-Befehl abgefragt werden:

```bash
ansible all -i ../inventory.ini -m setup -a 'filter=ansible_default_ipv4'
```

Die ermittelten IP-Adressen für den HTTP-Aufruf verwenden:

```bash
curl http://<Server-IP>:9100/metrics
curl http://<Worker-1-IP>:9100/metrics
curl http://<Worker-2-IP>:9100/metrics
```

Alternativ die URLs im Browser auf dem Deskmate öffnen. Die SSH-Adresse aus dem Inventory (127.0.0.1 mit weitergeleiteten SSH-Ports) ist nicht die Node-IP.

Node Exporter läuft direkt im Netzwerk-Namespace des jeweiligen Nodes. Daher ist Port 9100 über die Node-IP erreichbar, sofern das Docker-Netzwerk vom Client erreichbar ist. Ein Kubernetes-Service ist dafür nicht notwendig.

## Metriken

Beispiele: `node_cpu_seconds_total`, `node_memory_MemAvailable_bytes`, `node_load1` und `node_uname_info`.

Die Nodes teilen den Linux-Kernel des Docker-Hosts. CPU-, Speicher- und Load-Metriken sind deshalb nicht als unabhängige Node-Ressourcenmessungen zu interpretieren.

## Ausblick

Im Monitoring-Kapitel werden alle drei Node-IPs mit Port 9100 als Prometheus-Scrape-Targets ergänzt. Das Playbook ändert die Prometheus-Konfiguration noch nicht.

## Aufräumen

```bash
ansible all -i ../inventory.ini -b -m shell -a 'pkill -f "^/usr/bin/prometheus-node-exporter( |$)" || test $? -eq 1'
```

Das Paket bleibt installiert. Nach einem Neustart der Nodes muss der Exporter erneut über das Playbook gestartet werden.
