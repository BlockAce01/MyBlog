# EC2 Auto-Restart & Storage Management Guide

This guide fixes two critical issues:

1. **Auto-restart on EC2 reboot** - Application automatically starts after instance restart
2. **Storage management** - Prevents "out of storage" issues that block deployments

## 🚀 Quick Setup (Run Once on EC2)

SSH into your EC2 instance and run these commands:

```bash
# Navigate to your application directory
cd /home/ubuntu/myblog

# Pull latest changes (if using git)
git pull origin main

# 1. Setup auto-restart on EC2 reboot
sudo bash scripts/setup-systemd.sh

# 2. Setup automatic storage cleanup
sudo bash scripts/setup-auto-cleanup.sh

# 3. Run initial storage cleanup (if having storage issues now)
sudo bash scripts/cleanup-storage.sh
```

That's it! ✅

## 📋 What Gets Installed

### 1. Systemd Service (`myblog.service`)

**Purpose**: Automatically starts Docker containers on EC2 reboot

**Features**:

- ✅ Auto-starts on boot
- ✅ Restarts on failure
- ✅ Waits for Docker and network to be ready
- ✅ Pulls latest images (optional)

**Management Commands**:

```bash
# Check status
sudo systemctl status myblog

# View logs
sudo journalctl -u myblog -f

# Restart service
sudo systemctl restart myblog

# Stop service
sudo systemctl stop myblog

# Disable auto-start
sudo systemctl disable myblog
```

### 2. Automatic Storage Cleanup

**Purpose**: Prevents storage issues that block deployments

**Scheduled Tasks**:

| Task            | Frequency                      | Purpose                                     |
| --------------- | ------------------------------ | ------------------------------------------- |
| Docker cleanup  | Daily at 2 AM + Every 12 hours | Remove unused images, containers, volumes   |
| Storage cleanup | Every 4 hours (if disk > 80%)  | Aggressive cleanup when storage is critical |
| Health checks   | Every 5 minutes                | Monitor application health                  |
| Log rotation    | Weekly                         | Clean old logs                              |

**Docker Log Limits**:

- Max log file size: 10 MB
- Max log files per container: 3
- Total logs per container: ~30 MB

### 3. Storage Cleanup Scripts

#### `cleanup-docker.sh`

Regular Docker maintenance - safe for production

- Removes stopped containers
- Removes unused images
- Removes dangling volumes
- Cleans build cache

#### `cleanup-storage.sh`

Aggressive cleanup when storage is critical

- Everything in `cleanup-docker.sh`
- Truncates Docker logs
- Cleans system logs
- Removes temp files
- Cleans package cache

## 🔧 Manual Operations

### Check Disk Usage

```bash
# Overall disk usage
df -h

# Docker disk usage
docker system df

# Top disk consumers
du -sh /* | sort -h
```

### Manual Cleanup

```bash
# Regular cleanup
sudo /home/ubuntu/myblog/scripts/cleanup-docker.sh

# Aggressive cleanup (when desperate)
sudo /home/ubuntu/myblog/scripts/cleanup-storage.sh

# Nuclear option (removes ALL Docker data)
docker system prune -af --volumes
```

### View Cleanup Logs

```bash
# Regular cleanup logs
tail -f /var/log/myblog/cleanup.log

# Storage cleanup logs
tail -f /var/log/myblog/storage-cleanup.log

# Health check logs
tail -f /var/log/myblog/health.log
```

### Container Management

```bash
# View running containers
docker ps

# View container logs
docker logs -f myblog-frontend
docker logs -f myblog-backend
docker logs -f myblog-nginx

# Restart specific container
docker restart myblog-frontend
```

## 🧪 Testing Auto-Restart

### Test 1: Reboot EC2 Instance

```bash
# Reboot EC2
sudo reboot

# Wait for instance to come back up, then SSH back in
ssh -i your-key.pem ubuntu@your-ec2-ip

# Check if containers are running
docker ps

# Should see all three containers running
# Check service status
sudo systemctl status myblog
```

### Test 2: Simulate Service Failure

```bash
# Stop the service
sudo systemctl stop myblog

# Containers should stop
docker ps

# Start the service
sudo systemctl start myblog

# Containers should start automatically
docker ps
```

## 📊 Monitoring

### Check Storage Health

```bash
# View disk usage trend
df -h

# Check if cleanup is working
ls -lh /var/log/myblog/cleanup.log
tail -20 /var/log/myblog/cleanup.log
```

### Check Application Health

```bash
# Frontend health
curl http://localhost:3000/api/health

# Backend health
curl http://localhost:3003/health

# View health check logs
tail -f /var/log/myblog/health.log
```

### View Cron Jobs

```bash
# List scheduled jobs
crontab -l

# View cron execution logs
grep CRON /var/log/syslog
```

## ⚠️ Troubleshooting

### Issue: Service won't start after reboot

**Check:**

```bash
# View service logs
sudo journalctl -u myblog -n 50

# Check Docker status
sudo systemctl status docker

# Manually start
sudo systemctl start myblog
```

**Common fixes:**

- Ensure `.env` file exists in `/home/ubuntu/myblog/`
- Ensure `docker-compose.prod.yml` exists
- Check file permissions: `ls -la /home/ubuntu/myblog/`

### Issue: Still running out of storage

**Immediate fix:**

```bash
# Run aggressive cleanup
sudo /home/ubuntu/myblog/scripts/cleanup-storage.sh

# Check what's using space
du -sh /var/lib/docker/*
```

**Long-term solutions:**

1. **Increase EBS volume size:**

   ```bash
   # In AWS Console: EC2 → Volumes → Modify Volume
   # Then resize filesystem:
   sudo growpart /dev/xvda 1
   sudo resize2fs /dev/xvda1
   ```

2. **Use ECR image cleanup:**
   - In AWS Console: ECR → Repository → Lifecycle policies
   - Keep only last 5 images

3. **Upgrade instance:**
   - Consider t3.small (20GB) instead of t3.micro (8GB)

### Issue: Containers not responding after restart

**Check:**

```bash
# View container logs
docker logs myblog-frontend
docker logs myblog-backend

# Check health
docker inspect myblog-frontend | grep Health -A 10

# Restart containers
sudo systemctl restart myblog
```

## 🎯 Best Practices

### 1. Monitor Storage Weekly

```bash
# Add to your local routine
ssh ubuntu@your-ec2 "df -h && docker system df"
```

### 2. Review Logs Monthly

```bash
# Check cleanup logs
tail -100 /var/log/myblog/cleanup.log

# Check health logs
tail -100 /var/log/myblog/health.log
```

### 3. Plan for Growth

When to upgrade:

- Disk usage consistently > 70%: Increase volume size
- Memory usage > 80%: Upgrade instance type
- High traffic: Consider auto-scaling setup

## 📈 Scaling Recommendations

### Current Setup (Single EC2)

- **Instance**: t3.micro (1 vCPU, 1GB RAM, 8GB storage)
- **Suitable for**: Development, small blogs (<1000 visitors/day)
- **Limitations**: Limited storage, single point of failure

### Recommended Upgrades

**Small Production (100-1000 users/day):**

- Instance: t3.small (2 vCPU, 2GB RAM, 20GB storage)
- Cost: ~$15/month
- Benefits: More storage, better performance

**Medium Production (1000-10000 users/day):**

- Instance: t3.medium (2 vCPU, 4GB RAM)
- EBS: 30GB volume
- Load balancer + auto-scaling
- Cost: ~$50-80/month

**High Availability Setup:**

- ALB + ASG (2+ instances)
- Separate RDS for MongoDB
- CloudFront CDN
- Cost: ~$150-300/month

## 📞 Support Commands Cheat Sheet

```bash
# === Service Management ===
sudo systemctl status myblog        # Check status
sudo systemctl restart myblog       # Restart
sudo systemctl stop myblog          # Stop
sudo journalctl -u myblog -f        # View logs

# === Storage Management ===
df -h                               # Disk usage
docker system df                    # Docker disk usage
sudo scripts/cleanup-storage.sh     # Manual cleanup

# === Container Management ===
docker ps                           # Running containers
docker logs -f myblog-frontend      # View logs
docker restart myblog-frontend      # Restart container

# === Health Checks ===
curl http://localhost:3000/api/health  # Frontend
curl http://localhost:3003/health      # Backend

# === Monitoring ===
tail -f /var/log/myblog/cleanup.log        # Cleanup logs
tail -f /var/log/myblog/health.log         # Health logs
crontab -l                                  # Scheduled tasks
```

## ✅ Verification Checklist

After setup, verify everything works:

- [ ] Systemd service is enabled: `sudo systemctl is-enabled myblog`
- [ ] Service is running: `sudo systemctl is-active myblog`
- [ ] Containers are running: `docker ps` shows 3 containers
- [ ] Cron jobs are scheduled: `crontab -l` shows cleanup tasks
- [ ] Docker log rotation is configured: `cat /etc/docker/daemon.json`
- [ ] Health checks respond: `curl http://localhost:3000/api/health`
- [ ] Reboot test passed: Containers auto-start after `sudo reboot`

## 🎉 Success!

Your EC2 instance is now:

- ✅ Auto-restarts application on reboot
- ✅ Automatically cleans up storage
- ✅ Monitors application health
- ✅ Rotates logs to prevent disk filling
- ✅ Production-ready and resilient

---

**Last Updated**: November 2025
**Tested On**: Ubuntu 22.04 LTS, AWS EC2 t3.micro
