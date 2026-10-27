#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${HOME}/.local/share/plasma/plasmoids/org.scorn.projectpulse"
FEED_TARGET="${HOME}/.local/share/plasma/plasmoids/org.scorn.projectpulsefeed"
mkdir -p "$(dirname "$TARGET")"
ln -sfn "$ROOT" "$TARGET"
ln -sfn "$ROOT/feed" "$FEED_TARGET"
printf 'Installed Project Pulse at %s\n' "$TARGET"
printf 'Installed Project Pulse Feed at %s\n' "$FEED_TARGET"
printf 'Add both widgets from the Plasma widget picker.\n'
