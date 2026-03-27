# ============================================================
# ec2.tf — EC2 Web/App Tier Instances with user_data bootstrap
# ============================================================

# Launch Template for web tier
resource "aws_launch_template" "web" {
  name_prefix   = "${var.project_name}-web-"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_pair_name

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.web_sg.id]
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd

    # Deploy the application
    aws s3 cp s3://anish-devops-artifacts/app/ /var/www/html/ --recursive 2>/dev/null || true

    # Fallback: simple health-check page
    if [ ! -f /var/www/html/index.html ]; then
      INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
      AZ=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
      cat > /var/www/html/index.html <<HTML
    <!DOCTYPE html>
    <html>
    <head><title>AWS Multi-Tier App</title></head>
    <body>
      <h1>Automated Multi-Tier Web Application on AWS</h1>
      <p>Instance ID : $INSTANCE_ID</p>
      <p>Availability Zone: $AZ</p>
      <p>Deployed with Terraform by Anish Tiwari</p>
    </body>
    </html>
    HTML
    fi
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project_name}-web-instance"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "web" {
  name                = "${var.project_name}-web-asg"
  desired_capacity    = 2
  min_size            = 1
  max_size            = 4
  vpc_zone_identifier = aws_subnet.private[*].id
  target_group_arns   = [aws_lb_target_group.web.arn]
  health_check_type   = "ELB"
  health_check_grace_period = 120

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-web-asg-instance"
    propagate_at_launch = true
  }
}

# CPU Scaling Policy
resource "aws_autoscaling_policy" "cpu_scaling" {
  name                   = "${var.project_name}-cpu-scaling"
  autoscaling_group_name = aws_autoscaling_group.web.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 60.0
  }
}
