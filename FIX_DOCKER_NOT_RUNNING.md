# 🚨 Docker Not Running - Fix Now!

## Quick Fix - Copy & Paste This:

```bash
# Start Docker service
sudo systemctl start docker

# Wait for Docker to be ready
sleep 5

# Check if Docker is running
sudo systemctl status docker

# Test Docker
docker ps

# If Docker is working, now run cleanup:
cd /home/ubuntu/MyBlog
sudo docker system prune -af --volumes
sudo docker builder prune -af

# Check disk space
df -h /

# Start your containers
docker compose -f docker-compose.prod.yml up -d

# Wait and check
sleep 10
docker ps
```

## Enable Docker Auto-Start on Reboot:

```bash
# Enable Docker to start on boot
sudo systemctl enable docker

# Verify it's enabled
sudo systemctl is-enabled docker
# Should show: enabled
```

## If Docker Still Won't Start:

```bash
# Check Docker service status
sudo systemctl status docker --no-pager

# Check Docker logs
sudo journalctl -u docker -n 50 --no-pager

# Try restarting Docker
sudo systemctl restart docker

# Wait
sleep 5

# Test again
docker ps
```

## Complete Recovery Command Block:

**Copy this entire block and paste in Session Manager:**

```bash
#!/bin/bash
echo "Starting Docker recovery..."

# Start Docker
sudo systemctl start docker
sudo systemctl enable docker

# Wait for Docker to be ready
echo "Waiting for Docker to be ready..."
sleep 5

# Test Docker
if docker ps > /dev/null 2>&1; then
    echo "✅ Docker is running!"
else
    echo "❌ Docker failed to start. Checking logs..."
    sudo systemctl status docker --no-pager
    sudo journalctl -u docker -n 20 --no-pager
    exit 1
fi

# Navigate to app
cd /home/ubuntu/MyBlog || cd /home/ubuntu/myblog

# Cleanup
echo "Running cleanup..."
sudo docker system prune -af --volumes
sudo docker builder prune -af

# Check disk
echo "Disk usage:"
df -h /

# Start containers
echo "Starting containers..."
docker compose -f docker-compose.prod.yml up -d

# Wait
sleep 10

# Check status
echo "Container status:"
docker ps

echo "✅ Recovery complete!"
```

---

**Next: After this works, commit and push code to prevent this issue!**
