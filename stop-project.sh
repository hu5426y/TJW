#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUNTIME_ENV_FILE="$ROOT_DIR/.docker-runtime.env"

cd "$ROOT_DIR"

if [[ -f "$RUNTIME_ENV_FILE" ]]; then
  docker compose --env-file "$RUNTIME_ENV_FILE" down --remove-orphans || true
else
  docker compose down --remove-orphans || true
fi

pkill -f 'spring-boot:run' || true
pkill -f 'com.tjw.eldercare.EldercareApplication' || true
pkill -f 'vite --host 0.0.0.0' || true
pkill -f 'npm run dev -- --host 0.0.0.0' || true
pkill -f '/home/.*/dev/TJW/start-local.sh' || true

sleep 2

printf 'Project-related Docker containers and local frontend/backend processes have been stopped.\n'
printf 'Note: local system MySQL/Redis services on 3306/6379 are intentionally left untouched.\n'
