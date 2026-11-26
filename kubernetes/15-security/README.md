# Kubernetes-Sicherheit und betriebliche Anforderungen

## Lernziele
Zugriffsschutz, Netzwerkisolation, Workload-Sicherheit und Schwachstellenmanagement einordnen. Die Beispiele dienen ausschließlich dem Trainingscluster.

## 1. Identität und Autorisierung
ServiceAccounts sind Identitäten für Workloads. RBAC vergibt additive Rechte über Role/ClusterRole und RoleBinding/ClusterRoleBinding. Eine Role ist Namespace-bezogen; eine ClusterRole kann clusterweite oder wiederverwendbare Regeln enthalten. RoleBindings begrenzen Rechte auf ihren Namespace. ClusterRoleBindings wirken clusterweit. Least Privilege: nur benötigte Verben und Ressourcen erlauben. Praktische Demonstration: [rbac/rbac.ipynb](rbac/rbac.ipynb).

## 2. Netzwerksicherheit
Pods sind ohne isolierende NetworkPolicies grundsätzlich gegenseitig erreichbar. Policies selektieren Pods und erlauben Traffic additiv. Die Durchsetzung setzt ein geeignetes Netzwerk-Plugin voraus. Ingress und Egress werden getrennt betrachtet. TLS schützt Transportdaten; NetworkPolicies verschlüsseln nicht. Demonstration: [network-policies/network-policies.ipynb](network-policies/network-policies.ipynb).

## 3. Workload-Sicherheit
SecurityContext: runAsNonRoot, allowPrivilegeEscalation: false, readOnlyRootFilesystem, minimale Linux-Capabilities, seccompProfile RuntimeDefault. Anwendungen müssen diese Einschränkungen unterstützen. Privilegierte Container und Host-Mounts vermeiden. Pod Security Admission kann Baseline- oder Restricted-Anforderungen durchsetzen. Beispiel: [security-context.yml](security-context.yml).

## 4. Secrets und Verschlüsselung
Base64 ist keine Verschlüsselung. Zugriff per RBAC begrenzen; Verschlüsselung at rest für API-Daten konfigurieren und überprüfen. TLS für Übertragung, externe Secret-Verwaltung und Rotation erwägen. Keine echten Zugangsdaten in Git, Logs oder Notebooks speichern. Siehe Kapitel 07.

## 5. CVEs und Image-Scanning
CVE identifiziert veröffentlichte Schwachstellen. CVSS bewertet technische Schwere; tatsächliches Risiko hängt von Erreichbarkeit, Nutzung und Gegenmaßnahmen ab. Images, Abhängigkeiten und Betriebssystempakete regelmäßig scannen. SBOM dokumentiert Komponenten; Signaturen und Provenance unterstützen Lieferkettensicherheit. [Trivy-Demonstration](image-scanning/README.md).

## 6. Patch-Management und Compliance
Inventar pflegen, Schwachstellen priorisieren, Images neu bauen und testen, Updates kontrolliert ausrollen und Ergebnisse verifizieren. Cluster-Komponenten und Nodes separat pflegen. Keine produktiven Images mit unkontrollierten latest-Tags betreiben. Compliance verlangt nachvollziehbare Richtlinien, Verantwortlichkeiten, Nachweise und geregelte Ausnahmen; ein Scan allein belegt keine Compliance.

## 7. Sicherheitsüberwachung und Betrieb
Audit-Logs, Anwendungslogs, Events, Metriken und Laufzeitüberwachung kombinieren. Alarme mit Verantwortlichen, Eskalation und Incident-Response-Prozess verbinden. Backups und Wiederherstellung testen. Plattformteam verantwortet Cluster-Konfiguration und Updates; Anwendungsteams verantworten Images, Konfiguration und fachliche Sicherheit. Verantwortlichkeiten organisationsspezifisch festlegen.

## Ablauf (90 Minuten)
RBAC 20, Netzwerk 20, Workload/Secrets 15, Scanning 15, Patch/Compliance/Überwachung 20 Minuten. Demonstrationen bei Zeitbedarf kürzen.
