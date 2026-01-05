# TCP → Meshtastic Gateway Installer

This installer sets up a **systemd socket-activated TCP gateway** that forwards incoming TCP messages directly to a Meshtastic node using the Meshtastic CLI.

## Features

- Socket-activated (systemd) — no daemon running when idle
- One message per TCP connection
- Uses official Meshtastic CLI
- Secure systemd sandboxing
- Simple TCP interface (works with `nc`, scripts, or IoT devices)

## How It Works

1. systemd listens on a TCP port (default: `5555`)
2. Each incoming connection spawns a service instance
3. The service:
   - Reads one line from the socket
   - Sends it via `meshtastic --sendtext`
   - Exits immediately

## Requirements

- Debian / Ubuntu (or compatible)
- `systemd`
- Python 3
- Root access
- A working Meshtastic device already configured and accessible by the Meshtastic CLI

## Usage

Send a message by opening a TCP connection and writing a single line.

Example

```bash
echo "Hello mesh!" | nc gateway.ip 5555
```

Each connection sends exactly one message.

## Logging

View logs with:

```bash
journalctl -u tcp-to-meshtastic@*
```

Live view:

```bash
journalctl -f -u tcp-to-meshtastic@*
```

## Uninstall

```bash
sudo systemctl disable --now tcp-to-meshtastic.socket
sudo rm /etc/systemd/system/tcp-to-meshtastic.socket
sudo rm /etc/systemd/system/tcp-to-meshtastic@.service
sudo rm /usr/local/bin/tcp_to_meshtastic.sh
sudo systemctl daemon-reload
```