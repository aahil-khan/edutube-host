# Tools Directory

Server analysis, load testing, and capacity planning tools.

## Available Tools

### Server Analysis

#### `analyze-server-capacity.sh`
Comprehensive server analysis tool that generates detailed diagnostics and capacity estimates.

**Usage:**
```bash
bash analyze-server-capacity.sh
```

**What it analyzes:**
- CPU cores, threads, model, frequency, and capabilities
- Memory (total, available, used, swap)
- Disk space and I/O performance
- Network connectivity and latency
- Docker and container runtime
- OS kernel features
- System load and resource usage
- EduTube-specific capacity estimates

**Output:**
- Console summary with color-coded metrics
- Detailed report file: `edutube_server_analysis_YYYYMMDD_HHMMSS.txt`

**Key metrics:**
- Recommended instances
- Estimated concurrent users (sustained & peak)
- Performance score
- Recommendations

### Load Testing

#### `run-load-test.sh`
Validates server capacity through load testing with simulated concurrent users.

**Usage:**
```bash
# Basic test (uses curl, no dependencies)
bash run-load-test.sh basic http://target:3000 300 50

# Advanced test (requires k6)
bash run-load-test.sh k6 http://target:3000 300 100
```

**Parameters:**
- `test_type`: `basic` (curl) or `k6` (advanced)
- `target_url`: Server address (default: http://localhost:3000)
- `duration`: Test duration in seconds (default: 300)
- `concurrent_users`: Parallel requests (default: 50)

**Output:**
- Request count and success rates
- Error rates and failure analysis
- Average response time
- Throughput (requests per second)
- Test report file: `edutube_load_test_YYYYMMDD_HHMMSS.txt`

**Recommended test sequence:**
```bash
# Light load: 25 users
bash run-load-test.sh basic http://localhost:3000 300 25

# Medium load: 50 users
bash run-load-test.sh basic http://localhost:3000 300 50

# Heavy load: 100 users
bash run-load-test.sh basic http://localhost:3000 300 100
```

### Server Comparison

#### `compare-servers.sh`
Compares two server analyses to help with capacity planning and migration decisions.

**Usage:**
```bash
bash compare-servers.sh current_analysis.txt new_analysis.txt
```

**What it compares:**
- CPU cores and frequency
- Memory capacity
- Disk space
- Overall capacity
- Concurrent user capacity
- Performance improvements/degradation

**Output:**
- Side-by-side comparison table
- Capacity assessment and verdict
- Deployment recommendations
- Migration planning phases
- Pre-migration checklist

### Quick Reference

#### `QUICK_START.sh`
Quick reference guide showing all common commands.

**Usage:**
```bash
bash QUICK_START.sh
```

## Workflow Examples

### Analyze Server Capacity

```bash
# 1. Analyze your server
bash analyze-server-capacity.sh

# 2. Notes key metrics:
#    - CPU Cores
#    - Total Memory
#    - Estimated Concurrent Users
```

### Compare Two Servers

```bash
# 1. Get analysis from current server
ssh user@current-server "bash tools/analyze-server-capacity.sh" > current.txt

# 2. Get analysis from new server
ssh user@new-server "bash tools/analyze-server-capacity.sh" > new.txt

# 3. Compare them
bash compare-servers.sh current.txt new.txt
```

### Validate Server Capacity

```bash
# 1. Deploy EduTube on server
bash ../scripts/deploy.sh

# 2. Wait for startup
sleep 30

# 3. Run load tests (gradually increase)
bash run-load-test.sh basic http://localhost:3000 300 25   # Light
bash run-load-test.sh basic http://localhost:3000 300 50   # Medium
bash run-load-test.sh basic http://localhost:3000 300 100  # Heavy

# 4. Monitor resources during tests
watch -n 1 'free -h && echo "---" && top -b -n 1 | head -10'
```

## Monitoring During Tests

In another terminal, monitor system resources:

```bash
watch -n 1 'free -h && echo && top -b -n 1 | head -15'
```

Watch for:
- Memory usage (target < 80%)
- CPU usage (target < 70%)
- Disk I/O (should not be maxed)
- Swap usage (should be minimal)

## Interpreting Results

### Capacity Analysis

```
Recommended Instances: 2
Estimated Concurrent Users: 100 (sustained) / 300 (peak)
Conservative Estimate: 50 users
```

Means:
- Can run 2 instances of EduTube
- Normal load: ~100 concurrent users
- Peak load: ~300 concurrent users
- Safe estimate: 50 users (with buffer)

### Load Test Results

```
Total Requests: 5000
Success Rate: 99%
Error Rate: 1%
Average Response Time: 0.245s
```

Interpretation:
- Error rate < 1% → ✓ Server handling well
- Error rate 1-5% → ⚠ Watch closely
- Error rate > 5% → ✗ Server overwhelmed

## Common Issues

### analyze-server-capacity.sh fails

```bash
# Make sure script is executable
chmod +x analyze-server-capacity.sh

# Run with bash explicitly
bash analyze-server-capacity.sh
```

### run-load-test.sh shows high errors

```bash
# Check if services are running
docker ps

# Check connectivity
curl http://localhost:3000

# Check system resources
free -h && df -h

# View logs
docker logs edutube-backend
```

### Need advanced load testing

Install k6 for more features:
```bash
# Ubuntu/Debian
sudo apt-get install -y gnupg software-properties-common
sudo add-apt-repository "ppa:k6/k6"
sudo apt-get install k6

# Then run advanced tests
bash run-load-test.sh k6 http://localhost:3000 300 100
```

## Documentation

For detailed information, see:
- `../docs/SERVER_ANALYSIS.md` - Complete technical reference
- `../docs/START_HERE.md` - Quick start guide
- `../docs/DEPLOYMENT_GUIDE.md` - Capacity planning guide

