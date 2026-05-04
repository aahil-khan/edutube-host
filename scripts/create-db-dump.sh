#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DUMP_FILE="$ROOT_DIR/edutube-backend/dump/Video_Portal_Dummy_20250926_195641.dump"

if docker compose version &>/dev/null; then
    DC="docker compose"
else
    DC="docker-compose"
fi

echo "📦 Ensuring PostgreSQL is running..."
cd "$ROOT_DIR"
$DC up -d postgres

echo "💾 Writing dump to: $DUMP_FILE"
$DC exec -T postgres pg_dump -U postgres -Fc --no-owner --no-privileges -d Video_Portal_Dummy > "$DUMP_FILE"

echo "✅ Database dump updated"