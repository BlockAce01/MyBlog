#!/bin/bash

# MyBlog Automatic Cleanup Setup Script
# Sets up automatic storage cleanup to prevent "out of storage" issues
# Run this ONCE on your EC2 instance

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[✓]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

error() {
    echo -e "${RED}[✗]${NC} $1"
}

info() {
    echo -e "${BLUE}[i]${NC} $1"
}

echo ""
echo "========================================="
echo "  MyBlog Automatic Cleanup Setup"
echo "========================================="
echo ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   error "This script must be run as root (use sudo)"
   exit 1
fi

# Configuration
SCRIPTS_DIR="/home/ubuntu/myblog/scripts"
LOG_DIR="/var/log/myblog"
UBUNTU_USER="ubuntu"

# Create log directory
log "Creating log directory..."
mkdir -p "$LOG_DIR"
chown "$UBUNTU_USER:$UBUNTU_USER" "$LOG_DIR"

# Make cleanup scripts executable
log "Making cleanup scripts executable..."
chmod +x "$SCRIPTS_DIR/cleanup-docker.sh"
chmod +x "$SCRIPTS_DIR/cleanup-storage.sh"

# Setup Docker log rotation
log "Setting up Docker log rotation..."
cat > /etc/docker/daemon.json <<EOF
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF

# Restart Docker to apply log rotation
log "Restarting Docker to apply log rotation..."
systemctl restart docker

# Wait for Docker to be ready
sleep 3

# Backup existing crontab
log "Backing up current crontab..."
crontab -u "$UBUNTU_USER" -l > /tmp/crontab.backup 2>/dev/null || true

# Create new crontab
log "Setting up cron jobs..."
TEMP_CRON=$(mktemp)

# Add existing crontab (excluding old myblog entries)
crontab -u "$UBUNTU_USER" -l 2>/dev/null | grep -v "cleanup-docker\|cleanup-storage\|myblog" >> "$TEMP_CRON" || true

# Add new cron jobs
cat >> "$TEMP_CRON" << 'EOF'

# ====== MyBlog Automatic Maintenance ======

# Cleanup Docker resources - Daily at 2 AM
0 2 * * * /home/ubuntu/myblog/scripts/cleanup-docker.sh >> /var/log/myblog/cleanup.log 2>&1

# Cleanup Docker resources - Every 12 hours
0 */12 * * * /home/ubuntu/myblog/scripts/cleanup-docker.sh >> /var/log/myblog/cleanup.log 2>&1

# Storage cleanup if disk > 80% - Every 4 hours
0 */4 * * * DISK_USAGE=$(df / | awk 'NR==2 {print $5}' | sed 's/%//') && [ "$DISK_USAGE" -gt 80 ] && /home/ubuntu/myblog/scripts/cleanup-storage.sh >> /var/log/myblog/storage-cleanup.log 2>&1

# Health check - Every 5 minutes
*/5 * * * * curl -sf http://localhost:3000/api/health > /dev/null || echo "[$(date)] Frontend health check failed" >> /var/log/myblog/health.log

# Health check backend - Every 5 minutes
*/5 * * * * curl -sf http://localhost:3003/health > /dev/null || echo "[$(date)] Backend health check failed" >> /var/log/myblog/health.log

# Log rotation - Weekly
0 0 * * 0 find /var/log/myblog -name "*.log" -type f -mtime +7 -delete 2>/dev/null

EOF

# Install new crontab
crontab -u "$UBUNTU_USER" "$TEMP_CRON"
rm "$TEMP_CRON"

# Setup logrotate for myblog logs
log "Setting up log rotation..."
cat > /etc/logrotate.d/myblog <<EOF
/var/log/myblog/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 0640 ubuntu ubuntu
}
EOF

echo ""
log "========================================="
log "Automatic Cleanup Setup Complete!"
log "========================================="
echo ""
echo "Configured automatic tasks:"
echo ""
info "Docker Cleanup:"
echo "  • Daily at 2:00 AM"
echo "  • Every 12 hours"
echo ""
info "Storage Cleanup:"
echo "  • Every 4 hours (if disk usage > 80%)"
echo ""
info "Health Checks:"
echo "  • Every 5 minutes for both frontend and backend"
echo ""
info "Log Rotation:"
echo "  • Docker logs: max 10MB, keep 3 files"
echo "  • Application logs: keep 7 days"
echo ""
echo "View scheduled tasks:"
echo "  crontab -u $UBUNTU_USER -l"
echo ""
echo "View logs:"
echo "  tail -f /var/log/myblog/cleanup.log"
echo "  tail -f /var/log/myblog/storage-cleanup.log"
echo "  tail -f /var/log/myblog/health.log"
echo ""
echo "Manual cleanup:"
echo "  sudo $SCRIPTS_DIR/cleanup-storage.sh"
echo ""
log "Done! Your EC2 instance is now protected from storage issues."
echo ""
