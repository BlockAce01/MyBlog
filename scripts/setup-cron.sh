#!/bin/bash

# MyBlog Cron Job Setup Script
# Automatically sets up cron jobs for cleanup and monitoring
# Run this once to set up automation

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
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

# Configuration
SCRIPTS_DIR="/home/ubuntu/MyBlog/scripts"
CRONTAB_BACKUP="/home/ubuntu/crontab.backup"
UBUNTU_USER="ubuntu"

echo "========================================="
echo "MyBlog Cron Job Setup"
echo "========================================="
echo ""

# Check if scripts exist
if [ ! -f "$SCRIPTS_DIR/cleanup-docker.sh" ] || [ ! -f "$SCRIPTS_DIR/deploy.sh" ]; then
    error "Scripts not found in $SCRIPTS_DIR"
    exit 1
fi

# Make scripts executable
log "Making scripts executable..."
sudo chmod +x "$SCRIPTS_DIR/cleanup-docker.sh"
sudo chmod +x "$SCRIPTS_DIR/deploy.sh"

# Create log directory
log "Creating log directory..."
sudo mkdir -p /var/log/myblog
sudo chown "$UBUNTU_USER:$UBUNTU_USER" /var/log/myblog

# Backup current crontab
log "Backing up current crontab to $CRONTAB_BACKUP..."
sudo crontab -u "$UBUNTU_USER" -l > "$CRONTAB_BACKUP" 2>/dev/null || true

# Create new crontab entries
log "Setting up cron jobs for automated cleanup and monitoring..."

# Create temporary crontab file
TEMP_CRON=$(mktemp)

# Add existing crontab entries
sudo crontab -u "$UBUNTU_USER" -l 2>/dev/null | grep -v "cleanup-docker\|deploy" >> "$TEMP_CRON" || true

# Add new cron jobs
cat >> "$TEMP_CRON" << 'EOF'

# MyBlog Docker Cleanup - Every day at 2 AM
0 2 * * * /home/ubuntu/MyBlog/scripts/cleanup-docker.sh >> /var/log/myblog/cleanup.log 2>&1

# MyBlog Docker Cleanup - Every 6 hours
0 */6 * * * /home/ubuntu/MyBlog/scripts/cleanup-docker.sh >> /var/log/myblog/cleanup.log 2>&1

# MyBlog Health Check - Every 30 minutes
*/30 * * * * curl -s http://localhost:3000/api/health > /dev/null && curl -s http://localhost:3003/health > /dev/null || echo "Health check failed at $(date)" >> /var/log/myblog/health-check.log

EOF

# Install new crontab
sudo crontab -u "$UBUNTU_USER" "$TEMP_CRON"
rm "$TEMP_CRON"

log "Cron jobs have been set up successfully!"
log ""
log "Scheduled tasks:"
echo "  • Docker cleanup: Daily at 2:00 AM"
echo "  • Docker cleanup: Every 6 hours"
echo "  • Health check: Every 30 minutes"
log ""
log "View scheduled cron jobs:"
echo "  sudo crontab -u $UBUNTU_USER -l"
log ""
log "View logs:"
echo "  Cleanup logs: tail -f /var/log/myblog/cleanup.log"
echo "  Health checks: tail -f /var/log/myblog/health-check.log"
log ""
log "To remove cron jobs, restore from backup:"
echo "  sudo crontab -u $UBUNTU_USER -i < $CRONTAB_BACKUP"
log ""
echo "========================================="
