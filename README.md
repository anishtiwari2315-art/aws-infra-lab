# Automated Multi-Tier Web Application on AWS

![AWS](https://img.shields.io/badge/AWS-%23FF9900.svg?style=for-the-badge&logo=amazon-aws&logoColor=white)
![Terraform](https://img.shields.io/badge/terraform-%235835CC.svg?style=for-the-badge&logo=terraform&logoColor=white)
![Apache](https://img.shields.io/badge/apache-%23D42029.svg?style=for-the-badge&logo=apache&logoColor=white)
![MySQL](https://img.shields.io/badge/mysql-%2300f.svg?style=for-the-badge&logo=mysql&logoColor=white)

> **Resume Project** | Built by [Anish Tiwari](https://github.com/anishtiwari2315-art) | DevOps Engineer | Pune, India

A production-ready, fully automated **multi-tier web application** on AWS, provisioned entirely with **Terraform**. Implements a VPC-based network architecture with public and private subnets, an Application Load Balancer, an Auto Scaling Group of EC2 instances, a managed RDS MySQL database, and CloudWatch monitoring with alarms and dashboards.

---

## Architecture Overview

```
 Internet
     |
 [Internet Gateway]
     |
  [ALB] ---- Public Subnets (AZ-1a, AZ-1b)
     |
 [EC2 ASG] - Private Subnets (AZ-1a, AZ-1b)  <--- Apache + App
     |
 [RDS MySQL] - Private Subnets (isolated)
     |
 [NAT Gateway] --> Internet (for outbound only)

Monitoring: CloudWatch Alarms + Dashboard + SNS Alerts
```

| Layer | AWS Service | Details |
|---|---|---|
| Networking | VPC, Subnets, IGW, NAT GW, Route Tables | 10.0.0.0/16 across 2 AZs |
| Load Balancing | Application Load Balancer | HTTP listener, health checks |
| Compute | EC2 Launch Template + Auto Scaling Group | t3.micro, min=1, max=4 |
| Database | RDS MySQL 8.0 | Private subnet, encrypted at rest |
| Security | Security Groups | ALB -> EC2 -> RDS layered access |
| Monitoring | CloudWatch Alarms + Dashboard + SNS | CPU, latency, unhealthy hosts |
| IaC | Terraform >= 1.3 | AWS Provider ~> 5.0 |

---

## Features

- **One-command deployment** - `terraform init && terraform plan && terraform apply`
- **Multi-AZ high availability** - subnets and ASG spread across 2 availability zones
- **Auto Scaling** - CPU-based target tracking policy (scales at 60% CPU)
- **Layered security** - ALB SG -> Web SG -> RDS SG, no direct internet access to app or DB tier
- **CloudWatch monitoring** - 4 alarms (ASG CPU, ALB unhealthy hosts, ALB latency, RDS CPU)
- **Infrastructure as Code** - fully parameterized, no hardcoded values
- **Easy teardown** - `terraform destroy` removes everything cleanly

---

## Project Structure

```
aws-infra-lab/
├── infra/
│   └── terraform/
│       ├── main.tf              # Provider & backend config
│       ├── variables.tf         # All input variables
│       ├── outputs.tf           # Useful outputs (ALB DNS, VPC ID, etc.)
│       ├── vpc.tf               # VPC, IGW, NAT Gateway, Route Tables
│       ├── subnets.tf           # Public & Private subnets
│       ├── security-groups.tf   # SGs for ALB, EC2, RDS
│       ├── ec2.tf               # Launch Template, ASG, Scaling Policy
│       ├── alb.tf               # ALB, Target Group, HTTP Listener
│       ├── rds.tf               # RDS MySQL, DB Subnet Group
│       └── cloudwatch.tf        # Alarms, Dashboard, SNS Topic
├── app/
│   ├── index.html               # Web application (served by Apache)
│   └── scripts/
│       └── install_app.sh       # EC2 bootstrap script (user-data)
└── README.md
```

---

## Prerequisites

| Tool | Version | Install |
|---|---|---|
| AWS CLI | >= 2.x | [aws.amazon.com/cli](https://aws.amazon.com/cli/) |
| Terraform | >= 1.3.0 | [developer.hashicorp.com](https://developer.hashicorp.com/terraform/install) |
| AWS Account | - | Programmatic access configured |
| EC2 Key Pair | - | Created in `ap-south-1` region |

---

## How to Deploy

### Step 1 - Clone the repository

```bash
git clone https://github.com/anishtiwari2315-art/aws-infra-lab.git
cd aws-infra-lab/infra/terraform
```

### Step 2 - Configure AWS credentials

```bash
aws configure
# Enter: Access Key ID, Secret Access Key, Region (ap-south-1), Output (json)
```

### Step 3 - Set variables

Create a `terraform.tfvars` file:

```hcl
aws_region        = "ap-south-1"
project_name      = "aws-infra-lab"
environment       = "dev"
vpc_cidr_block    = "10.0.0.0/16"
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24"]
availability_zones   = ["ap-south-1a", "ap-south-1b"]
instance_type     = "t3.micro"
key_pair_name     = "your-key-pair-name"
db_password       = "YourStrongPassword123!"
```

> **Security tip:** Never commit `terraform.tfvars` with real passwords. Use `TF_VAR_db_password` env variable instead:
> ```bash
> export TF_VAR_db_password="YourStrongPassword123!"
> ```

### Step 4 - Deploy

```bash
terraform init      # Download providers & modules
terraform plan      # Preview changes
terraform apply     # Deploy (type 'yes' to confirm)
```

### Step 5 - Access the application

After `terraform apply` completes, get the ALB DNS name:

```bash
terraform output alb_dns_name
```

Open the URL in your browser - you will see the web application with instance metadata.

---

## CloudWatch Monitoring

This project creates the following CloudWatch alarms:

| Alarm | Metric | Threshold | Action |
|---|---|---|---|
| ASG High CPU | EC2 CPUUtilization | > 80% for 4 min | SNS notification |
| ALB Unhealthy Hosts | UnHealthyHostCount | > 0 | SNS notification |
| ALB High Latency | TargetResponseTime | > 1 second | SNS notification |
| RDS High CPU | RDS CPUUtilization | > 80% for 4 min | SNS notification |

A **CloudWatch Dashboard** is also created with EC2 CPU and ALB request count widgets.

To subscribe to alarm notifications:
```bash
# Get SNS topic ARN from output
terraform output sns_topic_arn

# Subscribe your email
aws sns subscribe --topic-arn <SNS_ARN> --protocol email --notification-endpoint your@email.com
```

---

## Outputs

After `terraform apply`, you get:

```bash
terraform output vpc_id                    # VPC ID
terraform output public_subnet_ids         # Public subnet IDs
terraform output private_subnet_ids        # Private subnet IDs
terraform output alb_dns_name              # ALB DNS (open in browser)
terraform output autoscaling_group_name    # ASG name
terraform output cloudwatch_dashboard_url  # Direct link to dashboard
terraform output sns_topic_arn             # Alarm notifications topic
```

---

## Cleanup

To destroy all resources and avoid AWS charges:

```bash
cd infra/terraform
terraform destroy
# Type 'yes' to confirm
```

---

## Tech Stack

- **Cloud:** AWS (ap-south-1 / Mumbai)
- **IaC:** Terraform >= 1.3, AWS Provider ~> 5.0
- **Networking:** VPC, Public/Private Subnets, IGW, NAT Gateway, Route Tables
- **Compute:** EC2 (Amazon Linux 2), Auto Scaling Group, Launch Template
- **Load Balancer:** Application Load Balancer with Health Checks
- **Database:** RDS MySQL 8.0 (encrypted, automated backups)
- **Security:** Security Groups (layered), no public access to app/DB
- **Monitoring:** CloudWatch Alarms, Dashboard, SNS
- **Web Server:** Apache HTTP Server (httpd)
- **App:** HTML/CSS (served by Apache)

---

## Future Improvements

- [ ] Add HTTPS with ACM certificate + ALB HTTPS listener
- [ ] Enable RDS Multi-AZ for production-grade HA
- [ ] Store Terraform state in S3 + DynamoDB lock
- [ ] Add WAF (Web Application Firewall) on ALB
- [ ] Integrate CI/CD pipeline to run `terraform plan` on PRs
- [ ] Add bastion host for secure SSH access to private instances

---

## Resume Description

> **Automated Multi-Tier Web Application on AWS** - Designed and provisioned a production-like VPC-based architecture (public/private subnets across 2 AZs, IGW, NAT Gateway) using Terraform. Deployed an Application Load Balancer with an EC2 Auto Scaling Group (CPU target tracking) and a private RDS MySQL database with layered Security Groups. Configured CloudWatch alarms (CPU, latency, health), dashboards, and SNS notifications for observability.

---

*Built and maintained by [Anish Tiwari](https://github.com/anishtiwari2315-art) | DevOps Engineer | Pune, India*
