# ToDo – Spring Boot Beispiel

Eine einfache REST-Anwendung mit Spring Data JPA und eingebetteter H2-Datenbank. Die Daten werden im Arbeitsspeicher gehalten und gehen beim Beenden der Anwendung verloren.

## Starten

Voraussetzung: Java 21 und Maven. Alle folgenden lokalen Befehle werden in `introduction/container/app` ausgeführt.

```bash
mvn spring-boot:run
```

Alternativ:

```bash
mvn clean package
java -jar target/todo-app-1.0.0.jar
```

## Weboberflächen

- Swagger-UI: http://localhost:8080/swagger-ui.html
- H2-Konsole: http://localhost:8080/h2-console
- H2 JDBC URL: `jdbc:h2:mem:todos`
- Benutzer: `sa`, Passwort leer

## REST-API

| Methode | URL | Bedeutung |
| --- | --- | --- |
| GET | /api/todos | Alle ToDos |
| GET | /api/todos/{id} | Ein ToDo |
| POST | /api/todos | Neues ToDo |
| PUT | /api/todos/{id} | ToDo aktualisieren |
| DELETE | /api/todos/{id} | ToDo löschen |

Beispiel für POST:

```json
{
  "description": "Kubernetes kennenlernen",
  "priority": 2,
  "status": "OPEN"
}
```

Die ID wird automatisch vergeben. Die Felder `description` und `status` müssen nicht leer sein; `priority` ist eine Ganzzahl.

## Docker lokal bauen

```bash
mvn clean package
docker build -t todo-app:local .
docker run --rm -p 8080:8080 todo-app:local
```

Die H2-Konsole ist für das Schulungsbeispiel auch aus dem Docker-Host erreichbar. Diese Konfiguration ist **nicht für den Produktivbetrieb** gedacht.

## GitHub Actions: JAR und Container-Image

Der Workflow befindet sich im Repository-Wurzelverzeichnis unter `.github/workflows/todo-app-docker.yml`.

Bei Pushes auf den Branch `Thales-24-26-11-2026` mit Änderungen an der Anwendung oder am Workflow sowie bei manueller Ausführung über **Actions → Build and publish ToDo application → Run workflow**:

1. Maven baut die Anwendung mit `mvn clean package` und führt die Tests aus.
2. Die ausführbare JAR-Datei wird als GitHub Actions Artifact `todo-app-jar` bereitgestellt (Aufbewahrung: 14 Tage).
3. Docker Buildx erstellt das Image aus dem gebauten JAR.
4. Das Image wird mit den Tags `latest` und der vollständigen Commit-SHA in die GitHub Container Registry (GHCR) veröffentlicht.

Bei Pull Requests werden Maven-Build, Artifact-Upload und Docker-Build ausgeführt, **ohne** das Image in die Registry zu pushen.

### JAR herunterladen

Im Repository unter **Actions** den erfolgreichen Workflow-Lauf öffnen. Unter **Artifacts** kann `todo-app-jar` als ZIP heruntergeladen werden. Die JAR-Datei ist im ZIP enthalten.

### Docker-Image aus GHCR verwenden

Nach einem erfolgreichen Publish:

```bash
docker pull ghcr.io/javacream/todo-app:latest
docker run --rm -p 8080:8080 ghcr.io/javacream/todo-app:latest
```

Alternativ kann statt `latest` die vollständige Git-Commit-SHA als unveränderlicher Versionsbezug verwendet werden.

Der Workflow authentifiziert sich mit dem von GitHub Actions bereitgestellten `GITHUB_TOKEN` und benötigt die Berechtigung `packages: write`. In den Repository-Einstellungen müssen GitHub Actions und die Paketveröffentlichung erlaubt sein. Neu erzeugte GHCR-Pakete können zunächst privat sein; dann ist für `docker pull` eine Anmeldung mit entsprechender `read:packages`-Berechtigung erforderlich. Für die Schulung kann das Paket in GitHub unter **Packages** öffentlich sichtbar gemacht werden.

**Hinweis:** Die eingebettete In-Memory-H2-Datenbank speichert keine Daten über einen Container-Neustart hinaus.
