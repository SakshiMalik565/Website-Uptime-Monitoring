# ==============================================================================
# Standalone Manifest for Direct Verification (puppet apply)
# Usage: sudo puppet apply standalone_apply.pp --modulepath=../modules
# ==============================================================================

# Ensure apache package is installed
package { 'apache2':
  ensure => installed,
}

# Ensure index.html is managed and enforces declared content
file { '/var/www/html/index.html':
  ensure  => file,
  owner   => 'www-data',
  group   => 'www-data',
  mode    => '0644',
  source  => "${facts['puppet_environmentpath']}/modules/apache_website/files/index.html",
  require => Package['apache2'],
  notify  => Service['apache2'],
}

# Ensure apache2 service is enabled and running
service { 'apache2':
  ensure     => running,
  enable     => true,
  hasrestart => true,
  hasstatus  => true,
  require    => Package['apache2'],
}
