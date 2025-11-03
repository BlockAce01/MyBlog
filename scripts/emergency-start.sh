#!/bin/bash

# Emergency Start Script
# Use this if containers don't start after reboot
# Run via AWS Systems Manager Session Manager

set -e

echo "========================================="
echo "MyBlog Emergency Start"
echo "========================================="
echo ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "⚠️  Not running as root. Some commands may fail."
   echo "Continuing anyway..."
fi

# Step 1: Ensure Docker is running
echo "[1/6] Checking Docker status..."
if ! systemctl is-active --quiet docker; then
    echo "⚠️  Docker is not running. Starting Docker..."
    sudo systemctl start docker
    sleep 5
else
    echo "✅ Docker is running"
fi

# Step 2: Wait for Docker to be ready
echo "[2/6] Waiting for Docker to be fully ready..."
TIMEOUT=30
COUNT=0
until docker info > /dev/null 2>&1 || [ $COUNT -eq $TIMEOUT ]; do
    echo "Waiting for Docker... ($COUNT/$TIMEOUT)"
    sleep 1
    COUNT=$((COUNT+1))
done

if [ $COUNT -eq $TIMEOUT ]; then
    echo "❌ Docker failed to start properly"
    exit 1
fi
echo "✅ Docker is ready"

# Step 3: Navigate to application directory
echo "[3/6] Navigating to application directory..."
if [ -d "/home/ubuntu/MyBlog" ]; then
    cd /home/ubuntu/MyBlog
    echo "✅ Found application directory: $(pwd)"
elif [ -d "/home/ubuntu/myblog" ]; then
    cd /home/ubuntu/myblog
    echo "✅ Found application directory: $(pwd)"
else
    echo "❌ Application directory not found!"
    echo "Searched: /home/ubuntu/MyBlog and /home/ubuntu/myblog"
    exit 1
fi

# Step 4: Check if docker-compose.prod.yml exists
echo "[4/6] Checking for docker-compose.prod.yml..."
if [ ! -f "docker-compose.prod.yml" ]; then
    echo "❌ docker-compose.prod.yml not found!"
    ls -la
    exit 1
fi
echo "✅ Found docker-compose.prod.yml"

# Step 5: Check if .env exists
echo "[5/6] Checking for .env file..."
if [ ! -f ".env" ]; then
    echo "⚠️  .env file not found! Creating minimal .env..."
    cat > .env << 'EOF'
NODE_ENV=production
TZ=Asia/Colombo
EOF
    echo "⚠️  .env created with minimal settings. Update with your secrets!"
else
    echo "✅ .env file exists"
fi

# Step 6: Start containers
echo "[6/6] Starting containers..."

# Stop any running containers first
echo "Stopping existing containers..."
docker compose -f docker-compose.prod.yml down 2>/dev/null || true

# Start containers
echo "Starting containers..."
if docker compose -f docker-compose.prod.yml up -d; then
    echo "✅ Containers started successfully!"
else
    echo "❌ Failed to start containers"
    echo ""
    echo "Checking Docker status:"
    docker ps -a
    echo ""
    echo "Checking logs:"
    docker compose -f docker-compose.prod.yml logs --tail=20
    exit 1
fi

# Wait and verify
echo ""
echo "Waiting for containers to initialize..."
sleep 10

echo ""
echo "========================================="
echo "Container Status:"
echo "========================================="
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo "========================================="
echo "Health Check:"
echo "========================================="

# Check frontend
if curl -sf http://localhost:3000/api/health > /dev/null 2>&1; then
    echo "✅ Frontend: Healthy"
else
    echo "⚠️  Frontend: Not responding yet (may need more time)"
fi

# Check backend
if curl -sf http://localhost:3003/health > /dev/null 2>&1; then
    echo "✅ Backend: Healthy"
else
    echo "⚠️  Backend: Not responding yet (may need more time)"
fi

echo ""
echo "========================================="
echo "✅ Emergency start completed!"
echo "========================================="
echo ""
echo "If services are not healthy, wait 30 seconds and check again:"
echo "  curl http://localhost:3000/api/health"
echo "  curl http://localhost:3003/health"
echo ""
echo "To view logs:"
echo "  docker logs -f myblog-frontend"
echo "  docker logs -f myblog-backend"
echo ""
