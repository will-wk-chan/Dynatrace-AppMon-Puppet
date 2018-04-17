#host_agent
class dynatraceappmon::role::host_agent (
  $ensure               = 'present',
  $role_name            = 'Dynatrace Host Agent',

  $host_installer_prefix_dir = $dynatraceappmon::host_agent_installer_prefix_dir,

  #Host Agent is installed with server; agents_package should be executed first to install configuration files

  # host_installer_file_name parameter for future useage
  $host_installer_file_name  = $dynatraceappmon::host_agent_installer_file_name,
  # host_installer_file_url parameter for future useage
  $host_installer_file_url   = $dynatraceappmon::host_agent_installer_file_url,

  $host_agent_name      = $dynatraceappmon::host_agent_name,
  $host_collector_name  = $dynatraceappmon::host_agent_collector_name,

  $dynatrace_owner      = $dynatraceappmon::dynatrace_owner,
  $dynatrace_group      = $dynatraceappmon::dynatrace_group

) inherits dynatraceappmon {

#  include dynatraceappmon::role::agents_package

  validate_re($ensure, ['^present$', '^absent$'])
  validate_string($host_agent_name, $host_collector_name)

  case $::kernel {
    'Linux': {
      $service = $dynatraceappmon::dynatrace_host_agent
      $ini_file = "${host_installer_prefix_dir}/dynatrace/agent/conf/dthostagent.ini"
      $init_scripts = [$service]
    }
    default: {}
  }

  file { $ini_file :
    ensure => file,
  }

  $service_ensure = $ensure ? {
    'present' => 'running',
    'absent'  => 'stopped',
    default   => 'running',
  }

  $installer_cache_dir = "${settings::vardir}/dynatrace"
  $installer_cache_dir_tree = dirtree($installer_cache_dir)

  include dynatraceappmon::role::dynatrace_user

  file_line { "Inject the Host Agent name '${host_agent_name}' into '${ini_file}'":
    ensure => $ensure,
    path   => $ini_file,
    line   => "Name ${host_agent_name}",
    match  => '^Name .*$'
  }

  file_line { "Inject the collector name '${host_collector_name}' into '${ini_file}'":
    ensure => $ensure,
    path   => $ini_file,
    line   => "Server ${host_collector_name}",
    match  => '^Server .*$'
  }

  # ln -s /opt/dynatrace/init.d/dynaTraceHostagent /etc/init.d/dynaTraceHostagent
  exec {"Creates link to execute service  ln -s ${host_installer_prefix_dir}/dynatrace/init.d/dynaTraceHostagent /etc/init.d/${service}":
    command => "ln -s ${host_installer_prefix_dir}/dynatrace/init.d/dynaTraceHostagent /etc/init.d/${service}",
    path    => ['/usr/bin', '/usr/sbin', '/bin'],
    unless  => ["test -L /etc/init.d/${service}"],
  }
  # hack to ensure start service (enable and stop service then start it)
  -> service { "Enable and stop the ${role_name}'s service: '${service}'":
    ensure => running,
    name   => $service,
    enable => true
  }
}
