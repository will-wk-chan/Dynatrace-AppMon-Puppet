#configure_init_script
define dynatraceappmon::resource::configure_init_script(
  $ensure               = 'present',
  $role_name            = undef,
  $installer_prefix_dir = undef,
  $owner                = undef,
  $group                = undef,
  $init_scripts_params  = {}
) {
  case $::kernel {
    'Linux': {
      case $::osfamily {
        'Debian': {
          $linux_service_start_runlevels = '2 3 4 5'
          $linux_service_stop_runlevels = '0 1 6'
        }
        default: {
          $linux_service_start_runlevels = '3 5'
          $linux_service_stop_runlevels = '0 1 2 6'
        }
      }
    }
  default: {
      fail("Not supported operating system: ${::operatingsystem}")
    }
  }

  case $facts['osfamily'] {
    'RedHat' : {
        if $facts['os']['release']['major'] >= "7" {
          info ("Redhat Major version: ${facts['os']['release']['major']}")
          # Fix for adding a service in linux servers that uses systemd 
          # instead of the old chkconfig (Red Hat 7, latest Centos and ubuntu, etc).
          # https://answers.dynatrace.com/questions/170158/installation-tip-how-to-add-services-for-systemd-b.html?childToView=182667#answer-182667
          $configure_systemd = true
          # set DT_RUNASUSER= for init.d/dynaTraceCollector script
          $dynatrace_runasuser = ''
        }
      }
    default : {
      $configure_systemd = false
      $dynatrace_runasuser = $dynatrace_owner
      }
  }

  $params = delete_undef_values(merge($init_scripts_params, {
    'linux_service_start_runlevels' => $linux_service_start_runlevels,
    'linux_service_stop_runlevels'  => $linux_service_stop_runlevels,
    'user'                          => $dynatrace_runasuser
  }))

  $link_ensure = $ensure ? {
    'present' => 'link',
    'absent'  => 'absent',
    default   => 'link'
  }

  file { "Configure and copy the ${role_name}'s '${name}' init script":
    ensure                  => $ensure,
    selinux_ignore_defaults => true,
    path                    => "${installer_prefix_dir}/dynatrace/init.d/${name}",
    owner                   => $owner,
    group                   => $group,
    mode                    => '0755',
    content                 => template("dynatraceappmon/init.d/${name}.erb"),
    require                 => Dynatrace_installation["Install the ${role_name}"]
  }
  file { "Make the '${name}' init script available in /etc/init.d":
    ensure                  => $link_ensure,
    selinux_ignore_defaults => true,
    mode                    => '0755',
    path                    => "/etc/init.d/${name}",
    target                  => "${installer_prefix_dir}/dynatrace/init.d/${name}",
    require                 => File["Configure and copy the ${role_name}'s '${name}' init script"]
  }

  if $configure_systemd {
    info ("Configure for systemd")
    $service_name = $name ? {
      $dynatraceappmon::dynaTraceCollector => 'dynacollector',
      # TODO add more service name mappings..
      default   => undef,
    }
    if $service_name == undef {
        fail ( "Unable to determine service name." )
    }

    # create systemd service file
    file { "${name}-systemd-service" :
      path    => "/etc/systemd/system/${service_name}.service",
      ensure  => present,
      content => epp("dynatraceappmon/systemd/${service_name}.service.epp"),
    }~>
    exec { "${name}-systemd-reload" :
      command     => '/bin/systemctl daemon-reload',
      refreshonly => true,
    }
  }
}
