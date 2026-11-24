variable "aws_region" {
  description = "AWS region for infrastructure provisioning"
  type        = string
  default     = "eu-north-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the project VPC"
  type        = string
  default     = "172.31.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR block for the project subnet"
  type        = string
  default     = "172.31.1.0/24"
}

variable "instance_type" {
  description = "EC2 instance type for nodes (t3.micro or t3.small recommended for puppetserver)"
  type        = string
  default     = "t3.small"
}

variable "key_name" {
  description = "Name of existing EC2 Key Pair for SSH access"
  type        = string
  default     = "devops-key"
}

variable "admin_ip_cidr" {
  description = "Administrator IP address CIDR for restricted SSH access"
  type        = string
  default     = "203.0.113.10/32" # Example documentation IP (RFC 5737)
}
