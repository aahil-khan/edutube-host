#!/bin/bash

################################################################################
# QUICK START GUIDE - EduTube Server Analysis
# Copy & paste these commands into your terminal
################################################################################

# ============================================================================
# STEP 1: SETUP - Copy scripts to your new server
# ============================================================================

echo "=== STEP 1: Setup Scripts on New Server ==="

# Upload scripts to new server (run from your local machine)
# scp analyze-server-capacity.sh run-load-test.sh compare-servers.sh user@new-server:~

# Or, copy this entire section and run on new server:
echo "Creating analysis scripts on $(hostname)..."
# [Scripts are already in place - this is just documentation]

chmod +x ~/analyze-server-capacity.sh ~/run-load-test.sh

# ============================================================================
# STEP 2: ANALYZE NEW SERVER
# ============================================================================

echo ""
echo "=== STEP 2: Analyze Server (run on NEW server) ==="
echo "Command:"
echo "  bash ~/analyze-server-capacity.sh"
echo ""
echo "This will:"
echo "  ✓ Check CPU (cores, frequency)"
echo "  ✓ Check RAM (total, available, usage)"
echo "  ✓ Check disk space and I/O"
echo "  ✓ Check network connectivity"
echo "  ✓ Verify Docker installation"
echo "  ✓ Estimate concurrent user capacity"
echo "  ✓ Generate detailed report file"
echo ""

# ============================================================================
# STEP 3: QUICK RESULTS
# ============================================================================

echo "=== STEP 3: What the Script Tells You ==="
echo ""
echo "Look for these key numbers in the output:"
echo ""
echo "  CPU Cores: ___"
echo "    → How many processor cores available"
echo "    → EduTube needs at least 2 cores"
echo ""
echo "  Total Memory (GB): ___"
echo "    → How much RAM available"
echo "    → EduTube minimum: 2.5 GB per instance"
echo "    → EduTube recommended: 4-6 GB"
echo ""
echo "  Recommended Instances: ___"
echo "    → How many EduTube deployments can run"
echo "    → 1 = good for medium traffic"
echo "    → 2+ = good for high traffic or load balancing"
echo ""
echo "  Estimated Concurrent Users: ___"
echo "    → Maximum users online at same time"
echo "    → Sustained: Normal expected load"
echo "    → Peak: During traffic spikes"
echo "    → Conservative: Safe estimate with buffer"
echo ""

# ============================================================================
# STEP 4: COMPARE WITH CURRENT SERVER
# ============================================================================

echo ""
echo "=== STEP 4: Compare New vs Current Server ==="
echo ""
echo "To compare with your current server:"
echo ""
echo "1. On CURRENT server, save analysis:"
echo "   bash ~/analyze-server-capacity.sh > ~/current_analysis.txt"
echo ""
echo "2. Copy to local machine:"
echo "   scp user@current-server:~/current_analysis.txt ./"
echo "   scp user@new-server:~/new_analysis.txt ./"
echo ""
echo "3. Run comparison:"
echo "   bash ~/compare-servers.sh current_analysis.txt new_analysis.txt"
echo ""

# ============================================================================
# STEP 5: VALIDATE WITH LOAD TEST
# ============================================================================

echo ""
echo "=== STEP 5: Validate with Load Testing ==="
echo ""
echo "Make sure EduTube is running first:"
echo "  cd ~/edutube-host"
echo "  docker-compose -f docker-compose.yml up -d"
echo ""
echo "Then run load tests (start small, increase gradually):"
echo ""
echo "Light test (5 min, 25 users):"
echo "  bash ~/run-load-test.sh basic http://localhost:3000 300 25"
echo ""
echo "Medium test (5 min, 50 users):"
echo "  bash ~/run-load-test.sh basic http://localhost:3000 300 50"
echo ""
echo "Heavy test (5 min, 100 users):"
echo "  bash ~/run-load-test.sh basic http://localhost:3000 300 100"
echo ""

# ============================================================================
# INTERPRETATION GUIDE
# ============================================================================

echo ""
echo "=== QUICK INTERPRETATION GUIDE ==="
echo ""
echo "IF NEW SERVER has:"
echo ""
echo "  CPU Cores ≥ Current: ✓ Good"
echo "  CPU Cores < Current: ⚠ Check memory to compensate"
echo ""
echo "  RAM ≥ 8GB: ✓ Excellent"
echo "  RAM 4-8GB: ✓ Good"
echo "  RAM 2-4GB: ⚠ Acceptable for single instance"
echo "  RAM < 2GB: ✗ Too small for production"
echo ""
echo "  Concurrent Users ≥ 90% of Current: ✓ Can replace"
echo "  Concurrent Users 75-90%: ⚠ Good for load balancing"
echo "  Concurrent Users 50-75%: ⚠ Use for development/staging"
echo "  Concurrent Users < 50%: ✗ Not suitable as primary"
echo ""

# ============================================================================
# DECISION MATRIX
# ============================================================================

echo ""
echo "=== DECISION MATRIX ==="
echo ""
echo "Compare estimated concurrent users:"
echo ""
echo "  New ≥ 125% of Current  → UPGRADE - Migrate to new server"
echo "  New 90-125% of Current → GOOD    - Gradual migration or load balance"
echo "  New 75-90% of Current  → OK      - Use for load balancing"
echo "  New 50-75% of Current  → LIMITED - Use for staging/backup"
echo "  New < 50% of Current   → RISKY   - Not recommended as primary"
echo ""

# ============================================================================
# MONITORING DURING TESTS
# ============================================================================

echo ""
echo "=== MONITORING DURING LOAD TESTS ==="
echo ""
echo "Open another terminal and run:"
echo "  watch -n 1 'free -h && echo \"---\" && top -b -n 1 | head -10'"
echo ""
echo "Watch for:"
echo "  Memory Usage: Should stay < 80%"
echo "  CPU Usage: Should stay < 70% average"
echo "  Disk I/O: Should not be maxed out"
echo "  Swap Usage: Should remain minimal"
echo ""

# ============================================================================
# TROUBLESHOOTING
# ============================================================================

echo ""
echo "=== TROUBLESHOOTING ==="
echo ""
echo "Scripts won't run:"
echo "  chmod +x *.sh"
echo ""
echo "Docker not found:"
echo "  curl -fsSL https://get.docker.com | sudo sh"
echo ""
echo "Load tests show high errors:"
echo "  1. Check if services running: docker ps"
echo "  2. Check if app is accessible: curl http://localhost:3000"
echo "  3. Check system resources: free -h && df -h"
echo "  4. Check app logs: docker logs edutube-backend"
echo ""

# ============================================================================
# SUMMARY
# ============================================================================

echo ""
echo "=========================================="
echo "QUICK START SUMMARY"
echo "=========================================="
echo ""
echo "1. Run analysis:"
echo "   bash analyze-server-capacity.sh"
echo ""
echo "2. Note these numbers:"
echo "   - CPU Cores"
echo "   - RAM (GB)"
echo "   - Estimated Concurrent Users"
echo ""
echo "3. Compare with current server:"
echo "   bash compare-servers.sh current.txt new.txt"
echo ""
echo "4. Run load tests to validate:"
echo "   bash run-load-test.sh basic http://localhost:3000 300 50"
echo ""
echo "5. Make decision based on:"
echo "   - CPU capacity"
echo "   - RAM capacity"
echo "   - User capacity comparison"
echo ""
echo "=========================================="
echo ""
