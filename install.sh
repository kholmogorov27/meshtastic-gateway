#!/usr/bin/env bash
set -euo pipefail

# --- Configuration ---
USER="root"
HOME_DIR="/root"
SCRIPT_PATH="/usr/local/bin/tcp_to_meshtastic.sh"
SOCKET_UNIT="/etc/systemd/system/tcp-to-meshtastic.socket"
SERVICE_UNIT="/etc/systemd/system/tcp-to-meshtastic@.service"

read -rp "Enter the port to listen on [default: 5555]: " PORT_INPUT
LISTEN_PORT="${PORT_INPUT:-5555}"

# --- Ensure pipx is installed ---
if ! command -v pipx &>/dev/null; then
    echo "[+] Installing pipx..."
    sudo apt update
    sudo apt install -y python3-pip python3-venv pipx
    python3 -m pipx ensurepath
fi

# --- Install Meshtastic CLI for the user ---
echo "[+] Installing Meshtastic CLI for $USER..."
sudo -u "$USER" -H bash -c 'pipx install meshtastic --force'

# --- Create TCP→Meshtastic script ---
echo "[+] Creating script $SCRIPT_PATH..."
sudo install -m 0755 ./tcp_to_meshtastic.sh "$SCRIPT_PATH"

# --- Create systemd service unit ---
echo "[+] Creating systemd service unit $SERVICE_UNIT..."
sudo install -m 0755 ./tcp-to-meshtastic.service "$SERVICE_UNIT"

# --- Create systemd socket unit ---
echo "[+] Creating systemd socket unit $SOCKET_UNIT..."
sudo install -m 0755 ./tcp-to-meshtastic.socket "$SOCKET_UNIT"

# --- Enable and start socket ---
echo "[+] Enabling and starting socket..."
sudo systemctl daemon-reload
sudo systemctl enable tcp-to-meshtastic.socket
sudo systemctl start tcp-to-meshtastic.socket
sudo systemctl restart tcp-to-meshtastic.socket

echo "[+] Installation complete!"