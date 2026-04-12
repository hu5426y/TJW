#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUNTIME_ENV_FILE="$ROOT_DIR/.docker-runtime.env"

port_in_use() {
  local port="$1"
  ss -ltn "( sport = :$port )" | tail -n +2 | grep -q .
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

wait_for_http() {
  local name="$1"
  local url="$2"
  local attempts="${3:-60}"
  local consecutive=0

  for _ in $(seq 1 "$attempts"); do
    if curl -s -o /dev/null --connect-timeout 2 "$url"; then
      consecutive=$((consecutive + 1))
      if [[ "$consecutive" -ge 3 ]]; then
        return 0
      fi
    else
      consecutive=0
    fi
    sleep 1
  done

  printf '\nTimed out waiting for %s at %s\n' "$name" "$url" >&2
  docker compose logs --tail=80 >&2 || true
  return 1
}

wait_for_windows_http() {
  local name="$1"
  local url="$2"
  local attempts="${3:-30}"
  local consecutive=0

  if ! command -v powershell.exe >/dev/null 2>&1; then
    return 0
  fi

  for _ in $(seq 1 "$attempts"); do
    if powershell.exe -NoProfile -Command "\$ProgressPreference='SilentlyContinue'; try { \$r = Invoke-WebRequest -Uri '$url' -UseBasicParsing -TimeoutSec 3; if (\$r.StatusCode -ge 200 -and \$r.StatusCode -lt 400) { exit 0 } else { exit 1 } } catch { exit 1 }" >/dev/null 2>&1; then
      consecutive=$((consecutive + 1))
      if [[ "$consecutive" -ge 2 ]]; then
        return 0
      fi
    else
      consecutive=0
    fi
    sleep 1
  done

  printf '\nTimed out waiting for Windows-side %s at %s\n' "$name" "$url" >&2
  return 1
}

FRONTEND_PORT="$(pick_first_free_port 5173 5185 "${FRONTEND_PORT:-}")"
BACKEND_PORT="$(pick_first_free_port 8080 8090 "${BACKEND_PORT:-}")"
MYSQL_PORT="$(pick_first_free_port 3306 3315 "${MYSQL_PORT:-}")"
REDIS_PORT="$(pick_first_free_port 6379 6388 "${REDIS_PORT:-}")"

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
docker compose --env-file "$RUNTIME_ENV_FILE" up -d --force-recreate --remove-orphans

wait_for_http "backend" "http://localhost:${BACKEND_PORT}/" 90
wait_for_http "frontend" "http://localhost:${FRONTEND_PORT}/" 90
wait_for_windows_http "frontend" "http://localhost:${FRONTEND_PORT}/" 45

printf '\nDocker development is ready.\n'
printf 'Frontend: http://localhost:%s\n' "$FRONTEND_PORT"
printf 'Backend:  http://localhost:%s\n' "$BACKEND_PORT"
printf 'MySQL:    localhost:%s\n' "$MYSQL_PORT"
printf 'Redis:    localhost:%s\n' "$REDIS_PORT"
printf 'Runtime env: %s\n' "$RUNTIME_ENV_FILE"
