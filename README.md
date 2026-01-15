# WireGuard Client Setup für Pop!_OS (und andere)

Dieses Skript automatisiert die Einrichtung einer WireGuard-VPN-Verbindung auf Pop!_OS (und anderen Ubuntu-basierten Systemen). Es bereinigt bei Bedarf alte Konfigurationen, um Konflikte zu vermeiden, und richtet die neue Verbindung als systemweiten Dienst ein.

## 🚀 Funktionen

* **Automatische Bereinigung:** Entfernt auf Wunsch alte WireGuard-Verbindungen aus dem NetworkManager (`nmcli`) und systemd (`wg-quick`).
* **Systemd-Integration:** Richtet das VPN als systemd-Service ein, damit es **vor** dem Benutzer-Login startet und Verbindungsabbrüche automatisch neu aufbaut.
* **Keine Dateien herumschieben:** Die Konfiguration wird direkt im Skript hinterlegt – kein hantieren mit externen `.conf`-Dateien nötig.


## 📋 Voraussetzungen

* Pop!_OS (oder Ubuntu/Debian)
* Root-Rechte (sudo)
* Installiertes WireGuard (`sudo apt install wireguard openresolv`)


## 🛠️ Anpassung (Für den Admin)

Bevor Sie das Skript an den Client weitergeben, müssen Sie die WireGuard-Konfiguration eintragen.

1. Öffnen Sie die Datei `setup_vpn.sh` in einem Editor.
2. Suchen Sie den Block zwischen `read -r -d '' WG_CONFIG << EOM` und `EOM`.
3. Ersetzen Sie die Platzhalter mit den echten Schlüsseln und IPs des Clients:
```bash
# ... im Skript Zeile 8 ...
read -r -d '' WG_CONFIG << EOM
[Interface]
PrivateKey = <HIER_DEN_PRIVATE_KEY_DES_CLIENTS_EINFÜGEN>
Address = 10.0.0.2/24
DNS = 10.0.0.1
MTU = 1380

[Peer]
PublicKey = <HIER_DEN_PUBLIC_KEY_DES_SERVERS_EINFÜGEN>
Endpoint = 123.123.123.123:51820
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
EOM
# ...
```

> **Wichtig:** Achten Sie darauf, dass keine Leerzeichen vor oder nach dem `EOM` stehen.

## 💻 Nutzung (Für den Client)

So führen Sie die Installation auf Ihrem Computer aus:

1. Laden Sie das Skript `setup_vpn.sh` herunter (z. B. auf den Desktop).
2. Öffnen Sie das Programm **Terminal**.
3. Geben Sie folgenden Befehl ein (noch nicht Enter drücken):

```bash
sudo bash 
```

*(Achten Sie auf das Leerzeichen nach `bash`)*
4. Ziehen Sie die Datei `setup_vpn.sh` vom Desktop in das Terminal-Fenster. Der Pfad wird automatisch eingefügt.
5. Drücken Sie **Enter** und geben Sie Ihr Passwort ein (es werden keine Sternchen angezeigt).

### Auswahlmenü

Das Skript fragt Sie nun, wie Sie fortfahren möchten:

* **Option 1) ☢️ ALLES LÖSCHEN und neu installieren:**
Wählen Sie dies, wenn Sie Probleme mit alten VPN-Verbindungen haben. Es löscht alle alten WireGuard-Profile und installiert das neue sauber.
* **Option 2) ➕ Nur neues Profil hinzufügen:**
Wählen Sie dies, wenn Sie andere VPNs behalten möchten und nur dieses spezielle Firmen-Profil aktualisieren wollen.


## ✅ Überprüfung \& Steuerung

Nach der Installation ist das VPN sofort aktiv.

**Status prüfen:**

```bash
sudo wg show
```

*(Es sollte unter "latest handshake" eine Zeitangabe stehen, z.B. "1 minute ago")*

**IP-Adresse prüfen (bin ich im VPN?):**

```bash
curl https://ifconfig.me
```

**VPN manuell stoppen/starten:**

```bash
# Stoppen
sudo systemctl stop wg-quick@wg0

# Starten
sudo systemctl start wg-quick@wg0
```


## ❓ Troubleshooting

**Fehler: `resolvconf: command not found`**
Falls dieser Fehler auftritt, fehlt ein kleines Paket für die DNS-Verwaltung. Installieren Sie es mit:

```bash
sudo apt update && sudo apt install openresolv
```

Führen Sie das Skript danach erneut aus.

