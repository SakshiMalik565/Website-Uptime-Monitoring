# @summary Deploys the static index.html website file and enforces desired configuration state
#
class apache_website::config {
  file { '/var/www/html/index.html':
    ensure  => file,
    owner   => 'www-data',
    group   => 'www-data',
    mode    => '0644',
    source  => 'puppet:///modules/apache_website/index.html',
    require => Class['apache_website::install'],
    notify  => Class['apache_website::service'],
  }
}
