#!/bin/sh

set -eu

LOCKFILE_CHANGED=0

if [ ! -f node_modules/.package-lock.json ]; then
  LOCKFILE_CHANGED=1
elif ! cmp -s package-lock.json node_modules/.package-lock.json; then
  LOCKFILE_CHANGED=1
fi

if [ ! -d node_modules ] || [ -z "$(ls -A node_modules 2>/dev/null)" ] || [ "$LOCKFILE_CHANGED" -eq 1 ] || [ ! -d node_modules/@formkit/auto-animate ]; then
  npm ci
fi

exec npm run dev -- --host 0.0.0.0
