#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUNTIME_ENV_FILE="$ROOT_DIR/.docker-runtime.env"

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

FRONTEND_PORT="$(pick_port 5173 5174 "${FRONTEND_PORT:-}")"
BACKEND_PORT="$(pick_port 8080 8081 "${BACKEND_PORT:-}")"
MYSQL_PORT="$(pick_port 3306 3307 "${MYSQL_PORT:-}")"
REDIS_PORT="$(pick_port 6379 6380 "${REDIS_PORT:-}")"

cat > "$RUNTIME_ENV_FILE" <<EOF
FRONTEND_PORT=$FRONTEND_PORT
BACKEND_PORT=$BACKEND_PORT
MYSQL_PORT=$MYSQL_PORT
REDIS_PORT=$REDIS_PORT
EOF

printf 'Using ports:\n'
printf '  Frontend: %s\n' "$FRONTEND_PORT"
printf '  Backend:  %s\n' "$BACKEND_PORT"
printf '  MySQL:    %s\n' "$MYSQL_PORT"
printf '  Redis:    %s\n' "$REDIS_PORT"

cd "$ROOT_DIR"
docker compose --env-file "$RUNTIME_ENV_FILE" up -d

printf '\nDocker development is ready.\n'
printf 'Frontend: http://localhost:%s\n' "$FRONTEND_PORT"
printf 'Backend:  http://localhost:%s\n' "$BACKEND_PORT"
printf 'MySQL:    localhost:%s\n' "$MYSQL_PORT"
printf 'Redis:    localhost:%s\n' "$REDIS_PORT"
printf 'Runtime env: %s\n' "$RUNTIME_ENV_FILE"
