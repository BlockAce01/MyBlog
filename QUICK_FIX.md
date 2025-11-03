# 🚨 QUICK FIX: EC2 Restart & Storage Issues# 🚨 QUICK FIX: EC2 Restart & Storage Issues

## Problem Summary## Problem Summary

1. ❌ When EC2 instance restarts, Docker containers don't auto-start

2. ❌ Running out of storage causing deployment failures1. ❌ When EC2 instance restarts, Docker containers don't auto-start

3. ❌ Running out of storage causing deployment failures

## ✅ AUTOMATIC Solution (No SSH Required!)

## ✅ Simple 3-Step Solution

### What You Need to Do: NOTHING! 🎉

### Step 1: SSH into Your EC2 Instance

The next deployment will **automatically** set up everything for you.

```bash

### Just Push Your Codessh -i your-key.pem ubuntu@your-ec2-ip

```

`````bash

# Commit and push your changes### Step 2: Run Setup Commands

git add .

git commit -m "Enable auto-restart and storage management"```bash

git push origin devOps  # or main# Navigate to your app directory

```cd /home/ubuntu/myblog



That's it! GitHub Actions will automatically:# Pull latest code

1. ✅ Build and deploy your applicationgit pull origin main

2. ✅ Set up auto-restart on EC2 reboot (systemd service)

3. ✅ Configure automatic storage cleanup# Make scripts executable

4. ✅ Set up health monitoringchmod +x scripts/*.sh

5. ✅ Configure Docker log rotation

# Setup auto-restart (fixes reboot issue)

**No SSH access needed!** Everything happens automatically via AWS Systems Manager (SSM).sudo bash scripts/setup-systemd.sh



## 🎯 What Gets Configured Automatically# Setup auto-cleanup (fixes storage issue)

sudo bash scripts/setup-auto-cleanup.sh

### 1. Auto-Restart on Reboot

- Systemd service that starts containers automatically# Run immediate cleanup (if having storage issues NOW)

- Auto-restart if containers crashsudo bash scripts/cleanup-storage.sh

- Service name: `myblog.service````



### 2. Automatic Storage Cleanup### Step 3: Test It Works



| Task | Frequency | Purpose |```bash

|------|-----------|---------|# Test 1: Check service is running

| Docker cleanup | Daily at 2 AM + Every 12 hours | Remove unused images, containers, volumes |sudo systemctl status myblog

| Emergency cleanup | Every 4 hours (if disk > 80%) | Aggressive cleanup when storage is critical |

| Health checks | Every 5 minutes | Monitor frontend & backend health |# Test 2: Reboot and verify

| Log rotation | Weekly | Clean old logs |sudo reboot



### 3. Docker Log Limits# After EC2 comes back up, SSH again and check:

- Max log size: 10 MB per containerdocker ps

- Max files: 3 per container# You should see 3 containers running (frontend, backend, nginx)

- Total per container: ~30 MB```



## 📊 Verify It's Working (Optional)## 🎯 What This Does



After your next deployment, you can check via **AWS Systems Manager Session Manager**:### Auto-Restart Fix



### Option 1: Via AWS Console- ✅ Creates systemd service that starts Docker containers on boot

1. Go to **AWS Console → EC2 → Systems Manager → Session Manager**- ✅ Automatically restarts if containers crash

2. Click **"Start session"** on your EC2 instance- ✅ Pulls latest images on restart (optional)

3. Run verification commands:

### Storage Fix

```bash

# Check auto-start is enabled- ✅ Automatic cleanup every 12 hours

sudo systemctl is-enabled myblog- ✅ Emergency cleanup when disk > 80%

# Should output: enabled- ✅ Docker log rotation (max 10MB per container)

- ✅ Removes unused images, containers, volumes

# Check containers are running

docker ps## 📊 Verify Everything Works

# Should show: myblog-frontend, myblog-backend, myblog-nginx

```bash

# Check cleanup is scheduled# Check auto-start is enabled

crontab -lsudo systemctl is-enabled myblog

# Should show cleanup cron jobs# Should output: enabled



# Check disk usage# Check containers are running

df -hdocker ps

```# Should show: myblog-frontend, myblog-backend, myblog-nginx



### Option 2: Via AWS CLI# Check disk usage

```bashdf -h

# Start a session# Should show reasonable usage

aws ssm start-session --target YOUR_INSTANCE_ID

# Check cleanup is scheduled

# Then run the verification commands abovecrontab -l

```# Should show cleanup jobs

`````

## 🧪 Test Auto-Restart

## 🔧 Quick Commands Reference

Want to verify auto-restart works?

````bash

1. Via **Session Manager**, reboot your EC2:# Start/Stop/Restart

   ```bashsudo systemctl start myblog      # Start containers

   sudo rebootsudo systemctl stop myblog       # Stop containers

   ```sudo systemctl restart myblog    # Restart containers



2. Wait 2-3 minutes, then start a new session# Check Status

sudo systemctl status myblog     # Service status

3. Check containers auto-started:docker ps                        # Running containers

   ```bashdf -h                           # Disk usage

   docker ps

   # Should show all 3 containers running!# Manual Cleanup (if needed)

   ```sudo /home/ubuntu/myblog/scripts/cleanup-storage.sh



## 🔧 Managing Your Service (via Session Manager)# View Logs

sudo journalctl -u myblog -f    # Service logs

If you ever need to manually control the service:docker logs -f myblog-frontend  # Frontend logs

docker logs -f myblog-backend   # Backend logs

### Start Session via AWS Console:```

**EC2 → Systems Manager → Session Manager → Start Session**

## ⚠️ If Still Having Issues

### Then run:

### Issue: Can't find scripts

```bash

# Service Control```bash

sudo systemctl start myblog      # Start containers# Clone repo again

sudo systemctl stop myblog       # Stop containerscd /home/ubuntu

sudo systemctl restart myblog    # Restart containersgit clone https://github.com/BlockAce01/MyBlog.git myblog

sudo systemctl status myblog     # Check statuscd myblog

# Then run setup commands again

# Manual Cleanup (if needed)```

sudo /home/ubuntu/MyBlog/scripts/cleanup-storage.sh

### Issue: Permission denied

# Check Disk Usage

df -h```bash

docker system df# Fix permissions

sudo chown -R ubuntu:ubuntu /home/ubuntu/myblog

# View Logschmod +x scripts/*.sh

sudo journalctl -u myblog -f                # Service logs```

docker logs -f myblog-frontend              # Frontend logs

docker logs -f myblog-backend               # Backend logs### Issue: Still out of storage

tail -f /var/log/myblog/cleanup.log         # Cleanup logs

tail -f /var/log/myblog/health.log          # Health check logs```bash

```# Emergency cleanup

sudo docker system prune -af --volumes

## ⚠️ Troubleshootingsudo apt-get clean

sudo apt-get autoremove -y

### Issue: Deployment Failed

# Then run setup again

**Check GitHub Actions:**sudo bash scripts/setup-auto-cleanup.sh

1. Go to your repo → **Actions** tab```

2. Click on the failed workflow

3. Review the deployment logs### Issue: Containers won't start



**Common issues:**```bash

- `EC2_INSTANCE_ID` secret not set or incorrect# Check .env file exists

- SSM agent not running on EC2ls -la /home/ubuntu/myblog/.env

- IAM permissions for SSM not configured

# If missing, create it with your secrets

### Issue: Still Running Out of Storage# Check logs

sudo journalctl -u myblog -n 50

If automatic cleanup isn't enough:docker logs myblog-frontend

docker logs myblog-backend

**Option 1: Manual emergency cleanup** (via Session Manager):```

```bash

sudo /home/ubuntu/MyBlog/scripts/cleanup-storage.sh## 💡 Pro Tips

````

1. **Monitor Storage**: Check weekly

**Option 2: Increase EBS volume size**:

1. **AWS Console → EC2 → Volumes** ```bash

2. Select your volume → **Actions** → **Modify Volume** df -h && docker system df

3. Increase from 8GB to 20GB ```

4. Via Session Manager, resize filesystem:

   ````bash2. **Check Cleanup Logs**: Make sure automation is working

   sudo growpart /dev/xvda 1

   sudo resize2fs /dev/xvda1   ```bash

   df -h  # Verify new size   tail -f /var/log/myblog/cleanup.log

   ```   ```
   ````

### Issue: Containers Not Responding3. **Upgrade Storage**: If consistently running out

````bash

Via Session Manager:   # In AWS Console: EC2 → Volumes → Modify Volume

```bash   # Increase from 8GB to 20GB

# Check container status   # Then resize filesystem:

docker ps -a   sudo growpart /dev/xvda 1

sudo resize2fs /dev/xvda1

# Check logs   ```

docker logs myblog-frontend --tail 50

docker logs myblog-backend --tail 50## 📖 Full Documentation



# Check service statusFor detailed documentation, see:

sudo systemctl status myblog

- [EC2_SETUP_GUIDE.md](./EC2_SETUP_GUIDE.md) - Complete guide

# Restart service- [DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md) - Full deployment docs

sudo systemctl restart myblog

## ✅ That's It!

# Check health endpoints

curl http://localhost:3000/api/healthYour EC2 instance is now:

curl http://localhost:3003/health

```- ✅ Auto-restarts containers on reboot

- ✅ Automatically cleans up storage

## 💡 Pro Tips- ✅ Production-ready



### 1. Monitor from GitHub Actions Logs---

Every deployment shows:

- Current disk usageNeed help? Check logs:

- Running containers

- Docker system usage```bash

sudo journalctl -u myblog -f

### 2. Check Cleanup Logs (via Session Manager)tail -f /var/log/myblog/cleanup.log

```bash```

# View recent cleanup activity
tail -100 /var/log/myblog/cleanup.log

# View health check logs
tail -100 /var/log/myblog/health.log
````

### 3. Set Up CloudWatch Alarms (Optional)

For production, consider setting up AWS CloudWatch alarms for:

- High disk usage (> 80%)
- Container health failures
- High memory usage

## 📖 Full Documentation

For detailed technical documentation:

- [EC2_SETUP_GUIDE.md](./EC2_SETUP_GUIDE.md) - Complete technical guide
- [DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md) - Full deployment workflow

## ✅ Summary

After your next `git push`:

✅ **Auto-restart on reboot** - Containers start automatically when EC2 reboots
✅ **Storage cleanup** - Automatic cleanup prevents "out of storage" errors
✅ **Health monitoring** - Continuous health checks every 5 minutes
✅ **Log rotation** - Docker logs limited to prevent disk filling
✅ **Production-ready** - Zero manual configuration required

---

**Need Help?**

Check deployment logs:

- GitHub Actions → Your workflow → View logs
- AWS Session Manager → Start session → Check container logs

**Questions?**

- Review [EC2_SETUP_GUIDE.md](./EC2_SETUP_GUIDE.md) for troubleshooting
- Check GitHub Actions workflow logs for deployment details
