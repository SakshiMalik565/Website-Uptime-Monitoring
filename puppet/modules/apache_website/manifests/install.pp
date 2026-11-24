# @summary Manages package installation for Apache HTTP Server
#
class apache_website::install {
  package { 'apache2':
    ensure => installed,
  }
}
