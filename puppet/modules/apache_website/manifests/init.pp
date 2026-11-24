# @summary Orchestrates the installation, configuration, and service enforcement for Apache HTTP Server
#
# Aligned with INT333: DevOps Advance Configuration Management
#
class apache_website {
  contain apache_website::install
  contain apache_website::config
  contain apache_website::service

  Class['apache_website::install']
  -> Class['apache_website::config']
  ~> Class['apache_website::service']
}
