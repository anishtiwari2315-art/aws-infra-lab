#!/bin/bash
# =============================================================
# install_app.sh - Bootstrap script for EC2 web tier
# Installs Apache, deploys the app, configures health check page
# Author: Anish Tiwari
# =============================================================

set -euo pipefail

LOG_FILE="/var/log/install_app.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "[$(date)] Starting installation..."

# ----- 1. Update system packages -----
yum update -y
echo "[$(date)] System update complete."

# ----- 2. Install Apache HTTP Server -----
yum install -y httpd
systemctl start httpd
systemctl enable httpd
echo "[$(date)] Apache installed and started."

# ----- 3. Fetch EC2 instance metadata -----
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id || echo "unknown")
AZ=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone || echo "unknown")
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 || echo "N/A")
echo "[$(date)] Instance: $INSTANCE_ID | AZ: $AZ | IP: $PUBLIC_IP"

# ----- 4. Deploy the application -----
WEB_ROOT="/var/www/html"

# Copy app files from S3 if available (optional)
# aws s3 cp s3://YOUR-BUCKET/app/ $WEB_ROOT/ --recursive

# Deploy index.html with injected instance metadata
cat > "$WEB_ROOT/index.html" << HTML
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="instance-id" content="$INSTANCE_ID" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>AWS Multi-Tier Web App</title>
  <style>
    body { font-family: Arial, sans-serif; background: #0d1117; color: #fff; text-align: center; padding: 60px 20px; }
    h1 { color: #ff9900; }
    .meta { background: #161b22; border: 1px solid #30363d; border-radius: 8px; display: inline-block; padding: 20px 40px; margin-top: 20px; }
    .meta p { margin: 8px 0; color: #8b949e; }
    .meta span { color: #f0f6fc; font-weight: bold; }
  </style>
</head>
<body>
  <h1>Automated Multi-Tier Web Application on AWS</h1>
  <p>Deployed with Terraform by Anish Tiwari | DevOps Engineer</p>
  <div class="meta">
    <p>Instance ID: <span>$INSTANCE_ID</span></p>
    <p>Availability Zone: <span>$AZ</span></p>
    <p>Public IP: <span>$PUBLIC_IP</span></p>
    <p>Status: <span style="color:#3fb950">HEALTHY</span></p>
  </div>
</body>
</html>
HTML

# ----- 5. Create a simple /health endpoint for ALB health checks -----
echo "OK" > "$WEB_ROOT/health"

# ----- 6. Set correct ownership and permissions -----
chown -R apache:apache "$WEB_ROOT"
chmod -R 755 "$WEB_ROOT"

echo "[$(date)] App deployed successfully to $WEB_ROOT"
echo "[$(date)] Installation complete!"
