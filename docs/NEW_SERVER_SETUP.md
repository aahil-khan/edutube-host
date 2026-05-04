# New Server Setup Guide - Ubuntu 20.04 LTS

## Overview

Your new server is completely fresh. Here's the workflow:

### Step 1: Initial Setup (Automated)
→ Run `provision-server.sh` to install all dependencies

### Step 2: Verify Setup (Optional)
→ Run `analyze-server-capacity.sh` to see server specs

### Step 3: Deploy EduTube
→ Configure `.env.production` and run `edutube-start`

---

## Quick Start (5 minutes)

### On Your New Server:

```bash
# Download and run provisioning script
curl -fsSL https://raw.githubusercontent.com/Dean-DCT-Thapar/edutube-host/main/provision-server.sh | sudo bash

# OR if you have the file locally:
sudo bash provision-server.sh
```

That's it! The script will:
- ✅ Update system packages
- ✅ Install Docker & Docker Compose
- ✅ Install git and essential tools
- ✅ Clone the edutube-host repository
- ✅ Optimize system for containers
- ✅ Create management commands
- ✅ Generate helpful scripts

---

## What Gets Installed

**Docker & Containers:**
- Docker CE (latest stable)
- Docker Compose (latest version)
- Container optimization

**Development Tools:**
- Git with submodule support
- curl, wget, nano, vim, htop
- jq (for JSON processing)
- net-tools for network debugging

**System Optimizations:**
- Increased file descriptors (65536)
- Memory accounting enabled
- TCP/networking tuning
- Performance optimizations

---

## After Provisioning

### New Commands Available:

```bash
# Start all EduTube services
edutube-start

# Stop all services
edutube-stop

# Check service status
edutube-status

# Analyze server capacity
edutube-analyze

# View logs
docker-compose -f /opt/edutube/docker-compose.yml logs -f backend
```

### Installation Location:

Everything is in: `/opt/edutube/`

```
/opt/edutube/
├── edutube/                    (Frontend - Next.js)
├── edutube-backend/            (Backend - Node.js/Express)
├── edutube-cli/                (CLI tools)
├── docker-compose.yml          (Production config)
├── docker-compose.dev.yml      (Dev config)
├── .env.production             (You create this!)
└── analyze-server-capacity.sh  (Analysis tool)
```

---

## Configuration Before Deploying

### Create `.env.production`

Before running `edutube-start`, create `/opt/edutube/.env.production` with:

```bash
# Database
DATABASE_URL="postgresql://postgres:pgadmin@postgres:5432/Video_Portal_Dummy"

# JWT
JWT_SECRET="your-super-secret-jwt-key-change-this"
JWT_EXPIRY="7d"

# API
API_URL="http://your-server-ip:5001"
FRONTEND_URL="http://your-server-ip:3000"

# Node environment
NODE_ENV="production"

# Optional: Add more as needed
REDIS_URL="redis://redis:6379"
```

### Deploy:

```bash
cd /opt/edutube
docker-compose -f docker-compose.yml up -d
```

---

## Provisioning Script Options

### Option 1: Setup Only (Default)
```bash
sudo bash provision-server.sh
```
→ Installs everything but doesn't start EduTube
→ You manually deploy when ready: `edutube-start`

### Option 2: Setup + Auto Deploy
```bash
sudo bash provision-server.sh yes
```
→ Installs everything AND starts EduTube immediately
→ Requires `.env.production` to already exist

---

## Monitoring Deployment

### Check if services are starting:
```bash
docker-compose -f /opt/edutube/docker-compose.yml ps
```

### View logs:
```bash
# Backend logs
docker-compose -f /opt/edutube/docker-compose.yml logs -f backend

# All services
docker-compose -f /opt/edutube/docker-compose.yml logs -f
```

### Check server capacity:
```bash
edutube-analyze
```

### Monitor resources while starting:
```bash
watch -n 1 'docker ps && echo && free -h && echo && df -h'
```

---

## Troubleshooting

### "Permission denied" error
```bash
# Make sure you're using sudo
sudo bash provision-server.sh
```

### Docker command not found
```bash
# Log out and back in, or:
exec su - $USER
```

### Services won't start
```bash
# Check logs
docker-compose -f /opt/edutube/docker-compose.yml logs backend | head -50

# Check if ports are in use
sudo netstat -tlnp | grep -E "(3000|5001|5433|6379|9200)"

# Check disk space
df -h
```

### "Cannot connect to Docker daemon"
```bash
# Docker service might not be running
sudo systemctl start docker

# Or add user to docker group
sudo usermod -aG docker $USER
```

---

## Next Steps

1. **SSH into new server**
   ```bash
   ssh user@new-server-ip
   ```

2. **Run provisioning**
   ```bash
   sudo bash provision-server.sh
   ```

3. **Configure environment** (on your local machine)
   ```bash
   # Copy your .env.production to the server
   scp .env.production user@new-server-ip:/opt/edutube/
   ```

4. **Verify setup** (optional)
   ```bash
   ssh user@new-server-ip
   edutube-analyze
   ```

5. **Start EduTube**
   ```bash
   edutube-start
   ```

6. **Run load tests** (if you need to validate capacity)
   ```bash
   bash run-load-test.sh basic http://localhost:3000 300 50
   ```

---

## Timeline

| Step | Time | Command |
|------|------|---------|
| SSH to server | 1 min | `ssh user@new-server-ip` |
| Run provisioning | 10-15 min | `sudo bash provision-server.sh` |
| Configure environment | 5 min | `scp .env.production ...` |
| Start services | 2 min | `edutube-start` |
| Wait for startup | 2-3 min | `docker ps` |
| Verify working | 1 min | Visit `http://new-server-ip:3000` |
| **Total** | **~30 minutes** | - |

---

## Helpful Resources

- **Full Documentation:** See `SERVER_ANALYSIS_README.md`
- **Load Testing:** See `run-load-test.sh`
- **Server Comparison:** See `compare-servers.sh`
- **Quick Reference:** See `QUICK_START.sh`

---

## Support

If provisioning fails:

1. Check the log file: `tail -100 /var/log/edutube-provision.log`
2. Verify Internet connection: `curl -I https://github.com`
3. Check disk space: `df -h /`
4. Verify you're running as root: `whoami`

---

**Server OS:** Ubuntu 20.04.6 LTS
**Installation Dir:** `/opt/edutube`
**Start Command:** `edutube-start`
**Status Command:** `edutube-status`

