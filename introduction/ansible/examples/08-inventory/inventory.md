# Inventory, Gruppen und Variablen

Das Inventory beschreibt, auf welchen Managed Nodes Ansible arbeiten soll.

Das lokale Inventory dieses Beispiels gruppiert die Kubernetes-Nodes. Die SSH-Verbindungsparameter stehen in der vollständigen Datei `inventory.ini`. Vereinfacht:

```ini
[workers]
k3s-agent-1
k3s-agent-2

[control_plane]
k3s-server
```

Mit Gruppen können Plays gezielt auf mehrere Hosts angewendet werden:

```yaml
hosts: workers
```

## Gruppen von Gruppen

Mit `:children` können Gruppen wiederum zu einer übergeordneten Gruppe zusammengefasst werden:

```ini
[kubernetes:children]
workers
control_plane
```

Damit kann ein Play beispielsweise auf alle Hosts der Gruppe `kubernetes` angewendet werden.

## `group_vars`

Variablen, die für eine ganze Gruppe gelten, können in einem Verzeichnis `group_vars` abgelegt werden.

Beispiel:

```text
group_vars/
└── kubernetes.yml
```

```yaml
application_port: 8080
```

Diese Variable steht den Hosts der Gruppe `kubernetes` zur Verfügung.

## `host_vars`

Variablen für einen einzelnen Host können analog in `host_vars` abgelegt werden:

```text
host_vars/
└── k3s-agent-1.yml
```

```yaml
application_name: worker-1
```

Damit lassen sich allgemeine Gruppenwerte mit hostspezifischen Einstellungen kombinieren.

## Beispiel ausführen

Aus dem Verzeichnis `08-inventory`:

```bash
ansible-playbook -i inventory.ini inventory_variables.yml
```

Das Playbook verwendet `hosts: all`. Die Gruppenvariable `application_port` gilt für alle drei Nodes; `application_name` ist nur für `k3s-agent-1` definiert.
