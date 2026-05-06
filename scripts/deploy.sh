#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$ROOT_DIR"

echo "🚀 Starting EduTube Production Deployment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Prefer `docker compose` (v2), fall back to `docker-compose` (v1)
if docker compose version &>/dev/null; then
    DC="docker compose"
else
    DC="docker-compose"
fi

# Function to print colored output
print_step() {
    echo -e "${BLUE}📋 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    print_error "Docker is not running. Please start Docker and try again."
    exit 1
fi

print_success "Docker is running (using: $DC)"

# Stop and remove existing containers
print_step "Stopping existing containers..."
$DC down --remove-orphans

# Remove old images to ensure clean build
print_step "Cleaning up old images..."
docker image prune -f

# Build all images first (needed before one-off migrate run)
print_step "Building images..."
if ! $DC build; then
    print_error "Docker image build failed. Aborting deployment."
    exit 1
fi

# Bring up data layer and seed before the long-running backend so migrations can run
# even if the backend container previously exited during start.sh
print_step "Starting PostgreSQL and Redis..."
$DC up -d postgres redis

print_step "Waiting for PostgreSQL to accept connections..."
PG_READY=0
for i in $(seq 1 60); do
    if $DC exec -T postgres pg_isready -U postgres > /dev/null 2>&1; then
        PG_READY=1
        break
    fi
    sleep 2
done
if [ "$PG_READY" -ne 1 ]; then
    print_error "PostgreSQL did not become ready in time"
    exit 1
fi
print_success "PostgreSQL is ready"

print_step "Running database seed (one-shot)..."
# Runs the db-seed service to completion (pg_restore)
if ! $DC up db-seed; then
    print_error "Database seed step failed — check logs: $DC logs db-seed"
    exit 1
fi

print_step "Applying Prisma migrations (one-shot backend container)..."
# If a prior deploy left this migration in "failed" (P3009), clear it so the idempotent
# migration.sql can apply. Harmless when there is nothing to resolve.
$DC run --rm --no-deps backend \
    npx prisma migrate resolve --rolled-back 20260208120000_add_cli_api_key_and_lecture_cli_fields \
    2>/dev/null || true

# --no-deps: do NOT start db-seed again (backend depends_on db-seed; without this, every
# retry re-ran pg_restore and failed with duplicate keys on an already-seeded volume).
MIGRATE_OK=0
for i in $(seq 1 25); do
    if $DC run --rm --no-deps backend npx prisma migrate deploy; then
        MIGRATE_OK=1
        print_success "Database migrations applied"
        break
    fi
    if [ "$i" -eq 25 ]; then
        break
    fi
    print_warning "Migration not ready yet, retrying ($i/25)..."
    sleep 3
done
if [ "$MIGRATE_OK" -ne 1 ]; then
    print_error "prisma migrate deploy failed after retries"
    print_error "Check: $DC logs postgres"
    print_error "Hint: $DC run --rm --no-deps backend npx prisma migrate deploy"
    exit 1
fi

print_step "Starting backend and frontend..."
$DC up -d backend frontend

print_step "Starting edge nginx proxy..."
$DC up -d nginx

print_step "Starting monitoring services..."
$DC up -d prometheus alertmanager loki promtail grafana cadvisor

# Wait for app processes
print_step "Waiting for services to start..."
sleep 8

# Check service health
print_step "Checking service health..."

# Check Redis
if $DC exec -T redis redis-cli ping > /dev/null 2>&1; then
    print_success "Redis is ready"
else
    print_warning "Redis might still be starting..."
fi

# Check backend health
print_step "Checking backend health..."
for i in $(seq 1 30); do
    if $DC exec -T backend node -e "require('http').get('http://127.0.0.1:5001/health', (res) => process.exit(res.statusCode === 200 ? 0 : 1)).on('error', () => process.exit(1))"; then
        print_success "Backend is healthy"
        break
    elif [ "$i" -eq 30 ]; then
        print_warning "Backend health check timed out — try: $DC logs backend"
    else
        echo -n "."
        sleep 2
    fi
done

# Check frontend health
print_step "Checking frontend health..."
for i in $(seq 1 30); do
    if $DC exec -T frontend node -e "require('http').get('http://127.0.0.1:4000', (res) => process.exit(res.statusCode < 500 ? 0 : 1)).on('error', () => process.exit(1))"; then
        print_success "Frontend is healthy"
        break
    elif [ "$i" -eq 30 ]; then
        print_warning "Frontend health check timed out"
    else
        echo -n "."
        sleep 2
    fi
done

# Show running containers
print_step "Deployment Status:"
$DC ps

echo ""
print_success "🎉 EduTube deployment completed!"
echo ""
echo -e "${BLUE}📱 Access your application:${NC}"
echo -e "   Frontend: ${GREEN}http://localhost${NC}"
echo -e "   Backend API: ${GREEN}http://localhost/api${NC}"
echo -e "   Prometheus: ${GREEN}http://localhost:9090${NC}"
echo -e "   Grafana: ${GREEN}http://localhost:3001${NC} (admin/admin)"
echo -e "   Loki: ${GREEN}http://localhost:3100${NC}"
echo -e "   Alertmanager: ${GREEN}http://localhost:9093${NC}"
echo -e "   Database: ${GREEN}internal Docker network only${NC}"
echo -e "   Redis: ${GREEN}internal Docker network only${NC}"
echo ""
echo -e "${BLUE}� Default Admin Credentials:${NC}"
echo -e "   Email: ${GREEN}admin@gmail.com${NC}"
echo -e "   Password: ${GREEN}aahil${NC}"
echo -e "   ${YELLOW}⚠️  Please change the password after first login!${NC}"
echo ""
echo -e "${BLUE}�🔧 Useful commands:${NC}"
echo -e "   View logs: ${YELLOW}$DC logs -f${NC}"
echo -e "   Stop services: ${YELLOW}$DC down${NC}"
echo -e "   Restart services: ${YELLOW}$DC restart${NC}"
echo -e "   Create user: ${YELLOW}$DC exec backend npm run setup:admin${NC}"
echo ""

# Optional: Open browser
if command -v xdg-open > /dev/null; then
    read -p "Open application in browser? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        xdg-open http://localhost
    fi
fi
