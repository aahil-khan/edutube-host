#!/bin/bash

################################################################################
# EduTube Server Comparison Script
#
# Compares specifications and performance between two servers
# Helps determine if new server can replace or supplement current deployment
#
# Usage: bash compare-servers.sh [current_analysis.txt] [new_analysis.txt]
################################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

if [ "$#" -lt 2 ]; then
    echo -e "${YELLOW}Usage:${NC}"
    echo "  bash compare-servers.sh [current_analysis.txt] [new_analysis.txt]"
    echo ""
    echo "Example:"
    echo "  bash compare-servers.sh edutube_server_analysis_current.txt edutube_server_analysis_new.txt"
    echo ""
    echo "Step 1: Generate analysis on current server:"
    echo "  ssh user@current-server 'bash analyze-server-capacity.sh' > current_analysis.txt"
    echo ""
    echo "Step 2: Generate analysis on new server:"
    echo "  ssh user@new-server 'bash analyze-server-capacity.sh' > new_analysis.txt"
    echo ""
    echo "Step 3: Compare them:"
    echo "  bash compare-servers.sh current_analysis.txt new_analysis.txt"
    exit 1
fi

CURRENT_FILE="$1"
NEW_FILE="$2"
COMPARISON_REPORT="server_comparison_$(date +%Y%m%d_%H%M%S).txt"

# Helper function to extract value from analysis file
extract_value() {
    local file=$1
    local pattern=$2
    grep "$pattern" "$file" | head -1 | grep -oE '[0-9]+' | head -1
}

# Helper function to extract text value
extract_text_value() {
    local file=$1
    local pattern=$2
    grep "$pattern" "$file" | head -1 | sed 's/.*: //' | xargs
}

{
    echo "==============================================================="
    echo "EduTube Server Comparison Report"
    echo "Generated: $(date)"
    echo "==============================================================="
    echo ""
    
    # Validate files
    if [ ! -f "$CURRENT_FILE" ]; then
        echo "ERROR: Current analysis file not found: $CURRENT_FILE"
        exit 1
    fi
    if [ ! -f "$NEW_FILE" ]; then
        echo "ERROR: New analysis file not found: $NEW_FILE"
        exit 1
    fi
    
    echo "Comparing:"
    echo "  Current: $CURRENT_FILE"
    echo "  New:     $NEW_FILE"
    echo ""
    
    # Extract CPU info
    CURRENT_CORES=$(extract_value "$CURRENT_FILE" "Physical CPU Cores")
    NEW_CORES=$(extract_value "$NEW_FILE" "Physical CPU Cores")
    
    CURRENT_FREQ=$(extract_value "$CURRENT_FILE" "CPU Frequency")
    NEW_FREQ=$(extract_value "$NEW_FILE" "CPU Frequency")
    
    echo "1. CPU COMPARISON"
    echo "==============================================================="
    printf "%-30s %15s %15s %15s\n" "Metric" "Current" "New" "Change"
    echo "---------------------------------------------------------------"
    
    CPU_DIFF=$((NEW_CORES - CURRENT_CORES))
    CPU_PCT=$((CPU_DIFF * 100 / CURRENT_CORES))
    printf "%-30s %15s %15s %+15s\n" "Physical Cores" "$CURRENT_CORES" "$NEW_CORES" "$CPU_PCT%"
    
    if [ -n "$CURRENT_FREQ" ] && [ -n "$NEW_FREQ" ]; then
        FREQ_DIFF=$((NEW_FREQ - CURRENT_FREQ))
        FREQ_PCT=$((FREQ_DIFF * 100 / CURRENT_FREQ))
        printf "%-30s %13s MHz %13s MHz %+13s%%\n" "Clock Speed" "$CURRENT_FREQ" "$NEW_FREQ" "$FREQ_PCT"
    fi
    echo ""
    
    # Extract Memory info
    CURRENT_MEM=$(extract_value "$CURRENT_FILE" "Total Memory:")
    NEW_MEM=$(extract_value "$NEW_FILE" "Total Memory:")
    
    echo "2. MEMORY COMPARISON"
    echo "==============================================================="
    printf "%-30s %15s %15s %15s\n" "Metric" "Current (MB)" "New (MB)" "Change"
    echo "---------------------------------------------------------------"
    
    MEM_DIFF=$((NEW_MEM - CURRENT_MEM))
    MEM_PCT=$((MEM_DIFF * 100 / CURRENT_MEM))
    printf "%-30s %15s %15s %+15s\n" "Total Memory" "$CURRENT_MEM" "$NEW_MEM" "$MEM_PCT%"
    
    # Memory sufficiency check
    if [ $NEW_MEM -lt 2048 ]; then
        echo ""
        echo "  ⚠️  WARNING: New server has less than 2GB RAM"
        echo "      Not recommended for production deployment"
    elif [ $NEW_MEM -lt 4096 ]; then
        echo ""
        echo "  ✓ Suitable for small/medium deployments"
    else
        echo ""
        echo "  ✓ Adequate for production deployments"
    fi
    echo ""
    
    # Extract capacity info
    CURRENT_INSTANCES=$(extract_value "$CURRENT_FILE" "Recommended Instances:")
    NEW_INSTANCES=$(extract_value "$NEW_FILE" "Recommended Instances:")
    
    CURRENT_USERS=$(grep -A10 "ESTIMATED CONCURRENT USER CAPACITY" "$CURRENT_FILE" | grep "sustained concurrent users" | grep -oE '[0-9]+' | head -1)
    NEW_USERS=$(grep -A10 "ESTIMATED CONCURRENT USER CAPACITY" "$NEW_FILE" | grep "sustained concurrent users" | grep -oE '[0-9]+' | head -1)
    
    echo "3. CAPACITY COMPARISON"
    echo "==============================================================="
    printf "%-30s %15s %15s %15s\n" "Metric" "Current" "New" "Change"
    echo "---------------------------------------------------------------"
    
    INSTANCE_DIFF=$((NEW_INSTANCES - CURRENT_INSTANCES))
    printf "%-30s %15s %15s %+15s\n" "Recommended Instances" "$CURRENT_INSTANCES" "$NEW_INSTANCES" "$INSTANCE_DIFF"
    
    USERS_DIFF=$((NEW_USERS - CURRENT_USERS))
    USERS_PCT=$((USERS_DIFF * 100 / CURRENT_USERS))
    printf "%-30s %15s %15s %+15s\n" "Concurrent Users" "$CURRENT_USERS" "$NEW_USERS" "$USERS_PCT%"
    echo ""
    
    # Assessment
    echo "4. CAPACITY ASSESSMENT"
    echo "==============================================================="
    
    if [ $NEW_USERS -ge $((CURRENT_USERS * 75 / 100)) ]; then
        echo "  ✓ New server can handle 75%+ of current capacity"
    fi
    
    if [ $NEW_USERS -eq $CURRENT_USERS ]; then
        echo "  ✓ New server matches current capacity (equivalent)"
    elif [ $NEW_USERS -gt $CURRENT_USERS ]; then
        IMPROVEMENT=$((NEW_USERS * 100 / CURRENT_USERS - 100))
        echo "  ✓ New server is ${IMPROVEMENT}% more powerful"
        echo "  → Can handle increased load"
    else
        REDUCTION=$((100 - NEW_USERS * 100 / CURRENT_USERS))
        echo "  ⚠ New server is ${REDUCTION}% less powerful"
        
        if [ $REDUCTION -lt 25 ]; then
            echo "     Acceptable for: Supplementary/failover deployment"
        elif [ $REDUCTION -lt 50 ]; then
            echo "     Use for: Development, testing, or staging"
        else
            echo "     ✗ NOT suitable for: Production replacement"
        fi
    fi
    echo ""
    
    # Recommendation
    echo "5. DEPLOYMENT RECOMMENDATIONS"
    echo "==============================================================="
    
    if [ $NEW_USERS -ge $((CURRENT_USERS * 80 / 100)) ]; then
        echo ""
        echo "  Primary Deployment Option:"
        echo "    • Deploy full EduTube stack on new server"
        echo "    • Use current server for: Backup/Failover"
        echo "    • Load balancing: Route traffic based on latency"
        echo ""
    elif [ $NEW_USERS -ge $((CURRENT_USERS / 2)) ]; then
        echo ""
        echo "  Recommended Deployment:"
        echo "    • Current server: Run full stack (primary)"
        echo "    • New server: Run as supplementary instance"
        echo "    • Load balancing: Distribute traffic 60-40 or 70-30"
        echo "    • Failover: New server can handle ~$NEW_USERS users if needed"
        echo ""
    else
        echo ""
        echo "  Deployment Strategy:"
        echo "    • Keep current server as primary production"
        echo "    • Use new server for: Development, staging, testing"
        echo "    • Or: As dedicated database/cache server"
        echo "    • Plan: Upgrade or add more resources to new server"
        echo ""
    fi
    
    # Cost-benefit analysis
    echo "6. COST-BENEFIT ANALYSIS"
    echo "==============================================================="
    
    if [ $NEW_CORES -gt $CURRENT_CORES ]; then
        echo "  Better CPU: $(($NEW_CORES * 100 / $CURRENT_CORES))% improvement"
    else
        echo "  Equivalent CPU"
    fi
    
    if [ $NEW_MEM -gt $CURRENT_MEM ]; then
        echo "  More Memory: $(($NEW_MEM * 100 / $CURRENT_MEM))% improvement"
    else
        echo "  Equivalent Memory"
    fi
    
    echo ""
    if [ $NEW_USERS -gt $((CURRENT_USERS * 125 / 100)) ]; then
        echo "  ✓ VERDICT: Excellent upgrade - significantly better capacity"
    elif [ $NEW_USERS -ge $((CURRENT_USERS * 90 / 100)) ]; then
        echo "  ✓ VERDICT: Good upgrade - comparable or slightly better"
    elif [ $NEW_USERS -ge $((CURRENT_USERS * 75 / 100)) ]; then
        echo "  ⚠ VERDICT: Modest capacity - good for supplementary role"
    else
        echo "  ✗ VERDICT: Limited upgrade - not suitable as primary"
    fi
    echo ""
    
    # Migration planning
    echo "7. MIGRATION PLANNING"
    echo "==============================================================="
    
    if [ $NEW_USERS -gt $CURRENT_USERS ]; then
        echo ""
        echo "  Phase 1 (Week 1):"
        echo "    • Deploy on new server"
        echo "    • Verify all services functional"
        echo "    • Run 24-hour smoke tests"
        echo ""
        echo "  Phase 2 (Week 2):"
        echo "    • Direct 10% traffic to new server"
        echo "    • Monitor error rates and latency"
        echo "    • Gradually increase to 50%"
        echo ""
        echo "  Phase 3 (Week 3):"
        echo "    • Route all traffic to new server"
        echo "    • Keep current server as standby"
        echo "    • Monitor for 1 week"
        echo ""
        echo "  Phase 4:"
        echo "    • Current server becomes backup"
        echo "    • Or repurpose for database/cache cluster"
        echo ""
    else
        echo ""
        echo "  Recommended Approach:"
        echo "    • Deploy on both servers (load balancing)"
        echo "    • Configure active-active or active-passive setup"
        echo "    • Use health checks for automatic failover"
        echo "    • Implement session replication"
        echo ""
    fi
    
    # Testing checklist
    echo "8. PRE-MIGRATION CHECKLIST"
    echo "==============================================================="
    echo ""
    echo "  Before switching to new server:"
    echo "    [ ] Run capacity analysis script on both servers"
    echo "    [ ] Perform load tests (start at 50%, ramp up)"
    echo "    [ ] Verify database replication/backup strategy"
    echo "    [ ] Test failover procedures"
    echo "    [ ] Verify DNS/load balancer configuration"
    echo "    [ ] Document both server configurations"
    echo "    [ ] Plan maintenance window (if needed)"
    echo "    [ ] Brief team on deployment plan"
    echo "    [ ] Monitor application logs during migration"
    echo ""
    
    echo "==============================================================="
    echo "Comparison completed at $(date)"
    echo "==============================================================="

} | tee "$COMPARISON_REPORT"

echo ""
echo -e "${GREEN}✓ Comparison complete!${NC}"
echo -e "${BLUE}Report saved to: $COMPARISON_REPORT${NC}"
echo ""
