# ===========================================================================
# Self-Driving Agent Platform
# ===========================================================================

FROM agnohq/python:3.12

# ---------------------------------------------------------------------------
# System dependencies
# ---------------------------------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
        curl \
    && rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------------------------------
# Application code
# ---------------------------------------------------------------------------
WORKDIR /app
ENV PYTHONPATH=/app
COPY requirements.txt ./
# UV_PRERELEASE=allow is needed while agno is pinned to the 2.7.0a1 alpha (it pulls
# the agnoctl>=0.1.0a1 prerelease). Drop it when the pin loosens at 2.7 stable.
RUN UV_PRERELEASE=allow uv pip sync requirements.txt --system
COPY . .

# ---------------------------------------------------------------------------
# Entrypoint
# ---------------------------------------------------------------------------
RUN chmod +x /app/scripts/entrypoint.sh
ENTRYPOINT ["/app/scripts/entrypoint.sh"]

# ---------------------------------------------------------------------------
# Default command (overridden by compose for dev)
# ---------------------------------------------------------------------------
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
