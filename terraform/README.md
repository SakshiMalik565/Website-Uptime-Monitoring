# Optional Terraform Extension (UNAPPLIED REFERENCE)

> [!IMPORTANT]
> **Academic Note on Scope:**
> As specified in the INT333 Project Rubric under *Possible Project Technology Combinations* ("Puppet + Ansible + Nagios"), the core implementation for this project operates directly on existing AWS EC2 instances. 
> 
> This Terraform configuration is provided solely as an **unapplied infrastructure-as-code extension** for future lab provisioning and grading reference. It is **not applied** to live AWS infrastructure to avoid unintended resource duplication, cost, or configuration conflicts.

## Purpose of this Module
This module documents how the three EC2 instances and network boundaries could be provisioned repeatably in AWS:
1. `puppet-master`: Puppet Server instance with TCP port 8140 open to VPC.
2. `puppet-agent`: Managed web server running Apache HTTP server on port 80.
3. `ansible`: Control node and Nagios Core monitoring host.

## Security Architecture
- Instances are provisioned inside a dedicated VPC private/public subnet.
- Security groups enforce least privilege:
  - SSH (port 22) allowed strictly from the administrator's CIDR.
  - Puppet communication (port 8140) restricted strictly to internal VPC.
  - HTTP checks (port 80) allowed internally between `ansible` and `puppet-agent`.
  - No public exposure of Nagios interface or SSH to `0.0.0.0/0`.
