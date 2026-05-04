# Setting Up edutube-host GitHub Repository

## Current Structure

You have 3 separate repositories:
- `Dean-DCT-Thapar/edutube` (Frontend)
- `aahil-khan/edutube-backend` (Backend) 
- `aahil-khan/edutube-cli` (CLI)

And a local folder `/opt/edutube-host/` that coordinates them.

---

## Recommended: Create Central edutube-host Repository

### Benefits:
✅ Single place to manage deployment configuration
✅ All deployment scripts in one repo
✅ All documentation together
✅ Version-controlled docker-compose files
✅ Easier for team collaboration
✅ Can use git submodules to reference other repos

---

## Setup Instructions

### Option 1: Create on GitHub, Then Clone

**Step 1: Create repo on GitHub**
- Go to https://github.com/new
- Repository name: `edutube-host`
- Description: "EduTube deployment configuration and orchestration"
- Make it **Private** (if your other repos are private)
- Click "Create repository"

**Step 2: Clone and populate locally**
```bash
git clone https://github.com/YOUR-USERNAME/edutube-host.git
cd edutube-host

# Add existing subdirectories as submodules
git submodule add https://github.com/Dean-DCT-Thapar/edutube.git edutube
git submodule add https://github.com/aahil-khan/edutube-backend.git edutube-backend
git submodule add https://github.com/aahil-khan/edutube-cli.git edutube-cli

# Copy deployment files
cp -r /your/current/path/* .

# Commit
git add .
git commit -m "Initial commit: EduTube deployment configuration"
git push -u origin main
```

**Step 3: Clone fresh for new server**
```bash
git clone --recurse-submodules https://github.com/YOUR-USERNAME/edutube-host.git /opt/edutube
cd /opt/edutube
```

---

### Option 2: Push Existing Local Folder

If you already have `/home/aahil/projects/edutube-host/` with everything:

**Step 1: Initialize git in the folder**
```bash
cd /home/aahil/projects/edutube-host
git init
git add .
git commit -m "Initial commit: EduTube deployment configuration"
```

**Step 2: Create repo on GitHub** (same as Option 1 Step 1)

**Step 3: Connect and push**
```bash
git remote add origin https://github.com/YOUR-USERNAME/edutube-host.git
git branch -M main
git push -u origin main
```

---

## Recommended Folder Structure

```
edutube-host/ (GitHub repo)
├── .gitmodules                    # Submodule configuration
├── .gitignore                     # Ignore sensitive files
├── README.md                      # Main documentation
├── LICENSE                        # Your license
│
├── edutube/                       # Frontend (submodule)
│   └── [Next.js app]
├── edutube-backend/               # Backend (submodule)
│   └── [Express.js API]
├── edutube-cli/                   # CLI (submodule)
│   └── [CLI tools]
│
├── docker-compose.yml             # Production deployment
├── docker-compose.dev.yml         # Development deployment
├── .env.example                   # Template for .env files
│
├── scripts/                       # Deployment scripts
│   ├── provision-server.sh        # New server setup
│   ├── deploy.sh                  # Deployment script
│   ├── redeploy.sh                # Redeployment
│   └── create-db-dump.sh          # Database utilities
│
├── docs/                          # Documentation
│   ├── PRODUCTION_DEPLOYMENT.md
│   ├── DOCKER_SETUP.md
│   ├── ADMIN_SETUP.md
│   ├── ROUTING_FIXES_SUMMARY.md
│   └── cli.md
│
├── analysis-tools/                # Server analysis tools
│   ├── analyze-server-capacity.sh
│   ├── run-load-test.sh
│   ├── compare-servers.sh
│   └── QUICK_START.sh
│
└── README.md                      # Main readme
```

---

## Essential Files to Include

### 1. `.env.example`
```bash
# Database
DATABASE_URL="postgresql://postgres:pgadmin@postgres:5432/Video_Portal_Dummy"

# JWT
JWT_SECRET="your-secret-key-here"
JWT_EXPIRY="7d"

# API URLs
API_URL="http://localhost:5001"
FRONTEND_URL="http://localhost:3000"

# Node Environment
NODE_ENV="production"

# Optional services
REDIS_URL="redis://redis:6379"
ELASTICSEARCH_URL="http://elasticsearch:9200"
```

### 2. `.gitignore`
```
# Environment files (real secrets)
.env
.env.production
.env.local
.env.*.local

# Docker volumes and data
/postgres_data
/redis_data
/elasticsearch_data

# Logs
*.log
logs/

# IDE
.vscode/
.idea/
*.swp
*.swo

# Dumps
dump/

# Dependencies (in submodules)
node_modules/
__pycache__/

# OS
.DS_Store
Thumbs.db

# Analysis reports
edutube_server_analysis_*.txt
edutube_load_test_*.txt
server_comparison_*.txt
```

### 3. Main `README.md`
```markdown
# EduTube - Complete Platform

Unified deployment and configuration for the EduTube learning platform.

## Repository Structure

- **edutube/** - Frontend (Next.js)
- **edutube-backend/** - Backend API (Express.js)
- **edutube-cli/** - Command-line utilities

## Quick Start

### New Server Setup
\`\`\`bash
curl -fsSL https://raw.githubusercontent.com/YOUR-USERNAME/edutube-host/main/provision-server.sh | sudo bash
\`\`\`

### Deploy Services
\`\`\`bash
docker-compose -f docker-compose.yml up -d
\`\`\`

### Analyze Server Capacity
\`\`\`bash
bash analyze-server-capacity.sh
\`\`\`

## Documentation

- [Production Deployment](docs/PRODUCTION_DEPLOYMENT.md)
- [Docker Setup](docs/DOCKER_SETUP.md)
- [Admin Setup](docs/ADMIN_SETUP.md)
- [New Server Setup](NEW_SERVER_SETUP.md)
- [Server Analysis](SERVER_ANALYSIS_README.md)

## Quick Commands

\`\`\`bash
edutube-start      # Start all services
edutube-stop       # Stop all services
edutube-status     # View service status
edutube-analyze    # Analyze server capacity
\`\`\`

## Authors

- Frontend: [Dean-DCT-Thapar]
- Backend: [aahil-khan]
- DevOps: [Your team]

## License

[Your License Here]
```

---

## Managing Submodules

### When You Update a Submodule:

```bash
# Update specific submodule
cd edutube-backend
git pull origin main
cd ..

# Commit the submodule update
git add edutube-backend
git commit -m "Update backend to latest version"
git push
```

### When Others Clone Your Repo:

```bash
# First time (with submodules)
git clone --recurse-submodules https://github.com/YOUR-USERNAME/edutube-host.git

# Or if already cloned
git submodule update --init --recursive
```

---

## Current Status Check

To see what you have now:

```bash
cd /home/aahil/projects/edutube-host

# Check if already a git repo
git status

# See what files are here
ls -la

# Check submodules (if any)
git config --file .gitmodules --name-only --get-regexp path
```

---

## Next Steps

1. **Decide**: Use submodules or copy files?
   - **Submodules**: Good for managing separate repos together
   - **Copy**: Good for monorepo approach

2. **Create GitHub repo**: Go to github.com/new

3. **Push your code**: Follow Option 1 or 2 above

4. **Update provision-server.sh**:
   ```bash
   # Change this line:
   REPO_URL="https://github.com/YOUR-USERNAME/edutube-host.git"
   ```

5. **Test on new server**: Deploy and verify

---

## Pro Tips

### Cloning with Submodules
```bash
# Download everything recursively
git clone --recurse-submodules URL

# Or if already cloned
git submodule update --init --recursive
```

### Keeping Submodules Updated
```bash
# Update all submodules to latest
git submodule update --remote

# Update specific submodule
cd edutube-backend
git pull origin main
cd ..
```

### Troubleshooting Submodules
```bash
# Remove a submodule
git rm --cached edutube-backend
rm -rf edutube-backend
git commit -m "Remove backend submodule"

# Re-add correctly
git submodule add https://github.com/aahil-khan/edutube-backend.git edutube-backend
git commit -m "Add backend submodule"
```

---

## Security Considerations

### Don't Commit These:
- ❌ `.env` or `.env.production` (use `.env.example` instead)
- ❌ Database dumps with real data
- ❌ Private SSH keys
- ❌ API keys or secrets

### Use .gitignore:
```bash
echo ".env.production" >> .gitignore
echo "cookies.txt" >> .gitignore
echo "dump/*.dump" >> .gitignore
```

### For Secrets:
- Use `.env.example` as template
- Store real `.env.production` outside git
- Or use GitHub Secrets for CI/CD
- Or use HashiCorp Vault for production

---

## GitHub Collaboration

### For Team Members:

```bash
# Clone with submodules
git clone --recurse-submodules https://github.com/YOUR-USERNAME/edutube-host.git

# Make changes in subfolders
cd edutube-backend
git checkout -b feature/new-api
# ... make changes ...
git push origin feature/new-api

# Create PR on backend repo
# Once merged, update main repo's submodule reference

# Back in root
git add edutube-backend
git commit -m "Update backend submodule to include new API"
git push
```

---

## Summary

**I recommend**: Create a GitHub repo for `edutube-host` with submodules pointing to your 3 existing repos. This keeps everything coordinated while maintaining separate versioning for each component.

**Next Action**: Create the GitHub repo and update the `provision-server.sh` with your new repo URL.

---

