#!/usr/bin/env bash
# ==============================================================================
# Optional Nagios Event Handler: restart-apache-ansible.sh
# Location: /usr/local/nagios/libexec/eventhandlers/restart-apache-ansible.sh
# Purpose: Triggers Ansible controlled recovery when HTTP service enters CRITICAL
# ==============================================================================

STATE="$1"       # OK, WARNING, UNKNOWN, CRITICAL
STATETYPE="$2"   # SOFT or HARD
ATTEMPT="$3"     # 1, 2, 3...

LOGFILE="/var/log/nagios-eventhandler.log"

log() {
    echo "[$(date -u '+%Y-%m-%dT%H:%M:%SZ')] [STATE: $STATE, TYPE: $STATETYPE, ATTEMPT: $ATTEMPT] $1" >> "$LOGFILE"
}

# Only act on HARD CRITICAL states (after retries have failed) to prevent flapping
case "$STATE" in
"CRITICAL")
    case "$STATETYPE" in
    "HARD")
        log "Hard critical state confirmed. Triggering Ansible controlled recovery playbook..."
        # Execute Ansible recovery playbook locally
        # Path to playbook should be adjusted to repository location on the ansible host
        /usr/bin/ansible-playbook /opt/uptime-devops/ansible/playbooks/recovery.yml >> "$LOGFILE" 2>&1
        STATUS=$?
        if [ $STATUS -eq 0 ]; then
            log "Ansible recovery playbook executed successfully."
        else
            log "ERROR: Ansible recovery playbook returned code $STATUS."
        fi
        ;;
    "SOFT")
        log "Soft critical state observed (attempt $ATTEMPT). Awaiting retry thresholds before remediation."
        ;;
    esac
    ;;
"OK")
    log "Service reported in OK state. No recovery action needed."
    ;;
*)
    log "Informational check: state $STATE."
    ;;
esac

exit 0
