# 🚨 IMMEDIATE Storage Fix - Run This Now!

## Option 1: Quick Fix via AWS Console (Recommended)

### Step 1: Open AWS Systems Manager Session

1. Go to **AWS Console → EC2 → Systems Manager → Session Manager**
2. Click **"Start session"**
3. Select your EC2 instance
4. Click **"Start session"**

### Step 2: Run Emergency Cleanup

Copy and paste this entire command block:

```bash
# Emergency Storage Cleanup
cd /home/ubuntu/MyBlog 2>/dev/null || cd /home/ubuntu

# Stop containers to free memory
sudo docker compose -f MyBlog/docker-compose.prod.yml down 2>/dev/null || true

# Aggressive Docker cleanup
sudo docker system prune -af --volumes
sudo docker builder prune -af

# Clean system cache
sudo apt-get clean
sudo apt-get autoclean
sudo apt-get autoremove -y

# Clean logs
sudo journalctl --vacuum-time=1d
sudo journalctl --vacuum-size=50M
sudo find /var/log -type f -name "*.log" -delete 2>/dev/null || true
sudo find /var/log -type f -name "*.gz" -delete 2>/dev/null || true

# Clean temp files
sudo rm -rf /tmp/*
sudo rm -rf /var/tmp/*

# Clean Docker logs
sudo find /var/lib/docker/containers -name "*.log" -type f -exec truncate -s 0 {} \;

# Check results
echo "===== AFTER CLEANUP ====="
df -h /
echo ""
docker system df

# Restart containers
cd /home/ubuntu/MyBlog
docker compose -f docker-compose.prod.yml up -d

# Wait and check
sleep 10
docker ps
```

### Step 3: Verify

```bash
# Check disk usage
df -h

# Should show more free space now
```

## Option 2: Increase EBS Volume (Long-term Solution)

### Via AWS Console:

1. **Go to EC2 → Volumes**
2. Select your EC2 instance's volume
3. Click **Actions → Modify Volume**
4. Change size from **8 GB → 20 GB** (or more)
5. Click **Modify**
6. Wait for state to change to "optimizing"

### Then Resize Filesystem (via Session Manager):

```bash
# Wait for volume modification to complete (check AWS console)

# Resize partition
sudo growpart /dev/xvda 1

# Resize filesystem
sudo resize2fs /dev/xvda1

# Verify new size
df -h /
```

## Option 3: Run Cleanup Script (If Already Deployed)

Via Session Manager:

```bash
# Run emergency cleanup script
sudo bash /home/ubuntu/MyBlog/scripts/cleanup-storage.sh

# Or run troubleshooting
sudo bash /home/ubuntu/MyBlog/scripts/troubleshoot.sh
```

## Check What's Using Space

```bash
# See largest directories
sudo du -h / --max-depth=1 2>/dev/null | sort -h | tail -20

# Check Docker usage
docker system df

# Check specific Docker components
sudo du -sh /var/lib/docker/*
```

## Prevent Future Issues

### 1. Set Up Docker Log Rotation (via Session Manager):

```bash
# Create Docker daemon config
sudo bash -c 'cat > /etc/docker/daemon.json << EOF
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF'

# Restart Docker
sudo systemctl restart docker

# Wait for Docker to be ready
sleep 5

# Restart containers
cd /home/ubuntu/MyBlog
docker compose -f docker-compose.prod.yml up -d
```

### 2. Set Up Automatic Cleanup Cron (via Session Manager):

```bash
# Create cron jobs for automatic cleanup
cat > /tmp/cleanup_cron << 'EOF'
# MyBlog Automatic Cleanup
0 2 * * * docker system prune -af > /dev/null 2>&1
0 */12 * * * docker system prune -af > /dev/null 2>&1
0 */4 * * * DISK_USAGE=$(df / | awk 'NR==2 {print $5}' | sed 's/%//') && [ "$DISK_USAGE" -gt 80 ] && docker system prune -af --volumes > /dev/null 2>&1
EOF

# Install cron
crontab /tmp/cleanup_cron
rm /tmp/cleanup_cron

# Verify
crontab -l
```

## Emergency Commands Cheat Sheet

```bash
# Quick cleanup
sudo docker system prune -af --volumes

# Check disk
df -h

# Check Docker disk usage
docker system df

# Stop all containers
docker stop $(docker ps -q)

# Remove all containers
docker rm $(docker ps -aq)

# Remove all images
docker rmi $(docker images -q)

# Clean logs
sudo journalctl --vacuum-time=1d

# Restart everything
cd /home/ubuntu/MyBlog
docker compose -f docker-compose.prod.yml up -d
```

## What's Taking Up Space?

Common culprits:

1. **Old Docker images** (biggest problem)
   - Fix: `docker image prune -af`

2. **Docker logs** (grows unlimited by default)
   - Fix: Configure log rotation (see above)

3. **System logs**
   - Fix: `sudo journalctl --vacuum-time=7d`

4. **Unused volumes**
   - Fix: `docker volume prune -f`

5. **Build cache**
   - Fix: `docker builder prune -af`

## Quick Decision Tree

```
Is disk > 90% full?
├─ YES → Run emergency cleanup immediately
│         Then increase EBS volume size
│
└─ NO → Is disk > 80% full?
    ├─ YES → Run cleanup & set up automatic cleanup
    │
    └─ NO → Just set up automatic cleanup for prevention
```

## Recommended Settings for t3.micro

- **EBS Volume**: 20 GB minimum (not 8 GB)
- **Docker log limit**: 10 MB per container, 3 files max
- **Auto cleanup**: Every 12 hours
- **Emergency cleanup**: When disk > 80%

---

**After fixing storage, commit and push code to enable automatic prevention!**
