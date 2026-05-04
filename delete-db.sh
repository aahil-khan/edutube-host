#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

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

# Detect docker compose command
if docker compose version &>/dev/null; then
  DC="docker compose"
else
  DC="docker-compose"
fi

# Confirm destructive action
print_warning "This will DELETE the entire database and all data!"
read -p "Are you sure? Type 'yes' to continue: " confirm
if [ "$confirm" != "yes" ]; then
  print_error "Cancelled."
  exit 1
fi

print_step "Stopping all services..."
$DC down || true

print_step "Removing postgres container..."
docker rm -f edutube-postgres 2>/dev/null || true

print_step "Removing postgres volume..."
docker volume rm edutube_postgres_data 2>/dev/null || true

print_success "Database deleted successfully"
echo ""
print_step "Next steps:"
echo "1. Run: ./deploy.sh (to rebuild and restore from dump)"
echo "2. Or run: $DC up -d postgres redis (to start fresh services)"
