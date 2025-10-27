# Build stage
FROM python:3.9-slim as builder

WORKDIR /app

# Install build dependencies (only what's needed for compilation)
RUN apt-get update && apt-get install -y \
    --no-install-recommends \
    gcc \
    g++ \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first for better layer caching
COPY requirements.txt .

# Install Python dependencies with user flag
RUN pip install --no-cache-dir --user -r requirements.txt

# Runtime stage
FROM python:3.9-slim as runtime

# Create non-root user for security
RUN groupadd -r appuser && useradd -r -g appuser appuser

WORKDIR /app

# Copy Python packages from builder stage
COPY --from=builder /root/.local /home/appuser/.local

# Copy application code (excluding unnecessary files via .dockerignore)
COPY . .

# Remove any cache and temporary files
RUN find . -type d -name __pycache__ -exec rm -rf {} + || true && \
    find . -type f -name "*.pyc" -delete || true

# Change ownership to non-root user (including the copied packages)
RUN chown -R appuser:appuser /app /home/appuser/.local

# Switch to non-root user
USER appuser

# Add local Python packages to PATH and PYTHONPATH
ENV PATH=/home/appuser/.local/bin:$PATH
ENV PYTHONPATH=/home/appuser/.local/lib/python3.9/site-packages
ENV PYTHONUSERBASE=/home/appuser/.local

# Environment variables that can be overridden at runtime
ENV FLASK_ENV=production
ENV FLASK_DEBUG=0
ENV PORT=5000
ENV HOST=0.0.0.0

# Expose the port
EXPOSE $PORT

# Health check with proper startup time and using Python instead of curl
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD python -c "import socket; sock = socket.socket(); sock.settimeout(5); result = sock.connect_ex(('localhost', int('$PORT'))); sock.close(); exit(0 if result == 0 else 1)"

# Use ENTRYPOINT + CMD for better flexibility
ENTRYPOINT ["python"]
CMD ["app.py"]