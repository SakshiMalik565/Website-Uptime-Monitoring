terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# ------------------------------------------------------------------------------
# VPC & Networking (Reference)
# ------------------------------------------------------------------------------
resource "aws_vpc" "devops_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name    = "INT333-DevOps-VPC"
    Project = "Website Uptime Monitoring"
  }
}

resource "aws_subnet" "devops_subnet" {
  vpc_id                  = aws_vpc.devops_vpc.id
  cidr_block              = var.subnet_cidr
  map_public_ip_on_launch = true

  tags = {
    Name = "INT333-DevOps-Subnet"
  }
}

# ------------------------------------------------------------------------------
# Security Groups (Enforcing Principle of Least Privilege)
# ------------------------------------------------------------------------------
resource "aws_security_group" "common_sg" {
  name        = "devops-common-sg"
  description = "Base security group for administration and internal traffic"
  vpc_id      = aws_vpc.devops_vpc.id

  # Inbound SSH restricted strictly to administrator IP
  ingress {
    description = "Restricted Administrator SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_ip_cidr]
  }

  # Inbound traffic between instances within the same VPC
  ingress {
    description = "Internal VPC communication"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "Allow all outbound traffic for package updates"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "INT333-Common-SG"
  }
}

# ------------------------------------------------------------------------------
# Latest Ubuntu 24.04 LTS AMI Lookup
# ------------------------------------------------------------------------------
data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"] # Canonical
}

# ------------------------------------------------------------------------------
# EC2 Node 1: Puppet Master (Control Plane)
# ------------------------------------------------------------------------------
resource "aws_instance" "puppet_master" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.small"
  subnet_id              = aws_subnet.devops_subnet.id
  vpc_security_group_ids = [aws_security_group.common_sg.id]
  key_name               = var.key_name

  tags = {
    Name = "puppet-master"
    Role = "Puppet Server Control Plane"
  }
}

# ------------------------------------------------------------------------------
# EC2 Node 2: Puppet Agent (Managed Apache Web Server)
# ------------------------------------------------------------------------------
resource "aws_instance" "puppet_agent" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.devops_subnet.id
  vpc_security_group_ids = [aws_security_group.common_sg.id]
  key_name               = var.key_name

  tags = {
    Name = "puppet-agent"
    Role = "Managed Web Host"
  }
}

# ------------------------------------------------------------------------------
# EC2 Node 3: Ansible Control Node & Nagios Core Host
# ------------------------------------------------------------------------------
resource "aws_instance" "ansible_monitoring" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.devops_subnet.id
  vpc_security_group_ids = [aws_security_group.common_sg.id]
  key_name               = var.key_name

  tags = {
    Name = "ansible"
    Role = "Ansible Control & Nagios Monitoring"
  }
}
