#!/bin/bash

# MyBlog Docker Cleanup Script
# Automatically cleans up Docker resources and frees disk space
# Run manually or via cron job

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
DISK_THRESHOLD=80  # Alert if disk usage exceeds 80%
LOG_FILE="/var/log/myblog-cleanup.log"

# Logging function
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Alert function
alert() {
    echo -e "${YELLOW}[ALERT]${NC} $1" | tee -a "$LOG_FILE"
}

# Success function
success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"
}

# Error function
error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

log "========================================="
log "MyBlog Docker Cleanup Started"
log "========================================="

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   error "This script must be run as root (use sudo)"
   exit 1
fi

# Function to check disk usage
check_disk_usage() {
    local disk_usage=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
    log "Current disk usage: ${disk_usage}%"

    if [ "$disk_usage" -gt "$DISK_THRESHOLD" ]; then
        alert "Disk usage is above threshold (${disk_usage}%)"
        return 1
    fi
    return 0
}

# Function to clean up Docker resources
cleanup_docker() {
    log "Cleaning up Docker resources..."

    # Remove stopped containers
    log "Removing stopped containers..."
    docker container prune -f

    # Remove unused images
    log "Removing unused images..."
    docker image prune -f

    # Remove dangling images
    log "Removing dangling images..."
    docker image prune -f -a

    # Remove unused volumes
    log "Removing unused volumes..."
    docker volume prune -f

    # Remove unused networks
    log "Removing unused networks..."
    docker network prune -f

    # Clean up Docker temporary files
    log "Cleaning Docker temporary files..."
    sudo rm -rf /var/lib/docker/tmp/* 2>/dev/null || true

    success "Docker cleanup completed"
}

# Function to clean up system files
cleanup_system() {
    log "Cleaning up system files..."

    # Remove old apt cache
    log "Removing apt cache..."
    apt-get autoremove -y
    apt-get autoclean -y

    # Clean up journal logs if too large
    log "Cleaning journal logs..."
    journalctl --vacuum=100M 2>/dev/null || true

    # Remove old log files
    log "Removing old log files..."
    find /var/log -type f -name "*.log" -mtime +30 -delete 2>/dev/null || true

    success "System cleanup completed"
}

# Function to report disk space reclaimed
report_reclaimed_space() {
    log "Running final Docker system prune for space calculation..."
    docker system prune -af

    log "========================================="
    log "Cleanup Report"
    log "========================================="

    # Get current disk usage
    local current_usage=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
    local available=$(df / | awk 'NR==2 {print $4}')

    log "Disk usage after cleanup: ${current_usage}%"
    log "Available space: ${available}K"

    check_disk_usage
}

# Function to display status
display_status() {
    log ""
    log "========================================="
    log "Docker Status"
    log "========================================="
    log "Running containers:"
    docker ps --format "table {{.Names}}\t{{.Status}}"
    log ""
    log "Docker images:"
    docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"
}

# Main execution
main() {
    trap 'error "Script interrupted"; exit 1' INT TERM

    check_disk_usage || alert "Disk space might be an issue"

    cleanup_docker
    cleanup_system
    report_reclaimed_space
    display_status

    log "========================================="
    log "MyBlog Docker Cleanup Completed"
    log "========================================="
}

# Run main function
main
