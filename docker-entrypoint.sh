#!/bin/bash
# Docker entrypoint for kiro-gateway
#
# Solves the token refresh race condition (Issue #203):
# When both kiro-cli (host) and kiro-gateway (container) share the same SQLite DB,
# each token refresh invalidates the other's access token, causing 403 loops.
#
# Solution: Copy the seed database at startup so the container has its own
# independent token lifecycle. The host DB is mounted read-only as a seed.

set -e

SEED_DB="${KIRO_CLI_DB_SEED:-}"
TARGET_DIR="/home/kiro/.local/share/kiro-cli"
TARGET_DB="${TARGET_DIR}/data.sqlite3"

# If a seed database path is provided, copy it for independent token lifecycle
if [ -n "$SEED_DB" ] && [ -f "$SEED_DB" ]; then
    mkdir -p "$TARGET_DIR"
    cp "$SEED_DB" "$TARGET_DB"
    chmod 600 "$TARGET_DB"
    echo "[entrypoint] Copied seed DB from $SEED_DB → $TARGET_DB (independent token lifecycle)"

    # Point the gateway at the local copy (if not already set)
    if [ -z "$KIRO_CLI_DB_FILE" ]; then
        export KIRO_CLI_DB_FILE="$TARGET_DB"
    fi
fi

# Run the main application
exec python main.py
