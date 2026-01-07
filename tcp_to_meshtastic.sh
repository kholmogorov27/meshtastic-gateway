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