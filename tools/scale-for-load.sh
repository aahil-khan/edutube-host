#!/usr/bin/env bash
set -euo pipefail

# Scale frontend and backend for load testing while keeping DB and Redis singletons.
# Usage: bash tools/scale-for-load.sh [backend_instances] [frontend_instances]

BACKEND=${1:-2}
FRONTEND=${2:-2}

if docker compose version >/dev/null 2>&1; then
	DC="docker compose"
else
	DC="docker-compose"
fi

echo "Scaling backend to $BACKEND and frontend to $FRONTEND (postgres/redis remain 1)"

$DC up -d --build --remove-orphans --scale backend="$BACKEND" --scale frontend="$FRONTEND"

echo "Refreshing edge nginx proxy"
$DC up -d --no-deps --force-recreate nginx

echo "Scaled. Use '$DC ps' to verify containers and '$DC logs -f' to monitor."
