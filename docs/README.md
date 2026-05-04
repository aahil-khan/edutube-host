# Documentation Index

## Quick Start

- **[START_HERE.md](START_HERE.md)** ⭐ **READ THIS FIRST**
  - Complete workflow for deploying to new servers
  - Step-by-step instructions
  - Timeline and troubleshooting

## Setup & Deployment

- **[NEW_SERVER_SETUP.md](NEW_SERVER_SETUP.md)**
  - Detailed new server setup walkthrough
  - Configuration examples
  - Environment setup

- **[DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)**
  - Deployment decision matrix
  - Migration planning strategies
  - Load capacity planning

- **[GITHUB_REPO_SETUP.md](GITHUB_REPO_SETUP.md)**
  - Creating central GitHub repository
  - Submodule configuration
  - Repository structure recommendations

## Technical Reference

- **[SERVER_ANALYSIS.md](SERVER_ANALYSIS.md)**
  - Complete technical documentation
  - Server analysis methodology
  - Load testing procedures
  - Best practices for capacity planning

- **[DOCKER_SETUP.md](DOCKER_SETUP.md)**
  - Docker and container configuration
  - Service setup and management
  - Development environment

- **[PRODUCTION_DEPLOYMENT.md](PRODUCTION_DEPLOYMENT.md)**
  - Production deployment specifics
  - Configuration recommendations
  - Performance tuning

## Architecture

### Services
- **Frontend**: `edutube/` - Next.js 15.1.2
- **Backend**: `edutube-backend/` - Node.js + Express
- **CLI**: `edutube-cli/` - Command-line utilities

### Key Files
- `docker-compose.yml` - Production configuration
- `docker-compose.dev.yml` - Development configuration
- `.env.example` - Environment template

## Quick Links

| Task | Location |
|------|----------|
| Deploy to new server | `../scripts/provision-server.sh` |
| Analyze server capacity | `../tools/analyze-server-capacity.sh` |
| Run load tests | `../tools/run-load-test.sh` |
| Compare servers | `../tools/compare-servers.sh` |
| Deploy application | `../scripts/deploy.sh` |
| Redeploy application | `../scripts/redeploy.sh` |

## Documentation By Use Case

### New Server Setup
1. Read: [START_HERE.md](START_HERE.md)
2. Run: `../scripts/provision-server.sh`
3. Deploy: `../scripts/deploy.sh`

### Server Capacity Planning
1. Read: [SERVER_ANALYSIS.md](SERVER_ANALYSIS.md)
2. Run: `../tools/analyze-server-capacity.sh`
3. Compare: `../tools/compare-servers.sh`
4. Load test: `../tools/run-load-test.sh`

### Migration Planning
1. Read: [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)
2. Analyze both servers
3. Run load tests
4. Execute deployment strategy

### Production Deployment
1. Read: [PRODUCTION_DEPLOYMENT.md](PRODUCTION_DEPLOYMENT.md)
2. Configure `.env.production`
3. Run deployment scripts
4. Monitor application

## Last Updated

April 30, 2026

