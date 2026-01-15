# \#!/bin/bash

# --- KONFIGURATION ---

# Name des neuen Interfaces (z.B. wg0, firma, vpn)

WG_INTERFACE="wg0"

# HIER IHRE CONFIG EINFÜGEN

# Achten Sie darauf, dass 'Address', 'PrivateKey' und 'Endpoint' korrekt sind.

read -r -d '' WG_CONFIG << EOM
[Interface]
PrivateKey = sadADADAsdasdASDASDASDASDASDADASDASDASDASDA=
Address = 10.0.0.2/24
DNS = 10.0.0.1
MTU = 1380

[Peer]
PublicKey = ASDASDASDASDASDASDASDASDASDASDASDASDASDASDAS=
Endpoint = 123.123.123.123:51820
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25

EOM

# ---------------------

# Root-Rechte prüfen

if [ "\$EUID" -ne 0 ]; then
echo "❌ Bitte führen Sie dieses Skript mit sudo aus:"
echo "   sudo bash \$0"
exit 1
fi

function remove_all_vpns() {
echo "🧹 [BEREINIGUNG] Starte vollständige Entfernung..."

    # 1. NetworkManager WireGuard Verbindungen löschen
    echo "   - Prüfe NetworkManager..."
    CONNECTIONS=$(nmcli -f UUID,TYPE connection show | grep wireguard | awk '{print $1}')
    if [ -n "$CONNECTIONS" ]; then
        echo "$CONNECTIONS" | while read uuid; do
            echo "     Lösche NM-Verbindung: $uuid"
            nmcli connection delete "$uuid" > /dev/null 2>&1
        done
    else
        echo "     Keine NM-WireGuard-Einträge gefunden."
    fi
    
    
    # 2. Laufende WireGuard Interfaces stoppen (wg-quick)
    echo "   - Stoppe aktive System-Tunnel..."
    # Stoppt alle Services, die mit wg-quick@ anfangen
    systemctl stop "wg-quick@*" 2>/dev/null
    
    # Sicherheitshalber manuell Interfaces down nehmen, falls nicht über systemd gestartet
    ACTIVE_WG=$(ip link show type wireguard | awk -F: '{print $2}' | xargs)
    if [ -n "$ACTIVE_WG" ]; then
        for iface in $ACTIVE_WG; do
            echo "     Fahre Interface herunter: $iface"
            ip link set "$iface" down 2>/dev/null
            ip link delete "$iface" 2>/dev/null
        done
    fi
    
    
    # 3. Config-Dateien löschen
    echo "   - Lösche Dateien in /etc/wireguard/..."
    # Wir löschen sicherheitshalber alles, wie angefordert
    rm -f /etc/wireguard/*.conf
    
    # Systemd-Reload, um gelöschte Units zu vergessen
    systemctl daemon-reload
    systemctl reset-failed
    echo "✅ Bereinigung abgeschlossen."
    }

function install_vpn() {
echo "📝 [INSTALLATION] Richte \$WG_INTERFACE ein..."

    CONFIG_PATH="/etc/wireguard/${WG_INTERFACE}.conf"
    
    # Config schreiben
    echo "$WG_CONFIG" > "$CONFIG_PATH"
    
    # Rechte setzen (Wichtig für Private Key Sicherheit)
    chmod 600 "$CONFIG_PATH"
    echo "   - Konfiguration geschrieben nach $CONFIG_PATH"
    
    
    # Service aktivieren und starten
    echo "🚀 [AKTIVIERUNG] Starte Tunnel..."
    systemctl enable "wg-quick@${WG_INTERFACE}" --now
    
    sleep 2
    
    # Status prüfen
    if systemctl is-active --quiet "wg-quick@${WG_INTERFACE}"; then
        echo "✅ VPN '$WG_INTERFACE' ist AKTIV und läuft als System-Dienst."
        echo "   Status-Check: sudo wg show"
    else
        echo "❌ Fehler: Der Dienst konnte nicht gestartet werden."
        echo "   Bitte prüfen Sie: systemctl status wg-quick@${WG_INTERFACE}"
        exit 1
    fi
    }

# --- HAUPTMENÜ ---

clear
echo "=========================================="
echo "   WireGuard Setup Helper (Pop!_OS)"
echo "=========================================="
echo "1) ☢️  ALLES LÖSCHEN und neu installieren"
echo "      (Entfernt alle NM-Profile \& alle Configs in /etc/wireguard)"
echo ""
echo "2) ➕ Nur neues Profil hinzufügen/überschreiben"
echo "      (Löscht nur bestehendes '\${WG_INTERFACE}', lässt andere intakt)"
echo "=========================================="
echo -n "Ihre Wahl (1 oder 2): "
read choice

case $choice in
    1)
        remove_all_vpns
        install_vpn
        ;;
    2)
        echo "⚠️  Überspringe vollständige Bereinigung..."
        # Wir stoppen zumindest diesen spezifischen Tunnel, falls er läuft
        systemctl stop "wg-quick@${WG_INTERFACE}" 2>/dev/null
install_vpn
;;
*)
echo "Ungültige Eingabe. Abbruch."
exit 1
;;
esac

gib mir für das script bitte eine github typische readme mit der erklärung wie man das wireguard client profile einfügt bzw. das script verwendet

Hier ist eine saubere, GitHub-typische `README.md` für Ihr Skript. Sie ist so strukturiert, dass sie sowohl für Sie (zum Anpassen) als auch für den Endanwender (zum Ausführen) verständlich ist.

Sie können diesen Text einfach als `README.md` abspeichern.

***

# WireGuard Client Setup für Pop!_OS

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

