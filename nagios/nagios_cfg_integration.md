# Nagios Configuration & Validation Guide

## 1. Directory Structure on Monitoring Host (`ansible`)
Depending on whether Nagios Core was installed via source (`/usr/local/nagios`) or via package manager (`/etc/nagios4`), place the object files in the corresponding directory:

- **Source install path**: `/usr/local/nagios/etc/servers/`
- **Package install path**: `/etc/nagios4/conf.d/`

## 2. Incorporating Object Files into `nagios.cfg`
Ensure `nagios.cfg` loads your server definitions. In `/usr/local/nagios/etc/nagios.cfg` (or `/etc/nagios4/nagios.cfg`):

```ini
# Add or uncomment directory recursion:
cfg_dir=/usr/local/nagios/etc/servers

# Or specify individual configuration files:
cfg_file=/usr/local/nagios/etc/objects/hosts.cfg
cfg_file=/usr/local/nagios/etc/objects/services.cfg
```

## 3. Strict Pre-Flight Validation
**Always** validate the Nagios configuration prior to restarting the daemon:

### Source Install Validation:
```bash
sudo /usr/local/nagios/bin/nagios -v /usr/local/nagios/etc/nagios.cfg
```

### APT / Package Install Validation:
```bash
sudo nagios4 -v /etc/nagios4/nagios.cfg
```

### Expected Output:
```text
Total Warnings: 0
Total Errors:   0
Things look okay - No serious problems were detected during the pre-flight check
```

## 4. Safely Reloading Nagios Service
Only reload after pre-flight check passes with 0 errors:
```bash
sudo systemctl reload nagios   # or sudo systemctl restart nagios
sudo systemctl status nagios --no-pager
```
