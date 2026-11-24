# DevOps Operational Runbook & Step-by-Step Verification Guide

This operational runbook provides the exact, copy-pasteable commands to deploy, verify, and demonstrate the **Website Uptime Monitoring and Controlled Recovery** project across your AWS EC2 instances.

---

## Stage Overview & Pre-requisites

You will interact with three EC2 instances:
1. `puppet-master` (Puppet Server Control Plane)
2. `puppet-agent` (Apache Web Host)
3. `ansible` (Ansible Control Node & Nagios Monitoring Host)

> [!SECURITY]
> - Never paste private keys, passwords, or tokens into terminal logs or public channels.
> - When sharing terminal outputs, redact private IPs (e.g., `172.31.X.X`), AWS Account IDs, and public IPs.
> - Access the Nagios Web Interface using an **SSH tunnel** (`-L 8080:localhost:80`) rather than opening port 80 to `0.0.0.0/0`.

---

## Stage 1: Read-Only Discovery and VPC Connectivity Check

### 1.1 On your Local Machine / Bastion
Establish SSH connections to each instance and identify their private VPC IPs:
```bash
# Example SSH connection syntax using your existing key:
ssh -i /path/to/your-key.pem ubuntu@<PUPPET_MASTER_PUBLIC_OR_EIP>
ssh -i /path/to/your-key.pem ubuntu@<PUPPET_AGENT_PUBLIC_OR_EIP>
ssh -i /path/to/your-key.pem ubuntu@<ANSIBLE_PUBLIC_OR_EIP>
```

### 1.2 On each instance: Verify Hostname and IP
Run the following on all 3 instances to record their internal network details:
```bash
hostnamectl
ip -4 addr show eth0
```
*Expected Result:*
- OS: Ubuntu 22.04 or 24.04 LTS
- IP addresses: `172.31.X.A` (`puppet-master`), `172.31.X.B` (`puppet-agent`), `172.31.X.C` (`ansible`).

### 1.3 On `ansible`: Test VPC Connectivity to `puppet-agent`
```bash
# Verify ping / ICMP reachability
ping -c 3 <PUPPET_AGENT_PRIVATE_IP>

# Verify TCP port 22 (SSH) reachability
nc -zv -w 3 <PUPPET_AGENT_PRIVATE_IP> 22
```
*Expected Result:* Ping returns 0% packet loss and port 22 reports `open`.

---

## Stage 2: Puppet Configuration and Desired-State Enforcement

> [!NOTE]
> **Puppet Code Path Environment Discovery:**
> In this environment, Puppet Server's active `environmentpath` is configured as `/etc/puppet/code/environments` (rather than `/etc/puppetlabs/code/environments`). Ensure modules and `site.pp` are placed in `/etc/puppet/code/environments/production`. Any legacy conflicting manifests (e.g., prior Nginx definitions) should be backed up and replaced with the Apache module.

### 2.1 On `puppet-master`: Deploy the Apache Website Module
1. Navigate to the active Puppet environment code directory:
   ```bash
   cd /etc/puppet/code/environments/production
   ```
2. Back up any legacy `site.pp`:
   ```bash
   sudo cp /etc/puppet/code/environments/production/manifests/site.pp /etc/puppet/code/environments/production/manifests/site.pp.legacy.bak 2>/dev/null || true
   ```
3. Ensure directory structure exists:
   ```bash
   sudo mkdir -p modules/apache_website/manifests modules/apache_website/files manifests
   ```
4. Copy the project files from `puppet/` (or from `/etc/puppetlabs/code/environments/production/`) into the active environment:
   - Copy `modules/apache_website/manifests/*` &rarr; `/etc/puppet/code/environments/production/modules/apache_website/manifests/`
   - Copy `modules/apache_website/files/index.html` &rarr; `/etc/puppet/code/environments/production/modules/apache_website/files/index.html`
   - Copy `manifests/site.pp` &rarr; `/etc/puppet/code/environments/production/manifests/site.pp`

5. Validate Puppet syntax before applying:
   ```bash
   sudo /opt/puppetlabs/bin/puppet parser validate /etc/puppet/code/environments/production/manifests/site.pp
   sudo /opt/puppetlabs/bin/puppet parser validate /etc/puppet/code/environments/production/modules/apache_website/manifests/*.pp
   ```
   *Expected Result:* Clean exit with 0 errors.

6. Verify Puppet Server service status:
   ```bash
   sudo systemctl status puppetserver --no-pager
   ```
   *(Note: If Puppet Server fails with Out-Of-Memory on t3.small, set JVM heap to 512m in `/etc/default/puppetserver` and restart).*

### 2.2 On `puppet-agent`: Resolve Port Contention and Execute Catalog
1. Ensure legacy or failed Nginx is stopped and disabled so Apache exclusively binds port 80:
   ```bash
   sudo systemctl stop nginx 2>/dev/null || true
   sudo systemctl disable nginx 2>/dev/null || true
   ```
2. Trigger catalog retrieval from Puppet Master:
   ```bash
   sudo /opt/puppetlabs/bin/puppet agent -t
   ```
   *Expected Result:* Puppet compiles the active Apache catalog, updates `/var/www/html/index.html`, and ensures service `apache2` is running. Exit code 2 (changes applied).

2. Verify Idempotence (Second Run):
   ```bash
   sudo puppet agent -t
   ```
   *Expected Result:* "Notice: Applied catalog in X.XX seconds" with **zero changes**. Exit code 0.

3. Verify Local Web Service Response:
   ```bash
   curl -I http://localhost/
   ```
   *Expected Result:* `HTTP/1.1 200 OK`.

### 2.3 Configuration Drift Remediation Drill
1. Tamper with the index page manually:
   ```bash
   echo "DRIFT TEST: Tampered Web Page" | sudo tee /var/www/html/index.html
   curl -s http://localhost/
   ```
2. Reapply Puppet agent:
   ```bash
   sudo puppet agent -t
   ```
   *Expected Result:* Puppet detects MD5 mismatch, restores `/var/www/html/index.html`, and reports corrective change.
3. Verify restored content:
   ```bash
   curl -s http://localhost/ | grep -i "Production Web Service"
   ```

---

## Stage 3: Nagios Core Configuration and Validation on `ansible`

### 3.1 Install Prerequisites and Nagios (if not already present)
```bash
sudo apt update && sudo apt install -y nagios4 nagios-plugins-basic nagios-plugins-standard
```
*(Or use source-built Nagios in `/usr/local/nagios/` if already deployed).*

### 3.2 Place Host and Service Configurations
1. Copy `nagios/objects/hosts.cfg` and `nagios/objects/services.cfg` to your Nagios configuration directory (e.g., `/etc/nagios4/conf.d/` or `/usr/local/nagios/etc/servers/`).
2. Update `address` in `hosts.cfg` with `<PUPPET_AGENT_PRIVATE_IP>`.

### 3.3 Strict Pre-Flight Validation
Before reloading Nagios, validate the syntax:
```bash
# For APT package install:
sudo nagios4 -v /etc/nagios4/nagios.cfg

# Or for Source install:
sudo /usr/local/nagios/bin/nagios -v /usr/local/nagios/etc/nagios.cfg
```
*Expected Result:*
```text
Total Warnings: 0
Total Errors:   0
Things look okay - No serious problems were detected during the pre-flight check
```

### 3.4 Reload Nagios Daemon
```bash
sudo systemctl reload nagios4 || sudo systemctl reload nagios
```

---

## Stage 4: Steady-State Monitoring Verification

### 4.1 On `ansible`: Test Nagios Probe from CLI
```bash
/usr/lib/nagios/plugins/check_http -H <PUPPET_AGENT_PRIVATE_IP> -u /
# Or source path:
/usr/local/nagios/libexec/check_http -H <PUPPET_AGENT_PRIVATE_IP> -u /
```
*Expected Result:*
`HTTP OK: HTTP/1.1 200 OK - ... response time ...`

### 4.2 Securely View Nagios Web Interface via SSH Tunnel
On your local laptop:
```bash
ssh -i /path/to/key.pem -L 8080:localhost:80 ubuntu@<ANSIBLE_PUBLIC_IP>
```
Open your browser to:
`http://localhost:8080/nagios4` (or `http://localhost:8080/nagios`)
*Expected Result:* Host `puppet-agent` is **UP**, Service `HTTP_Website_Uptime` is **OK (GREEN)**.

---

## Stage 5: Controlled Outage Simulation Drill

### 5.1 On `ansible`: Setup Inventory for Ansible
1. Navigate to the `ansible/` directory on the `ansible` node.
2. Copy `inventory/hosts.example.ini` to `inventory/hosts.ini`:
   ```bash
   cp inventory/hosts.example.ini inventory/hosts.ini
   ```
3. Edit `inventory/hosts.ini` with `<PUPPET_AGENT_PRIVATE_IP>` and path to SSH key.
4. Test Ansible connectivity:
   ```bash
   ansible -i inventory/hosts.ini puppet_agent -m ping
   ```
   *Expected Result:* `SUCCESS => {"pong": "pong"}`.

### 5.2 Execute Outage Drill Playbook
```bash
ansible-playbook -i inventory/hosts.ini playbooks/outage_drill.yml
```
*Expected Result:* Apache2 is stopped. Playbook completes with `changed=2, failed=0`.

### 5.3 Observe Detection in Nagios
1. Check immediate probe:
   ```bash
   /usr/lib/nagios/plugins/check_http -H <PUPPET_AGENT_PRIVATE_IP> -u /
   ```
   *Expected Result:* `CRITICAL - Socket timeout` or `Connection refused`.
2. Refresh the Nagios Web UI:
   - Check 1: State `CRITICAL` (Soft State 1/3)
   - Check 2: State `CRITICAL` (Soft State 2/3)
   - Check 3: State `CRITICAL` (Hard State 3/3 - RED Alert)

---

## Stage 6: Controlled Recovery Playbook Execution

### 6.1 On `ansible`: Run Recovery Playbook
```bash
ansible-playbook -i inventory/hosts.ini playbooks/recovery.yml
```
*Expected Output:*
- Tasks check pre-service status (`inactive`).
- Restarts `apache2` service.
- Waits for port 80 to become available.
- Confirms HTTP 200 status code.
- Writes audit log to `/var/log/ansible-recovery.log`.
- Recap: `changed=2, failed=0`.

### 6.2 Verify Nagios Monitoring State Recovery
1. Run CLI check:
   ```bash
   /usr/lib/nagios/plugins/check_http -H <PUPPET_AGENT_PRIVATE_IP> -u /
   ```
   *Expected Result:* `HTTP OK: HTTP/1.1 200 OK`.
2. Check Nagios Web UI: Service status shifts back to **OK (GREEN)**.
3. Check audit log on `puppet-agent`:
   ```bash
   ssh -i /path/to/key.pem ubuntu@<PUPPET_AGENT_PRIVATE_IP> "sudo cat /var/log/ansible-recovery.log"
   ```
   *Expected Result:* Contains timestamped recovery log entry.

---

## Stage 7: Clean-Up & Evidence Collection

1. Confirm all services are healthy.
2. Capture terminal outputs into `docs/TEST_RESULTS_TEMPLATE.md` with sensitive information redacted.
3. Do not commit actual `hosts.ini` or `.pem` keys to GitHub.
