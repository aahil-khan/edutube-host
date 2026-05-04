# EduTube Platform - Deployment & Configuration

Complete deployment configuration and orchestration for the EduTube learning platform.

## Quick Start

### For New Servers
```bash
# Run provisioning on new server (Ubuntu 20.04 LTS)
curl -fsSL https://raw.githubusercontent.com/YOUR-USERNAME/edutube-host/main/scripts/provision-server.sh | sudo bash
```

### For Existing Installations
```bash
# Deploy/update services
bash scripts/deploy.sh

# Redeploy with fresh containers
bash scripts/redeploy.sh

# Analyze server capacity
bash tools/analyze-server-capacity.sh
```

## Documentation

**Start Here:** [`docs/START_HERE.md`](docs/START_HERE.md) ⭐

For complete documentation, see [`docs/README.md`](docs/README.md)

### Key Documentation

| Document | Purpose |
|----------|---------|
| [START_HERE.md](docs/START_HERE.md) | Quick start for new servers |
| [NEW_SERVER_SETUP.md](docs/NEW_SERVER_SETUP.md) | Detailed setup walkthrough |
| [DEPLOYMENT_GUIDE.md](docs/DEPLOYMENT_GUIDE.md) | Deployment strategy & planning |
| [SERVER_ANALYSIS.md](docs/SERVER_ANALYSIS.md) | Capacity analysis reference |
| [GITHUB_REPO_SETUP.md](docs/GITHUB_REPO_SETUP.md) | Repository setup guide |
| [PRODUCTION_DEPLOYMENT.md](docs/PRODUCTION_DEPLOYMENT.md) | Production specifics |
| [DOCKER_SETUP.md](docs/DOCKER_SETUP.md) | Docker configuration |

## Architecture

### Services
- **Frontend**: `edutube/` - Next.js 15.1.2 application submodule
- **Backend**: `edutube-backend/` - Express.js REST API submodule
- **CLI**: `edutube-cli/` - Command-line utilities submodule

### Core Files
- `docker-compose.yml` - Production services configuration
- `docker-compose.dev.yml` - Development configuration
- `.env.example` - Environment template (copy to `.env.production`)

## Directory Structure

```
edutube-host/
├── docs/                        Documentation
│   ├── START_HERE.md           Quick start guide ⭐
│   ├── NEW_SERVER_SETUP.md     Setup walkthrough
│   ├── DEPLOYMENT_GUIDE.md     Deployment strategy
│   ├── GITHUB_REPO_SETUP.md    Repository setup
│   ├── SERVER_ANALYSIS.md      Technical reference
│   └── README.md               Documentation index
│
├── scripts/                     Deployment scripts
│   ├── provision-server.sh     New server provisioning
│   ├── deploy.sh               Deploy services
│   ├── redeploy.sh             Redeploy with fresh containers
│   ├── test-deployment.sh      Test deployment
│   ├── create-db-dump.sh       Database backup
│   ├── setup-admin.sh          Admin setup
│   └── README.md               Scripts documentation
│
├── tools/                       Analysis & testing
│   ├── analyze-server-capacity.sh    Server analysis
│   ├── run-load-test.sh        Load testing
│   ├── compare-servers.sh      Server comparison
│   ├── QUICK_START.sh          Quick reference
│   └── README.md               Tools documentation
│
├── edutube/                    Frontend (git submodule)
├── edutube-backend/            Backend (git submodule)
├── edutube-cli/                CLI utilities (git submodule)
│
├── docker-compose.yml          Production config
├── docker-compose.dev.yml      Development config
├── .env.example                Environment template
├── .gitignore                  Git ignore rules
└── README.md                   This file
```

## Common Commands

### Service Management
```bash
# Start services
docker-compose -f docker-compose.yml up -d

# Stop services
docker-compose -f docker-compose.yml down

# View status
docker-compose -f docker-compose.yml ps

# View logs
docker-compose -f docker-compose.yml logs -f backend
```

### Clone With Submodules
```bash
git clone --recurse-submodules https://github.com/aahil-khan/edutube-host.git
cd edutube-host
git submodule update --init --recursive
```

### Deployment
```bash
# Full deployment
bash scripts/deploy.sh

# Redeploy (fresh containers)
bash scripts/redeploy.sh

# Test deployment
bash scripts/test-deployment.sh
```

### Analysis & Planning
```bash
# Analyze server capacity
bash tools/analyze-server-capacity.sh

# Run load tests
bash tools/run-load-test.sh basic http://localhost:3000 300 50

# Compare servers
bash tools/compare-servers.sh current.txt new.txt
```

### Management (After Provisioning)
```bash
# Start all services
edutube-start

# Stop all services
edutube-stop

# Check status
edutube-status

# Analyze capacity
edutube-analyze
```

## Configuration

### Environment Setup

1. Copy the template:
   ```bash
   cp .env.example .env.production
   ```

2. Edit with your settings:
   ```bash
   nano .env.production
   ```

3. Required variables:
   ```
   DATABASE_URL=postgresql://...
   JWT_SECRET=your-secret-key
   API_URL=http://your-server:5001
   FRONTEND_URL=http://your-server:3000
   NODE_ENV=production
   ```

### Docker Services

Services defined in `docker-compose.yml`:
- **postgres** - PostgreSQL database
- **redis** - Redis cache
- **backend** - Express.js API
- **frontend** - Next.js application

## System Requirements

### Minimum
- 2.5 GB RAM
- 1 CPU core
- Ubuntu 20.04 LTS or later

### Recommended
- 4.5 GB RAM
- 2 CPU cores
- 20 GB disk space
- Ubuntu 20.04 LTS or Ubuntu 22.04 LTS

## Deployment Timeline

| Step | Time | Action |
|------|------|--------|
| Provision | 10-15 min | Run provisioning script |
| Configure | 5 min | Set up .env.production |
| Deploy | 2 min | Start services |
| Startup | 5-10 min | Wait for services |
| Verify | 2 min | Test connectivity |
| **Total** | **~30 min** | - |

## Troubleshooting

### Services won't start
```bash
# Check logs
docker-compose logs backend

# Check if ports are in use
netstat -tlnp | grep -E "(3000|5001|5433)"

# Check disk space
df -h
```

### Can't access web interface
```bash
# Verify services running
docker-compose ps

# Test backend
curl http://localhost:5001/health

# Check firewall
sudo ufw allow 3000/tcp
sudo ufw allow 5001/tcp
```

### Database errors
```bash
# Check database logs
docker-compose logs postgres

# Verify connectivity
psql -h localhost -U postgres -d Video_Portal_Dummy

# Check database dumps
ls -lh scripts/dumps/
```

## Performance Tuning

### For Higher Load
1. Increase Node.js workers
2. Configure connection pooling
3. Add Redis caching
4. Use load balancer
5. Enable compression

See `docs/DEPLOYMENT_GUIDE.md` for detailed strategies.

## Monitoring

### Key Metrics
- Memory usage (target < 80%)
- CPU usage (target < 70% average)
- Database connections
- Response times
- Error rates

### Tools
```bash
# Monitor resources
watch -n 1 'free -h && top -b -n 1 | head -10'

# Monitor containers
watch -n 1 'docker stats'

# View logs
docker-compose logs -f

# Analyze capacity
bash tools/analyze-server-capacity.sh
```

## Security

### Environment Variables
- `.env.production` - Contains secrets (not in git)
- `.env.example` - Template only (in git)

### Firewall
```bash
# Allow only needed ports
sudo ufw default deny incoming
sudo ufw allow 22/tcp      # SSH
sudo ufw allow 80/tcp      # HTTP
sudo ufw allow 443/tcp     # HTTPS
sudo ufw allow 3000/tcp    # Frontend (internal)
sudo ufw allow 5001/tcp    # Backend (internal)
```

### Backups
```bash
# Create database backup
bash scripts/create-db-dump.sh backup_$(date +%Y%m%d).dump

# Restore backup
docker-compose exec postgres pg_restore -d Video_Portal_Dummy backup.dump
```

## Version Management

This repository uses git submodules for component repositories:
- `edutube` - Frontend repository
- `edutube-backend` - Backend repository
- `edutube-cli` - CLI repository

### Updating Components
```bash
# Update all submodules
git submodule update --remote --merge

# Update specific component
cd edutube-backend && git pull origin main && cd ..
```

## License

[Your License Here]

## Contributing

[Your Contributing Guidelines Here]

## Support

For issues or questions:
1. Check the [documentation](docs/README.md)
2. Review [troubleshooting](docs/START_HERE.md#troubleshooting)
3. Check service logs: `docker-compose logs`
4. Contact the team

## Useful Links

- **Frontend**: http://localhost:3000 (development)
- **Backend API**: http://localhost:5001 (development)
- **Database**: localhost:5433 (PostgreSQL)
- **Cache**: localhost:6379 (Redis)

---

**Last Updated**: April 30, 2026
**Status**: Production Ready ✅

