#!/bin/bash

# MyBlog Systemd Service Setup Script
# This script sets up automatic restart of Docker containers on EC2 reboot
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
echo "  MyBlog Systemd Service Setup"
echo "========================================="
echo ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   error "This script must be run as root (use sudo)"
   exit 1
fi

# Variables
SERVICE_FILE="/etc/systemd/system/myblog.service"
APP_DIR="/home/ubuntu/myblog"
UBUNTU_USER="ubuntu"

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    error "Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if application directory exists
if [ ! -d "$APP_DIR" ]; then
    warning "Application directory $APP_DIR does not exist. Creating it..."
    mkdir -p "$APP_DIR"
    chown "$UBUNTU_USER:$UBUNTU_USER" "$APP_DIR"
fi

# Check if docker-compose.prod.yml exists
if [ ! -f "$APP_DIR/docker-compose.prod.yml" ]; then
    error "docker-compose.prod.yml not found in $APP_DIR"
    error "Please deploy your application first before running this script."
    exit 1
fi

# Check if .env file exists
if [ ! -f "$APP_DIR/.env" ]; then
    warning ".env file not found in $APP_DIR"
    warning "Make sure to create it before starting the service."
fi

# Copy service file
log "Installing systemd service file..."
cp "$(dirname "$0")/myblog.service" "$SERVICE_FILE"

# Set correct permissions
chmod 644 "$SERVICE_FILE"

# Reload systemd
log "Reloading systemd daemon..."
systemctl daemon-reload

# Enable the service
log "Enabling myblog service to start on boot..."
systemctl enable myblog.service

# Check if Docker containers are already running
if docker ps | grep -q "myblog"; then
    warning "MyBlog containers are already running."
    info "Stopping them before starting via systemd..."
    cd "$APP_DIR"
    docker compose -f docker-compose.prod.yml down
fi

# Start the service
log "Starting myblog service..."
systemctl start myblog.service

# Wait a moment for services to initialize
sleep 5

# Check service status
log "Checking service status..."
if systemctl is-active --quiet myblog.service; then
    log "✅ MyBlog service is running successfully!"
else
    error "Service failed to start. Checking logs..."
    systemctl status myblog.service --no-pager
    exit 1
fi

# Display running containers
echo ""
info "Running containers:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""
log "========================================="
log "Setup completed successfully!"
log "========================================="
echo ""
echo "Your MyBlog application will now:"
echo "  ✓ Start automatically on EC2 reboot"
echo "  ✓ Restart automatically if it crashes"
echo "  ✓ Pull latest images on start (optional)"
echo ""
echo "Useful commands:"
echo "  • Check service status:    sudo systemctl status myblog"
echo "  • View service logs:       sudo journalctl -u myblog -f"
echo "  • Restart service:         sudo systemctl restart myblog"
echo "  • Stop service:            sudo systemctl stop myblog"
echo "  • Disable auto-start:      sudo systemctl disable myblog"
echo ""
echo "Container logs:"
echo "  • Frontend logs:           docker logs -f myblog-frontend"
echo "  • Backend logs:            docker logs -f myblog-backend"
echo "  • Nginx logs:              docker logs -f myblog-nginx"
echo ""
log "Done! Your application is now production-ready."
echo ""
