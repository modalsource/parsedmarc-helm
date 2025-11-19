FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    gcc \
    libxml2-dev \
    libxslt1-dev \
    && rm -rf /var/lib/apt/lists/*

# Install parsedmarc and dependencies
RUN pip install --no-cache-dir \
    parsedmarc \
    opensearch-py \
    kafka-python

# Create parsedmarc user and required directories
RUN useradd -m -u 1000 parsedmarc && \
    mkdir -p /tmp /etc/parsedmarc && \
    chown -R parsedmarc:parsedmarc /app /tmp

# Copy entrypoint script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Switch to non-root user
USER parsedmarc

# Health check (parsedmarc doesn't expose HTTP, so we just check process)
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD pgrep -f parsedmarc || exit 1

# Set entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Default command (will be overridden by Kubernetes deployment)
CMD []
