#!/bin/bash

# MyBlog Automated Deployment Script
# Pulls latest images from ECR and deploys them with automatic cleanup
# Usage: ./deploy.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
AWS_REGION="us-east-1"
AWS_ACCOUNT_ID="${AWS_ACCOUNT_ID:-856708425793}"
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
MYBLOG_DIR="/home/ubuntu/MyBlog"
LOG_FILE="${MYBLOG_DIR}/deployment.log"
HEALTH_CHECK_RETRIES=10
HEALTH_CHECK_INTERVAL=5

# Logging functions
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

success() {
    echo -e "${GREEN}[✓]${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[✗]${NC} $1" | tee -a "$LOG_FILE"
}

warning() {
    echo -e "${YELLOW}[!]${NC} $1" | tee -a "$LOG_FILE"
}

info() {
    echo -e "${BLUE}[i]${NC} $1" | tee -a "$LOG_FILE"
}

# Function to check if we're in the right directory
check_directory() {
    if [ ! -f "$MYBLOG_DIR/docker-compose.prod.yml" ]; then
        error "docker-compose.prod.yml not found in $MYBLOG_DIR"
        exit 1
    fi
    cd "$MYBLOG_DIR"
    success "Working directory verified: $MYBLOG_DIR"
}

# Function to check disk space
check_disk_space() {
    local available=$(df "$MYBLOG_DIR" | awk 'NR==2 {print $4}')
    local available_gb=$((available / 1024 / 1024))

    if [ "$available_gb" -lt 2 ]; then
        warning "Low disk space available: ${available_gb}GB"
        log "Running cleanup before deployment..."
        cleanup_resources
    else
        info "Available disk space: ${available_gb}GB"
    fi
}

# Function to cleanup resources
cleanup_resources() {
    log "Cleaning up Docker resources..."

    docker system prune -af || warning "Failed to prune Docker system"
    docker volume prune -f || warning "Failed to prune volumes"

    success "Docker cleanup completed"
}

# Function to login to ECR
ecr_login() {
    log "Logging in to Amazon ECR..."

    if aws ecr get-login-password --region "$AWS_REGION" | \
       docker login --username AWS --password-stdin "$ECR_REGISTRY"; then
        success "Successfully logged in to ECR"
    else
        error "Failed to login to ECR"
        exit 1
    fi
}

# Function to remove old images
remove_old_images() {
    log "Removing old cached images..."

    docker rmi -f "${ECR_REGISTRY}/myblog/frontend:latest" 2>/dev/null || true
    docker rmi -f "${ECR_REGISTRY}/myblog/backend:latest" 2>/dev/null || true

    success "Old images removed"
}

# Function to pull latest images
pull_latest_images() {
    log "Pulling latest images from ECR..."

    info "Pulling backend image..."
    if docker pull "${ECR_REGISTRY}/myblog/backend:latest"; then
        success "Backend image pulled successfully"
    else
        error "Failed to pull backend image"
        exit 1
    fi

    info "Pulling frontend image..."
    if docker pull "${ECR_REGISTRY}/myblog/frontend:latest"; then
        success "Frontend image pulled successfully"
    else
        error "Failed to pull frontend image"
        exit 1
    fi
}

# Function to stop running containers
stop_containers() {
    log "Stopping running containers..."

    docker compose -f docker-compose.prod.yml down || warning "Failed to stop containers"

    success "Containers stopped"
}

# Function to start new containers
start_containers() {
    log "Starting new containers..."

    if docker compose -f docker-compose.prod.yml up -d --pull always; then
        success "Containers started successfully"
    else
        error "Failed to start containers"
        exit 1
    fi
}

# Function to wait for containers to be ready
wait_for_containers() {
    log "Waiting for containers to be ready..."

    sleep 10

    local retries=0
    while [ $retries -lt "$HEALTH_CHECK_RETRIES" ]; do
        info "Health check attempt $((retries + 1))/$HEALTH_CHECK_RETRIES"

        # Check backend
        if curl -sf --connect-timeout 5 http://localhost:3003/health > /dev/null 2>&1; then
            success "Backend is healthy"
        else
            warning "Backend is not responding yet"
        fi

        # Check frontend
        if curl -sf --connect-timeout 5 http://localhost:3000/api/health > /dev/null 2>&1; then
            success "Frontend is healthy"
        else
            warning "Frontend is not responding yet"
        fi

        retries=$((retries + 1))

        if [ $retries -lt "$HEALTH_CHECK_RETRIES" ]; then
            sleep "$HEALTH_CHECK_INTERVAL"
        fi
    done
}

# Function to verify deployment
verify_deployment() {
    log "Verifying deployment..."

    local container_count=$(docker ps --filter "label=com.docker.compose.project=MyBlog" --quiet | wc -l)

    if [ "$container_count" -ge 3 ]; then
        success "All containers are running"
    else
        warning "Not all expected containers are running (found: $container_count, expected: 3)"
    fi

    # Display container info
    log "Running containers:"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Size}}"
}

# Function to display deployment report
show_report() {
    log ""
    log "========================================="
    log "DEPLOYMENT REPORT"
    log "========================================="
    log "Deployment completed at: $(date)"
    log "AWS Region: $AWS_REGION"
    log "ECR Registry: $ECR_REGISTRY"
    log ""
    log "Running Services:"
    docker ps --format "table {{.Names}}\t{{.Status}}" | grep myblog || warning "No MyBlog containers found"
    log ""
    log "========================================="
}

# Function to handle errors
handle_error() {
    error "Deployment failed!"
    error "Check logs at: $LOG_FILE"
    exit 1
}

# Trap errors
trap handle_error ERR

# Main execution
main() {
    log "========================================="
    log "MyBlog Deployment Started"
    log "========================================="

    check_directory
    check_disk_space
    ecr_login
    remove_old_images
    pull_latest_images
    stop_containers
    start_containers
    wait_for_containers
    verify_deployment
    show_report

    success "Deployment completed successfully!"
}

# Run main function
main
