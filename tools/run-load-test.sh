#!/bin/bash

################################################################################
# EduTube Load Test Runner Script
#
# This script sets up and runs load tests against EduTube deployments
# to validate estimated capacity and identify bottlenecks.
#
# Prerequisites:
#   - curl (for basic HTTP tests)
#   - Optional: k6, Apache JMeter, or artillery for advanced testing
#
# Usage: bash run-load-test.sh [test_type] [target_url] [duration_seconds]
################################################################################

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Defaults
TEST_TYPE="${1:-basic}"
TARGET_URL="${2:-http://localhost:3000}"
DURATION="${3:-300}"  # 5 minutes default
CONCURRENT_USERS="${4:-50}"

# Output file
TEST_REPORT="edutube_load_test_$(date +%Y%m%d_%H%M%S).txt"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}EduTube Load Testing Tool${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Target: $TARGET_URL"
echo "Test Type: $TEST_TYPE"
echo "Duration: ${DURATION}s"
echo "Concurrent Users: $CONCURRENT_USERS"
echo ""

# Function to run basic HTTP load test using curl
basic_load_test() {
    echo -e "${YELLOW}Running basic curl-based load test...${NC}"
    
    {
        echo "EduTube Load Test Report"
        echo "Generated: $(date)"
        echo "Target URL: $TARGET_URL"
        echo "Test Type: Basic HTTP (curl)"
        echo "Duration: ${DURATION}s"
        echo "Concurrent Users: $CONCURRENT_USERS"
        echo "=============================================="
        echo ""
        
        echo "Test Configuration:"
        echo "  Method: Distributed parallel requests via curl"
        echo "  Endpoint: $TARGET_URL"
        echo "  Test duration: $DURATION seconds"
        echo ""
        
        echo "Starting load test..."
        echo ""
        
        START_TIME=$(date +%s)
        END_TIME=$((START_TIME + DURATION))
        REQUEST_COUNT=0
        SUCCESS_COUNT=0
        ERROR_COUNT=0
        TOTAL_RESPONSE_TIME=0
        
        # Temp file for responses
        TEMP_DIR=$(mktemp -d)
        trap "rm -rf $TEMP_DIR" EXIT
        
        # Start background curl processes
        echo "Spawning $CONCURRENT_USERS concurrent request streams..."
        echo ""
        
        for i in $(seq 1 $CONCURRENT_USERS); do
            {
                while [ $(date +%s) -lt $END_TIME ]; do
                    RESPONSE=$(curl -w "\n%{http_code}\n%{time_total}\n" -s "$TARGET_URL" 2>/dev/null || echo -e "0\n0")
                    
                    # Parse response
                    HTTP_CODE=$(echo "$RESPONSE" | tail -2 | head -1)
                    RESPONSE_TIME=$(echo "$RESPONSE" | tail -1)
                    
                    echo "$HTTP_CODE:$RESPONSE_TIME" >> "$TEMP_DIR/results_$i.txt"
                    
                    # Small delay between requests
                    sleep 0.1
                done
            } &
        done
        
        # Wait for all background jobs
        wait
        
        # Aggregate results
        echo "Analyzing results..."
        echo ""
        
        for result_file in "$TEMP_DIR"/results_*.txt; do
            [ -f "$result_file" ] || continue
            while IFS=: read -r http_code response_time; do
                REQUEST_COUNT=$((REQUEST_COUNT + 1))
                if [[ $http_code == "200" ]] || [[ $http_code == "301" ]] || [[ $http_code == "302" ]]; then
                    SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
                else
                    ERROR_COUNT=$((ERROR_COUNT + 1))
                fi
                TOTAL_RESPONSE_TIME=$(echo "$TOTAL_RESPONSE_TIME + $response_time" | bc)
            done < "$result_file"
        done
        
        # Calculate statistics
        AVERAGE_RESPONSE_TIME=0
        if [ $REQUEST_COUNT -gt 0 ]; then
            AVERAGE_RESPONSE_TIME=$(echo "scale=3; $TOTAL_RESPONSE_TIME / $REQUEST_COUNT" | bc)
        fi
        SUCCESS_RATE=0
        if [ $REQUEST_COUNT -gt 0 ]; then
            SUCCESS_RATE=$((SUCCESS_COUNT * 100 / REQUEST_COUNT))
        fi
        ERROR_RATE=$((100 - SUCCESS_RATE))
        THROUGHPUT=$(echo "scale=2; $REQUEST_COUNT / $DURATION" | bc)
        
        echo "RESULTS:"
        echo "========"
        echo "Total Requests: $REQUEST_COUNT"
        echo "Successful Requests: $SUCCESS_COUNT ($SUCCESS_RATE%)"
        echo "Failed Requests: $ERROR_COUNT ($ERROR_RATE%)"
        echo "Average Response Time: ${AVERAGE_RESPONSE_TIME}s"
        echo "Throughput: $THROUGHPUT req/s"
        echo "Test Duration: $DURATION seconds"
        echo ""
        
        if [ $ERROR_COUNT -eq 0 ]; then
            echo -e "${GREEN}✓ All requests succeeded!${NC}"
        elif [ $ERROR_RATE -gt 50 ]; then
            echo -e "${RED}✗ Server overwhelmed! Error rate > 50%${NC}"
        else
            echo -e "${YELLOW}⚠ Some errors detected (${ERROR_RATE}% error rate)${NC}"
        fi
        
    } | tee "$TEST_REPORT"
}

# Function to generate k6 script and run it
k6_load_test() {
    if ! command -v k6 &> /dev/null; then
        echo -e "${RED}Error: k6 not installed${NC}"
        echo "Install k6 from: https://k6.io/docs/getting-started/installation/"
        return 1
    fi
    
    echo -e "${YELLOW}Running k6-based load test...${NC}"
    
    # Create k6 script
    K6_SCRIPT=$(mktemp --suffix=.js)
    cat > "$K6_SCRIPT" << 'EOFK6'
import http from 'k6/http';
import { check, sleep } from 'k6';

export let options = {
  stages: [
    { duration: '30s', target: __ENV.USERS || 50 },      // Ramp up
    { duration: __ENV.DURATION - 60 + 's', target: __ENV.USERS || 50 }, // Stay
    { duration: '30s', target: 0 },                       // Ramp down
  ],
  thresholds: {
    http_req_duration: ['p(95)<500', 'p(99)<1000'],
    http_req_failed: ['rate<0.5'],
  },
};

export default function () {
  let res = http.get(__ENV.TARGET || 'http://localhost:3000');
  
  check(res, {
    'status is 200': (r) => r.status === 200,
    'response time < 500ms': (r) => r.timings.duration < 500,
  });
  
  sleep(1);
}
EOFK6
    
    # Run k6
    k6 run \
        --vus "$CONCURRENT_USERS" \
        --duration "${DURATION}s" \
        -e TARGET="$TARGET_URL" \
        -e DURATION="$DURATION" \
        -e USERS="$CONCURRENT_USERS" \
        "$K6_SCRIPT" | tee "$TEST_REPORT"
    
    rm -f "$K6_SCRIPT"
}

# Function to check server health before load test
health_check() {
    echo -e "${YELLOW}Performing health check...${NC}"
    echo ""
    
    if ! curl -s -o /dev/null -w "%{http_code}" "$TARGET_URL" | grep -q "^200"; then
        echo -e "${RED}✗ Health check failed! Server not responding.${NC}"
        echo "Target: $TARGET_URL"
        return 1
    fi
    
    echo -e "${GREEN}✓ Server health check passed${NC}"
    echo ""
}

# Function to display recommendations
show_recommendations() {
    echo ""
    echo -e "${BLUE}Load Test Recommendations:${NC}"
    echo ""
    echo "To get accurate capacity measurements:"
    echo ""
    echo "1. Basic Testing (using this script):"
    echo "   bash run-load-test.sh basic http://your-server:3000 300 50"
    echo ""
    echo "2. Intermediate Testing (requires k6):"
    echo "   k6 install  # Install k6"
    echo "   bash run-load-test.sh k6 http://your-server:3000 300 100"
    echo ""
    echo "3. Advanced Testing (requires Apache JMeter or Artillery):"
    echo "   # Apache JMeter:"
    echo "   jmeter -n -t plan.jmx -l results.csv -j jmeter.log"
    echo ""
    echo "   # Artillery:"
    echo "   artillery run load-test.yml"
    echo ""
    echo "4. Test Sequence (recommended):"
    echo "   • Start with 25 concurrent users, 5 min duration"
    echo "   • Increase to 50 users if stable"
    echo "   • Increase to 100 users if stable"
    echo "   • Continue until failure point is found"
    echo ""
    echo "5. Monitor during tests:"
    echo "   • In another terminal, monitor system resources:"
    echo "   watch -n 1 'free -h && echo && top -b -n 1 | head -15'"
    echo ""
}

# Main execution
case "$TEST_TYPE" in
    basic)
        health_check || exit 1
        basic_load_test
        ;;
    k6)
        health_check || exit 1
        k6_load_test
        ;;
    help|"")
        echo -e "${YELLOW}Usage:${NC}"
        echo "  bash run-load-test.sh [test_type] [target_url] [duration] [users]"
        echo ""
        echo -e "${YELLOW}Arguments:${NC}"
        echo "  test_type: basic (default), k6"
        echo "  target_url: http://localhost:3000 (default)"
        echo "  duration: 300 seconds (default)"
        echo "  users: 50 concurrent users (default)"
        echo ""
        show_recommendations
        ;;
    *)
        echo -e "${RED}Unknown test type: $TEST_TYPE${NC}"
        echo "Use: bash run-load-test.sh help"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}✓ Load test completed!${NC}"
echo -e "${BLUE}Results saved to: $TEST_REPORT${NC}"
echo ""
