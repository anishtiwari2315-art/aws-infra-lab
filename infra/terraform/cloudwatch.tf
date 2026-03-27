# ============================================================
# cloudwatch.tf — Alarms and Dashboard for monitoring
# ============================================================

# SNS Topic for alarm notifications
resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-alerts"
}

# CloudWatch Alarm: High CPU on ASG
resource "aws_cloudwatch_metric_alarm" "asg_high_cpu" {
  alarm_name          = "${var.project_name}-asg-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Triggers when average CPU > 80% for 4 minutes"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web.name
  }
}

# CloudWatch Alarm: ALB Unhealthy Hosts
resource "aws_cloudwatch_metric_alarm" "alb_unhealthy_hosts" {
  alarm_name          = "${var.project_name}-alb-unhealthy-hosts"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 0
  alarm_description   = "Triggers when there are unhealthy hosts in target group"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    LoadBalancer = aws_lb.web.arn_suffix
    TargetGroup  = aws_lb_target_group.web.arn_suffix
  }
}

# CloudWatch Alarm: ALB High Latency
resource "aws_cloudwatch_metric_alarm" "alb_high_latency" {
  alarm_name          = "${var.project_name}-alb-high-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 1
  alarm_description   = "Triggers when ALB response time > 1 second"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    LoadBalancer = aws_lb.web.arn_suffix
  }
}

# CloudWatch Alarm: RDS High CPU
resource "aws_cloudwatch_metric_alarm" "rds_high_cpu" {
  alarm_name          = "${var.project_name}-rds-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 120
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Triggers when RDS CPU > 80%"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.mysql.id
  }
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        width  = 12
        height = 6
        properties = {
          title   = "EC2 ASG CPU Utilization"
          metrics = [["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", aws_autoscaling_group.web.name]]
          period  = 300
          stat    = "Average"
          region  = var.aws_region
        }
      },
      {
        type   = "metric"
        width  = 12
        height = 6
        properties = {
          title   = "ALB Request Count"
          metrics = [["AWS/ApplicationELB", "RequestCount", "LoadBalancer", aws_lb.web.arn_suffix]]
          period  = 300
          stat    = "Sum"
          region  = var.aws_region
        }
      }
    ]
  })
}
