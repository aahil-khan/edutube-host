#!/bin/bash

################################################################################
# EduTube Server Provisioning Script - Ubuntu 20.04 LTS
#
# Fully automates server setup from scratch:
#  - Installs Docker & Docker Compose
#  - Installs required dependencies
#  - Configures system for optimal performance
#  - Clones edutube-host repository
#  - Optionally deploys EduTube
#
# Usage: curl -fsSL https://your-repo-url/provision.sh | sudo bash
# Or:    bash provision.sh [deploy_yes_or_no]
#
# Run with: bash provision.sh yes    (full deployment)
#           bash provision.sh no     (setup only, no deployment)
################################################################################

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
DEPLOY_NOW="${1:-no}"
REPO_URL="${EDUTUBE_REPO_URL:-https://github.com/Dean-DCT-Thapar/edutube-host.git}"
INSTALL_DIR="/opt/edutube"
LOG_FILE="/var/log/edutube-provision.log"

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}This script must be run as root (use: sudo bash provision.sh)${NC}"
    exit 1
fi

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}EduTube Server Provisioning${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Target: Ubuntu 20.04 LTS"
echo "Install Directory: $INSTALL_DIR"
echo "Repo: $REPO_URL"
echo "Deploy Now: $DEPLOY_NOW"
echo ""
echo "Logging to: $LOG_FILE"
echo ""

# Start logging
{
    echo "==============================================="
    echo "EduTube Server Provisioning Log"
    echo "Started: $(date)"
    echo "OS: $(lsb_release -ds)"
    echo "Hostname: $(hostname)"
    echo "==============================================="
    echo ""

    # ===== STEP 1: Update system =====
    echo -e "${YELLOW}[1/8] Updating system packages...${NC}"
    echo "Updating system..." >> "$LOG_FILE"
    
    apt-get update
    apt-get upgrade -y
    
    echo -e "${GREEN}✓ System updated${NC}"
    echo ""

    # ===== STEP 2: Install dependencies =====
    echo -e "${YELLOW}[2/8] Installing dependencies...${NC}"
    echo "Installing dependencies..." >> "$LOG_FILE"
    
    apt-get install -y \
        curl \
        wget \
        git \
        htop \
        net-tools \
        vim \
        nano \
        unzip \
        jq \
        ca-certificates \
        gnupg \
        lsb-release \
        software-properties-common \
        apt-transport-https
    
    echo -e "${GREEN}✓ Dependencies installed${NC}"
    echo ""

    # ===== STEP 3: Install Docker =====
    echo -e "${YELLOW}[3/8] Installing Docker...${NC}"
    echo "Installing Docker..." >> "$LOG_FILE"
    
    # Add Docker GPG key
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    
    # Add Docker repository
    echo \
        "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
        $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    
    # Enable Docker daemon
    systemctl enable docker
    systemctl start docker
    
    # Verify installation
    docker --version >> "$LOG_FILE"
    
    echo -e "${GREEN}✓ Docker installed${NC}"
    echo ""

    # ===== STEP 4: Install Docker Compose (standalone) =====
    echo -e "${YELLOW}[4/8] Installing Docker Compose...${NC}"
    echo "Installing Docker Compose..." >> "$LOG_FILE"
    
    DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d'"' -f4)
    DOCKER_COMPOSE_URL="https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-Linux-x86_64"
    
    curl -L "$DOCKER_COMPOSE_URL" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    
    docker-compose --version >> "$LOG_FILE"
    
    echo -e "${GREEN}✓ Docker Compose installed${NC}"
    echo ""

    # ===== STEP 5: Create installation directory =====
    echo -e "${YELLOW}[5/8] Creating installation directory...${NC}"
    echo "Creating $INSTALL_DIR..." >> "$LOG_FILE"
    
    mkdir -p "$INSTALL_DIR"
    cd "$INSTALL_DIR"
    
    echo -e "${GREEN}✓ Directory created${NC}"
    echo ""

    # ===== STEP 6: Clone repository =====
    echo -e "${YELLOW}[6/8] Cloning EduTube repository...${NC}"
    echo "Cloning from: $REPO_URL" >> "$LOG_FILE"
    
    git clone --recurse-submodules "$REPO_URL" . 2>&1 | tee -a "$LOG_FILE" || {
        echo -e "${YELLOW}Note: Could not clone with submodules. Trying without...${NC}"
        git clone "$REPO_URL" .
    }
    
    echo -e "${GREEN}✓ Repository cloned${NC}"
    echo ""

    # ===== STEP 7: System tuning =====
    echo -e "${YELLOW}[7/8] Optimizing system for containers...${NC}"
    echo "Tuning system..." >> "$LOG_FILE"
    
    # Increase file descriptor limits
    cat >> /etc/security/limits.conf << 'EOF'
# EduTube limits
* soft nofile 65536
* hard nofile 65536
* soft nproc 65536
* hard nproc 65536
EOF
    
    # Enable memory accounting (for better container limits)
    if ! grep -q "GRUB_CMDLINE_LINUX.*memory.accounting" /etc/default/grub; then
        sed -i 's/^GRUB_CMDLINE_LINUX=.*/&\ cgroup_enable=memory/' /etc/default/grub || true
    fi
    
    # Sysctl optimizations for Docker
    cat >> /etc/sysctl.conf << 'EOF'
# EduTube container optimizations
vm.overcommit_memory = 1
vm.max_map_count = 262144
net.core.somaxconn = 65535
net.ipv4.tcp_max_syn_backlog = 65535
EOF
    
    sysctl -p >> "$LOG_FILE" 2>&1 || true
    
    echo -e "${GREEN}✓ System optimized${NC}"
    echo ""

    # ===== STEP 8: Create startup scripts =====
    echo -e "${YELLOW}[8/8] Setting up management scripts...${NC}"
    echo "Creating management scripts..." >> "$LOG_FILE"
    
    # Create start script
    cat > /usr/local/bin/edutube-start << 'EOSTART'
#!/bin/bash
cd /opt/edutube
docker-compose -f docker-compose.yml up -d
echo "EduTube started. Check status with: docker ps"
EOSTART
    chmod +x /usr/local/bin/edutube-start
    
    # Create stop script
    cat > /usr/local/bin/edutube-stop << 'EOSTOP'
#!/bin/bash
cd /opt/edutube
docker-compose -f docker-compose.yml down
echo "EduTube stopped"
EOSTOP
    chmod +x /usr/local/bin/edutube-stop
    
    # Create status script
    cat > /usr/local/bin/edutube-status << 'EOSTATUS'
#!/bin/bash
cd /opt/edutube
docker-compose -f docker-compose.yml ps
EOSTATUS
    chmod +x /usr/local/bin/edutube-status
    
    # Create analysis script link
    cp "$INSTALL_DIR/tools/analyze-server-capacity.sh" /usr/local/bin/edutube-analyze
    chmod +x /usr/local/bin/edutube-analyze
    
    echo -e "${GREEN}✓ Management scripts created${NC}"
    echo ""

    # ===== Summary =====
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}Provisioning Complete!${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    
    echo -e "${GREEN}Installed Components:${NC}"
    echo "  ✓ Docker $(docker --version | awk '{print $3}' | tr -d ',')"
    echo "  ✓ Docker Compose $(docker-compose --version | awk '{print $NF}')"
    echo "  ✓ Git $(git --version | awk '{print $3}')"
    echo "  ✓ Essential tools (curl, wget, htop, nano, vim, jq)"
    echo ""
    
    echo -e "${GREEN}Installation Location:${NC}"
    echo "  $INSTALL_DIR"
    echo ""
    
    echo -e "${GREEN}Useful Commands:${NC}"
    echo "  Start EduTube:   edutube-start"
    echo "  Stop EduTube:    edutube-stop"
    echo "  Check Status:    edutube-status"
    echo "  Analyze Server:  edutube-analyze"
    echo "  View Logs:       docker-compose -f docker-compose.yml logs -f"
    echo ""
    
    echo -e "${GREEN}Quick Start:${NC}"
    echo "  cd $INSTALL_DIR"
    echo "  docker-compose -f docker-compose.yml up -d"
    echo "  docker-compose -f docker-compose.yml logs -f backend"
    echo ""
    
    # ===== Optional: Deploy now =====
    if [[ "$DEPLOY_NOW" == "yes" ]] || [[ "$DEPLOY_NOW" == "y" ]]; then
        echo -e "${YELLOW}Deploying EduTube...${NC}"
        cd "$INSTALL_DIR"
        
        # Check if .env.production exists
        if [ ! -f ".env.production" ]; then
            echo -e "${RED}⚠ Warning: .env.production not found${NC}"
            echo "  Create this file with your environment variables before deploying"
            echo "  Required variables: DATABASE_URL, JWT_SECRET, etc."
            echo ""
        else
            echo "Starting services..."
            docker-compose -f docker-compose.yml up -d
            
            echo ""
            echo -e "${GREEN}✓ EduTube deployed!${NC}"
            echo ""
            echo "Waiting for services to start..."
            sleep 10
            
            echo ""
            echo "Service Status:"
            docker-compose -f docker-compose.yml ps
            
            echo ""
            echo "Access EduTube at:"
            echo "  Frontend: http://$(hostname -I | awk '{print $1}'):3000"
            echo "  Backend: http://$(hostname -I | awk '{print $1}'):5001"
        fi
    else
        echo -e "${YELLOW}Note: EduTube not deployed automatically${NC}"
        echo "When ready, deploy with: edutube-start"
    fi
    
    echo ""
    echo "Provisioning log: $LOG_FILE"
    echo ""
    echo -e "${GREEN}Setup finished at: $(date)${NC}"
    
} | tee -a "$LOG_FILE"

exit 0
