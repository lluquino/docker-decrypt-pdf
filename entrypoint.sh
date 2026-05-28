#!/bin/bash
set -e

if [ -z "$PDF_PASSWORD" ]; then
    echo "ERROR: PDF_PASSWORD environment variable is required."
    exit 1
fi

# Optional PUID/PGID support
if [ -n "$PUID" ] || [ -n "$PGID" ]; then
    PUID="${PUID:-1000}"
    PGID="${PGID:-1000}"

    echo "Setting up user with PUID=$PUID PGID=$PGID"

    groupadd -f -g "$PGID" appgroup 2>/dev/null || true
    id -u appuser &>/dev/null || useradd -u "$PUID" -g "$PGID" -M -s /bin/bash appuser 2>/dev/null || true

    mkdir -p /tmp/pdf_work
    chown "$PUID:$PGID" /tmp/pdf_work

    exec gosu appuser /app/decrypt_pdfs.sh
fi

exec /app/decrypt_pdfs.sh
