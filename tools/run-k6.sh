#!/usr/bin/env bash
set -euo pipefail

# Simple runner for the k6 tests included in tools/k6
# Usage: bash tools/run-k6.sh [internal|backend|frontend] [target] [duration_seconds] [users]

TEST=${1:-internal}
TARGET=${2:-}
DURATION=${3:-300}
USERS=${4:-50}

SCRIPT_DIR="$(dirname "$0")/k6"

if ! command -v k6 &>/dev/null; then
  echo "k6 is not installed. Visit https://k6.io/docs/getting-started/installation/"
  exit 1
fi

case "$TEST" in
  internal|suite)
    SCRIPT="$SCRIPT_DIR/internal-suite.js"
    ;;
  frontend)
    SCRIPT="$SCRIPT_DIR/frontend.js"
    ;;
  backend)
    SCRIPT="$SCRIPT_DIR/backend.js"
    ;;
  *)
    echo "Unknown test type: $TEST"
    echo "Use: bash tools/run-k6.sh [internal|backend|frontend] [target] [duration] [users]"
    exit 1
    ;;
esac

if [ -z "$TARGET" ]; then
  if [ "$TEST" = "backend" ]; then
    TARGET="http://localhost:5001"
  else
    TARGET="http://localhost:4000"
  fi
fi

if [ ! -f "$SCRIPT" ]; then
  echo "Unknown test script: $SCRIPT"
  exit 1
fi

echo "Running k6 test: $TEST"
echo "Web target: $TARGET | Duration: ${DURATION}s | Users: $USERS"

if [ "$TEST" = "backend" ]; then
  k6 run -e TARGET="$TARGET" -e DURATION="$DURATION" -e USERS="$USERS" "$SCRIPT"
else
  k6 run \
    -e WEB_BASE="$TARGET" \
    -e API_BASE="${API_BASE:-http://localhost:5001}" \
    -e DURATION="$DURATION" \
    -e USERS="$USERS" \
    -e EMAIL="${EMAIL:-student@thapar.edu}" \
    -e PASSWORD="${PASSWORD:-123456}" \
    "$SCRIPT"
fi
