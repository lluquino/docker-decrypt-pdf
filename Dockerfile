FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y \
    qpdf \
    gosu \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY entrypoint.sh /entrypoint.sh
COPY decrypt_pdfs.sh /app/decrypt_pdfs.sh

RUN chmod +x /entrypoint.sh /app/decrypt_pdfs.sh \
    && mkdir -p /watch /tmp/pdf_work

# Required
ENV PDF_PASSWORD=""
# Seconds between scans
ENV SCAN_INTERVAL=60
# Optional: run as specific user/group
ENV PUID=""
ENV PGID=""

VOLUME ["/watch"]

ENTRYPOINT ["/entrypoint.sh"]
