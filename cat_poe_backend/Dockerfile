FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    postgresql-client \
    curl \
    && rm -rf /var/lib/apt/lists/*


# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Create logs directory
RUN mkdir -p /app/logs

# Expose port
EXPOSE 8000

# Run with uvicorn.
#
# --proxy-headers makes Starlette honour X-Forwarded-Proto / X-Forwarded-For,
# which the reverse proxy already sets. Without it uvicorn believes every
# request arrived over plain http, so FastAPI's automatic trailing-slash
# redirect answers an https request with an absolute http:// Location — an
# outright downgrade. Dart's HttpClient follows same-host redirects and keeps
# the Authorization header, so a bearer token would be sent in cleartext, and
# release builds (cleartextTrafficPermitted=false) simply fail the request.
#
# --forwarded-allow-ips=* is safe here because this service publishes no host
# ports; it is reachable only from the compose network, so the only client that
# can set those headers is our own proxy. Narrow it if that ever changes.
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", \
     "--proxy-headers", "--forwarded-allow-ips", "*"]
