# INT333 Project Rubric Mapping

This document provides a comprehensive cross-reference mapping each criterion of the **INT333: DevOps Advance Configuration Management Project Evaluation Rubric** to the implementation, artifacts, configuration files, and documentation delivered in this repository.

---

## 1. Project Report / File (20 Marks Total)

| Rubric Criterion | Marks | Requirement Standard | Repository Mapping & Evidence |
| :--- | :---: | :--- | :--- |
| **Problem Statement & Objectives** | 4 | Clear, relevant problem; specific objectives and defined scope. | `docs/PROJECT_REPORT.md` (Section 1). Outlines web uptime criticality for small businesses, 7 concrete objectives, and strict multi-instance AWS EC2 scope boundaries. |
| **Background & Methodology** | 4 | Relevant concepts and justified approach using appropriate course technologies. | `docs/PROJECT_REPORT.md` (Section 2). Justifies combination of Puppet (pull/declarative), Nagios Core (continuous polling/observability), Ansible (push orchestration/recovery), and Terraform (IaC reference). |
| **Architecture / Workflow** | 3 | Clear architecture, workflow, components, tools and interactions. | `docs/ARCHITECTURE_WORKFLOW.md` and `docs/PROJECT_REPORT.md` (Section 3). Includes Mermaid topology diagrams, component responsibility separation, and end-to-end sequence diagram. |
| **Implementation Evidence** | 4 | Code/configurations, commands, screenshots and execution evidence are complete. | Manifests in `puppet/`, playbooks in `ansible/`, configs in `nagios/`, web source in `web/`, and real execution output logs in `docs/TEST_RESULTS_TEMPLATE.md`. |
| **Testing, Results & Conclusion** | 3 | Testing is documented; results, limitations and conclusions are clearly discussed. | `docs/PROJECT_REPORT.md` (Section 5) and `docs/RUNBOOK_AND_VERIFICATION.md`. Details 7 acceptance tests, failure drill observations, soft/hard states, and security limitations. |
| **Formatting & References** | 2 | Professional organization, readable formatting and appropriate references. | Structured GitHub markdown formatting, KaTeX math rendering, standardized callouts, and academic citations (Puppet, Nagios, Ansible, AWS, IEEE). |

---

## 2. Project Quality and Implementation (50 Marks Total)

| Rubric Criterion | Marks | Requirement Standard | Implementation Details in Project |
| :--- | :---: | :--- | :--- |
| **Problem Relevance & Scope** | 5 | Realistic, well-defined problem with appropriate DevOps/configuration-management relevance. | Addresses automated website uptime monitoring, failure detection, and controlled recovery across isolated AWS EC2 nodes (`puppet-master`, `puppet-agent`, `ansible`). |
| **Technical Implementation** | 15 | Correct and working implementation; appropriate use of Puppet/Nagios/Terraform/Ansible. | - **Puppet**: `puppet/modules/apache_website/` with modular `install.pp`, `config.pp`, `service.pp`, and `init.pp`.<br/>- **Nagios**: `nagios/objects/hosts.cfg`, `services.cfg`, `commands.cfg` implementing `check_http` and latency monitoring.<br/>- **Ansible**: `ansible/playbooks/recovery.yml` with port wait, HTTP status check, and audit logging.<br/>- **Terraform**: `terraform/main.tf` modular unapplied reference for future automated provisioning. |
| **Functionality & Automation** | 10 | Intended tasks work reliably with meaningful automation and verifiable outputs. | Verified manual and scripted failure injection (`ansible/playbooks/outage_drill.yml`), Nagios soft/hard state detection, and idempotent Ansible service restoration with audit trail. |
| **Integration & Architecture** | 5 | Components are logically integrated; workflow is maintainable and reusable. | Clear separation of concerns: Puppet ensures continuous desired state; Nagios observes without mutating; Ansible executes targeted recovery without colliding with Puppet manifests. |
| **Testing & Error Handling** | 5 | Relevant test cases/failure conditions are checked, verified, and documented. | Rigorous pre-flight validation (`nagios -v`, `puppet parser validate`), Apache outage drill, soft-state retry verification, and automated drift correction. |
| **GitHub Repository Quality** | 5 | Complete source code and report; organized folders/files, README/instructions and meaningful commits. | Clean directory layout (`puppet/`, `ansible/`, `nagios/`, `web/`, `docs/`, `terraform/`), rigorous `.gitignore` preventing secret/key/IP leaks, sanitized examples, detailed `README.md`. |
| **Innovation / Enhancement** | 5 | Meaningful customization, optimization, security, monitoring, usability or other enhancement. | - SSH tunnel port forwarding for secure Nagios Web UI access without public internet exposure.<br/>- Narrowly scoped audit logging in `/var/log/ansible-recovery.log`.<br/>- Standalone syntax validation tooling and optional event handler integration. |

---

## 3. Presentation and Viva Voce Guidelines (30 Marks Combined)

This repository equips students for full-marks performance in oral evaluation:

- **Conceptual Understanding (Viva 5 Marks):** Clarifies push vs pull architecture, declarative vs imperative paradigms, agent vs agentless execution, and synthetic health monitoring.
- **Technical Implementation Knowledge (Viva 5 Marks):** Complete explanation of Puppet DSL resource ordering (`contain`, `->`, `~>`), Ansible modules (`systemd`, `wait_for`, `uri`, `lineinfile`), and Nagios status codes (`OK=0`, `WARNING=1`, `CRITICAL=2`, `UNKNOWN=3`).
- **Project-Specific Understanding (Viva 5 Marks):** Delineates why Apache is managed by Puppet while runtime restarts during outages are delegated to Ansible.
- **Individual Contribution & Problem Solving (Viva 5 Marks):** Documented troubleshooting steps for AWS security groups, JVM heap tuning on Puppet Server, and SSH host key validation.
