#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$ROOT_DIR/backend"
FRONTEND_DIR="$ROOT_DIR/frontend"
LOG_DIR="$ROOT_DIR/.logs"

mkdir -p "$LOG_DIR"

backend_log="$LOG_DIR/backend.log"
frontend_log="$LOG_DIR/frontend.log"

port_in_use() {
  local port="$1"
  ss -ltn "( sport = :$port )" | tail -n +2 | grep -q .
}

pick_backend_port() {
  if [[ -n "${SERVER_PORT:-}" ]]; then
    printf '%s\n' "$SERVER_PORT"
    return
  fi

  if port_in_use 8080; then
    printf '8081\n'
  else
    printf '8080\n'
  fi
}

pick_frontend_port() {
  if [[ -n "${VITE_DEV_PORT:-}" ]]; then
    printf '%s\n' "$VITE_DEV_PORT"
    return
  fi

  if port_in_use 5173; then
    printf '5174\n'
  else
    printf '5173\n'
  fi
}

wait_for_http() {
  local name="$1"
  local url="$2"
  local pid="$3"
  local log_file="$4"
  local attempts=60

  for _ in $(seq 1 "$attempts"); do
    if ! kill -0 "$pid" 2>/dev/null; then
      printf '\n%s failed to start. Last log lines:\n' "$name" >&2
      tail -n 40 "$log_file" >&2 || true
      return 1
    fi

    if curl -s -o /dev/null "$url"; then
      return 0
    fi

    sleep 1
  done

  printf '\nTimed out waiting for %s at %s. Last log lines:\n' "$name" "$url" >&2
  tail -n 40 "$log_file" >&2 || true
  return 1
}

cleanup() {
  local exit_code="$?"

  if [[ -n "${FRONTEND_PID:-}" ]] && kill -0 "$FRONTEND_PID" 2>/dev/null; then
    kill "$FRONTEND_PID" 2>/dev/null || true
  fi

  if [[ -n "${BACKEND_PID:-}" ]] && kill -0 "$BACKEND_PID" 2>/dev/null; then
    kill "$BACKEND_PID" 2>/dev/null || true
  fi

  wait "${FRONTEND_PID:-}" 2>/dev/null || true
  wait "${BACKEND_PID:-}" 2>/dev/null || true

  exit "$exit_code"
}

trap cleanup EXIT INT TERM

BACKEND_PORT="$(pick_backend_port)"
FRONTEND_PORT="$(pick_frontend_port)"

export SERVER_PORT="$BACKEND_PORT"
export SPRING_DATASOURCE_URL="${SPRING_DATASOURCE_URL:-jdbc:mysql://localhost:3306/eldercare?useUnicode=true&characterEncoding=utf-8&serverTimezone=Asia/Shanghai}"
export SPRING_DATASOURCE_USERNAME="${SPRING_DATASOURCE_USERNAME:-root}"
export SPRING_DATASOURCE_PASSWORD="${SPRING_DATASOURCE_PASSWORD:-root1234}"
export SPRING_DATA_REDIS_HOST="${SPRING_DATA_REDIS_HOST:-localhost}"
export SPRING_DATA_REDIS_PORT="${SPRING_DATA_REDIS_PORT:-6379}"
export VITE_API_PROXY_TARGET="${VITE_API_PROXY_TARGET:-http://localhost:${BACKEND_PORT}}"
export VITE_DEV_PORT="$FRONTEND_PORT"

if [[ ! -d "$FRONTEND_DIR/node_modules" ]] || [[ -z "$(ls -A "$FRONTEND_DIR/node_modules" 2>/dev/null)" ]]; then
  printf 'Installing frontend dependencies...\n'
  (
    cd "$FRONTEND_DIR"
    npm install
  )
fi

: > "$backend_log"
: > "$frontend_log"

printf 'Starting backend on port %s...\n' "$BACKEND_PORT"
(
  cd "$BACKEND_DIR"
  mvn spring-boot:run
) >"$backend_log" 2>&1 &
BACKEND_PID=$!

wait_for_http "Backend" "http://localhost:${BACKEND_PORT}" "$BACKEND_PID" "$backend_log"

printf 'Starting frontend on port %s...\n' "$FRONTEND_PORT"
(
  cd "$FRONTEND_DIR"
  npm run dev -- --host 0.0.0.0
) >"$frontend_log" 2>&1 &
FRONTEND_PID=$!

wait_for_http "Frontend" "http://localhost:${FRONTEND_PORT}" "$FRONTEND_PID" "$frontend_log"

printf '\nLocal development is ready.\n'
printf 'Frontend: http://localhost:%s\n' "$FRONTEND_PORT"
printf 'Backend:  http://localhost:%s\n' "$BACKEND_PORT"
printf 'Logs:     %s and %s\n' "$backend_log" "$frontend_log"
printf 'Press Ctrl+C to stop both services.\n\n'

wait "$BACKEND_PID" "$FRONTEND_PID"
