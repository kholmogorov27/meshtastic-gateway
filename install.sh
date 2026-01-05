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

# --- Create TCP -> Meshtastic script ---
echo "[+] Creating script $SCRIPT_PATH..."
sudo tee "$SCRIPT_PATH" >/dev/null <<EOF
#!/usr/bin/env bash

MESHTASTIC_CMD="$HOME_DIR/.local/bin/meshtastic"
MESHTASTIC_ARGS="--sendtext"

# Read one line per TCP connection, then exit
if IFS= read -r MESSAGE; then
    # Empty message → consider it "ignored" but successful
    [[ -z "\$MESSAGE" ]] && { echo "No message received"; exit 0; }

    echo "Received: \$MESSAGE"

    # Send message via Meshtastic
    if "\$MESHTASTIC_CMD" \$MESHTASTIC_ARGS "\$MESSAGE"; then
        echo "Message sent successfully"
        exit 0  # Success
    else
        echo "Failed to send message" >&2
        exit 1  # Failure
    fi
else
    echo "No input received" >&2
    exit 2  # Read failed
fi
EOF

sudo chmod +x "$SCRIPT_PATH"

# --- Create systemd service unit ---
echo "[+] Creating systemd service unit $SERVICE_UNIT..."
sudo tee "$SERVICE_UNIT" >/dev/null <<EOF
[Unit]
Description=TCP to Meshtastic Gateway (connection %i)
After=network.target

[Service]
Type=simple
User=$USER
Environment="PATH=$HOME_DIR/.local/bin:/usr/local/bin:/usr/bin"
ExecStart=$SCRIPT_PATH
StandardInput=socket
StandardOutput=socket
StandardError=journal
NoNewPrivileges=true
ProtectSystem=full
ProtectHome=read-only
PrivateTmp=true
BindReadOnlyPaths=$HOME_DIR/.local/bin/meshtastic
EOF

# --- Create systemd socket unit ---
echo "[+] Creating systemd socket unit $SOCKET_UNIT..."
sudo tee "$SOCKET_UNIT" >/dev/null <<EOF
[Unit]
Description=TCP Socket for Meshtastic Gateway

[Socket]
ListenStream=$LISTEN_PORT
Accept=yes
Service=tcp-to-meshtastic@.service

[Install]
WantedBy=sockets.target
EOF

# --- Enable and start socket ---
echo "[+] Enabling and starting socket..."
sudo systemctl daemon-reload
sudo systemctl enable tcp-to-meshtastic.socket
sudo systemctl start tcp-to-meshtastic.socket
sudo systemctl restart tcp-to-meshtastic.socket

echo
echo "[+] Installation complete!"