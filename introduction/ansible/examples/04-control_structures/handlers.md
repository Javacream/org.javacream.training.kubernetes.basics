# Handler

Handler sind spezielle Tasks, die nur dann ausgeführt werden, wenn sie von einem anderen Task benachrichtigt wurden und dieser Task tatsächlich eine Änderung verursacht hat.

Ein typischer Anwendungsfall ist:

```text
Konfigurationsdatei ändern
          │
          ▼
      changed?
       /    \
     nein    ja
      │       │
      │       ▼
      │    Handler
      │       │
      │       ▼
      │   Dienst neu starten
      │
      ▼
   nichts
```

## Einen Handler benachrichtigen

Ein normaler Task kann mit `notify` einen Handler benachrichtigen:

```yaml
- name: Konfigurationsdatei kopieren
  ansible.builtin.copy:
    content: "example configuration\n"
    dest: ./example.conf
  notify: Konfiguration neu laden
```

`notify` bedeutet dabei nicht, dass der Handler sofort ausgeführt wird.

Der Handler wird für eine spätere Ausführung vorgemerkt, wenn der Task den Status `changed` erhält.

## Handler definieren

Handler werden im Play unter `handlers:` definiert:

```yaml
handlers:
  - name: Konfiguration neu laden
    ansible.builtin.debug:
      msg: "Die Konfiguration wurde geändert und der Handler wird ausgeführt"
```

Der Name des Handlers wird von `notify` referenziert:

```yaml
notify: Konfiguration neu laden
```

und

```yaml
- name: Konfiguration neu laden
```

gehören also zusammen.

## Handler werden nur bei Änderungen ausgeführt

Das ist der entscheidende Unterschied zu einem normalen nachfolgenden Task.

Beim ersten Lauf existiert `./example.conf` noch nicht. Das `copy`-Modul erzeugt die Datei und meldet:

```text
changed
```

Dadurch wird der Handler benachrichtigt.

Beim nächsten Lauf entspricht die Datei bereits dem gewünschten Zustand. Das `copy`-Modul muss nichts verändern und meldet:

```text
ok
```

Der Handler wird dann nicht ausgeführt.

## Typischer Einsatz

Handler werden häufig verwendet, wenn eine Änderung eine weitere Aktion notwendig macht.

Ein typisches Beispiel ist eine Konfigurationsdatei eines Dienstes:

```text
Konfiguration unverändert
        │
        └── Dienst muss nicht neu gestartet werden

Konfiguration geändert
        │
        └── Handler startet den Dienst neu
```

Dadurch werden unnötige Aktionen vermieden.

## Zusammenhang mit deklarativem Arbeiten

Handler passen gut zum deklarativen Ansatz von Ansible.

Ein Task beschreibt zunächst den gewünschten Zustand. Nur wenn Ansible diesen Zustand tatsächlich ändern muss, wird über `notify` eine Folgeaktion ausgelöst.

Die wichtigsten Begriffe sind daher:

```text
notify       Handler benachrichtigen
handlers    Handler definieren
changed     Voraussetzung für die Benachrichtigung
```

## Zeitpunkt der Handler-Ausführung

Handler werden nicht direkt nach dem benachrichtigenden Task ausgeführt. Ansible führt vorgemerkte Handler automatisch am Ende der folgenden Abschnitte eines Plays aus:

- `pre_tasks`
- `roles` und `tasks` (gemeinsam)
- `post_tasks`

Wird derselbe Handler innerhalb eines Abschnitts mehrfach benachrichtigt, wird er pro Host nur einmal ausgeführt. Mehrere Handler werden in der Reihenfolge ihrer Definition ausgeführt, nicht in der Reihenfolge der Benachrichtigungen.

## Handler vorzeitig ausführen: `flush_handlers`

Mit `ansible.builtin.meta: flush_handlers` werden alle bis dahin vorgemerkten Handler ausgeführt.

```yaml
tasks:
  - name: Konfiguration kopieren
    ansible.builtin.copy:
      content: "example configuration\n"
      dest: ./example.conf
    notify: Konfiguration neu laden

  - name: Vorgemerkte Handler ausführen
    ansible.builtin.meta: flush_handlers

  - name: Weitere Aufgabe
    ansible.builtin.debug:
      msg: "Die vorgemerkten Handler wurden ausgeführt"
```

Das ist beispielsweise sinnvoll, wenn ein nachfolgender Task voraussetzt, dass ein Dienst bereits mit der neuen Konfiguration läuft.

Nach einem Flush kann ein Handler erneut benachrichtigt und erneut ausgeführt werden. Ohne vorherige Benachrichtigung wird er durch den Flush nicht ausgeführt.

## Handler trotz Fehlern ausführen: `force_handlers`

Schlägt ein nachfolgender Task fehl, werden noch vorgemerkte Handler standardmäßig auf dem betroffenen Host nicht mehr ausgeführt. Dadurch kann beispielsweise eine geänderte Konfigurationsdatei vorliegen, ohne dass der zugehörige Dienst neu gestartet wurde.

Mit `force_handlers: true` lässt sich dieses Verhalten auf Play-Ebene ändern:

```yaml
- hosts: all
  force_handlers: true
  tasks:
    - name: Konfiguration kopieren
      ansible.builtin.copy:
        content: "example configuration\n"
        dest: ./example.conf
      notify: Konfiguration neu laden

    - name: Fehler simulieren
      ansible.builtin.fail:
        msg: "Simulierter Fehler"

  handlers:
    - name: Konfiguration neu laden
      ansible.builtin.debug:
        msg: "Handler wird trotz Task-Fehler ausgeführt"
```

Alternativ kann die Option beim Aufruf gesetzt werden:

```bash
ansible-playbook --force-handlers playbook.yml
```

Oder in der Datei `ansible.cfg`:

```ini
[defaults]
force_handlers = True
```

Auch mit dieser Option werden nur benachrichtigte Handler ausgeführt. Ist ein Host beispielsweise nicht mehr erreichbar, kann die Ausführung trotzdem scheitern.

## Handler können andere Handler benachrichtigen

Auch ein Handler kann mit `notify` einen weiteren Handler benachrichtigen. Voraussetzung ist wiederum der Status `changed`.

```yaml
handlers:
  - name: Nginx neu starten
    ansible.builtin.service:
      name: nginx
      state: restarted
    notify: Nginx prüfen

  - name: Nginx prüfen
    ansible.builtin.uri:
      url: http://localhost
      status_code: 200
```

Wird der erste Handler benachrichtigt und meldet der Neustart eine Änderung, wird auch der zweite Handler benachrichtigt.

Die Handler sollten in der gewünschten Ausführungsreihenfolge definiert werden. Ein nachfolgend definierter Handler kann noch im selben Ausführungszyklus ausgeführt werden. Ein bereits ausgeführter Handler wird innerhalb desselben Zyklus nicht erneut ausgeführt.

## Vertiefung: Weitere eventartige Mechanismen

Handler sind der zentrale eventartige Mechanismus innerhalb normaler Ansible-Playbooks. Es gibt jedoch einige verwandte Konzepte.

### Mehrere Handler mit `listen`

Mit `listen` können mehrere Handler auf denselben logischen Namen reagieren.

Ein Task kann beispielsweise ein Ereignis melden:

```yaml
notify: configuration changed
```

Mehrere Handler können darauf reagieren:

```yaml
handlers:
  - name: Meldung ausgeben
    ansible.builtin.debug:
      msg: "Configuration changed"
    listen: configuration changed

  - name: Weitere Aktion ausführen
    ansible.builtin.debug:
      msg: "Another reaction"
    listen: configuration changed
```

Dadurch kann ein `notify` mehrere Reaktionen auslösen.

Vereinfacht:

```text
Task meldet Änderung
        │
        ▼
notify: configuration changed
        │
        ├──► Handler 1
        │
        └──► Handler 2
```

### `block`, `rescue` und `always`

Mit `block`, `rescue` und `always` kann auf Fehler bei der Ausführung von Tasks reagiert werden.

Das ähnelt einer ereignisgesteuerten Reaktion, gehört aber eher zum Exception Handling als zum Handler-Konzept.

### Callback-Plugins

Ansible besitzt außerdem Callback-Plugins. Diese können auf Ereignisse während einer Ansible-Ausführung reagieren, beispielsweise auf den Start, Erfolg oder Fehler eines Tasks.

Sie werden unter anderem für Logging und angepasste Ausgaben verwendet.

Callback-Plugins sind ein fortgeschrittenes Thema und werden hier nicht weiter behandelt.

### Event-Driven Ansible

Mit Event-Driven Ansible existiert darüber hinaus ein eigener Ansatz, bei dem externe Ereignisse Regeln und Aktionen auslösen können.

Auch dieses Thema geht über normale Playbooks hinaus und wird hier nur der Vollständigkeit halber erwähnt.

