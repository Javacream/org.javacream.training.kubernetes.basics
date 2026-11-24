# Jupyter Notebooks

Ein Jupyter Notebook (`.ipynb`) besteht aus einer Folge von **Markdown-Zellen** und **Codezellen**. Markdown-Zellen enthalten Erläuterungen, Lernziele und Arbeitsanweisungen. Codezellen führen Befehle aus und zeigen ihre Ausgaben unmittelbar darunter. In unseren Kubernetes-Notebooks wird ein **Python-Kernel** verwendet; die Shell-Befehle laufen in Codezellen mit `%%bash` als erster Zeile. So wechseln sich Erklärung und praktische Ausführung kleinschrittig ab.

## Vorbereiten in unserer Umgebung

Die folgenden Schritte erfolgen in **Visual Studio Code auf dem Deskmate**. Python ist dort bereits installiert; wir verwenden die vorhandene Python-Installation **ohne virtuelles Environment**.

### 1. VS-Code-Erweiterungen installieren

In VS Code die Erweiterungsansicht öffnen (`Ctrl+Shift+X`) und diese beiden Microsoft-Erweiterungen installieren:

- **Python** (`ms-python.python`)
- **Jupyter** (`ms-toolsai.jupyter`)

Alternativ über ein Terminal mit verfügbarem `code`-Befehl:

```bash
code --install-extension ms-python.python
code --install-extension ms-toolsai.jupyter
```

### 2. Python und pip prüfen bzw. pip installieren

Im Terminal auf dem Deskmate:

```bash
python3 --version
python3 -m pip --version
```

Falls `pip` noch nicht vorhanden ist, auf dem Ubuntu-/Debian-basierten Deskmate installieren:

```bash
sudo apt update
sudo apt install -y python3-pip
```

Danach erneut prüfen:

```bash
python3 -m pip --version
```

### 3. ipykernel in der vorhandenen Python-Installation installieren

`ipykernel` stellt den Python-Kernel bereit, über den VS Code die Notebook-Codezellen ausführt. Wir verwenden bewusst **kein virtuelles Environment**:

```bash
python3 -m pip install --user --break-system-packages ipykernel
```

Installation überprüfen:

```bash
python3 -c "import ipykernel; print(ipykernel.__version__)"
```

**Hinweis:** `--break-system-packages` erlaubt pip-Installationen trotz der Schutzmechanismen einer extern verwalteten Python-Installation (PEP 668). Die Option `--user` installiert in das Benutzerverzeichnis und vermeidet eine systemweite pip-Installation. Änderungen an der Python-Umgebung können dennoch mit distributionsverwalteten Paketen kollidieren.

### 4. Vorhandene Python-Runtime auswählen

1. Das Repository in VS Code öffnen und beispielsweise `kubernetes/01-pods/pods.ipynb` öffnen.
2. Rechts oben im Notebook auf **Select Kernel** / **Kernel auswählen** klicken.
3. **Python Environments** wählen und den **bereits installierten Python-Interpreter des Deskmate** auswählen (typischerweise `/usr/bin/python3`; den tatsächlich angebotenen Pfad verwenden).
4. Falls nötig mit `Python: Select Interpreter` in der Befehlspalette (`Ctrl+Shift+P`) denselben Interpreter festlegen.
5. Eine Codezelle ausführen. Bei `%%bash` werden die enthaltenen Shell-Befehle über den Python-Kernel gestartet.

Zur Kontrolle im VS-Code-Terminal:

```bash
python3 -c "import sys; print(sys.executable)"
kubectl config current-context
kubectl get nodes
```

**Wichtig für unsere Übungen:** Das Notebook sollte mit dem Arbeitsverzeichnis `kubernetes/01-pods` ausgeführt werden, weil die Codezellen Dateien wie `hello.yaml` direkt ansprechen. Der Python-Kernel muss auf dem Deskmate laufen, auf dem auch `kubectl` für den Trainingscluster eingerichtet ist.
