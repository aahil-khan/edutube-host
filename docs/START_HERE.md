# EduTube Complete Setup for New Empty Server

## Your Situation
- New server: Ubuntu 20.04.6 LTS (completely empty)
- Current setup: Multiple repos + deployment configs locally
- Goal: Deploy EduTube to new server with capacity verification

---

## Complete Workflow (30-45 minutes)

### Phase 1: Repository Setup (Local Machine)

#### Option A: Create GitHub Repo (RECOMMENDED)
```bash
# 1. Create new GitHub repo named "edutube-host"
#    → Go to github.com/new
#    → Name: edutube-host
#    → Add submodules for edutube, edutube-backend, edutube-cli

# 2. Initialize and push your local repo
cd /home/aahil/projects/edutube-host
git init
git add .
git commit -m "Initial commit: EduTube deployment"
git remote add origin https://github.com/YOUR-USERNAME/edutube-host.git
git push -u origin main
```

**Why this matters**: The new server will clone from GitHub, so you need it there first.

#### Option B: Keep Local (Skip GitHub)
If you don't want GitHub, skip to Phase 2.

---

### Phase 2: Prepare Your New Server

#### Step 1: SSH into New Server
```bash
ssh root@your-new-server-ip
# or
ssh user@your-new-server-ip
sudo -i  # Get root access
```

#### Step 2: Run Provisioning Script

**If using GitHub repo:**
```bash
# One command does everything
curl -fsSL https://raw.githubusercontent.com/YOUR-USERNAME/edutube-host/main/provision-server.sh | sudo bash
```

**If not using GitHub:**
```bash
# Copy provision script to server first
scp provision-server.sh root@your-new-server-ip:~/
ssh root@your-new-server-ip
bash ~/provision-server.sh
```

**What this does:**
- ✅ Installs Docker & Docker Compose
- ✅ Installs git and essential tools
- ✅ Clones your edutube-host repo to `/opt/edutube`
- ✅ Optimizes system for containers
- ✅ Creates management commands

**Time: ~10-15 minutes**

---

### Phase 3: Configure and Deploy

#### Step 3: Create Environment File
```bash
# On the new server
cd /opt/edutube
nano .env.production
```

**Paste this template (modify as needed):**
```bash
# Database
DATABASE_URL="postgresql://postgres:pgadmin@postgres:5432/Video_Portal_Dummy"

# JWT
JWT_SECRET="your-super-secret-key-change-this-in-production"
JWT_EXPIRY="7d"

# URLs
API_URL="http://your-server-ip:5001"
FRONTEND_URL="http://your-server-ip:3000"

# Environment
NODE_ENV="production"

# Optional
REDIS_URL="redis://redis:6379"
```

**Save:** Press `Ctrl+X`, then `Y`, then `Enter`

#### Step 4: Deploy EduTube
```bash
# On the new server
edutube-start

# Wait 10-20 seconds for services to start
sleep 20

# Verify services are running
edutube-status
```

**Should see:**
```
edutube-postgres    running
edutube-backend     running
edutube-redis       running
```

#### Step 5: Verify It Works
```bash
# From your local machine
curl http://your-new-server-ip:3000

# Should return HTML (not error)

# Or open in browser
open http://your-new-server-ip:3000
```

---

## Server Capacity Analysis

### Analyze Your New Server

```bash
# On new server
edutube-analyze

# Output will show:
# - CPU cores
# - RAM available
# - Estimated concurrent users
# - Recommendations
```

### Compare with Current Server (Optional)

```bash
# 1. Get both analyses
edutube-analyze > new_analysis.txt

# 2. From current server (if you want to compare)
ssh user@current-server "bash analyze-server-capacity.sh" > current_analysis.txt

# 3. Compare them
bash compare-servers.sh current_analysis.txt new_analysis.txt
```

---

## Load Testing (Validation)

**Only do this if you want to verify capacity estimates:**

```bash
# On new server, with EduTube running
bash run-load-test.sh basic http://localhost:3000 300 50

# Interpret results:
# Error rate < 1%  → ✓ Server handling well
# Error rate 1-5%  → ⚠ Watch it
# Error rate > 5%  → ✗ Server struggling
```

---

## New Commands Now Available

After provisioning, you can use these shortcuts:

```bash
edutube-start       # Start all services
edutube-stop        # Stop all services
edutube-status      # Check if running
edutube-analyze     # See server capacity
```

---

## Troubleshooting

### Services Won't Start
```bash
# Check logs
docker-compose -f /opt/edutube/docker-compose.yml logs backend | head -50

# Check if ports are free
sudo netstat -tlnp | grep -E "(3000|5001|5433|6379)"

# Check disk space
df -h /

# Restart
edutube-stop
sleep 5
edutube-start
```

### Can't Access Web Interface
```bash
# Check if frontend is running
docker ps | grep edutube

# Check if port is open
curl http://localhost:3000

# Check firewall
sudo ufw status
sudo ufw allow 3000/tcp
sudo ufw allow 5001/tcp
```

### Provisioning Script Failed
```bash
# Check the log
tail -100 /var/log/edutube-provision.log

# Try manually
sudo apt-get update
sudo apt-get install -y docker.io docker-compose git
systemctl start docker
```

---

## About GitHub Repo Structure

**For your question about GitHub repo:**

✅ **YES, create a GitHub repo for edutube-host**

This solves:
- ✓ Centralized deployment configuration
- ✓ Version-controlled docker-compose files
- ✓ All scripts in one place
- ✓ Easy provisioning with single command
- ✓ Team collaboration

**Setup:**
```bash
# 1. Create on GitHub (github.com/new)
# 2. Initialize your local folder
cd /home/aahil/projects/edutube-host
git init
git add .
git commit -m "Initial: EduTube deployment"
git remote add origin https://github.com/YOUR-USERNAME/edutube-host.git
git push -u origin main

# 3. Update provision-server.sh
REPO_URL="https://github.com/YOUR-USERNAME/edutube-host.git"

# 4. Now new servers can do:
curl -fsSL https://raw.githubusercontent.com/YOUR-USERNAME/edutube-host/main/provision-server.sh | sudo bash
```

See detailed guide in: [GITHUB_REPO_SETUP.md](GITHUB_REPO_SETUP.md)

---

## Complete Timeline

| Time | Action | Command |
|------|--------|---------|
| 0 min | SSH to server | `ssh root@new-server-ip` |
| 1 min | Start provisioning | `curl ... \| sudo bash` |
| 15 min | Provisioning done | Check: `docker ps` |
| 16 min | Create .env file | `nano /opt/edutube/.env.production` |
| 17 min | Deploy services | `edutube-start` |
| 20 min | Verify running | `edutube-status` |
| 21 min | Test web interface | `curl http://localhost:3000` |
| 22 min | **DONE** ✅ | Services running |

---

## One-Command Setup

Once you have GitHub repo set up:

**For completely new servers, this single command does everything:**

```bash
# New server just needs:
curl -fsSL https://raw.githubusercontent.com/YOUR-USERNAME/edutube-host/main/provision-server.sh | sudo bash
```

---

## File Guide

### New Files Created for You

| File | Purpose | When to Use |
|------|---------|------------|
| `provision-server.sh` | **Server setup** | First time on new server |
| `analyze-server-capacity.sh` | **Capacity analysis** | Verify server can handle load |
| `run-load-test.sh` | Load testing | Validate capacity estimates |
| `compare-servers.sh` | Server comparison | Compare current vs new |
| `NEW_SERVER_SETUP.md` | Setup guide | Instructions for new server |
| `GITHUB_REPO_SETUP.md` | GitHub guide | Setting up central repo |
| `DEPLOYMENT_GUIDE.md` | Deployment strategy | Decide what to do |
| `SERVER_ANALYSIS_README.md` | Documentation | Full technical reference |

### Existing Files Used

| File | Purpose |
|------|---------|
| `docker-compose.yml` | Production services |
| `docker-compose.dev.yml` | Development services |
| `deploy.sh` | Deployment script |
| `redeploy.sh` | Redeployment script |
| All documentation | Reference guides |

---

## Next Actions

### Immediate (Next 30 minutes)
1. ☐ Set up GitHub repo (or skip if not needed)
2. ☐ SSH into new server
3. ☐ Run provisioning script
4. ☐ Create `.env.production`
5. ☐ Run `edutube-start`
6. ☐ Test in browser

### Short Term (Next day)
1. ☐ Run `edutube-analyze` to check capacity
2. ☐ Compare with current server (if needed)
3. ☐ Run load tests (if you want to validate)
4. ☐ Configure monitoring/logs

### Medium Term (Next week)
1. ☐ Set up automated backups
2. ☐ Configure failover procedures
3. ☐ Plan migration strategy
4. ☐ Train team on new commands

---

## Quick Reference

### Essential Commands

```bash
# Provisioning (one time)
curl -fsSL https://raw.githubusercontent.com/YOUR-USERNAME/edutube-host/main/provision-server.sh | sudo bash

# Daily operations
edutube-start      # Start all services
edutube-stop       # Stop all services
edutube-status     # View status

# Analysis
edutube-analyze    # Check capacity

# Logs
docker-compose -f /opt/edutube/docker-compose.yml logs -f backend
```

### Important Paths

```
/opt/edutube/                  # Installation directory
/opt/edutube/.env.production   # Configuration (create this)
/opt/edutube/docker-compose.yml # Services definition
/var/log/edutube-provision.log # Setup log
```

---

## Success Criteria

Your new server is ready when:

✅ Provisioning script completes without errors
✅ `edutube-status` shows all services running
✅ Browser shows EduTube frontend at http://your-server-ip:3000
✅ Backend API responds at http://your-server-ip:5001
✅ `edutube-analyze` shows capacity estimates
✅ No errors in: `docker-compose logs backend`

---

## Getting Help

**If something fails:**

1. Check logs: `docker-compose logs backend`
2. Check status: `edutube-status`
3. Review this guide's Troubleshooting section
4. Check provision log: `cat /var/log/edutube-provision.log`

**For complex issues:**
- Review individual service docs in `/docs/` folder
- Check Docker logs: `docker ps -a` then `docker logs CONTAINER_NAME`
- Check system resources: `free -h` and `df -h`

---

**Created:** April 30, 2026
**For:** Empty Ubuntu 20.04.6 LTS Server
**Status:** Ready to Deploy ✅

