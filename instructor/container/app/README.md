# Trainerleitfaden: Spring-Boot-Anwendung, Docker und GitHub Actions

Diese README dokumentiert die im Rahmen der Kubernetes-Einführung durchgeführten Schritte. Die Anwendung selbst und ihre Bedienung sind unter [`introduction/container/app/README.md`](../../../introduction/container/app/README.md) beschrieben.

## 1. Spring-Boot-Anwendung erstellen

Unter `introduction/container/app` wurde eine einfache ToDo-Anwendung eingerichtet:

- Java 21 und Maven, Spring Boot
- REST-CRUD für ToDos mit den Feldern `description`, `priority` und `status`; die `id` wird generiert
- Spring Data JPA mit eingebetteter H2-In-Memory-Datenbank
- Swagger-UI unter `http://localhost:8080/swagger-ui.html`
- H2-Konsole unter `http://localhost:8080/h2-console`
- Ein einfacher Spring-Boot-Test

Die Datenbankinhalte gehen beim Beenden der Anwendung verloren. Die H2-Konsole wurde für den Zugriff aus dem Docker-Host freigeschaltet; das ist ausschließlich für die Schulung gedacht.

Lokal bauen und starten (im Verzeichnis `introduction/container/app`):

```bash
mvn clean package
java -jar target/todo-app-1.0.0.jar
```

## 2. Docker-Image erstellen

Das Dockerfile nutzt `eclipse-temurin:21-jre` und kopiert die mit Maven erzeugte JAR-Datei in das Image. Nach dem Maven-Build:

```bash
docker build -t todo-app:local .
docker run --rm -p 8080:8080 todo-app:local
```

Die Anwendung ist anschließend über Port 8080 erreichbar.

## 3. GitHub-Actions-Workflow einrichten

Der Workflow liegt zwingend im **Repository-Wurzelverzeichnis** unter [`.github/workflows/todo-app-docker.yml`](../../../.github/workflows/todo-app-docker.yml). GitHub erkennt Workflows nicht in einem beliebigen Anwendungsverzeichnis.

Der Workflow wurde für den Branch `Thales-24-26-11-2026` eingerichtet. Bei Änderungen an der Anwendung oder der Workflow-Datei sowie bei manueller Ausführung führt er folgende Schritte aus:

1. Repository auschecken und Java 21 einrichten
2. Maven-Build einschließlich Tests: `mvn --batch-mode clean package`
3. JAR als GitHub Actions Artifact `todo-app-jar` hochladen (Aufbewahrung: 14 Tage)
4. Docker-Image bauen
5. Image bei Push bzw. manuellem Lauf in GHCR veröffentlichen, mit den Tags `latest` und Commit-SHA

Bei Pull Requests wird das Image nur gebaut, nicht veröffentlicht. Die Veröffentlichung nutzt `GITHUB_TOKEN` und die Workflow-Berechtigung `packages: write`; ein persönlicher Docker-Hub-Account wird dafür nicht benötigt.

## 4. JAR-Datei herunterladen und optional als Release veröffentlichen

Das JAR-Artefakt liegt nach einem erfolgreichen Workflow-Lauf unter **Actions → Workflow-Lauf → Artifacts → todo-app-jar** als ZIP-Datei. Der Download eines Actions Artifacts über GitHub setzt eine Anmeldung voraus.

Für einen öffentlichen Download kann man die JAR-Datei **manuell** als GitHub Release Asset bereitstellen:

1. Als berechtigter Benutzer anmelden und das ZIP aus dem erfolgreichen Workflow-Lauf herunterladen
2. `todo-app-1.0.0.jar` entpacken
3. Im Repository **Releases → Draft a new release** öffnen
4. Einen Tag wie `todo-app-v1.0.0` für den richtigen Branch auswählen bzw. anlegen
5. Die JAR als Release Asset hochladen und den Release veröffentlichen

Bei einem öffentlichen Repository kann das Release Asset danach ohne Anmeldung heruntergeladen werden. Diese Veröffentlichung wurde als Möglichkeit besprochen, **nicht automatisiert**.

## 5. Docker-Image aus GitHub Container Registry beziehen

Der Workflow veröffentlicht das Image unter:

```text
ghcr.io/javacream/todo-app:latest
```

Ein zunächst privates GHCR-Paket lässt sich ohne passende Anmeldung nicht herunterladen. In der Schulung wurde die **Paketsichtbarkeit auf Public geändert**; anschließend funktionierte der Pull ohne Anmeldung:

```bash
docker pull ghcr.io/javacream/todo-app:latest
docker run --rm -p 8080:8080 ghcr.io/javacream/todo-app:latest
```

Die Sichtbarkeit wird in GitHub über **Packages → todo-app → Package settings → Change package visibility** geändert. Ist die Einstellung mit „Setting is disabled by organization administrators“ gesperrt, müssen zunächst die entsprechenden Organisationsrichtlinien bzw. Berechtigungen geprüft werden.

**Hinweis zur Fehlersuche:** Ein vollständig qualifizierter Image-Name mit `ghcr.io/` adressiert GHCR. Docker wechselt bei einem fehlgeschlagenen GHCR-Pull normalerweise nicht automatisch zu Docker Hub. Bei Anmeldeaufforderungen den exakten Befehl und die Fehlermeldung prüfen.

## 6. Workflow pausieren (deaktivieren) und wieder aktivieren

**Aktueller Schulungsstand:** Der Workflow wurde nach der erfolgreichen Veröffentlichung **manuell deaktiviert**, damit nicht bei jeder Änderung erneut gebaut und veröffentlicht wird. Die YAML-Datei bleibt dabei unverändert im Repository.

Deaktivieren über die GitHub-Weboberfläche:

1. Im Repository **Actions** öffnen
2. Links **Build and publish ToDo application** auswählen
3. Über das Menü **…** die Aktion **Disable workflow** auswählen

Wieder aktivieren: Im selben Menü **Enable workflow** auswählen.

Alternativ über die GitHub CLI:

```bash
gh workflow disable todo-app-docker.yml -R Javacream/org.javacream.training.kubernetes.basics
gh workflow enable todo-app-docker.yml -R Javacream/org.javacream.training.kubernetes.basics
gh workflow list --all -R Javacream/org.javacream.training.kubernetes.basics
```

Die Deaktivierung betrifft den Workflow im Repository insgesamt, nicht nur einen einzelnen Branch. Bereits laufende Jobs werden dadurch nicht automatisch abgebrochen. Während der Workflow deaktiviert ist, erfolgen keine neuen automatischen oder manuellen Läufe dieses Workflows. Bereits veröffentlichte Images und gespeicherte Artifacts bleiben davon unberührt (Artifacts nur bis zum Ablauf ihrer Aufbewahrungsfrist).

## 7. Bezug zu Kubernetes

Das veröffentlichte Image kann direkt in einem Kubernetes Deployment als Container-Image eingetragen werden:

```yaml
containers:
  - name: todo-app
    image: ghcr.io/javacream/todo-app:latest
    ports:
      - containerPort: 8080
```

Für reproduzierbare Übungen empfiehlt sich statt `latest` ein konkreter Commit-SHA-Tag. Da H2 hier im Arbeitsspeicher läuft, bleiben ToDo-Daten beim Neustart eines Pods nicht erhalten.
