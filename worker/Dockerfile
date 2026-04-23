ARG PYTHON_VERSION=3.13.2

FROM python:${PYTHON_VERSION}-slim as base
ENV PYTHONDONTWRITEBYTECODE=1

ENV PYTHONUNBUFFERED=1

WORKDIR /app

FROM base as builder

COPY requirements.txt .

RUN pip install --no-cache-dir --upgrade -r requirements.txt

FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
WORKDIR /app
ARG UID=10001
RUN adduser \
    --disabled-password \
    --gecos "" \
    --home "/nonexistent" \
    --shell "/sbin/nologin" \
    --no-create-home \
    --uid "${UID}" \
    appuser

# Copy the Python dependencies from the builder stage
COPY --from=builder /usr/local/lib/python3.13/site-packages/ /usr/local/lib/python3.13/site-packages/
COPY --from=builder /usr/local/bin/ /usr/local/bin/
ENV PATH="/install/bin:$PATH"

# Copy application code
COPY ./worker.py .

RUN chown -R appuser:appuser /app

# Switch to the non-privileged user to run the application.
USER appuser

# Run the application.
CMD ["python", "worker.py"]