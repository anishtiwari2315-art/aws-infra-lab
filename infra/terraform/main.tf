# ============================================================
# main.tf — Provider & Backend Configuration
# Project: Automated Multi-Tier Web Application on AWS
# Author : Anish Tiwari
# ============================================================

terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Uncomment to store state in S3
  # backend "s3" {
  #   bucket         = "anish-tf-state-bucket"
  #   key            = "aws-infra-lab/terraform.tfstate"
  #   region         = "ap-south-1"
  #   dynamodb_table = "tf-lock-table"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Owner       = "Anish Tiwari"
    }
  }
}
