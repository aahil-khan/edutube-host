# Scripts Directory

Deployment and management scripts for EduTube.

## Available Scripts

### Server Provisioning

#### `provision-server.sh`
Automated setup for new empty servers. Installs all dependencies, clones repository, and prepares system.

**Usage:**
```bash
# On new server
curl -fsSL https://raw.githubusercontent.com/YOUR-USERNAME/edutube-host/main/scripts/provision-server.sh | sudo bash

# Or locally
sudo bash provision-server.sh
```

**What it does:**
- Installs Docker, Docker Compose, Git
- Installs essential tools and dependencies
- Clones edutube-host repository
- Optimizes system for containers
- Creates management commands

### Deployment

#### `deploy.sh`
Deploys or updates EduTube services using docker-compose.

**Usage:**
```bash
bash deploy.sh
```

#### `redeploy.sh`
Redeploys EduTube with fresh containers.

**Usage:**
```bash
bash redeploy.sh
```

#### `test-deployment.sh`
Tests the deployment to ensure all services are working.

**Usage:**
```bash
bash test-deployment.sh
```

### Database

#### `create-db-dump.sh`
Creates a database dump for backup or migration.

**Usage:**
```bash
bash create-db-dump.sh [filename.dump]
```

### Setup & Configuration

#### `setup-admin.sh`
Sets up admin user and initial configuration.

**Usage:**
```bash
bash setup-admin.sh
```

#### `fix-api-routes.sh`
Fixes API routing issues (if needed).

**Usage:**
```bash
bash fix-api-routes.sh
```

## Quick Commands

```bash
# Deploy services
bash deploy.sh

# Redeploy with fresh containers
bash redeploy.sh

# Test deployment
bash test-deployment.sh

# Backup database
bash create-db-dump.sh backup_$(date +%Y%m%d).dump

# Setup admin
bash setup-admin.sh
```

## Running Remotely

All scripts can be run remotely via SSH:

```bash
ssh user@server "cd /opt/edutube && bash scripts/deploy.sh"
```

## Documentation

For more details, see the main documentation in `../docs/`

