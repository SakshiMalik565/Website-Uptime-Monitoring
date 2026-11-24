# Website Uptime Monitoring and Controlled Recovery on AWS EC2
### Using Puppet, Ansible, and Nagios Core

[![Course](https://img.shields.io/badge/Course-INT333%20DevOps-blue.svg)](docs/PROJECT_REPORT.md)
[![Platform](https://img.shields.io/badge/Platform-AWS%20EC2-orange.svg)](#aws-ec2-architecture)
[![Puppet](https://img.shields.io/badge/Puppet-Master%2FAgent-purple.svg)](puppet/)
[![Ansible](https://img.shields.io/badge/Ansible-Automation-red.svg)](ansible/)
[![Nagios](https://img.shields.io/badge/Nagios-Core%20Monitoring-darkgreen.svg)](nagios/)
[![License](https://img.shields.io/badge/License-Academic%20Evaluation-lightgrey.svg)](#)

---

## 📖 Project Overview

This repository contains the complete implementation, configurations, operational runbooks, and academic project report for **INT333: DevOps Advance Configuration Management** at Lovely Professional University.

The project demonstrates an end-to-end automated infrastructure and observability lifecycle:
- **Declarative Desired-State Management (Puppet):** Provisions and continuously enforces configuration for an Apache HTTP web server and a styled sample website on `puppet-agent`. Proves configuration idempotence and remediates unauthorized configuration drift.
- **Continuous Synthetic Observability (Nagios Core):** Monitored from `ansible`, continuously probing the web endpoint over private VPC networking using `check_http` with custom soft and hard failure thresholds.
- **Controlled Disaster Recovery (Ansible):** Orchestrates a narrowly scoped, non-destructive recovery playbook over SSH to restart the failed Apache service, verify port 80 readiness and HTTP 200 responses, and log an audit trail.
- **Infrastructure-as-Code Reference (Terraform):** Provides an unapplied, modular Terraform extension modeling the multi-node AWS VPC topology for future automated provisioning.

---

## 🏛 AWS EC2 Architecture

```
                    +-------------------------------------------------------------+
                    |                      AWS VPC (172.31.0.0/16)                |
                    |                                                             |
+-----------------+ |  +--------------------+   TCP 8140    +-------------------+ |
| DevOps Engineer | |  |   puppet-master    | <===========> |   puppet-agent    | |
|  (Workstation)  | |  | Puppet Server 8.x  |               | Apache Web Server | |
+-----------------+ |  +--------------------+               | Sample Website    | |
        |           |                                       +-------------------+ |
        | SSH Tunnel|                                                 ^           |
        | 8080:80   |                                                 |           |
        v           |                                                 |           |
+-----------------+ |  +--------------------+   check_http (Port 80)  |           |
| Nagios Web UI   |==> |      ansible       | ------------------------+           |
|  (Browser)      | |  | Nagios Core 4.x    |   ansible recovery (SSH 22)         |
+-----------------+ |  | Ansible Control    | ------------------------------------+
                    |  +--------------------+                                     |
                    +-------------------------------------------------------------+
```

### Dedicated Instance Roles
| Instance Role | Hostname / Tag | Primary Software | Responsibility |
| :--- | :--- | :--- | :--- |
| **Configuration Control Plane** | `puppet-master` | Puppet Server 8.x | Compiles catalogs, stores modules, signs agent certificates, and serves desired state. |
| **Managed Web Host** | `puppet-agent` | Puppet Agent, Apache2 | Hosts the production web service, enforces catalog states, and reports drift. |
| **Monitoring & Control Node** | `ansible` | Nagios Core 4.x, Ansible Core | Issues continuous HTTP health checks, alerts on outages, and runs recovery playbooks. |

---

## 📂 Repository Organization

```text
├── .gitignore                      # Strict isolation for .pem, .key, real IPs, and tfstate
├── README.md                       # Main project documentation and quickstart
├── web/
│   └── index.html                  # Styled sample website served on puppet-agent
├── puppet/
│   ├── manifests/
│   │   ├── site.pp                 # Master site manifest classifying agent nodes
│   │   └── standalone_apply.pp     # Standalone manifest for direct puppet apply verification
│   └── modules/
│       └── apache_website/         # Modular Puppet class structure
│           ├── manifests/
│           │   ├── init.pp         # Class orchestration & resource relationships
│           │   ├── install.pp      # Apache package installation
│           │   ├── config.pp       # Index page management and drift trigger
│           │   └── service.pp      # Service enablement and status enforcement
│           └── files/
│               └── index.html      # Canonical website source file
├── ansible/
│   ├── ansible.cfg                 # Safe execution configuration and timeout settings
│   ├── inventory/
│   │   └── hosts.example.ini       # Sanitized inventory template (real IPs git-ignored)
│   └── playbooks/
│       ├── recovery.yml            # Controlled restart, wait_for, and HTTP 200 verification
│       ├── outage_drill.yml        # Intentional outage drill for Nagios failure detection
│       └── status_check.yml        # Non-destructive service inspection playbook
├── nagios/
│   ├── nagios_cfg_integration.md   # Nagios integration and pre-flight validation instructions
│   ├── objects/
│   │   ├── hosts.cfg               # Host definition for puppet-agent
│   │   ├── services.cfg            # HTTP uptime, ping, and SSH service checks
│   │   └── commands.cfg            # Standard check_http and optional event handler commands
│   └── eventhandlers/
│       └── restart-apache-ansible.sh # Optional automated recovery script
├── terraform/                      # Clearly marked UNAPPLIED reference extension
│   ├── README.md                   # Scope and architecture explanation
│   ├── main.tf                     # VPC, Subnet, Security Groups, and 3 EC2 nodes
│   ├── variables.tf                # Configurable parameters with safe defaults
│   ├── outputs.tf                  # Exported private IPs
│   └── terraform.tfvars.example    # Variable assignment template
└── docs/
    ├── PROJECT_REPORT.md           # Comprehensive academic report (20 Marks standard)
    ├── ARCHITECTURE_WORKFLOW.md    # Multi-node topology, sequence diagrams, and port matrix
    ├── RUNBOOK_AND_VERIFICATION.md # Stage-by-stage copy-paste operational instructions
    ├── RUBRIC_MAPPING.md           # Complete cross-reference to INT333 project rubric
    └── TEST_RESULTS_TEMPLATE.md    # Formatted acceptance check logs with redacted evidence
```

---

## 🚀 Execution & Verification Workflow

Detailed command sequences are documented in [docs/RUNBOOK_AND_VERIFICATION.md](docs/RUNBOOK_AND_VERIFICATION.md). Below is the high-level operational lifecycle:

### 1. Puppet Desired-State & Drift Correction
```bash
# 1. Validate manifest syntax on puppet-master
sudo puppet parser validate /etc/puppetlabs/code/environments/production/manifests/site.pp

# 2. Apply catalog on puppet-agent (installs Apache & starts service)
sudo puppet agent -t

# 3. Confirm catalog idempotency (second run reports 0 changes)
sudo puppet agent -t

# 4. Demonstrate drift remediation (tamper with index.html and reapply)
echo "Tampered" | sudo tee /var/www/html/index.html
sudo puppet agent -t  # Restores declared file
```

### 2. Nagios Synthetic Observability
```bash
# 1. Perform pre-flight configuration check on ansible
sudo /usr/local/nagios/bin/nagios -v /usr/local/nagios/etc/nagios.cfg

# 2. Reload daemon
sudo systemctl reload nagios

# 3. Validate steady-state HTTP probe from CLI
/usr/local/nagios/libexec/check_http -H <PUPPET_AGENT_PRIVATE_IP> -u /
# Expected: HTTP OK: HTTP/1.1 200 OK
```

### 3. Outage Drill & Controlled Recovery
```bash
# 1. Simulate outage by stopping Apache from ansible node
ansible-playbook -i inventory/hosts.ini playbooks/outage_drill.yml

# 2. Observe Nagios detection
# Soft State (Attempt 1/3) -> Soft State (Attempt 2/3) -> Hard State (Attempt 3/3: CRITICAL)

# 3. Execute controlled recovery playbook
ansible-playbook -i inventory/hosts.ini playbooks/recovery.yml

# 4. Confirm Nagios state returns to OK
/usr/local/nagios/libexec/check_http -H <PUPPET_AGENT_PRIVATE_IP> -u /
# Expected: HTTP OK: HTTP/1.1 200 OK
```

---

## 📊 Rubric Compliance Summary

This project satisfies all grading criteria specified in the **INT333 Project Evaluation Rubric**:

| Evaluation Component | Maximum Marks | Key Deliverables in this Repository |
| :--- | :---: | :--- |
| **Project Report / File** | **20** | Full report in [docs/PROJECT_REPORT.md](docs/PROJECT_REPORT.md) addressing Problem Statement, Methodology, Architecture, and Testing. |
| **Project Quality & Implementation** | **50** | Verified Puppet modules, Ansible recovery playbooks, Nagios Core checks, and Terraform IaC reference. |
| **Presentation & Live Demonstration** | **10** | Live failure drill runbook in [docs/RUNBOOK_AND_VERIFICATION.md](docs/RUNBOOK_AND_VERIFICATION.md) and Mermaid workflows in [docs/ARCHITECTURE_WORKFLOW.md](docs/ARCHITECTURE_WORKFLOW.md). |
| **Viva Voce Preparation** | **20** | Technical concepts, design justifications, and failure edge cases detailed in [docs/RUBRIC_MAPPING.md](docs/RUBRIC_MAPPING.md). |
| **TOTAL** | **100** | **Complete Academic Submission Package** |

---

## 🔒 Security & Safe Operational Practices

1. **Zero Secret Leakage:** No AWS access keys, private keys (`.pem`), passwords, or real VPC host addresses are committed to version control.
2. **Private Network Routing:** All synthetic health probes, catalog transfers, and automation playbooks travel over internal AWS VPC private IPs (`172.31.0.0/16`).
3. **Encrypted Web UI Access:** The Nagios dashboard is accessed via local SSH port forwarding (`ssh -L 8080:localhost:80`) rather than exposing port 80 to `0.0.0.0/0`.
4. **JVM Memory Tuning:** Puppet Server memory heap is adjusted to 512 MB in `/etc/default/puppetserver` to ensure stable execution on AWS `t3.small` instances without kernel OOM crashes.

---

## 👥 Author and Course Information
- **Student Name:** Sakshi Malik
- **Registration ID:** 12313947
- **Course:** INT333 (DevOps Advance Configuration Management)
- **Institution:** Lovely Professional University
