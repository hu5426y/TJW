#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$ROOT_DIR/backend"
FRONTEND_DIR="$ROOT_DIR/frontend"
LOG_DIR="$ROOT_DIR/.logs"
RUNTIME_ENV_FILE="$ROOT_DIR/.docker-runtime.env"

mkdir -p "$LOG_DIR"

backend_log="$LOG_DIR/backend.log"
frontend_log="$LOG_DIR/frontend.log"

port_in_use() {
  local port="$1"
  ss -ltn "( sport = :$port )" | tail -n +2 | grep -q .
}

pick_port() {
  local preferred="$1"
  local fallback="$2"
  local provided="${3:-}"

  if [[ -n "$provided" ]]; then
    printf '%s\n' "$provided"
    return
  fi

  if port_in_use "$preferred"; then
    printf '%s\n' "$fallback"
  else
    printf '%s\n' "$preferred"
  fi
}

pick_first_free_port() {
  local start="$1"
  local end="$2"
  local provided="${3:-}"
  local port

  if [[ -n "$provided" ]]; then
    printf '%s\n' "$provided"
    return
  fi

  for port in $(seq "$start" "$end"); do
    if ! port_in_use "$port"; then
      printf '%s\n' "$port"
      return
    fi
  done

  printf 'No free port available in range %s-%s\n' "$start" "$end" >&2
  return 1
}

pick_backend_port() {
  pick_first_free_port 8080 8090 "${SERVER_PORT:-}"
}

pick_frontend_port() {
  pick_first_free_port 5173 5185 "${VITE_DEV_PORT:-}"
}

pick_mysql_port() {
  pick_first_free_port 3306 3315 "${MYSQL_PORT:-}"
}

pick_redis_port() {
  pick_first_free_port 6379 6388 "${REDIS_PORT:-}"
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

wait_for_container_health() {
  local name="$1"
  local container="$2"
  local attempts=60

  for _ in $(seq 1 "$attempts"); do
    local status
    status="$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' "$container" 2>/dev/null || true)"
    if [[ "$status" == "healthy" || "$status" == "running" ]]; then
      return 0
    fi
    sleep 2
  done

  printf '\nTimed out waiting for %s container (%s).\n' "$name" "$container" >&2
  return 1
}

ensure_local_infra() {
  local need_mysql=false
  local need_redis=false
  local services=()

  if [[ -z "${SPRING_DATASOURCE_URL:-}" ]]; then
    need_mysql=true
    MYSQL_PORT="$(pick_mysql_port)"
    services+=("mysql")
  fi

  if [[ -z "${SPRING_DATA_REDIS_HOST:-}" ]] && [[ -z "${SPRING_DATA_REDIS_PORT:-}" ]]; then
    need_redis=true
    REDIS_PORT="$(pick_redis_port)"
    services+=("redis")
  fi

  if [[ "${#services[@]}" -eq 0 ]]; then
    return
  fi

  cat > "$RUNTIME_ENV_FILE" <<EOF
FRONTEND_PORT=$FRONTEND_PORT
BACKEND_PORT=$BACKEND_PORT
MYSQL_PORT=${MYSQL_PORT:-3306}
REDIS_PORT=${REDIS_PORT:-6379}
EOF

  printf 'Starting local infrastructure with Docker: %s\n' "${services[*]}"
  (
    cd "$ROOT_DIR"
    docker compose --env-file "$RUNTIME_ENV_FILE" up -d "${services[@]}"
  )

  if [[ "$need_mysql" == true ]]; then
    wait_for_container_health "MySQL" "eldercare-mysql"
  fi
  if [[ "$need_redis" == true ]]; then
    wait_for_container_health "Redis" "eldercare-redis"
  fi

  if [[ "$need_mysql" == true ]]; then
    export SPRING_DATASOURCE_URL="jdbc:mysql://localhost:${MYSQL_PORT}/eldercare?useUnicode=true&characterEncoding=UTF-8&connectionCollation=utf8mb4_unicode_ci&serverTimezone=Asia/Shanghai"
    export SPRING_DATASOURCE_USERNAME="${SPRING_DATASOURCE_USERNAME:-root}"
    export SPRING_DATASOURCE_PASSWORD="${SPRING_DATASOURCE_PASSWORD:-root1234}"
  fi
  if [[ "$need_redis" == true ]]; then
    export SPRING_DATA_REDIS_HOST="localhost"
    export SPRING_DATA_REDIS_PORT="$REDIS_PORT"
  fi
}

verify_demo_login() {
  local url="http://localhost:${BACKEND_PORT}/api/auth/login"
  local payload='{"username":"demo_admin","password":"123456"}'
  local attempts=30

  for _ in $(seq 1 "$attempts"); do
    local response
    response="$(curl -s -H 'Content-Type: application/json' -d "$payload" "$url" || true)"
    if [[ "$response" == *'"code":200'* ]]; then
      return 0
    fi

    if ! kill -0 "$BACKEND_PID" 2>/dev/null; then
      break
    fi

    sleep 1
  done

  printf '\nBackend started, but demo login did not become ready. Last log lines:\n' >&2
  tail -n 60 "$backend_log" >&2 || true
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

ensure_local_infra

export SERVER_PORT="$BACKEND_PORT"
export SPRING_DATASOURCE_URL="${SPRING_DATASOURCE_URL:-jdbc:mysql://localhost:3306/eldercare?useUnicode=true&characterEncoding=UTF-8&connectionCollation=utf8mb4_unicode_ci&serverTimezone=Asia/Shanghai}"
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
verify_demo_login

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
if [[ -n "${MYSQL_PORT:-}" ]]; then
  printf 'MySQL:    localhost:%s (Docker)\n' "$MYSQL_PORT"
fi
if [[ -n "${REDIS_PORT:-}" ]]; then
  printf 'Redis:    localhost:%s (Docker)\n' "$REDIS_PORT"
fi
printf 'Logs:     %s and %s\n' "$backend_log" "$frontend_log"
printf 'Press Ctrl+C to stop both services.\n\n'

wait "$BACKEND_PID" "$FRONTEND_PID"
