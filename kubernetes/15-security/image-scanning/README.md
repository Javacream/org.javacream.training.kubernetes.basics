# Image-Scanning mit Trivy

Voraussetzung: Trivy CLI auf der Trainings-VM installiert (offizielle Anleitung: https://trivy.dev/latest/getting-started/installation/), Internetzugriff für Image und Vulnerability-Datenbank. Keine Installation im Kubernetes-Cluster notwendig.

```bash
trivy --version
trivy image --scanners vuln --severity HIGH,CRITICAL nginx:stable
```

Die Ausgabe zeigt betroffene Pakete, CVE-IDs, installierte und gegebenenfalls korrigierte Versionen. Ergebnisse hängen vom Image-Digest und Datenbankstand ab. Keine konkreten Treffer voraussetzen.

Optional: CI-Prüfung mit Exit-Code 1 bei kritischen Schwachstellen:

```bash
trivy image --scanners vuln --severity CRITICAL --exit-code 1 nginx:stable
```

Ein Treffer ist kein automatischer Beweis für Ausnutzbarkeit. Fix-Verfügbarkeit und Anwendungskontext prüfen. Nach einem Patch erneut bauen, scannen und kontrolliert ausrollen. Ein leerer Bericht garantiert keine Sicherheit.
