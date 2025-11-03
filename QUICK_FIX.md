# 🚨 QUICK FIX: EC2 Restart & Storage Issues

## Problem Summary

1. ❌ When EC2 instance restarts, Docker containers don't auto-start
2. ❌ Running out of storage causing deployment failures

## ✅ Simple 3-Step Solution

### Step 1: SSH into Your EC2 Instance

```bash
ssh -i your-key.pem ubuntu@your-ec2-ip
```

### Step 2: Run Setup Commands

```bash
# Navigate to your app directory
cd /home/ubuntu/myblog

# Pull latest code
git pull origin main

# Make scripts executable
chmod +x scripts/*.sh

# Setup auto-restart (fixes reboot issue)
sudo bash scripts/setup-systemd.sh

# Setup auto-cleanup (fixes storage issue)
sudo bash scripts/setup-auto-cleanup.sh

# Run immediate cleanup (if having storage issues NOW)
sudo bash scripts/cleanup-storage.sh
```

### Step 3: Test It Works

```bash
# Test 1: Check service is running
sudo systemctl status myblog

# Test 2: Reboot and verify
sudo reboot

# After EC2 comes back up, SSH again and check:
docker ps
# You should see 3 containers running (frontend, backend, nginx)
```

## 🎯 What This Does

### Auto-Restart Fix

- ✅ Creates systemd service that starts Docker containers on boot
- ✅ Automatically restarts if containers crash
- ✅ Pulls latest images on restart (optional)

### Storage Fix

- ✅ Automatic cleanup every 12 hours
- ✅ Emergency cleanup when disk > 80%
- ✅ Docker log rotation (max 10MB per container)
- ✅ Removes unused images, containers, volumes

## 📊 Verify Everything Works

```bash
# Check auto-start is enabled
sudo systemctl is-enabled myblog
# Should output: enabled

# Check containers are running
docker ps
# Should show: myblog-frontend, myblog-backend, myblog-nginx

# Check disk usage
df -h
# Should show reasonable usage

# Check cleanup is scheduled
crontab -l
# Should show cleanup jobs
```

## 🔧 Quick Commands Reference

```bash
# Start/Stop/Restart
sudo systemctl start myblog      # Start containers
sudo systemctl stop myblog       # Stop containers
sudo systemctl restart myblog    # Restart containers

# Check Status
sudo systemctl status myblog     # Service status
docker ps                        # Running containers
df -h                           # Disk usage

# Manual Cleanup (if needed)
sudo /home/ubuntu/myblog/scripts/cleanup-storage.sh

# View Logs
sudo journalctl -u myblog -f    # Service logs
docker logs -f myblog-frontend  # Frontend logs
docker logs -f myblog-backend   # Backend logs
```

## ⚠️ If Still Having Issues

### Issue: Can't find scripts

```bash
# Clone repo again
cd /home/ubuntu
git clone https://github.com/BlockAce01/MyBlog.git myblog
cd myblog
# Then run setup commands again
```

### Issue: Permission denied

```bash
# Fix permissions
sudo chown -R ubuntu:ubuntu /home/ubuntu/myblog
chmod +x scripts/*.sh
```

### Issue: Still out of storage

```bash
# Emergency cleanup
sudo docker system prune -af --volumes
sudo apt-get clean
sudo apt-get autoremove -y

# Then run setup again
sudo bash scripts/setup-auto-cleanup.sh
```

### Issue: Containers won't start

```bash
# Check .env file exists
ls -la /home/ubuntu/myblog/.env

# If missing, create it with your secrets
# Check logs
sudo journalctl -u myblog -n 50
docker logs myblog-frontend
docker logs myblog-backend
```

## 💡 Pro Tips

1. **Monitor Storage**: Check weekly

   ```bash
   df -h && docker system df
   ```

2. **Check Cleanup Logs**: Make sure automation is working

   ```bash
   tail -f /var/log/myblog/cleanup.log
   ```

3. **Upgrade Storage**: If consistently running out
   ```bash
   # In AWS Console: EC2 → Volumes → Modify Volume
   # Increase from 8GB to 20GB
   # Then resize filesystem:
   sudo growpart /dev/xvda 1
   sudo resize2fs /dev/xvda1
   ```

## 📖 Full Documentation

For detailed documentation, see:

- [EC2_SETUP_GUIDE.md](./EC2_SETUP_GUIDE.md) - Complete guide
- [DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md) - Full deployment docs

## ✅ That's It!

Your EC2 instance is now:

- ✅ Auto-restarts containers on reboot
- ✅ Automatically cleans up storage
- ✅ Production-ready

---

Need help? Check logs:

```bash
sudo journalctl -u myblog -f
tail -f /var/log/myblog/cleanup.log
```
