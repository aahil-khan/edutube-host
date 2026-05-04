#!/bin/bash

################################################################################
# EduTube Server Capacity Analysis Script
# 
# This script comprehensively analyzes a Linux server and estimates its capacity
# to handle the EduTube platform load.
# 
# EduTube Stack:
#   - Frontend: Next.js 15.1.2
#   - Backend: Node.js + Express
#   - Database: PostgreSQL 15 (Alpine)
#   - Cache: Redis 7 (Alpine)
#   - Optional: Elasticsearch for search
#   - Container Runtime: Docker + Docker Compose
#
# Usage: bash analyze-server-capacity.sh
################################################################################

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Constants for edutube resource requirements (based on containerized deployment)
NEXT_FRONTEND_MIN_RAM_MB=512
NEXT_FRONTEND_RECOMMENDED_RAM_MB=1024
EXPRESS_BACKEND_MIN_RAM_MB=512
EXPRESS_BACKEND_RECOMMENDED_RAM_MB=1024
POSTGRES_MIN_RAM_MB=1024
POSTGRES_RECOMMENDED_RAM_MB=2048
REDIS_MIN_RAM_MB=512
REDIS_RECOMMENDED_RAM_MB=512

# Concurrent user estimates (per container instance)
USERS_PER_BACKEND_INSTANCE=50    # Express backend can handle ~50 concurrent users
USERS_PER_FRONTEND_POD=100       # Next.js can handle ~100 concurrent users
USERS_PER_POSTGRES_INSTANCE=500  # PostgreSQL connection pool ~100-200 connections

# Output file
ANALYSIS_FILE="edutube_server_analysis_$(date +%Y%m%d_%H%M%S).txt"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}EduTube Server Capacity Analysis${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Analysis Date: $(date)"
echo "Hostname: $(hostname)"
echo "Analysis Output: $ANALYSIS_FILE"
echo ""

{
    echo "==============================================="
    echo "EduTube Server Capacity Analysis Report"
    echo "Generated: $(date)"
    echo "Hostname: $(hostname)"
    echo "Kernel: $(uname -r)"
    echo "==============================================="
    echo ""

    # ===== SECTION 1: CPU ANALYSIS =====
    echo "1. CPU ANALYSIS"
    echo "==============================================="
    
    CPU_CORES=$(nproc)
    CPU_THREADS=$(grep -c '^processor' /proc/cpuinfo 2>/dev/null || printf '1')
    
    echo "Physical CPU Cores: $CPU_CORES"
    echo "Logical CPU Threads: $CPU_THREADS"
    
    # Get CPU model
    CPU_MODEL=$(grep "model name" /proc/cpuinfo | head -1 | cut -d: -f2 | xargs)
    echo "CPU Model: $CPU_MODEL"
    
    # Get CPU frequency
    if [ -f /proc/cpuinfo ]; then
        CPU_FREQ=$(grep "cpu MHz" /proc/cpuinfo | head -1 | cut -d: -f2 | xargs)
        echo "CPU Frequency: ${CPU_FREQ} MHz"
    fi
    
    # Get CPU flags
    CPU_FLAGS=$(grep "flags" /proc/cpuinfo | head -1 | cut -d: -f2 | xargs)
    SELECTED_FLAGS=$(printf '%s' "$CPU_FLAGS" | grep -Eo 'sse|avx|aes|virt|pae' | paste -sd ',' - 2>/dev/null || true)
    echo "CPU Flags (selected): ${SELECTED_FLAGS:-none detected}"
    echo ""
    
    # ===== SECTION 2: MEMORY ANALYSIS =====
    echo "2. MEMORY ANALYSIS"
    echo "==============================================="
    
    TOTAL_MEM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    TOTAL_MEM_MB=$((TOTAL_MEM_KB / 1024))
    TOTAL_MEM_GB=$((TOTAL_MEM_MB / 1024))
    
    AVAILABLE_MEM_KB=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
    AVAILABLE_MEM_MB=$((AVAILABLE_MEM_KB / 1024))
    
    USED_MEM_MB=$((TOTAL_MEM_MB - AVAILABLE_MEM_MB))
    MEM_USAGE_PCT=$((USED_MEM_MB * 100 / TOTAL_MEM_MB))
    
    echo "Total Memory: ${TOTAL_MEM_GB}GB (${TOTAL_MEM_MB}MB)"
    echo "Available Memory: ${AVAILABLE_MEM_MB}MB"
    echo "Used Memory: ${USED_MEM_MB}MB (${MEM_USAGE_PCT}%)"
    
    # Swap analysis
    SWAP_TOTAL_KB=$(grep SwapTotal /proc/meminfo | awk '{print $2}')
    SWAP_TOTAL_MB=$((SWAP_TOTAL_KB / 1024))
    SWAP_FREE_KB=$(grep SwapFree /proc/meminfo | awk '{print $2}')
    SWAP_FREE_MB=$((SWAP_FREE_KB / 1024))
    
    echo "Swap Total: ${SWAP_TOTAL_MB}MB"
    echo "Swap Free: ${SWAP_FREE_MB}MB"
    echo ""
    
    # ===== SECTION 3: DISK ANALYSIS =====
    echo "3. DISK ANALYSIS"
    echo "==============================================="
    
    df -h / | tail -1 | awk '{print "Root Filesystem: " $1 "\n  Total: " $2 "\n  Used: " $3 " (" $5 ")\n  Available: " $4}'
    
    # Check for /var and /tmp if separate
    if [ "$(df /var 2>/dev/null | wc -l)" -gt 1 ]; then
        echo ""
        df -h /var | tail -1 | awk '{print "/var Filesystem: " $1 "\n  Total: " $2 "\n  Used: " $3 " (" $5 ")\n  Available: " $4}'
    fi
    
    # Disk I/O check
    if command -v iostat &> /dev/null; then
        echo ""
        echo "Disk I/O Performance (first disk):"
        iostat -d -x 1 2 2>/dev/null | tail -5 || echo "  (iostat output not available)"
    else
        echo ""
        echo "Note: iostat not installed (install sysstat package for I/O analysis)"
    fi
    echo ""
    
    # ===== SECTION 4: NETWORK ANALYSIS =====
    echo "4. NETWORK ANALYSIS"
    echo "==============================================="
    
    echo "Network Interfaces:"
    ip link show | grep "^[0-9]" | awk -F: '{print "  " $2}' | while read iface; do
        ip addr show $iface 2>/dev/null | grep "inet " | awk '{print "    IPv4: " $2}'
    done
    
    # Check connectivity
    echo ""
    echo "Connectivity Tests:"
    if ping -c 1 8.8.8.8 &> /dev/null; then
        echo "  Internet: ✓ Connected"
        LATENCY=$(ping -c 1 8.8.8.8 2>&1 | grep time= | awk -F'time=' '{print $2}')
        echo "  Latency: $LATENCY"
    else
        echo "  Internet: ✗ Not reachable"
    fi
    
    # DNS resolution
    if nslookup google.com &>/dev/null; then
        echo "  DNS: ✓ Working"
    else
        echo "  DNS: ✗ Not working"
    fi
    echo ""
    
    # ===== SECTION 5: DOCKER & CONTAINER RUNTIME =====
    echo "5. CONTAINER RUNTIME ANALYSIS"
    echo "==============================================="
    
    if command -v docker &> /dev/null; then
        DOCKER_VERSION=$(docker --version)
        echo "Docker: ✓ Installed"
        echo "  Version: $DOCKER_VERSION"
        
        # Docker daemon info
        if docker info &>/dev/null; then
            DOCKER_STORAGE=$(docker info 2>/dev/null | grep "Storage Driver" | awk -F: '{print $2}' | xargs)
            echo "  Storage Driver: $DOCKER_STORAGE"
            
            DOCKER_MEMORY=$(docker info 2>/dev/null | grep "Memory Limit:" | awk -F: '{print $2}' | xargs)
            if [ -n "$DOCKER_MEMORY" ]; then
                echo "  Memory Limit: $DOCKER_MEMORY"
            fi
        fi
    else
        echo "Docker: ✗ Not installed"
    fi
    
    echo ""
    if command -v docker-compose &> /dev/null; then
        echo "Docker Compose: ✓ Installed ($(docker-compose --version | awk '{print $NF}'))"
    else
        echo "Docker Compose: ✗ Not installed"
    fi
    echo ""
    
    # ===== SECTION 6: KERNEL & OS =====
    echo "6. OPERATING SYSTEM & KERNEL"
    echo "==============================================="
    
    OS_INFO=$(cat /etc/os-release 2>/dev/null | grep "PRETTY_NAME" | cut -d= -f2 | tr -d '"')
    echo "OS: $OS_INFO"
    echo "Kernel: $(uname -r)"
    
    # Check required kernel features for containers
    echo ""
    echo "Container Features:"
    [ -d /sys/kernel/cgroup ] && echo "  cgroups v1: ✓" || echo "  cgroups v1: ✗"
    [ -d /sys/fs/cgroup/cgroup.procs ] && echo "  cgroups v2: ✓" || echo "  cgroups v2: ✗"
    [ -e /dev/loop0 ] && echo "  loop devices: ✓" || echo "  loop devices: ✗"
    
    echo ""
    
    # ===== SECTION 7: CURRENT SYSTEM LOAD =====
    echo "7. CURRENT SYSTEM LOAD"
    echo "==============================================="
    
    LOAD_AVG=$(cat /proc/loadavg | awk '{print "1m: " $1 " 5m: " $2 " 15m: " $3}')
    echo "Load Average: $LOAD_AVG"
    
    UPTIME=$(uptime -p 2>/dev/null || uptime | awk -F, '{print $1}')
    echo "Uptime: $UPTIME"
    
    echo ""
    echo "Top Memory Consumers:"
    ps aux --sort=-%mem | head -6 | tail -5 | awk '{printf "  %s: %s MB (%s%%)\n", $11, int($6/1024), $4}'
    
    echo ""
    echo "Top CPU Consumers:"
    ps aux --sort=-%cpu | head -6 | tail -5 | awk '{printf "  %s: %s%% CPU\n", $11, $3}'
    echo ""
    
    # ===== SECTION 8: EDUTUBE RESOURCE REQUIREMENTS =====
    echo "8. EDUTUBE RESOURCE REQUIREMENTS"
    echo "==============================================="
    
    echo "Single Instance Requirements (Minimum):"
    TOTAL_MIN_MB=$((NEXT_FRONTEND_MIN_RAM_MB + EXPRESS_BACKEND_MIN_RAM_MB + POSTGRES_MIN_RAM_MB + REDIS_MIN_RAM_MB))
    echo "  Next.js Frontend: $NEXT_FRONTEND_MIN_RAM_MB MB"
    echo "  Express Backend: $EXPRESS_BACKEND_MIN_RAM_MB MB"
    echo "  PostgreSQL: $POSTGRES_MIN_RAM_MB MB"
    echo "  Redis: $REDIS_MIN_RAM_MB MB"
    echo "  Total Minimum: ${TOTAL_MIN_MB} MB"
    
    echo ""
    echo "Single Instance Requirements (Recommended):"
    TOTAL_REC_MB=$((NEXT_FRONTEND_RECOMMENDED_RAM_MB + EXPRESS_BACKEND_RECOMMENDED_RAM_MB + POSTGRES_RECOMMENDED_RAM_MB + REDIS_RECOMMENDED_RAM_MB))
    echo "  Next.js Frontend: $NEXT_FRONTEND_RECOMMENDED_RAM_MB MB"
    echo "  Express Backend: $EXPRESS_BACKEND_RECOMMENDED_RAM_MB MB"
    echo "  PostgreSQL: $POSTGRES_RECOMMENDED_RAM_MB MB"
    echo "  Redis: $REDIS_RECOMMENDED_RAM_MB MB"
    echo "  Total Recommended: ${TOTAL_REC_MB} MB"
    echo ""
    
    # ===== SECTION 9: CAPACITY ESTIMATION =====
    echo "9. CAPACITY ESTIMATION FOR THIS SERVER"
    echo "==============================================="
    
    # Calculate usable memory (80% of available, leaving 20% for OS and overhead)
    USABLE_MEM_MB=$((AVAILABLE_MEM_MB * 80 / 100))
    
    # Number of instances that can run
    INSTANCES_MIN=$((USABLE_MEM_MB / TOTAL_MIN_MB))
    INSTANCES_REC=$((USABLE_MEM_MB / TOTAL_REC_MB))
    INSTANCES_CPU=$((CPU_CORES / 2)) # Assume 2 cores per instance
    
    # Take conservative estimate (minimum of memory and CPU constraints)
    if [ $INSTANCES_CPU -lt $INSTANCES_MIN ]; then
        RECOMMENDED_INSTANCES=$INSTANCES_CPU
        LIMITING_FACTOR="CPU cores"
    else
        RECOMMENDED_INSTANCES=$INSTANCES_MIN
        LIMITING_FACTOR="Available Memory"
    fi
    
    echo "Memory Analysis:"
    echo "  Usable Memory (80% of available): ${USABLE_MEM_MB}MB"
    echo "  Max instances (memory, minimum): $INSTANCES_MIN"
    echo "  Max instances (memory, recommended): $INSTANCES_REC"
    
    echo ""
    echo "CPU Analysis:"
    echo "  Available CPU Cores: $CPU_CORES"
    echo "  Cores per instance: 2"
    echo "  Max instances (CPU): $INSTANCES_CPU"
    
    echo ""
    echo "RECOMMENDED CONFIGURATION:"
    echo "  Number of instances: $RECOMMENDED_INSTANCES"
    echo "  Limiting factor: $LIMITING_FACTOR"
    
    # Estimate concurrent users
    CONCURRENT_USERS=$((RECOMMENDED_INSTANCES * USERS_PER_BACKEND_INSTANCE))
    PEAK_CONCURRENT_USERS=$((CONCURRENT_USERS * 3)) # Peak is ~3x average
    
    echo ""
    echo "10. ESTIMATED CONCURRENT USER CAPACITY"
    echo "==============================================="
    echo "  Recommended instances: $RECOMMENDED_INSTANCES"
    echo "  Users per backend instance: $USERS_PER_BACKEND_INSTANCE"
    echo "  Estimated sustained concurrent users: $CONCURRENT_USERS"
    echo "  Estimated peak concurrent users: $PEAK_CONCURRENT_USERS"
    
    # Calculate based on CPU
    CPU_CONCURRENT=$((CPU_CORES * 25))  # ~25 concurrent connections per core
    echo ""
    echo "  Alternative estimate (CPU-based): $CPU_CONCURRENT concurrent users"
    
    # More conservative estimate
    CONSERVATIVE=$((CONCURRENT_USERS / 2))
    echo "  Conservative estimate (50% buffer): $CONSERVATIVE concurrent users"
    echo ""
    
    # ===== SECTION 11: COMPARISON WITH CURRENT SERVER =====
    echo "11. PERFORMANCE PROFILE"
    echo "==============================================="
    
    # Calculate performance score
    PERF_SCORE=$((CPU_CORES * 10 + (TOTAL_MEM_MB / 256)))
    echo "Server Performance Score: $PERF_SCORE (higher is better)"
    echo ""
    
    # Recommendations
    echo "12. RECOMMENDATIONS"
    echo "==============================================="
    
    if [ $AVAILABLE_MEM_MB -lt $TOTAL_MIN_MB ]; then
        echo "  ⚠️  WARNING: Server has less memory than minimum requirements!"
        echo "      Consider upgrading RAM or running single instance."
    fi
    
    if [ $CPU_CORES -lt 2 ]; then
        echo "  ⚠️  WARNING: Server has insufficient CPU cores (< 2)"
        echo "      Consider upgrading CPU or running single instance."
    fi
    
    if [ $MEM_USAGE_PCT -gt 70 ]; then
        echo "  ⚠️  WARNING: Memory usage already at ${MEM_USAGE_PCT}%"
        echo "      Close unnecessary services before deploying."
    fi
    
    echo ""
    echo "Deployment Strategy:"
    if [ $RECOMMENDED_INSTANCES -eq 1 ]; then
        echo "  • Run single instance deployment (all services on one container)"
        echo "  • Recommended for small to medium traffic"
        echo "  • Use for: Development, testing, small production instances"
    elif [ $RECOMMENDED_INSTANCES -le 3 ]; then
        echo "  • Run $RECOMMENDED_INSTANCES instances with load balancing (nginx/HAProxy)"
        echo "  • Suitable for: Medium traffic, some redundancy"
        echo "  • Use separate database server if possible"
    else
        echo "  • Run $RECOMMENDED_INSTANCES instances with load balancing"
        echo "  • Suitable for: High traffic, production environments"
        echo "  • Consider using managed database (RDS/Cloud SQL)"
        echo "  • Implement horizontal scaling with orchestration (Kubernetes)"
    fi
    
    echo ""
    echo "Performance Tuning:"
    echo "  • Use Alpine-based containers to minimize overhead"
    echo "  • Configure PostgreSQL with: max_connections = $(($CONCURRENT_USERS / 2))"
    echo "  • Set Redis maxmemory: $(($REDIS_RECOMMENDED_RAM_MB * 1024 * 1024))"
    echo "  • Configure Node.js cluster mode for CPU utilization"
    echo "  • Use connection pooling (PgBouncer for PostgreSQL)"
    echo "  • Enable compression for API responses"
    
    echo ""
    echo "Monitoring Setup:"
    echo "  • Monitor memory usage (target < 80%)"
    echo "  • Monitor CPU usage (target < 70% average)"
    echo "  • Track database connections and query performance"
    echo "  • Monitor container startup times and scaling"
    echo "  • Set alerts for resource exhaustion"
    
    echo ""
    echo "Load Testing Recommendations:"
    echo "  • Test with: $CONSERVATIVE - $CONCURRENT_USERS concurrent users"
    echo "  • Ramp-up time: 5-10 minutes"
    echo "  • Test duration: 30-60 minutes minimum"
    echo "  • Monitor: Response times, error rates, resource usage"
    echo "  • Tools: Apache JMeter, k6, Locust, Artillery"
    
    echo ""
    echo "==============================================="
    echo "Analysis completed at $(date)"
    echo "==============================================="

} | tee "$ANALYSIS_FILE"

# Display summary to console
echo ""
echo -e "${GREEN}✓ Analysis Complete!${NC}"
echo -e "${BLUE}Results saved to: $ANALYSIS_FILE${NC}"
echo ""

# Extract key metrics for quick reference
echo -e "${YELLOW}QUICK REFERENCE:${NC}"
echo -e "  CPU Cores: ${GREEN}$CPU_CORES${NC}"
echo -e "  RAM: ${GREEN}${TOTAL_MEM_GB}GB${NC}"
echo -e "  Recommended Instances: ${GREEN}$RECOMMENDED_INSTANCES${NC}"
echo -e "  Estimated Users: ${GREEN}$CONCURRENT_USERS (sustained) / $PEAK_CONCURRENT_USERS (peak)${NC}"
echo -e "  Conservative Estimate: ${GREEN}$CONSERVATIVE users${NC}"

echo ""
