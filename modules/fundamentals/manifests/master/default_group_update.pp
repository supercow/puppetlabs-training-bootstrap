# CLASS: fundamentals::master::default_group_update
#
# This class adds an incron task to watch for changes to the puppet cert directory
#
# Upon detecting a new certificate, the incron task will trigger an update to
# ensure that all nodes are in the default group. This will cause new nodes to
# show up immediately, as opposed to waiting for the default 2 minute interval
# before nodes are added.
#
# incrond is a cron-like service that triggers jobs based on changes to the
# filesystem.
class fundamentals::master::default_group_update {

  $incron_conditions = "${settings::ssldir}/certs IN_CREATE"
  $rake_command = "/opt/puppet/bin/rake -f /opt/puppet/share/puppet-dashboard/Rakefile RAILS_ENV=production"
  $update_task = "nodegroup:add_all_nodes['default']"
  $update_command = "${rake_command} ${update_task}"

  package { 'incron':
    ensure => present,
  }

  file { '/etc/incron.d/default_group_update':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0744',
    content => "${incron_conditions} ${update_command}",
    require => Package['incron'],
  }

  service { 'incrond':
    ensure  => running,
    enable  => true,
    require => Package['incron'],
  }
}

