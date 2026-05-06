#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$ROOT_DIR"

echo "Starting EduTube rolling redeploy..."

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_step() {
  echo -e "${BLUE}==> $1${NC}"
}

print_success() {
  echo -e "${GREEN}OK: $1${NC}"
}

print_warning() {
  echo -e "${YELLOW}WARN: $1${NC}"
}

print_error() {
  echo -e "${RED}ERROR: $1${NC}"
}

if docker compose version &>/dev/null; then
  DC="docker compose"
else
  DC="docker-compose"
fi

if ! docker info > /dev/null 2>&1; then
  print_error "Docker is not running."
  exit 1
fi

print_success "Using compose command: $DC"

print_step "Building updated images..."
$DC build backend frontend

print_step "Ensuring data services are up (postgres, redis)..."
$DC up -d postgres redis

print_step "Waiting for PostgreSQL readiness..."
PG_READY=0
PG_CONTAINER_ID=""
for i in $(seq 1 120); do
  if [ -z "$PG_CONTAINER_ID" ]; then
    PG_CONTAINER_ID="$($DC ps -q postgres 2>/dev/null || true)"
  fi

  if [ -n "$PG_CONTAINER_ID" ]; then
    PG_HEALTH="$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' "$PG_CONTAINER_ID" 2>/dev/null || true)"
    if [ "$PG_HEALTH" = "healthy" ]; then
      PG_READY=1
      break
    fi

    # Fallback probe in case healthcheck metadata is unavailable.
    if docker exec "$PG_CONTAINER_ID" sh -lc 'pg_isready -U "${POSTGRES_USER:-postgres}" -d "${POSTGRES_DB:-postgres}"' > /dev/null 2>&1; then
      PG_READY=1
      break
    fi
  else
    PG_HEALTH="none"
  fi

  if [ "$i" -eq 1 ] || [ $((i % 15)) -eq 0 ]; then
    if [ -n "$PG_HEALTH" ] && [ "$PG_HEALTH" != "none" ]; then
      print_warning "PostgreSQL still starting... ($i/120, health=$PG_HEALTH)"
    else
      print_warning "PostgreSQL still starting... ($i/120)"
    fi
  fi
  sleep 2
done
if [ "$PG_READY" -ne 1 ]; then
  print_error "PostgreSQL did not become ready in time."
  print_error "Recent postgres logs:"
  $DC logs --tail=80 postgres || true
  exit 1
fi
print_success "PostgreSQL is ready"

print_step "Running idempotent db-seed check..."
if ! $DC up db-seed; then
  print_error "db-seed step failed."
  exit 1
fi

print_step "Applying Prisma migrations..."
print_step "Checking Prisma migration status..."
if ! $DC run --rm --no-deps backend npx prisma migrate status; then
  print_error "Prisma migration status check failed."
  print_error "If schema changed, ensure a migration exists in prisma/migrations."
  exit 1
fi

MIGRATE_OK=0
for i in $(seq 1 25); do
  if $DC run --rm --no-deps backend npx prisma migrate deploy; then
    MIGRATE_OK=1
    break
  fi
  if [ "$i" -eq 25 ]; then
    break
  fi
  print_warning "Migration retry $i/25..."
  sleep 3
done
if [ "$MIGRATE_OK" -ne 1 ]; then
  print_error "Migration failed after retries."
  exit 1
fi
print_success "Migrations applied"

print_step "Verifying database is at latest migration..."
if ! $DC run --rm --no-deps backend npx prisma migrate status; then
  print_error "Database is not aligned with latest migration history."
  exit 1
fi

print_step "Redeploying backend without full stack teardown..."
$DC up -d --no-deps backend

print_step "Waiting for backend health..."
BACKEND_OK=0
for i in $(seq 1 40); do
  if $DC exec -T backend node -e "require('http').get('http://127.0.0.1:5001/health', (res) => process.exit(res.statusCode === 200 ? 0 : 1)).on('error', () => process.exit(1))"; then
    BACKEND_OK=1
    break
  fi
  sleep 2
done
if [ "$BACKEND_OK" -ne 1 ]; then
  print_error "Backend failed health check."
  print_error "Check logs: $DC logs backend"
  exit 1
fi
print_success "Backend healthy"

print_step "Redeploying frontend without full stack teardown..."
$DC up -d --no-deps frontend

print_step "Refreshing edge nginx proxy..."
$DC up -d --no-deps --force-recreate --remove-orphans nginx

print_step "Ensuring monitoring services are up..."
$DC up -d prometheus alertmanager loki promtail grafana cadvisor

print_step "Waiting for monitoring services health..."
test_http_health() {
  local url="$1"
  local name="$2"
  local max_attempts="${3:-30}"
  for i in $(seq 1 "$max_attempts"); do
    code="$(curl -s -o /dev/null -w "%{http_code}" "$url" || true)"
    if [ "$code" = "200" ]; then
      print_success "$name healthy"
      return 0
    fi
    sleep 2
  done
  print_warning "$name health check did not pass at $url"
  return 1
}

test_http_health "http://localhost/monitoring/prometheus/-/healthy" "Prometheus" 30 || true
test_http_health "http://localhost/monitoring/grafana/api/health" "Grafana" 30 || true
test_http_health "http://localhost/monitoring/loki/ready" "Loki" 30 || true
test_http_health "http://localhost/monitoring/alertmanager/-/healthy" "Alertmanager" 30 || true

print_step "Waiting for frontend health..."
FRONTEND_OK=0
for i in $(seq 1 40); do
  if $DC exec -T frontend node -e "require('http').get('http://127.0.0.1:4000', (res) => process.exit(res.statusCode < 500 ? 0 : 1)).on('error', () => process.exit(1))"; then
    FRONTEND_OK=1
    break
  fi
  sleep 2
done
if [ "$FRONTEND_OK" -ne 1 ]; then
  print_error "Frontend failed health check."
  print_error "Check logs: $DC logs frontend"
  exit 1
fi
print_success "Frontend healthy"

print_step "Current status:"
$DC ps

echo ""
print_success "Redeploy complete."
echo -e "${BLUE}Frontend:${NC} http://localhost"
echo -e "${BLUE}Backend API:${NC}  http://localhost/api"
echo -e "${BLUE}Prometheus:${NC}   http://localhost/monitoring/prometheus/"
echo -e "${BLUE}Grafana:${NC}      http://localhost/monitoring/grafana/ (admin/admin)"
echo -e "${BLUE}Loki:${NC}         http://localhost/monitoring/loki/"
echo -e "${BLUE}Alertmanager:${NC} http://localhost/monitoring/alertmanager/"
echo ""
print_warning "Note: services now stay on the private Docker network; only Nginx is published on the host."
