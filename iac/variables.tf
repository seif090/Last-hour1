# ================================================================
# LAST HOUR — Terraform Variables
# ================================================================

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "me-south-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
  validation {
    condition     = contains(["production", "staging", "development"], var.environment)
    error_message = "Must be one of: production, staging, development"
  }
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["me-south-1a", "me-south-1b", "me-south-1c"]
}

variable "domain_name" {
  description = "Root domain name"
  type        = string
  default     = "lasthour.app"
}

variable "route53_zone_id" {
  description = "Route53 hosted zone ID"
  type        = string
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN for *.lasthour.app"
  type        = string
}

variable "rds_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.r6g.large"
}

variable "rds_allocated_storage" {
  description = "RDS allocated storage in GB"
  type        = number
  default     = 100
}

variable "rds_backup_retention" {
  description = "RDS backup retention in days"
  type        = number
  default     = 30
}

variable "redis_node_type" {
  description = "ElastiCache node type"
  type        = string
  default     = "cache.r6g.large"
}

variable "backend_cpu" {
  description = "ECS task CPU units"
  type        = string
  default     = "1024"
}

variable "backend_memory" {
  description = "ECS task memory in MB"
  type        = string
  default     = "2048"
}

variable "backend_desired_count" {
  description = "Desired number of backend tasks"
  type        = number
  default     = 2
}

variable "backend_image_url" {
  description = "Backend Docker image URL in ECR"
  type        = string
}

variable "github_repository" {
  description = "GitHub repository (owner/repo) for OIDC"
  type        = string
  default     = "seif090/Last-hour1"
}

variable "datadog_site" {
  description = "Datadog site (e.g. datadoghq.eu, datadoghq.com)"
  type        = string
  default     = "datadoghq.eu"
}
