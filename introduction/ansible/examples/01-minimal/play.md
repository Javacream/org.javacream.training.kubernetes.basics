# Plays in einem Ansible Playbook

## Was ist ein Play?

Ein **Play** beschreibt, auf welchen Managed Nodes Ansible arbeiten soll und welche Aktionen dort ausgeführt werden sollen.

Ein Playbook besteht aus einer **Liste von Plays**. Die Listenelemente werden in YAML durch einen Bindestrich (`-`) gekennzeichnet.

Ein minimales Play kann beispielsweise so aussehen:

```yaml
- name: Erstes Play
  hosts: all
```

`name` gibt dem Play einen beschreibenden Namen.

Mit `hosts` wird festgelegt, für welche Hosts beziehungsweise Hostgruppen aus dem Inventory das Play ausgeführt werden soll.

## Mehrere Plays in einem Playbook

Ein Playbook kann mehrere Plays enthalten:

```yaml
---
- name: Webserver
  hosts: all

- name: Datenbankserver
  hosts: all
```

Die beiden Bindestriche vor `name` zeigen, dass die oberste Struktur des YAML-Dokuments eine Liste mit zwei Elementen ist.

Ansible interpretiert jedes dieser Listenelemente als ein eigenes Play.

Vereinfacht dargestellt:

```text
Playbook
│
├── Play 1
│   ├── name: Webserver
│   └── hosts: all
│
└── Play 2
    ├── name: Datenbankserver
    └── hosts: all
```

Es gibt im Playbook also keinen Schlüssel `plays:`. Die Liste der Plays bildet direkt die oberste Struktur des YAML-Dokuments.

## Ausführung

Das Playbook wird mit `ansible-playbook` ausgeführt:

```bash
ansible-playbook multiple_plays.yml
```

Ansible verarbeitet die Plays in der Reihenfolge, in der sie im Playbook definiert sind.

Beide Plays richten sich mit `hosts: all` an alle Hosts des Inventories. Grundsätzlich können einzelne Plays auch unterschiedliche Hosts oder Hostgruppen adressieren.

Da wir noch keine eigenen Tasks definiert haben, ist insbesondere das automatische `Gathering Facts` bei jedem Play zu beobachten.
