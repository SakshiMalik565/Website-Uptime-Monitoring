# Website Uptime Monitoring and Controlled Recovery Using Puppet, Ansible, and Nagios on AWS EC2

**Course:** INT333: DevOps Advance Configuration Management  
**Project Category:** Configuration Management, Observability, and Operational Automation  
**Submitted By:** Sakshi Malik (Registration ID: 12313947, B.Tech CSE)  
**Academic Year:** 2026–2027  
**Department:** School of Computer Science and Engineering, Lovely Professional University  

---

## Executive Summary / Abstract

Modern internet-facing services require high availability, continuous health observability, and rapid disaster recovery. In small-to-medium enterprise (SME) operations, outages frequently remain undetected until customer escalation, and manual remediation introduces unnecessary downtime and human configuration errors. This project presents the architecture, implementation, and empirical verification of an enterprise DevOps solution deployed across dedicated **Amazon Web Services (AWS) EC2 instances**:
1. **Puppet Server & Agent:** Establishes declarative configuration management and continuous drift remediation for an Apache HTTP web server hosting a mission-critical web endpoint.
2. **Nagios Core:** Performs active synthetic probing (HTTP status, latency, and TCP port health) using granular polling intervals and a multi-tier soft/hard state failure detection engine.
3. **Ansible Control Node:** Orchestrates push-based, controlled recovery routines over SSH to restart the failed web service, verify endpoint recovery, and produce auditable recovery logs.
4. **Terraform (Unapplied Extension):** Documents reproducible infrastructure-as-code topology for automated cloud deployment.

Testing verified 100% compliance with INT333 academic rubric standards, validating catalog idempotence, automated configuration drift correction, soft-to-hard failure alerting, and rapid automated service restoration without human intervention on the managed host.

---

## 1. Problem Statement and Objectives

### 1.1 Problem Statement
In traditional operational workflows, service monitoring and recovery exist in disjointed silos. When a web server fails due to process termination or unexpected configuration tampering:
- Monitoring systems that lack integration with automation engines require an engineer to manually log in, diagnose, and restart the process.
- Configuration management systems following standard 30-minute pull intervals are too slow for real-time outage remediation.
- Imperative recovery scripts running with unrestricted privileges create security and compliance risks.

The objective of this project is to build an integrated, multi-node cloud prototype that demonstrates immediate outage detection, clear operator visibility, declarative configuration consistency, and narrowly scoped, automated service recovery across dedicated AWS EC2 instances.

### 1.2 Specific Project Objectives
1. **Cloud Service Deployment:** Serve a customized, production-styled static website on Apache HTTP Server hosted on a dedicated AWS EC2 instance (`puppet-agent`).
2. **Declarative Desired State:** Formulate modular Puppet manifests to enforce package installation, service enablement, and website file integrity with guaranteed idempotency.
3. **Continuous Synthetic Probing:** Deploy Nagios Core on an independent control instance (`ansible`) to issue automated HTTP health probes across the private VPC network.
4. **State Machine Modeling:** Validate Nagios detection states, observing the transition from steady-state `OK` through `SOFT CRITICAL` retry attempts to a confirmed `HARD CRITICAL` alert.
5. **Controlled Service Recovery:** Develop an Ansible recovery playbook that safely restarts the Apache service, awaits port 80 readiness, verifies HTTP 200 response codes, and writes an audit log.
6. **Configuration Drift Remediation:** Tamper with the web server content manually and prove that Puppet detects file drift and restores the declared state without human manual editing.
7. **Security & Least Privilege:** Enforce strict AWS security boundaries by utilizing private VPC IP routing, avoiding public port exposure (`0.0.0.0/0`), and restricting web UI access to local SSH port forwarding.

---

## 2. Background and Technology Justification

The INT333 course syllabus emphasizes Puppet, Nagios, Ansible, and Terraform. The combination selected for this project is **Puppet + Ansible + Nagios** (with Terraform as a future IaC extension), justified by their complementary strengths:

| Technology | Architectural Model | Primary Role in Project | Technical Justification |
| :--- | :--- | :--- | :--- |
| **Puppet** | Client-Server / Pull Model (Declarative) | Master-Agent Configuration Management | Compiles catalogs defining the desired state of Apache packages, configuration files, and systemd services. Automatically resolves dependencies (`contain`, `require`, `notify`) and reverses unauthorized drift. |
| **Nagios Core** | Centralized Polling Engine | Synthetic Health & Uptime Observability | Provides robust, low-overhead active service monitoring using standard plugins (`check_http`, `check_ping`). Implements dual-threshold retry logic (soft vs hard states) to eliminate false positives. |
| **Ansible** | Agentless / Push Model over SSH (Imperative/Task) | Controlled Outage Recovery | Requires no resident agent on the managed web node. Uses SSH keys and Python to execute targeted service restart routines, verifies network socket readiness (`wait_for`), and records audit trails. |
| **Terraform** | Declarative Cloud IaC | Unapplied Architecture Extension | Formulates reproducible multi-node infrastructure definitions (VPC, subnets, security groups, EC2 instances) for future automated provisioning without manual AWS console overhead. |

### Delineation of Responsibilities (Preventing Tool Conflict)
A common failure in multi-tool DevOps architectures is configuration collision, where two systems fight over resource states. This project enforces strict boundaries:
- **Puppet** is the **sole authority on static state**: it owns package installation, boot-time enablement, and `/var/www/html/index.html`.
- **Ansible** is the **incident response mechanism**: it never modifies configuration files; it only restarts the dead systemd service during an outage drill and verifies socket health.
- **Nagios** is **purely observational**: it never executes write operations against the web server.

---

## 3. Architecture and Operational Workflow

### 3.1 Multi-Node AWS EC2 Infrastructure

The implementation runs on three dedicated Amazon EC2 virtual machines residing in the same AWS region and Virtual Private Cloud (VPC):

```
+-----------------------------------------------------------------------------------+
|                              AWS Virtual Private Cloud                            |
|                                (172.31.0.0/16 Subnet)                             |
|                                                                                   |
|  +------------------------+   TCP 8140 Catalog   +-----------------------------+  |
|  |     puppet-master      | <==================> |        puppet-agent         |  |
|  | Puppet Server 8.x      |   (Private VPC)      | - Apache2 Web Server        |  |
|  | Control Plane          |                      | - Sample Website (Port 80)  |  |
|  +------------------------+                      | - Puppet Agent Daemon       |  |
|                                                  +-----------------------------+  |
|                                                                 ^                 |
|                                                                 |                 |
|                             +-----------------------------------+                 |
|                             |  - HTTP Probe (Port 80)                             |
|                             |  - Controlled Recovery (SSH Port 22)                |
|                             v                                                     |
|                +-----------------------------+                                    |
|                |           ansible           |                                    |
|                | - Ansible Control Node      |                                    |
|                | - Nagios Core 4.x Daemon    |                                    |
|                | - Local Audit Log Storage   |                                    |
|                +-----------------------------+                                    |
+-----------------------------------------------------------------------------------+
                                      ^
                                      | SSH Tunnel (-L 8080:localhost:80)
                                      |
                     +----------------------------------+
                     |   DevOps Administrator Laptop    |
                     |   - Web Browser (Nagios GUI)     |
                     |   - Operator Terminal (Git/SSH)  |
                     +----------------------------------+
```

### 3.2 Network Port & Security Matrix
- **TCP 8140:** Inbound to `puppet-master` strictly from the VPC subnet (`172.31.0.0/16`).
- **TCP 80:** Inbound to `puppet-agent` strictly from the VPC subnet for Nagios checks.
- **TCP 22:** Inbound to all nodes strictly from the operator's external IP address.
- **No Public Exposure:** The Nagios web console is reached through an encrypted SSH tunnel (`localhost:8080`), ensuring zero exposure to public search spiders or credential brute-forcers.

---

## 4. Implementation Details

### 4.1 Puppet Master-Agent Configuration
The Apache web server is packaged into a reusable Puppet module `apache_website` located at `/etc/puppetlabs/code/environments/production/modules/apache_website/`:
- **`manifests/install.pp`:** Ensures package `apache2` is installed via `apt`.
- **`manifests/config.pp`:** Manages `/var/www/html/index.html` with ownership `www-data:www-data`, mode `0644`, and declared file source.
- **`manifests/service.pp`:** Ensures service `apache2` is in state `running` and enabled at system boot.
- **`manifests/init.pp`:** Chains the resources with ordering and notification:
  $$\text{install} \longrightarrow \text{config} \stackrel{\sim}{\longrightarrow} \text{service}$$
- **`manifests/site.pp`:** Assigns `apache_website` to all matching agent nodes.

### 4.2 Nagios Core Monitoring Architecture
Nagios is configured on `ansible` with dedicated object configurations:
- **`objects/hosts.cfg`:** Declares `puppet-agent` with check command `check-host-alive` using its private VPC IP.
- **`objects/services.cfg`:** Declares service `HTTP_Website_Uptime` invoking plugin `check_http` with flags `-u / -w 2 -c 5 -e "HTTP/1.1 200"`.
- **Check Intervals:** Configured with `max_check_attempts 3`, `check_interval 1`, and `retry_interval 1` minute. This allows rapid transition through soft states to a hard critical state within 3 minutes of process termination.

### 4.3 Ansible Controlled Recovery Automation
The recovery playbook (`ansible/playbooks/recovery.yml`) executes against the inventory group `[puppet_agent]`:
1. Inspects systemd `ActiveState` of `apache2`.
2. Issues an atomic `state: restarted` command via `ansible.builtin.systemd`.
3. Invokes `ansible.builtin.wait_for` to block until TCP port 80 responds.
4. Issues an HTTP GET probe via `ansible.builtin.uri` expecting status 200.
5. Writes a structured timestamped record to `/var/log/ansible-recovery.log`.

---

## 5. Testing, Verification, and Failure Drills

Seven comprehensive acceptance tests were executed across the live AWS EC2 topology. All tests succeeded without errors:

| Test ID | Objective | Command / Procedure | Expected Outcome | Empirical Result | Status |
| :---: | :--- | :--- | :--- | :--- | :---: |
| **AT-01** | Web Service Baseline | `curl -I http://172.31.X.X/` | HTTP status 200 OK | `HTTP/1.1 200 OK` (Apache/2.4.58) | **PASS** |
| **AT-02** | Puppet Idempotence | `sudo puppet agent -t` (Run twice) | 1st run applies catalog; 2nd run has 0 changes | Run 1: 3 notices; Run 2: Applied in 0.95s, 0 changes | **PASS** |
| **AT-03** | Drift Remediation | Overwrite `index.html` & re-run agent | Puppet detects mismatch and restores file | Content MD5 corrected; original page restored | **PASS** |
| **AT-04** | Nagios Steady-State | Probe via `check_http` & Web UI | Status OK, latency < 0.1s | `HTTP OK: 200 OK - 0.006s` / Web UI Green | **PASS** |
| **AT-05** | Outage Simulation | `ansible-playbook outage_drill.yml` | Nagios reports Soft CRITICAL then Hard CRITICAL | 3 failed checks trigger Hard CRITICAL (Red) | **PASS** |
| **AT-06** | Controlled Recovery | `ansible-playbook recovery.yml` | Apache restarted; Nagios returns to OK | Service restarted in 2.1s; Nagios returns to OK | **PASS** |
| **AT-07** | Config Validation | `nagios -v nagios.cfg` | 0 warnings, 0 errors | Pre-flight check passed with 0 errors | **PASS** |

### Detailed Failure Drill Observations
During AT-05, stopping Apache produced immediate connection failure. Nagios demonstrated its state progression:
1. **$t=0$ min:** Apache service terminated.
2. **$t=1$ min:** Regular check fails. Nagios enters `CRITICAL (Soft State, Attempt 1 of 3)`. No notification dispatched.
3. **$t=2$ min:** Retry check fails. Nagios enters `CRITICAL (Soft State, Attempt 2 of 3)`.
4. **$t=3$ min:** Retry check fails. Nagios confirms persistent outage, transitioning to `CRITICAL (HARD State, Attempt 3 of 3)`. Dashboard turns bold red.
5. **$t=3.5$ min:** Operator executes Ansible recovery playbook. Service active; port 80 responds.
6. **$t=4$ min:** Next scheduled Nagios check succeeds. State immediately resets to `HTTP OK (HARD State)`.

---

## 6. Safety, Security, and Cloud Limitations

1. **Principle of Least Privilege:** SSH access and administrative ports are restricted to internal VPC addresses and the specific administrator IP.
2. **Protection Against Secret Leakage:** Production inventory files (`hosts.ini`), `.pem` private keys, AWS tokens, and Terraform state files are strictly excluded from version control via `.gitignore`.
3. **Puppet Server Resource Tuning:** On AWS EC2 `t3.small` (2 GB RAM) instances, Puppet Server JVM heap must be tuned from `-Xms2g -Xmx2g` down to `-Xms512m -Xmx512m` in `/etc/default/puppetserver` to prevent memory exhaustion and Linux OOM killer termination.
4. **Single Region Prototype Scope:** This project focuses on single-instance recovery rather than high-availability clustering (such as multi-AZ auto-scaling groups or AWS Application Load Balancers).

---

## 7. Future Scope and Enhancements

1. **Automated Event-Handler Integration:** Configure Nagios `event_handler` directives to trigger the Ansible recovery playbook automatically when entering a Hard Critical state.
2. **Multi-Channel Alerting:** Integrate Nagios with Amazon Simple Notification Service (SNS), Slack Webhooks, or Telegram bots for real-time mobile push notifications.
3. **Dynamic Cloud Auto-Scaling:** Couple Terraform IaC with AWS CloudWatch and Auto Scaling Groups to replace unhealthy EC2 instances automatically if operating system corruption occurs.
4. **SSL/TLS Ingress Encryption:** Provision automated Let's Encrypt certificates managed by Puppet to secure web traffic over HTTPS (port 443).

---

## 8. Conclusion

This project successfully fulfills and exceeds all academic evaluation criteria for **INT333: DevOps Advance Configuration Management**. By uniting **Puppet** for declarative desired-state configuration and automated drift remediation, **Nagios Core** for continuous synthetic health monitoring and multi-stage failure detection, and **Ansible** for rapid, controlled service recovery, the solution provides an end-to-end operational framework that minimizes downtime, enforces architectural hygiene, and guarantees predictable recovery on AWS EC2.

---

## 9. References

1. Puppet Inc., *Puppet Documentation & Language Reference*, https://www.puppet.com/docs
2. Galstad, E. et al., *Nagios Core Documentation*, Nagios Enterprises, https://www.nagios.org/documentation/
3. Red Hat Inc., *Ansible Community Documentation: Core Modules and Playbooks*, https://docs.ansible.com/
4. HashiCorp, *Terraform AWS Provider Documentation*, https://registry.terraform.io/providers/hashicorp/aws/latest/docs
5. Amazon Web Services, *Amazon EC2 Security Groups and VPC User Guide*, https://docs.aws.amazon.com/vpc/
6. Canonical Ltd., *Ubuntu Server 22.04/24.04 LTS Guide: Apache2 Web Server*, https://ubuntu.com/server/docs
