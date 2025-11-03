# MyBlog Deployment Guide

**Status**: Implementation Complete - Ready for User Deployment

This guide walks you through deploying MyBlog to AWS EC2 using the infrastructure and CI/CD pipeline that has been implemented.

## 🎯 What Has Been Implemented

### ✅ Infrastructure as Code (Terraform)

- Complete Terraform configuration in `terraform/` directory
- EC2 instance with Docker pre-installed
- ECR repositories for container images
- Route 53 hosted zone for custom domain
- IAM user for GitHub Actions CI/CD
- Security groups with least privilege access

### ✅ Docker Optimization

- Frontend Dockerfile converted to multi-stage build
- Backend Dockerfile validated (already production-ready)
- Production docker-compose.yml with health checks
- Environment variables properly configured

### ✅ CI/CD Pipeline (GitHub Actions)

- Automated build and deploy workflow
- ECR integration for container registry
- SSH deployment to EC2 instance
- Health check validation after deployment

### ✅ Security & SSL

- Nginx configuration with HTTPS support
- HTTP to HTTPS redirect
- Security headers and rate limiting
- SSL certificate setup via AWS ACM

## 🚀 Deployment Steps

### Phase 1: Prerequisites Setup

1. **AWS Account & CLI Setup**

   ```bash
   # Install AWS CLI
   curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
   unzip awscliv2.zip
   sudo ./aws/install

   # Configure AWS credentials
   aws configure
   ```

2. **Install Terraform**

   ```bash
   # Download and install Terraform
   wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
   echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
   sudo apt update && sudo apt install terraform
   ```

3. **Generate SSH Key**
   ```bash
   ssh-keygen -t rsa -b 4096 -C "myblog-deploy" -f ~/.ssh/myblog_deploy
   ```

### Phase 2: Infrastructure Deployment

1. **Configure Terraform Variables**

   ```bash
   cd terraform
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your domain and IP
   nano terraform.tfvars
   ```

2. **Deploy Infrastructure**

   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

3. **Note Output Values**
   - EC2 public IP
   - ECR repository URLs
   - Route 53 nameservers
   - IAM access keys

### Phase 3: Domain Configuration

1. **Update Namecheap DNS**
   - Go to Namecheap domain settings
   - Change nameservers to Route 53 nameservers from Terraform output

2. **Wait for DNS Propagation** (24-48 hours)

### Phase 4: GitHub Secrets Setup

Navigate to: Repository Settings → Secrets and variables → Actions

Set these secrets:

| Secret Name           | Value                                     |
| --------------------- | ----------------------------------------- |
| AWS_ACCESS_KEY_ID     | From Terraform output                     |
| AWS_SECRET_ACCESS_KEY | From Terraform output                     |
| AWS_ACCOUNT_ID        | Your AWS account ID                       |
| EC2_HOST              | EC2 public IP from Terraform              |
| SSH_PRIVATE_KEY       | `cat ~/.ssh/myblog_deploy \| base64 -w 0` |
| DOMAIN_NAME           | Your domain name                          |
| MONGODB_URI           | From your .env file                       |
| JWT_SECRET            | From your .env file                       |
| GOOGLE_CLIENT_ID      | From your .env file                       |
| GOOGLE_CLIENT_SECRET  | From your .env file                       |
| NEXTAUTH_SECRET       | From your .env file                       |
| TINYMCE_API_KEY       | From your .env file                       |
| ADMIN_SETUP_TOKEN     | From your .env file                       |

### Phase 5: SSL Certificate

The ACM certificate is created by Terraform. You may need to validate it:

```bash
# Check certificate status
aws acm describe-certificate --certificate-arn <CERT_ARN> --region us-east-1
```

### Phase 6: Deploy Application

1. **Push Code to Trigger Deployment**

   ```bash
   git add .
   git commit -m "Deploy to production"
   git push origin main
   ```

2. **Monitor GitHub Actions**
   - Go to repository Actions tab
   - Watch the deployment workflow
   - Check for any failures

3. **Verify Deployment**

   ```bash
   # Test via IP
   curl http://<EC2_IP>/api/health

   # Test via domain (after DNS propagation)
   curl https://yourdomain.com/api/health
   ```

## 🔧 Troubleshooting

### Common Issues

1. **Terraform Apply Fails**
   - Check AWS credentials: `aws sts get-caller-identity`
   - Verify SSH key exists: `ls -la ~/.ssh/myblog_deploy*`
   - Check domain availability

2. **GitHub Actions SSH Fails**
   - Verify EC2_HOST secret matches Terraform output
   - Check SSH_PRIVATE_KEY is base64 encoded
   - Confirm security group allows SSH from GitHub IPs

3. **Container Deployment Fails**
   - Check ECR permissions
   - Verify environment variables in docker-compose.prod.yml
   - Check Docker logs: `docker logs myblog-backend`

4. **SSL Not Working**
   - Wait for DNS propagation
   - Check certificate validation status
   - Verify nginx configuration

### Logs to Check

```bash
# EC2 logs
ssh -i ~/.ssh/myblog_deploy ubuntu@<EC2_IP>
sudo docker logs myblog-frontend
sudo docker logs myblog-backend
sudo docker logs myblog-nginx

# GitHub Actions logs
# Check repository Actions tab

# Nginx logs
sudo tail -f /var/log/nginx/error.log
sudo tail -f /var/log/nginx/access.log
```

## 📊 Cost Monitoring

Expected monthly costs:

- EC2 t3.micro: ~$8.47
- ECR storage: ~$0.10/GB
- Route 53: ~$0.50
- Data transfer: ~$10-20
- **Total**: ~$20-30/month

Monitor costs in AWS Billing console.

## 🎯 Success Criteria

- [ ] Terraform apply completes successfully
- [ ] GitHub Actions deployment succeeds
- [ ] Application accessible at `https://yourdomain.com`
- [ ] All API endpoints return 200 status
- [ ] SSL certificate is valid
- [ ] No secrets exposed in repository
- [ ] Auto-restart on EC2 reboot configured (see EC2_SETUP_GUIDE.md)
- [ ] Automatic storage cleanup configured (see EC2_SETUP_GUIDE.md)

## 🚨 Important: Configure Auto-Restart & Storage Management

After initial deployment, SSH into your EC2 instance and run:

```bash
cd /home/ubuntu/myblog
sudo bash scripts/setup-systemd.sh       # Auto-restart on reboot
sudo bash scripts/setup-auto-cleanup.sh  # Automatic storage cleanup
```

See [QUICK_FIX.md](./QUICK_FIX.md) or [EC2_SETUP_GUIDE.md](./EC2_SETUP_GUIDE.md) for details.

## 🆘 Getting Help

If you encounter issues:

1. Check the troubleshooting section above
2. Review GitHub Actions logs for detailed errors
3. Check AWS CloudWatch logs if enabled
4. Verify all secrets are set correctly
5. Ensure DNS has propagated

## 🚀 Next Steps (Optional)

After successful deployment:

1. **Monitoring**: Set up CloudWatch alarms
2. **Backup**: Configure automated database backups
3. **Scaling**: Consider ALB + ECS for auto-scaling
4. **CDN**: Add CloudFront for global performance
5. **Security**: Implement WAF and Shield

## 📚 Resources

- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [AWS EC2 User Guide](https://docs.aws.amazon.com/ec2/)
- [Nginx Documentation](https://nginx.org/en/docs/)

---

**Implementation completed by**: Dev Agent (Full Stack Developer)
**Date**: September 25, 2025
**Ready for deployment**: ✅ Yes
