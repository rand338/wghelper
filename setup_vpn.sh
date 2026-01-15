#!/bin/bash

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
if [ "$EUID" -ne 0 ]; then
  echo "❌ Bitte führen Sie dieses Skript mit sudo aus:"
  echo "   sudo bash $0"
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
    echo "📝 [INSTALLATION] Richte $WG_INTERFACE ein..."
    
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
echo "      (Entfernt alle NM-Profile & alle Configs in /etc/wireguard)"
echo ""
echo "2) ➕ Nur neues Profil hinzufügen/überschreiben"
echo "      (Löscht nur bestehendes '${WG_INTERFACE}', lässt andere intakt)"
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
