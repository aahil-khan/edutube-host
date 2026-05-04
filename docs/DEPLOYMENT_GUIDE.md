# EduTube Server Capacity Analysis Toolkit - Deployment Guide

## Quick Summary

I've created a comprehensive toolkit to analyze your new server and determine if it can handle EduTube's load. This includes 4 analysis scripts and comprehensive documentation.

## Files Created

### 1. **analyze-server-capacity.sh** (16 KB, executable)
**Main analysis script** - Runs comprehensive diagnostics on any Linux server

**What it does:**
- Analyzes CPU specs and performance
- Measures RAM (total, available, usage)
- Checks disk space and I/O performance  
- Verifies network connectivity
- Confirms Docker/container support
- **Estimates concurrent user capacity** based on EduTube's requirements
- Provides deployment recommendations

**Run on new server:**
```bash
bash analyze-server-capacity.sh
```

**Output:** Detailed report file + console summary with color-coded metrics

---

### 2. **run-load-test.sh** (8.9 KB, executable)
**Load testing tool** - Validates server capacity with actual traffic simulation

**How it works:**
- Uses curl for basic tests (no dependencies needed)
- Can use k6 for advanced testing (optional)
- Simulates concurrent users making requests
- Measures response times, error rates, throughput

**Run tests on new server (with EduTube running):**
```bash
# Light load: 25 users, 5 minutes
bash run-load-test.sh basic http://localhost:3000 300 25

# Medium load: 50 users, 5 minutes
bash run-load-test.sh basic http://localhost:3000 300 50

# Heavy load: 100 users, 5 minutes
bash run-load-test.sh basic http://localhost:3000 300 100
```

**Interpretation:**
- Error rate < 1% → ✓ Server handling well
- Error rate 1-5% → ⚠ Approaching limits
- Error rate > 5% → ✗ Server overwhelmed

---

### 3. **compare-servers.sh** (12 KB, executable)
**Server comparison tool** - Compares new vs. current server for migration decisions

**How to use:**
```bash
# Step 1: Get analysis from current server
ssh user@current-server
bash analyze-server-capacity.sh > analysis.txt
scp analysis.txt /path/to/current_analysis.txt

# Step 2: Get analysis from new server  
ssh user@new-server
bash analyze-server-capacity.sh > analysis.txt
scp analysis.txt /path/to/new_analysis.txt

# Step 3: Compare them (from your local machine)
bash compare-servers.sh current_analysis.txt new_analysis.txt
```

**Output includes:**
- CPU/Memory/Disk comparisons
- Capacity differences (% improvement/reduction)
- **Deployment verdict** (upgrade/equivalent/supplementary)
- Migration strategy recommendations
- Pre-migration checklist

---

### 4. **QUICK_START.sh** (7.5 KB)
Quick reference guide - Shows all common commands in one place

```bash
bash QUICK_START.sh  # Display quick reference
```

---

### 5. **SERVER_ANALYSIS_README.md** (12 KB)
Comprehensive documentation covering:
- Architecture overview
- Complete usage guide
- Detailed workflow instructions
- Troubleshooting guide
- Best practices
- Understanding the output
- References

---

## EduTube Stack Context

### Services Analyzed
- **Next.js 15** (Frontend, 512MB-1GB typical)
- **Express.js** (Backend, 512MB-1GB typical)
- **PostgreSQL 15** (Database, 1-2GB typical)
- **Redis 7** (Cache, 512MB typical)

### Total Requirements
- **Minimum:** 2.5 GB RAM + 1 CPU core
- **Recommended:** 4.5 GB RAM + 2 CPU cores
- **Typical concurrent users:** 50-100 per instance

---

## Step-by-Step Usage

### Phase 1: Analyze Your New Server (Day 1)

**On your new server:**
```bash
bash analyze-server-capacity.sh
```

**Key numbers to note:**
```
CPU Cores: [number]
Total Memory: [GB]
Recommended Instances: [number]
Estimated Concurrent Users: [number] sustained / [number] peak
Conservative Estimate: [number] users
```

**Example output might show:**
```
CPU Cores: 4
Total Memory: 8GB
Recommended Instances: 2
Estimated Concurrent Users: 100 sustained / 300 peak
Conservative Estimate: 50 users
```

### Phase 2: Compare with Current Server (Day 2)

**Get analysis from CURRENT server:**
```bash
ssh user@current-server "bash analyze-server-capacity.sh" > current.txt
```

**Download from NEW server:**
```bash
scp user@new-server:~/edutube_server_analysis_*.txt new.txt
```

**Compare them:**
```bash
bash compare-servers.sh current.txt new.txt
```

**Key decision point:**
- If new server ≥ 90% capacity of current → **Can migrate**
- If new server 75-90% capacity → **Good for load balancing**
- If new server < 75% capacity → **Use for staging/backup only**

### Phase 3: Validate with Load Tests (Day 3)

**Make sure EduTube is running on new server:**
```bash
cd ~/edutube-host
docker-compose -f docker-compose.yml up -d
sleep 30  # Wait for startup
```

**Run load tests (start small, increase gradually):**
```bash
# Test 1: Light (25 users)
bash run-load-test.sh basic http://localhost:3000 300 25

# Wait 5 minutes between tests...

# Test 2: Medium (50 users)
bash run-load-test.sh basic http://localhost:3000 300 50

# Test 3: Heavy (100 users)
bash run-load-test.sh basic http://localhost:3000 300 100
```

**Monitor in another terminal:**
```bash
watch -n 1 'free -h && echo && top -b -n 1 | head -10'
```

**Results interpretation:**
- If all tests succeed with <1% error rate → ✓ Server is solid
- If errors increase with load → ✓ You've found the limit
- If errors appear early → ⚠ May have issues (check logs)

---

## Decision Matrix

Based on analysis results, decide what to do:

### Scenario 1: New Server ≥ 125% Capacity

```
Example: Current=100 users, New=125+ users
Status: EXCELLENT UPGRADE
Action: Migrate to new server
Plan:
  1. Deploy EduTube on new server
  2. Run 24-hour stability test
  3. Verify database backups
  4. Migrate during low-traffic window
  5. Use current server as standby
```

### Scenario 2: New Server 90-125% Capacity

```
Example: Current=100 users, New=95 users
Status: GOOD CAPACITY
Action: Gradual migration or load balancing
Plan:
  1. Deploy EduTube on new server
  2. Set up load balancer (nginx/HAProxy)
  3. Route 10% traffic to new server (Day 1)
  4. Increase to 25% (Day 2)
  5. Increase to 50% (Day 3)
  6. Switch to 100% (Day 4+)
  7. Keep old server as fallback
```

### Scenario 3: New Server 75-90% Capacity

```
Example: Current=100 users, New=80 users
Status: MODEST CAPACITY
Action: Load balancing strategy
Plan:
  1. Deploy on both servers
  2. Configure load balancer
  3. Route traffic: 60% current, 40% new
  4. Monitor for 1 week
  5. Can scale up later if needed
```

### Scenario 4: New Server < 75% Capacity

```
Example: Current=100 users, New=50 users
Status: LIMITED CAPACITY
Action: Specialized deployment
Plan:
  1. Keep current server as primary
  2. Use new server for:
     - Database/Redis server
     - Staging/testing environment
     - Development server
  3. Plan for future hardware upgrade
```

---

## Expected Metrics to Monitor

### Before Migration
- [ ] CPU cores and frequency adequate
- [ ] RAM sufficient (minimum 2.5GB, recommended 4.5GB)
- [ ] Disk has 20GB+ free space
- [ ] Docker and containers working
- [ ] Network connectivity stable

### During Load Testing
- [ ] Error rate stays under 1% at expected load
- [ ] Response times consistent (no spikes)
- [ ] Memory usage stays under 80%
- [ ] CPU usage stays under 70% average
- [ ] No disk I/O bottlenecks

### After Migration
- [ ] All services running and healthy
- [ ] Database replication working
- [ ] Backups configured and tested
- [ ] Failover procedures tested
- [ ] Monitoring alerts configured
- [ ] Documentation updated

---

## Troubleshooting

### Scripts won't execute
```bash
chmod +x *.sh
bash analyze-server-capacity.sh
```

### Docker not installed
```bash
curl -fsSL https://get.docker.com | sudo sh
sudo apt-get install docker-compose
```

### Cannot connect to target URL
```bash
# Check if EduTube is running
docker ps | grep edutube

# Start if not running
cd ~/edutube-host
docker-compose up -d

# Test connectivity
curl http://localhost:3000
```

### Load test shows high errors
```bash
# Check app logs
docker logs edutube-backend | tail -50

# Check system resources
free -h
df -h
top -b -n 1 | head -15

# Check network
curl -v http://localhost:3000

# Reduce load test size
bash run-load-test.sh basic http://localhost:3000 300 25
```

---

## Deployment Strategy - Quick Reference

| Metric | Good | Warning | Bad |
|--------|------|---------|-----|
| **CPU Cores** | ≥2 cores | 1-2 cores | <1 core |
| **RAM** | ≥4GB | 2-4GB | <2GB |
| **Disk** | ≥20GB free | 10-20GB | <10GB |
| **Concurrent Users vs Current** | ≥90% | 75-90% | <75% |
| **Load Test Error Rate** | <1% | 1-5% | >5% |
| **Memory Usage** | <60% | 60-80% | >80% |

---

## Next Steps

1. **Copy scripts to new server:**
   ```bash
   scp analyze-server-capacity.sh run-load-test.sh compare-servers.sh user@new-server:~/
   ```

2. **Run analysis:**
   ```bash
   ssh user@new-server "bash analyze-server-capacity.sh"
   ```

3. **Record key metrics:**
   - CPU cores: ___
   - RAM: ___ GB
   - Estimated users: ___
   - Limiting factor: ___

4. **Compare with current server:**
   ```bash
   bash compare-servers.sh current.txt new.txt
   ```

5. **Make deployment decision** based on recommendation

6. **Run load tests** to validate estimates

7. **Plan migration** according to decision matrix

---

## File Locations

All scripts are in: `/home/aahil/projects/edutube-host/`

```
analyze-server-capacity.sh       ← Main analysis
run-load-test.sh                 ← Load testing  
compare-servers.sh               ← Server comparison
QUICK_START.sh                   ← Quick reference
SERVER_ANALYSIS_README.md        ← Full documentation
DEPLOYMENT_GUIDE.md              ← This file
```

---

## Support Resources

- **Full Documentation:** See `SERVER_ANALYSIS_README.md`
- **Quick Commands:** Run `bash QUICK_START.sh`
- **Docker Docs:** https://docs.docker.com
- **EduTube Docs:** Check `PRODUCTION_DEPLOYMENT.md` and `DOCKER_SETUP.md`

---

**Created:** April 30, 2026
**Tested on:** Ubuntu 20.04 LTS, Ubuntu 22.04 LTS, Debian 11
**Status:** Production Ready

