#!/bin/bash
set -euo pipefail

WATCH_DIR="${WATCH_DIR:-/watch}"
SCAN_INTERVAL="${SCAN_INTERVAL:-60}"
PDF_PASSWORD="${PDF_PASSWORD:-}"
TEMP_DIR="/tmp/pdf_work"

mkdir -p "$TEMP_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

process_pdf() {
    local pdf_file="$1"
    local filename
    filename=$(basename "$pdf_file")
    local temp_original="$TEMP_DIR/original_${filename}"
    local temp_decrypted="$TEMP_DIR/decrypted_${filename}"

    # Skip if not encrypted
    if ! qpdf --is-encrypted "$pdf_file" > /dev/null 2>&1; then
        return 0
    fi

    log "Encrypted PDF found: $pdf_file"

    # Safety: copy original to temp dir before any modification
    if ! cp "$pdf_file" "$temp_original"; then
        log "ERROR: Could not copy '$pdf_file' to temp dir — skipping"
        return 1
    fi

    # Decrypt into a separate temp file
    if qpdf --decrypt --password="$PDF_PASSWORD" "$temp_original" "$temp_decrypted" 2>/dev/null; then
        # Replace original only after successful decryption
        if mv "$temp_decrypted" "$pdf_file"; then
            log "SUCCESS: '$pdf_file' decrypted and replaced"
            rm -f "$temp_original"
        else
            log "ERROR: Could not replace '$pdf_file' — original preserved in $temp_original"
            rm -f "$temp_decrypted"
            return 1
        fi
    else
        log "ERROR: Decryption failed for '$pdf_file' (wrong password?) — original preserved in $temp_original"
        rm -f "$temp_decrypted"
        return 1
    fi
}

log "PDF decryption monitor started"
log "Watch directory : $WATCH_DIR"
log "Scan interval   : ${SCAN_INTERVAL}s"

while true; do
    while IFS= read -r -d '' pdf_file; do
        process_pdf "$pdf_file" || true
    done < <(find "$WATCH_DIR" -name "*.pdf" -type f -print0 2>/dev/null)

    sleep "$SCAN_INTERVAL"
done
