# Kapitel 01 – Pods, Init-Container und Sidecars

Die Beispiele demonstrieren den Aufbau eines Pods, den Start einer Anwendung nach einer Initialisierungsbedingung sowie einen dauerhaft laufenden Sidecar-Container mit gemeinsamem Volume.

**Voraussetzungen:** Die Kubernetes-Trainingsumgebung läuft und `kubectl` ist für den K3s-Cluster eingerichtet. Alle Befehle werden auf der Ubuntu-Trainings-VM **im Wurzelverzeichnis des Schulungsrepositories** ausgeführt. Die Beispiele verwenden den Namespace `default`. Vorab prüfen:

```bash
kubectl config current-context
kubectl get nodes
kubectl config view --minify -o jsonpath='{..namespace}'; echo
```

Falls ein anderer Namespace als `default` aktiv ist, diesen für die Übungen ausdrücklich wählen: `kubectl config set-context --current --namespace=default`.

Die Beispiele können nacheinander ausgeführt werden. Für die Webtests wird jeweils Port 8080 auf dem Ubuntu-Host verwendet; daher jeweils nur **ein** Port-Forwarding gleichzeitig laufen lassen. Ein Port-Forwarding mit `Ctrl+C` beenden. Bei Zugriff über einen Browser außerhalb der Trainings-VM ist `localhost` der Rechner, auf dem `kubectl port-forward` läuft; gegebenenfalls den Browser auf der VM verwenden oder einen SSH-Tunnel einrichten.

## 1. `hello.yaml` – Einfacher Pod

### Lernziel

Ein Pod mit einem Container (`nigelpoulton/k8sbook:1.0`) wird deklarativ erstellt. Das Manifest definiert Labels (`zone=prod`, `version=v1`), einen Container-Port (8080) sowie CPU- und Speicherlimits. Der Pod wird direkt verwaltet, noch nicht über ein Deployment.

### Bereitstellen

```bash
kubectl apply -f kubernetes/01-pods/hello.yaml
kubectl wait --for=condition=Ready pod/hello-pod --timeout=120s
```

### Untersuchen und ausprobieren

```bash
# Pod und zugewiesenen Node anzeigen
kubectl get pod hello-pod -o wide

# Labels untersuchen und nach einem Label filtern
kubectl get pods --show-labels
kubectl get pods -l zone=prod

# Container-Image, Port, Ressourcenlimits und Ereignisse ansehen
kubectl describe pod hello-pod
kubectl get pod hello-pod -o yaml

# Anwendungsprotokoll ansehen
kubectl logs hello-pod

# Anwendung auf der Trainings-VM verfügbar machen
kubectl port-forward pod/hello-pod 8080:8080
```

In einem **zweiten Terminal** auf der Trainings-VM:

```bash
curl http://localhost:8080/
```

Das Port-Forwarding anschließend im ersten Terminal mit `Ctrl+C` beenden.

### Aufräumen

```bash
kubectl delete -f kubernetes/01-pods/hello.yaml
```

## 2. `initpod.yml` und `initsvc.yml` – Startreihenfolge mit Init-Container

### Lernziel

Der Init-Container `init-ctr` wartet mit `nslookup k8sbook`, bis der DNS-Name des Service `k8sbook` aufgelöst werden kann. Erst danach startet der eigentliche Webcontainer `web-ctr`. Das Service-Manifest `initsvc.yml` gehört daher **zu diesem Beispiel** und wird bewusst erst im zweiten Schritt angewendet.

**Wichtig:** Geprüft wird nur die Existenz des DNS-Namens, **nicht** die Erreichbarkeit oder Bereitschaft eines Backends. Der Service selektiert hier den eigenen Pod (`app=initializer`) – eine bewusst vereinfachte Demonstration, kein Muster für produktive Abhängigkeitsprüfungen.

### Bereitstellen – zunächst ohne Service

```bash
kubectl apply -f kubernetes/01-pods/initpod.yml
```

### Untersuchen – der Init-Container wartet

```bash
# Initialisierungsstatus beobachten (typisch: Init:0/1)
kubectl get pod initpod
kubectl describe pod initpod

# Wiederholte DNS-Abfragen und Warteausgaben ansehen
kubectl logs initpod -c init-ctr

# Prüfen, dass der benötigte Service noch fehlt
kubectl get service k8sbook
```

Der letzte Befehl meldet erwartungsgemäß `NotFound`. Der Hauptcontainer wird noch nicht gestartet.

### Fehlenden Service bereitstellen und Übergang beobachten

```bash
kubectl apply -f kubernetes/01-pods/initsvc.yml
kubectl get service k8sbook
kubectl get pod initpod -w
```

Sobald der Pod `Running` und `READY 1/1` zeigt, die Beobachtung mit `Ctrl+C` beenden.

```bash
# Abschlussmeldung des Init-Containers
kubectl logs initpod -c init-ctr

# Zustand der beiden Container nachvollziehen
kubectl describe pod initpod
kubectl get pod initpod -o jsonpath='{.status.initContainerStatuses[0].state.terminated.reason}'; echo

# Hauptcontainer und Anwendung prüfen
kubectl logs initpod -c web-ctr
kubectl port-forward pod/initpod 8080:8080
```

In einem **zweiten Terminal**:

```bash
curl http://localhost:8080/
```

Port-Forwarding mit `Ctrl+C` beenden.

### Aufräumen

```bash
kubectl delete -f kubernetes/01-pods/initpod.yml
kubectl delete -f kubernetes/01-pods/initsvc.yml
```

## 3. `initsidecar.yml` – GitSync-Sidecar mit gemeinsamem Volume

### Lernziel

Ein Pod kombiniert einen dauerhaft laufenden **nativen Sidecar** (`ctr-sync` unter `initContainers` mit `restartPolicy: Always`) und einen NGINX-Webcontainer (`ctr-web`). GitSync 4.8.0 synchronisiert den Branch `sidecar-example` aus dem Schulungsrepository in ein gemeinsames `emptyDir`-Volume. NGINX liest die dort bereitgestellten Dateien. Das Manifest erstellt außerdem den Service `svc-sidecar` (Typ `LoadBalancer`).

Der Demo-Inhalt liegt unter [`index.html` im Branch `sidecar-example`](https://github.com/Javacream/org.javacream.training.kubernetes.basics/blob/sidecar-example/index.html). Er zeigt zunächst **Version 1.0**.

### Bereitstellen

```bash
kubectl apply -f kubernetes/01-pods/initsidecar.yml
kubectl get pod git-sync -w
```

Sobald der Pod bereit ist, `Ctrl+C` drücken. Falls er nicht startet, die folgenden Diagnosebefehle verwenden.

### Untersuchen und ausprobieren

```bash
# Pod, Containerstatus und Service ansehen
kubectl get pod git-sync -o wide
kubectl describe pod git-sync
kubectl get service svc-sidecar

# GitSync-Ausgaben und NGINX-Protokolle getrennt ansehen
kubectl logs git-sync -c ctr-sync
kubectl logs git-sync -c ctr-web

# Synchronisierte Dateien im gemeinsam genutzten Volume untersuchen
kubectl exec git-sync -c ctr-web -- ls -la /usr/share/nginx/
kubectl exec git-sync -c ctr-web -- ls -la /usr/share/nginx/html/

# Service lokal erreichen, auch wenn der LoadBalancer keine externe IP erhält
kubectl port-forward service/svc-sidecar 8080:8080
```

In einem **zweiten Terminal**:

```bash
curl http://localhost:8080/html/index.html
```

Die Antwort soll die Begrüßung und **Version 1.0** enthalten. Der Pfad `/html/index.html` entspricht dem von GitSync angelegten symbolischen Link `html`. Danach das Port-Forwarding mit `Ctrl+C` beenden.

### Änderung ohne Neustart demonstrieren

1. Im GitHub-Branch [`sidecar-example`](https://github.com/Javacream/org.javacream.training.kubernetes.basics/tree/sidecar-example) die Datei `index.html` bearbeiten und **Version 1.0** durch **Version 1.1** ersetzen; die Änderung committen.
2. GitSync synchronisiert regelmäßig den Branch. Den Pod **nicht** neu starten.
3. Auf der Trainings-VM den aktualisierten Inhalt prüfen:

```bash
kubectl logs git-sync -c ctr-sync --tail=30
kubectl exec git-sync -c ctr-web -- cat /usr/share/nginx/html/index.html
kubectl port-forward service/svc-sidecar 8080:8080
```

In einem zweiten Terminal:

```bash
curl http://localhost:8080/html/index.html
```

Jetzt sollte **Version 1.1** erscheinen. Das Port-Forwarding mit `Ctrl+C` beenden. Die GitHub-Änderung bleibt auch nach dem Löschen des Pods bestehen; für eine erneute Übung gegebenenfalls wieder auf Version 1.0 zurücksetzen.

**Hinweise:** GitSync benötigt Netzwerkzugriff auf GitHub. Das Image muss in der Trainingsumgebung abrufbar sein. Die ältere GitSync-Konfiguration wurde auf `registry.k8s.io/git-sync/git-sync:v4.8.0` und die aktuellen `GITSYNC_*`-Variablen umgestellt. Der Laufzeittest dieser Fassung ist noch ausstehend. Falls der Pod nicht bereit wird, `kubectl describe pod git-sync` und `kubectl logs git-sync -c ctr-sync` auswerten.

### Aufräumen

```bash
kubectl delete -f kubernetes/01-pods/initsidecar.yml
```

## Abschließende Kontrolle

Nach allen Übungen sollten keine Ressourcen dieser Beispiele mehr vorhanden sein:

```bash
kubectl get pods
kubectl get services
```

Der standardmäßige Service `kubernetes` bleibt selbstverständlich bestehen.
