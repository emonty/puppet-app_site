# == Class: app_site
#
class app_site (
  $vhost_name = $::fqdn,
  $root_dir = "/opt/app_site",
  $commit = 'master',
  $ssl_cert_file = "/etc/ssl/certs/${::fqdn}.pem",
  $ssl_key_file = "/etc/ssl/private/${::fqdn}.key",
  $ssl_chain_file = '',
  $ssl_cert_file_contents = '', # If left empty puppet will not create file.
  $ssl_key_file_contents = '',  # If left empty puppet will not create file.
  $ssl_chain_file_contents = '' # If left empty puppet will not create file.
) {

  if !defined(Package['git']) {
    package { 'git':
      ensure => present
    }
  }

  if $ssl_cert_file_contents != '' {
    file { $ssl_cert_file:
      owner   => 'root',
      group   => 'root',
      mode    => '0640',
      content => $ssl_cert_file_contents,
      before  => Apache::Vhost[$vhost_name],
    }
  }

  if $ssl_key_file_contents != '' {
    file { $ssl_key_file:
      owner   => 'root',
      group   => 'ssl-cert',
      mode    => '0640',
      content => $ssl_key_file_contents,
      before  => Apache::Vhost[$vhost_name],
    }
  }

  if $ssl_chain_file_contents != '' {
    file { $ssl_chain_file:
      owner   => 'root',
      group   => 'root',
      mode    => '0640',
      content => $ssl_chain_file_contents,
      before  => Apache::Vhost[$vhost_name],
    }
  }

  vcsrepo { "${root_dir}":
    ensure   => latest,
    provider => git,
    revision => $commit,
    source   => "https://git.openstack.org/stackforge/app_site.git",
    require  => [
      Package['git'],
    ]
  }

  include apache
  a2mod { 'rewrite':
    ensure => present,
  }

  apache::vhost { $vhost_name:
    port     => 443,
    docroot  => "${root_dir}",
    priority => '50',
    template => "app_site/vhost.erb",
    ssl      => true,
  }

}
