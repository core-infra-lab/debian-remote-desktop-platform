#!/bin/sh

set -eu

USERNAME="${1:-radandri}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
POST_INSTALL_DIR="$SCRIPT_DIR/post_install.d"

if [ ! -d "$POST_INSTALL_DIR" ]; then
    echo "Dossier $POST_INSTALL_DIR introuvable." >&2
    exit 1
fi

found_script=0

for script in "$POST_INSTALL_DIR"/*.sh; do
    if [ ! -f "$script" ]; then
        continue
    fi

    found_script=1
    echo "Execution de $(basename "$script")..."
    chmod +x "$script"
    "$script" "$USERNAME"
done

if [ "$found_script" -eq 0 ]; then
    echo "Aucun script post-install a executer."
fi
