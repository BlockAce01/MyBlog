#!/bin/bash

# MyBlog Aggressive Storage Cleanup Script
# Fixes "out of storage" issues on EC2 instances
# Run this when facing storage problems

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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
echo "  MyBlog Storage Cleanup"
echo "========================================="
echo ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   error "This script must be run as root (use sudo)"
   exit 1
fi

# Function to show disk usage
show_disk_usage() {
    info "Current disk usage:"
    df -h / | awk 'NR==1{print "  "$0} NR==2{print "  "$0}'
    echo ""
}

# Function to show docker disk usage
show_docker_usage() {
    info "Docker disk usage:"
    docker system df
    echo ""
}

# Show initial state
log "BEFORE CLEANUP:"
show_disk_usage
show_docker_usage

# Step 1: Clean Docker Build Cache
log "Step 1: Cleaning Docker build cache..."
docker builder prune -af

# Step 2: Remove all stopped containers
log "Step 2: Removing all stopped containers..."
docker container prune -f

# Step 3: Remove unused images (aggressive)
log "Step 3: Removing unused images..."
docker image prune -af

# Step 4: Remove unused volumes
log "Step 4: Removing unused volumes..."
docker volume prune -af

# Step 5: Remove unused networks
log "Step 5: Removing unused networks..."
docker network prune -f

# Step 6: Remove old Docker logs
log "Step 6: Cleaning Docker logs..."
if [ -d "/var/lib/docker/containers" ]; then
    find /var/lib/docker/containers -name "*.log" -type f -exec truncate -s 0 {} \;
    log "Truncated all Docker container logs"
fi

# Step 7: Clean package manager cache
log "Step 7: Cleaning package manager cache..."
apt-get clean
apt-get autoclean
apt-get autoremove -y

# Step 8: Clean journal logs
log "Step 8: Cleaning system journal logs..."
journalctl --vacuum-time=7d
journalctl --vacuum-size=100M

# Step 9: Remove old log files
log "Step 9: Removing old log files..."
find /var/log -type f -name "*.log" -mtime +30 -delete 2>/dev/null || true
find /var/log -type f -name "*.gz" -delete 2>/dev/null || true

# Step 10: Clean apt cache
log "Step 10: Cleaning apt cache..."
rm -rf /var/cache/apt/archives/*.deb

# Step 11: Remove temporary files
log "Step 11: Removing temporary files..."
rm -rf /tmp/*
rm -rf /var/tmp/*

# Step 12: Clean thumbnail cache
log "Step 12: Cleaning thumbnail cache..."
rm -rf /home/*/.cache/thumbnails/* 2>/dev/null || true

# Step 13: Complete Docker system prune
log "Step 13: Running complete Docker system prune..."
docker system prune -af --volumes

# Show final state
echo ""
log "AFTER CLEANUP:"
show_disk_usage
show_docker_usage

# Calculate space reclaimed
info "Cleanup completed successfully!"
echo ""
warning "NOTE: If storage is still critical, consider:"
echo "  1. Increasing EC2 instance volume size"
echo "  2. Using external storage (EBS volume)"
echo "  3. Implementing log rotation"
echo "  4. Moving to larger instance type"
echo ""
log "Done!"
echo ""
