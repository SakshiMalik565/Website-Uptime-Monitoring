# @summary Manages service state for Apache HTTP Server
#
class apache_website::service {
  service { 'apache2':
    ensure     => running,
    enable     => true,
    hasrestart => true,
    hasstatus  => true,
    require    => Class['apache_website::install'],
  }
}
