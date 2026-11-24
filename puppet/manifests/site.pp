# ==============================================================================
# Puppet Master Control Plane - Main Site Manifest (site.pp)
# Project: Website Uptime Monitoring and Controlled Recovery (INT333)
# ==============================================================================

# Baseline configuration applied to all managed nodes
node default {
  # Notify catalog application timestamp for audit verification
  notify { "Node ${facts['networking']['fqdn']} checking in to Puppet Master": }
}

# Dedicated node definition for the sample website host (puppet-agent)
node /puppet-agent.*/, /ip-172-.*/ {
  include apache_website
}
