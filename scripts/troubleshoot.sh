#!/bin/bash

# MyBlog Troubleshooting Script
# Run this via AWS Systems Manager Session Manager to diagnose issues

echo "========================================="
echo "MyBlog Troubleshooting Report"
echo "========================================="
echo "Time: $(date)"
echo ""

# 1. Docker Status
echo "========================================="
echo "1. DOCKER STATUS"
echo "========================================="
if systemctl is-active --quiet docker; then
    echo "✅ Docker service: RUNNING"
else
    echo "❌ Docker service: NOT RUNNING"
    echo "To fix: sudo systemctl start docker"
fi
echo ""
docker --version 2>/dev/null || echo "❌ Docker not installed"
echo ""

# 2. Docker Info
echo "========================================="
echo "2. DOCKER INFO"
echo "========================================="
docker info 2>&1 | head -20 || echo "❌ Docker not responding"
echo ""

# 3. Application Directory
echo "========================================="
echo "3. APPLICATION DIRECTORY"
echo "========================================="
if [ -d "/home/ubuntu/MyBlog" ]; then
    echo "✅ Found: /home/ubuntu/MyBlog"
    cd /home/ubuntu/MyBlog
    ls -lah
elif [ -d "/home/ubuntu/myblog" ]; then
    echo "✅ Found: /home/ubuntu/myblog"
    cd /home/ubuntu/myblog
    ls -lah
else
    echo "❌ Application directory NOT FOUND"
    echo "Searched: /home/ubuntu/MyBlog and /home/ubuntu/myblog"
fi
echo ""

# 4. Required Files
echo "========================================="
echo "4. REQUIRED FILES"
echo "========================================="
for file in docker-compose.prod.yml .env; do
    if [ -f "$file" ]; then
        echo "✅ $file exists"
    else
        echo "❌ $file MISSING"
    fi
done
echo ""

# 5. Running Containers
echo "========================================="
echo "5. RUNNING CONTAINERS"
echo "========================================="
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" || echo "❌ No containers running"
echo ""

# 6. All Containers (including stopped)
echo "========================================="
echo "6. ALL CONTAINERS (INCLUDING STOPPED)"
echo "========================================="
docker ps -a --format "table {{.Names}}\t{{.Status}}" || echo "❌ No containers found"
echo ""

# 7. Systemd Service Status
echo "========================================="
echo "7. SYSTEMD SERVICE STATUS"
echo "========================================="
if [ -f "/etc/systemd/system/myblog.service" ]; then
    echo "✅ Service file exists"
    echo ""
    sudo systemctl status myblog.service --no-pager || true
    echo ""
    if sudo systemctl is-enabled myblog.service &>/dev/null; then
        echo "✅ Service is ENABLED (will start on boot)"
    else
        echo "❌ Service is NOT ENABLED (won't start on boot)"
        echo "To fix: sudo systemctl enable myblog.service"
    fi
else
    echo "❌ Service file NOT FOUND at /etc/systemd/system/myblog.service"
fi
echo ""

# 8. Health Checks
echo "========================================="
echo "8. HEALTH CHECKS"
echo "========================================="
if curl -sf --connect-timeout 5 http://localhost:3000/api/health > /dev/null 2>&1; then
    echo "✅ Frontend (port 3000): HEALTHY"
else
    echo "❌ Frontend (port 3000): NOT RESPONDING"
fi

if curl -sf --connect-timeout 5 http://localhost:3003/health > /dev/null 2>&1; then
    echo "✅ Backend (port 3003): HEALTHY"
else
    echo "❌ Backend (port 3003): NOT RESPONDING"
fi
echo ""

# 9. Disk Usage
echo "========================================="
echo "9. DISK USAGE"
echo "========================================="
df -h / | awk 'NR==1{print $0} NR==2{print $0; if(int($5)>80) print "⚠️  WARNING: Disk usage is HIGH!"}'
echo ""

# 10. Docker Disk Usage
echo "========================================="
echo "10. DOCKER DISK USAGE"
echo "========================================="
docker system df || echo "❌ Docker not responding"
echo ""

# 11. Recent Docker Logs
echo "========================================="
echo "11. RECENT CONTAINER LOGS (Last 10 lines)"
echo "========================================="
for container in myblog-frontend myblog-backend myblog-nginx; do
    if docker ps --format "{{.Names}}" | grep -q "^${container}$"; then
        echo "--- $container ---"
        docker logs "$container" --tail 10 2>&1
        echo ""
    fi
done

# 12. System Journal Errors
echo "========================================="
echo "12. RECENT SYSTEM ERRORS (Last 20 lines)"
echo "========================================="
sudo journalctl -u myblog.service -n 20 --no-pager 2>/dev/null || echo "No journal entries"
echo ""

# 13. Cron Jobs
echo "========================================="
echo "13. SCHEDULED CLEANUP JOBS"
echo "========================================="
if crontab -l 2>/dev/null | grep -q 'cleanup'; then
    echo "✅ Cleanup cron jobs are configured:"
    crontab -l 2>/dev/null | grep cleanup
else
    echo "⚠️  No cleanup cron jobs found"
fi
echo ""

# 14. Network Connectivity
echo "========================================="
echo "14. NETWORK CONNECTIVITY"
echo "========================================="
if ping -c 1 google.com > /dev/null 2>&1; then
    echo "✅ Internet connectivity: OK"
else
    echo "❌ Internet connectivity: FAILED"
fi
echo ""

# Summary
echo "========================================="
echo "QUICK FIX COMMANDS"
echo "========================================="
echo ""
echo "If Docker is not running:"
echo "  sudo systemctl start docker"
echo ""
echo "If containers are not running:"
echo "  cd /home/ubuntu/MyBlog"
echo "  docker compose -f docker-compose.prod.yml up -d"
echo ""
echo "If systemd service is not enabled:"
echo "  sudo systemctl enable myblog.service"
echo "  sudo systemctl start myblog.service"
echo ""
echo "Emergency restart everything:"
echo "  sudo bash /home/ubuntu/MyBlog/scripts/emergency-start.sh"
echo ""
echo "Clean up storage:"
echo "  sudo bash /home/ubuntu/MyBlog/scripts/cleanup-storage.sh"
echo ""
echo "========================================="
echo "Troubleshooting completed!"
echo "========================================="
