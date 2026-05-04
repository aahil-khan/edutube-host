# EduTube Server Capacity Analysis Toolkit

This toolkit helps you comprehensively analyze Linux servers for EduTube deployment and determine their capacity to handle user load.

## Overview

The toolkit consists of three main scripts:

1. **`analyze-server-capacity.sh`** - Analyzes a single server's hardware and estimates load capacity
2. **`run-load-test.sh`** - Performs load testing to validate capacity estimates
3. **`compare-servers.sh`** - Compares two server analyses to help migration planning

## Architecture Understanding

EduTube Stack:
- **Frontend**: Next.js 15 (React framework)
- **Backend**: Node.js + Express.js REST API
- **Database**: PostgreSQL 15 (Alpine Docker)
- **Cache**: Redis 7 (Alpine Docker)
- **Container Runtime**: Docker + Docker Compose

### Resource Requirements

**Minimum per instance:**
- Next.js Frontend: 512 MB
- Express Backend: 512 MB  
- PostgreSQL: 1024 MB
- Redis: 512 MB
- **Total Minimum: 2.5 GB RAM**

**Recommended per instance:**
- All services: 4.5 GB RAM
- 2 CPU cores
- 10GB disk space

## Usage Guide

### Step 1: Analyze Your Current Server

```bash
# On your CURRENT server
ssh user@current-server
bash analyze-server-capacity.sh > ~/current_analysis.txt

# Download the report
scp user@current-server:~/current_analysis.txt ./
```

### Step 2: Analyze the New Server

```bash
# On your NEW server
ssh user@new-server
bash analyze-server-capacity.sh > ~/new_analysis.txt

# Download the report
scp user@new-server:~/new_analysis.txt ./
```

### Step 3: Compare Servers

```bash
# On your local machine
bash compare-servers.sh current_analysis.txt new_analysis.txt
```

This will generate a detailed comparison showing:
- CPU, Memory, and Disk comparisons
- Capacity differences
- Concurrent user capacity
- Deployment recommendations
- Migration planning guidance

## Detailed Script Usage

### analyze-server-capacity.sh

**Purpose**: Comprehensive analysis of a single server

**What it analyzes:**
- CPU cores, threads, model, frequency, and flags
- RAM (total, available, used, swap)
- Disk space and I/O performance
- Network interfaces and connectivity
- Docker/container runtime
- OS kernel and container features
- Current system load
- EduTube-specific resource requirements
- Estimated concurrent user capacity

**Output:**
- Console output with color-coded summary
- Detailed report file: `edutube_server_analysis_YYYYMMDD_HHMMSS.txt`

**Key Metrics:**
- **Recommended Instances**: How many EduTube instances can run
- **Estimated Concurrent Users**: Sustained load capacity
- **Peak Concurrent Users**: ~3x sustained load
- **Performance Score**: Overall server capability

**Example Output Interpretation:**

```
Recommended Instances: 2
Limiting Factor: Available Memory

Estimated Concurrent Users: 100 (sustained) / 300 (peak)
Conservative Estimate: 50 users
```

This means:
- The server can run 2 instances of EduTube
- Under normal load: ~100 concurrent users
- During traffic spikes: up to 300 concurrent users  
- Conservative (safe) estimate: 50 concurrent users

### run-load-test.sh

**Purpose**: Validate server capacity with actual load testing

**Syntax:**
```bash
bash run-load-test.sh [test_type] [target_url] [duration] [concurrent_users]
```

**Parameters:**
- `test_type`: `basic` (curl-based) or `k6` (requires k6 installation)
- `target_url`: http://your-server:3000 (default)
- `duration`: Test duration in seconds (default: 300)
- `concurrent_users`: Number of parallel requests (default: 50)

**Examples:**

```bash
# Basic 5-minute test with 50 concurrent users
bash run-load-test.sh basic http://new-server:3000 300 50

# Intermediate test with 100 users (requires k6)
bash run-load-test.sh k6 http://new-server:3000 300 100

# 10-minute sustained load test
bash run-load-test.sh basic http://new-server:3000 600 75
```

**Recommended Test Sequence:**

```bash
# Test 1: Light load (5 min, 25 users)
bash run-load-test.sh basic http://new-server:3000 300 25

# Test 2: Medium load (5 min, 50 users)  
bash run-load-test.sh basic http://new-server:3000 300 50

# Test 3: Heavy load (5 min, 100 users)
bash run-load-test.sh basic http://new-server:3000 300 100

# Test 4: Sustained load (15 min, capacity users)
bash run-load-test.sh basic http://new-server:3000 900 [capacity_users]
```

**Interpreting Results:**

```
Total Requests: 5000
Successful Requests: 4950 (99%)
Failed Requests: 50 (1%)
Average Response Time: 0.245s
Throughput: 16.67 req/s
```

- ✓ If error rate < 1% and response time < 500ms → Server handling load well
- ⚠ If error rate 1-5% → Monitor closely, approaching limits
- ✗ If error rate > 5% → Server overwhelmed, reduce load

**Monitoring During Tests:**

In another terminal on the test server, run:
```bash
watch -n 1 'free -h && echo && top -b -n 1 | head -15'
```

Watch for:
- Memory usage staying under 80%
- CPU usage staying under 70% average
- No significant disk I/O contention

### compare-servers.sh

**Purpose**: Compare two server analyses for migration planning

**Syntax:**
```bash
bash compare-servers.sh current_analysis.txt new_analysis.txt
```

**Output Includes:**
- CPU comparison (cores, frequency, % improvement)
- Memory comparison
- Capacity comparison (instances, concurrent users)
- Deployment verdict (upgrade, equivalent, supplementary)
- Migration planning phases
- Pre-migration checklist

**Deployment Verdicts:**

- **Excellent upgrade**: New server 125%+ better capacity
  - → Migrate all traffic to new server
  - → Use old server as backup

- **Good upgrade**: New server 90-125% capacity
  - → Gradual migration with load balancing
  - → Monitor closely

- **Modest capacity**: New server 75-90% capacity
  - → Use as supplementary/load balancing node
  - → Or as development/staging server

- **Limited upgrade**: New server <75% capacity
  - → Not suitable as primary replacement
  - → Consider as failover/cache server

## Complete Migration Workflow

### Phase 1: Assessment (Day 1)

```bash
# 1. Analyze current server
ssh user@current-server
bash analyze-server-capacity.sh > ~/analysis.txt
scp user@current-server:~/analysis.txt ./current_analysis.txt

# 2. Analyze new server
ssh user@new-server
bash analyze-server-capacity.sh > ~/analysis.txt
scp user@new-server:~/analysis.txt ./new_analysis.txt

# 3. Compare and plan
bash compare-servers.sh current_analysis.txt new_analysis.txt
# Review recommendations
```

### Phase 2: Validation (Days 2-3)

```bash
# On new server - light load test
bash run-load-test.sh basic http://localhost:3000 300 25

# On new server - medium load test
bash run-load-test.sh basic http://localhost:3000 300 50

# Monitor system resources during tests
watch -n 1 'free -h; echo; top -b -n 1 | head -10'
```

### Phase 3: Deployment Planning (Based on Results)

**If new server >= 90% of current capacity:**
```
Option A: Direct Migration
1. Deploy EduTube on new server
2. Test for 24 hours
3. Verify database backups
4. Cut over during low-traffic window
5. Keep old server as standby for 1 week

Option B: Gradual Migration (recommended)
1. Deploy EduTube on new server
2. Set up load balancer between servers
3. Route 10% traffic to new server (1 day)
4. Increase to 25% (1 day)
5. Increase to 50% (1 day)
6. Switch to 100% new server
7. Keep old as failover (optional)
```

**If new server 75-90% of current capacity:**
```
Option: Load Balancing Strategy
1. Deploy on both servers
2. Configure load balancer (nginx/HAProxy)
3. Route traffic: 60% current, 40% new
4. Monitor for 1 week
5. Can increase new server capacity later
```

**If new server < 75% of current capacity:**
```
Option: Specialized Deployment
1. Use old server: Primary (web + app)
2. Use new server: Database/Redis only
3. Or: Use new for staging/development
4. Plan upgrade path for new server
```

## Troubleshooting

### Scripts won't run
```bash
# Make scripts executable
chmod +x analyze-server-capacity.sh run-load-test.sh compare-servers.sh

# Run with bash explicitly
bash analyze-server-capacity.sh
```

### analyze-server-capacity.sh shows "Docker: Not installed"
```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Install Docker Compose
sudo apt-get install docker-compose
```

### iostat not available (optional, non-critical)
```bash
# Install sysstat for disk I/O analysis
sudo apt-get install sysstat
```

### run-load-test.sh needs k6
```bash
# Install k6 (optional, for advanced testing)
sudo apt-get install -y gnupg software-properties-common
sudo add-apt-repository "ppa:k6/k6"
sudo apt-get install k6
```

### Load test shows high error rate
**Possible causes:**
1. Server is overloaded → reduce concurrent users or duration
2. Application not running → start EduTube services
3. Port mismatch → verify target URL
4. Firewall blocking → check security groups/rules
5. Out of memory → check disk space and RAM

**Solution:**
```bash
# Check if services are running
docker ps  # or: systemctl status docker

# Check logs
docker logs edutube-backend  # or: journalctl -u edutube

# Check network
curl http://localhost:3000  # or: your-server IP

# Check resources
free -h
df -h
```

## Best Practices

### For Accurate Estimates

1. **Run during representative times**: Test when typical load is present (or simulate it)
2. **Warm up first**: Let services settle before measuring
3. **Multiple runs**: Average results from 2-3 runs
4. **Real-world scenarios**: Test with actual user patterns, not just RPS
5. **Include database**: Don't just test frontend; include database queries

### For Safe Deployment

1. **Start conservative**: Use 50% of calculated capacity initially
2. **Monitor closely**: First week requires attention
3. **Gradual increases**: Increase load by 25% weekly
4. **Have rollback plan**: Keep old server or recent backup
5. **Test failover**: Verify backup/failover procedures work
6. **Schedule maintenance**: Migrate during low-traffic windows

### For Long-term Capacity

1. **Track metrics**: Log resource usage over time
2. **Plan growth**: Estimate user growth rate
3. **Set alerts**: Alert when usage exceeds thresholds
4. **Version control**: Track configuration changes
5. **Document**: Keep notes on modifications and learnings

## Understanding the Output

### Key Metrics Explained

- **CPU Cores**: Physical processors available
- **CPU Threads**: Logical processors (cores × threads per core)
- **Available Memory**: RAM currently free for use
- **Performance Score**: Composite score (higher is better)
- **Concurrent Users**: Estimated simultaneous connections
- **Peak Concurrent Users**: 3× sustained (traffic spikes)
- **Conservative Estimate**: 50% of estimated (safety buffer)

### Estimation Methodology

The scripts use these assumptions:

- Each Node.js worker: ~50 concurrent connections
- Each CPU core: ~25 concurrent connections  
- Memory: 50% reserved for database/cache, 50% for compute
- Overhead: 20% system reserve (never fully allocate)
- Peak load: 3× average sustained load

## References & Additional Resources

### EduTube Documentation
- Check PRODUCTION_DEPLOYMENT.md for deployment specifics
- Review docker-compose.yml for service requirements
- Check DOCKER_SETUP.md for environment setup

### Performance Tuning
- PostgreSQL: Configure max_connections based on concurrent users
- Redis: Set maxmemory and eviction policy
- Node.js: Enable clustering with NODE_ENV=production
- Docker: Use resource limits (memory, CPU)

### Load Testing Tools
- **k6**: Modern, script-based load testing
- **Apache JMeter**: GUI-based, feature-rich
- **Artillery**: YAML-configured, Node.js based
- **Locust**: Python-based, distributed testing

### Monitoring
- Set up prometheus/grafana for metrics
- Configure alerting for resource thresholds
- Track application performance metrics
- Monitor database performance

## Support

For issues or questions:

1. Check this README first
2. Review the Troubleshooting section
3. Run analyze-server-capacity.sh for diagnostic info
4. Check Docker and application logs
5. Consult EduTube project documentation

---

**Last Updated**: 2026-04-30
**Version**: 1.0
**Tested on**: Ubuntu 20.04 LTS, Ubuntu 22.04 LTS, Debian 11
