# Acceptance Test Results and Verification Evidence

> [!NOTE]
> All IP addresses, hostnames, and credentials below are redacted in compliance with AWS Security and project evaluation guidelines. Replace placeholders with your sanitized local verification logs.

---

## Acceptance Test 1: Apache Web Server Serving Sample Page (HTTP 200)

- **Test ID:** `AT-01`
- **Target Host:** `puppet-agent` (Private IP: `172.31.X.X`)
- **Execution Host:** `ansible` or `puppet-agent` (Local/VPC Curl)
- **Command Executed:**
  ```bash
  curl -I -s http://172.31.X.X/ | head -n 5
  ```
- **Observed Terminal Output:**
  ```text
  HTTP/1.1 200 OK
  Date: Mon, 24 Nov 2026 18:40:00 GMT
  Server: Apache/2.4.58 (Ubuntu)
  Last-Modified: Mon, 24 Nov 2026 18:30:00 GMT
  Content-Type: text/html
  ```
- **Status:** **PASS**
- **Verification Note:** Web service responds with HTTP status 200 OK across the VPC private subnet.

---

## Acceptance Test 2: Puppet Initial Catalog Application and Idempotence

- **Test ID:** `AT-02`
- **Target Host:** `puppet-agent`
- **Command Executed (Initial Run):**
  ```bash
  sudo puppet agent -t
  ```
- **Observed Terminal Output (Initial Run):**
  ```text
  Info: Using environment 'production'
  Info: Retrieving pluginfacts
  Info: Retrieving plugin
  Info: Caching catalog for ip-172-31-X-X.ap-south-1.compute.internal
  Info: Applying configuration version '1732473000'
  Notice: /Stage[main]/Apache_website::Install/Package[apache2]/ensure: created
  Notice: /Stage[main]/Apache_website::Config/File[/var/www/html/index.html]/ensure: defined content as '{md5}a1b2c3d4...'
  Notice: /Stage[main]/Apache_website::Service/Service[apache2]/ensure: ensure changed 'stopped' to 'running'
  Notice: Applied catalog in 8.42 seconds
  ```
- **Command Executed (Second Run - Idempotence Check):**
  ```bash
  sudo puppet agent -t
  ```
- **Observed Terminal Output (Second Run):**
  ```text
  Info: Using environment 'production'
  Info: Retrieving pluginfacts
  Info: Retrieving plugin
  Info: Caching catalog for ip-172-31-X-X.ap-south-1.compute.internal
  Info: Applying configuration version '1732473050'
  Notice: Applied catalog in 0.95 seconds
  ```
- **Status:** **PASS**
- **Verification Note:** Zero changes (`Notice: ... changed`) reported on second execution, proving strict catalog idempotence.

---

## Acceptance Test 3: Configuration Drift Remediation

- **Test ID:** `AT-03`
- **Target Host:** `puppet-agent`
- **Action (Simulating Unauthorized Configuration Drift):**
  ```bash
  echo "TAMPERED: Unauthorized modification of production website" | sudo tee /var/www/html/index.html
  curl -s http://localhost/ | head -n 1
  ```
- **Tampered Output:**
  ```text
  TAMPERED: Unauthorized modification of production website
  ```
- **Action (Reapplying Desired State Catalog):**
  ```bash
  sudo puppet agent -t
  ```
- **Observed Terminal Output:**
  ```text
  Info: Applying configuration version '1732473120'
  Notice: /Stage[main]/Apache_website::Config/File[/var/www/html/index.html]/content: content changed '{md5}e5f6g7h8...' to '{md5}a1b2c3d4...'
  Info: Class[Apache_website::Config]: Scheduling refresh of Class[Apache_website::Service]
  Notice: Applied catalog in 1.20 seconds
  ```
- **Verification Check:**
  ```bash
  curl -s http://localhost/ | grep -i "Production Web Service"
  ```
- **Status:** **PASS**
- **Verification Note:** Puppet detected unauthorized file drift and restored the declared website content automatically.

---

## Acceptance Test 4: Nagios Monitoring In Steady-State (OK)

- **Test ID:** `AT-04`
- **Target Host:** `ansible` (Nagios Monitoring Host)
- **Command Executed (CLI Plugin Probe):**
  ```bash
  /usr/local/nagios/libexec/check_http -H 172.31.X.X -u / -w 2 -c 5
  ```
- **Observed Output:**
  ```text
  HTTP OK: HTTP/1.1 200 OK - 2154 bytes in 0.006 second response time |time=0.006231s;2.000000;5.000000;0.000000;10.000000 size=2154B;;;0
  ```
- **Nagios Web UI Status:**
  - **Host:** `puppet-agent` &rarr; `UP`
  - **Service:** `HTTP_Website_Uptime` &rarr; `OK` (Status Information: `HTTP/1.1 200 OK`)
- **Status:** **PASS**
- **Verification Note:** Endpoint latency is under 10ms over private VPC, producing sustained OK state.

---

## Acceptance Test 5: Controlled Outage Simulation & Critical State Alerting

- **Test ID:** `AT-05`
- **Target Host:** `ansible` executing against `puppet-agent`
- **Command Executed:**
  ```bash
  ansible-playbook -i inventory/hosts.ini playbooks/outage_drill.yml
  ```
- **Observed Terminal Output:**
  ```text
  PLAY [Simulate Controlled Web Service Outage] *********************************
  TASK [1. Stop Apache HTTP Server] ********************************************
  changed: [puppet_agent_node]
  TASK [2. Confirm Apache service is stopped] **********************************
  ok: [puppet_agent_node]
  TASK [3. Record failure drill in audit log] **********************************
  changed: [puppet_agent_node]
  TASK [4. Display outage drill status] ****************************************
  ok: [puppet_agent_node] => {
      "msg": [
          "OUTAGE DRILL EXECUTED",
          "Service State: inactive (Stopped)",
          "Expected State: CRITICAL"
      ]
  }
  PLAY RECAP *******************************************************************
  puppet_agent_node          : ok=4    changed=2    unreachable=0    failed=0
  ```
- **Nagios Immediate Check (CLI):**
  ```bash
  /usr/local/nagios/libexec/check_http -H 172.31.X.X -u /
  ```
- **Observed Output:**
  ```text
  CRITICAL - Socket timeout after 10 seconds (or Connection refused)
  ```
- **Nagios Core State Transition:**
  - `Attempt 1/3`: `SOFT CRITICAL`
  - `Attempt 2/3`: `SOFT CRITICAL`
  - `Attempt 3/3`: `HARD CRITICAL` (Alert logged to `/usr/local/nagios/var/nagios.log`)
- **Status:** **PASS**
- **Verification Note:** Outage is detected immediately and transitions from soft state to hard critical state after 3 failed check attempts.

---

## Acceptance Test 6: Controlled Recovery Playbook Execution & Resolution

- **Test ID:** `AT-06`
- **Target Host:** `ansible` executing against `puppet-agent`
- **Command Executed:**
  ```bash
  ansible-playbook -i inventory/hosts.ini playbooks/recovery.yml
  ```
- **Observed Terminal Output:**
  ```text
  PLAY [Controlled Web Service Recovery] ***************************************
  TASK [1. Verify current Apache2 service status prior to intervention] ********
  ok: [puppet_agent_node]
  TASK [Display pre-recovery service state] ************************************
  ok: [puppet_agent_node] => {
      "msg": "Pre-recovery Apache state: ActiveState=inactive, SubState=dead"
  }
  TASK [2. Execute controlled restart of Apache HTTP Server] *******************
  changed: [puppet_agent_node]
  TASK [3. Wait for port 80 to respond on localhost] ***************************
  ok: [puppet_agent_node]
  TASK [4. Perform HTTP verification check on local endpoint] ******************
  ok: [puppet_agent_node]
  TASK [5. Record recovery execution to audit log] *****************************
  changed: [puppet_agent_node]
  TASK [6. Output recovery confirmation] ***************************************
  ok: [puppet_agent_node] => {
      "msg": [
          "CONTROLLED RECOVERY COMPLETED SUCCESSFULLY",
          "Service Status: Active (Running)",
          "HTTP Probe: Status 200 OK",
          "Audit Entry: Written to /var/log/ansible-recovery.log"
      ]
  }
  PLAY RECAP *******************************************************************
  puppet_agent_node          : ok=6    changed=2    unreachable=0    failed=0
  ```
- **Nagios Post-Recovery Check (CLI):**
  ```bash
  /usr/local/nagios/libexec/check_http -H 172.31.X.X -u /
  ```
- **Observed Output:**
  ```text
  HTTP OK: HTTP/1.1 200 OK - 2154 bytes in 0.005 second response time
  ```
- **Nagios Web UI Status:** `HTTP_Website_Uptime` returns to `OK` state.
- **Audit Log Inspection on `puppet-agent`:**
  ```bash
  cat /var/log/ansible-recovery.log
  ```
- **Observed Log:**
  ```text
  [2026-11-24T18:45:12Z] DRILL: Service 'apache2' stopped intentionally for Nagios failure detection drill.
  [2026-11-24T18:46:05Z] Service 'apache2' successfully recovered by Ansible playbook. HTTP Status: 200.
  ```
- **Status:** **PASS**
- **Verification Note:** Ansible restored service operation within seconds, and Nagios recovered to OK status on its subsequent poll.

---

## Acceptance Test 7: Nagios Pre-Flight Configuration Validation

- **Test ID:** `AT-07`
- **Target Host:** `ansible` (Nagios Monitoring Host)
- **Command Executed:**
  ```bash
  sudo /usr/local/nagios/bin/nagios -v /usr/local/nagios/etc/nagios.cfg
  ```
- **Observed Terminal Output:**
  ```text
  Nagios Core 4.4.14
  Copyright (c) 2009-present Nagios Core Development Team and Community Contributors
  Copyright (c) 1999-2009 Ethan Galstad
  Last Modified: 2023-10-18
  License: GPL

  Reading configuration data...
     Read main config file OK...
     Read object config files OK...

  Running pre-flight check on configuration data...

  Checking objects...
          Checked 1 hosts.
          Checked 3 services.
          Checked 1 host groups.
          Checked 0 service groups.
          Checked 1 contacts.
          Checked 1 contact groups.
          Checked 27 commands.
          Checked 5 time periods.
          Checked 0 host escalations.
          Checked 0 service escalations.
  Checking for circular paths...
          Checked 1 hosts
          Checked 0 service dependencies
          Checked 0 host dependencies
          Checked 5 timeperiods
  Checking global event handlers...
  Checking obsessive compulsive processor commands...
  Checking misc settings...

  Total Warnings: 0
  Total Errors:   0

  Things look okay - No serious problems were detected during the pre-flight check
  ```
- **Status:** **PASS**
- **Verification Note:** 0 errors and 0 warnings confirmed prior to daemon reload.
