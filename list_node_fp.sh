#!/usr/bin/env bash
# ==============================================================================
# pve-fingerprints.sh
# Liest SSL-Fingerprints aller Cluster-Nodes aus /etc/pve/nodes/pve*
# Keine SSH-Verbindungen, läuft lokal auf einem Cluster-Node.
# ==============================================================================
# Version: 1.2 — nullglob fix + Robustheit
# ==============================================================================

set -euo pipefail

GREEN="\033[0;32m"
YELLOW="\033[1;33m"
CYAN="\033[0;36m"
RESET="\033[0m"

echo -e "${CYAN}=== Proxmox Node Fingerprint Checker (lokal) ===${RESET}\n"

# Prüfen, ob Cluster-Verzeichnis vorhanden ist
if [ ! -d "/etc/pve/nodes" ]; then
    echo -e "${YELLOW}❌ Kein /etc/pve/nodes-Verzeichnis gefunden. Läuft dieses System in einem Proxmox-Cluster?${RESET}"
    exit 1
fi

# Nullglob aktivieren: ungematchte Muster liefern keine Einträge (anstatt das Muster als Literal)
shopt -s nullglob

# Nodes finden (nur Verzeichnisse, die mit pve beginnen)
node_dirs=(/etc/pve/nodes/*)

# Falls du andere Namen hast (z. B. node1, pve-xyz), passe das Muster an oder nutze /* für alle
# node_dirs=(/etc/pve/nodes/*)

# Prüfen, ob etwas gefunden wurde
if [ "${#node_dirs[@]}" -eq 0 ]; then
    echo -e "${YELLOW}⚠️  Keine Nodes unter /etc/pve/nodes/* gefunden.${RESET}"
    echo "Verfügbare Einträge in /etc/pve/nodes/:"
    ls -1 /etc/pve/nodes || true
    exit 0
fi

# Fingerprints auslesen
for node_dir in "${node_dirs[@]}"; do
    NODE_NAME=$(basename "$node_dir")
    CERT_FILE="$node_dir/pve-ssl.pem"

    echo -e "${GREEN}=== Node: $NODE_NAME ===${RESET}"

    if [ -f "$CERT_FILE" ]; then
        # Ausgabe ohne Fehlerdetails zur Sauberkeit; falls openssl scheitert, zeigen wir Hinweis
        if ! openssl x509 -noout -fingerprint -sha256 -in "$CERT_FILE" 2>/dev/null; then
            echo "⚠️  Fehler beim Lesen des Zertifikats: $CERT_FILE"
        fi
    else
        echo -e "⚠️  Kein Zertifikat gefunden unter: $CERT_FILE"
    fi

    echo
done

echo -e "${CYAN}Fertig.${RESET}"
