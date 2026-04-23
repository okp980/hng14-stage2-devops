#!/usr/bin/env bash
# End-to-end integration: full Docker Compose stack, job submit via frontend, poll to completion.
# Expects a .env in the repo root (CI writes it) with REDIS_*, API_URL, PORT for Compose services.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
COMPOSE_FILE="${COMPOSE_FILE:-compose.yaml}"

cleanup() {
  echo "Tearing down stack..."
  docker compose -f "$COMPOSE_FILE" down -v --remove-orphans 2>/dev/null || true
}
trap cleanup EXIT

if [[ ! -f .env ]]; then
  echo "No .env found; using defaults for local/CI (Redis + API service URLs)"
  cat > .env << 'EOF'
REDIS_HOST=redis
REDIS_PORT=6379
API_URL=http://api:8000
PORT=3000
EOF
fi

echo "Starting stack (build + up)..."
docker compose -f "$COMPOSE_FILE" up -d --build

echo "Waiting for frontend health..."
for i in $(seq 1 60); do
  if curl -sf "http://localhost:3000/health" > /dev/null; then
    echo "Frontend is up."
    break
  fi
  if [[ "$i" -eq 60 ]]; then
    echo "Timeout waiting for frontend"
    docker compose -f "$COMPOSE_FILE" logs --tail=200
    exit 1
  fi
  sleep 2
done

echo "Submitting job via POST http://localhost:3000/submit (same path as the dashboard)"
RESP=$(curl -sf -X POST "http://localhost:3000/submit" -H "Content-Type: application/json" -d '{}') || {
  echo "Submit request failed"
  docker compose -f "$COMPOSE_FILE" logs --tail=200
  exit 1
}
JOB_ID=$(echo "$RESP" | python3 -c "import sys,json; print(json.load(sys.stdin)['job_id'])")
echo "Job ID: $JOB_ID"

echo "Polling status via GET http://localhost:3000/status/{id} until completed..."
STATUS=""
for i in $(seq 1 45); do
  if ! RAW=$(curl -sf "http://localhost:3000/status/${JOB_ID}"); then
    echo "Status request failed"
    docker compose -f "$COMPOSE_FILE" logs --tail=200
    exit 1
  fi
  STATUS=$(echo "$RAW" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('status') or d.get('error') or '')")

  if [[ "$STATUS" == "completed" ]]; then
    echo "Integration passed: final status is completed"
    exit 0
  fi
  if [[ "$STATUS" == "something went wrong" ]]; then
    echo "Frontend returned error: $RAW"
    docker compose -f "$COMPOSE_FILE" logs --tail=200
    exit 1
  fi
  sleep 2
done

echo "Timeout waiting for completed (last status: ${STATUS:-unknown})"
docker compose -f "$COMPOSE_FILE" logs --tail=200
exit 1
