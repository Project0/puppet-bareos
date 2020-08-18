# Class: bareos
#
# Authors
# -------
#
# Richard Hillmann <richie@project0.de>
#
class bareos (
  $config_dir       = $::bareos::params::config_dir,
  $config_dir_webui = $::bareos::params::config_dir_webui,
  $file_owner       = $::bareos::params::file_owner,
  $file_group       = $::bareos::params::file_group,
  $file_mode        = $::bareos::params::file_mode,
  $file_dir_mode    = $::bareos::params::file_dir_mode,
  $user_groups      = $::bareos::params::user_groups,
  $repo_release     = $::bareos::params::repo_release,
  $manage_repo      = $::bareos::params::manage_repo,
  $manage_user      = $::bareos::params::manage_user,
  $manage_package   = $::bareos::params::manage_package,
  $manage_service   = $::bareos::params::manage_service,
  $manage_database  = $::bareos::params::manage_database,
  $package_name     = $::bareos::params::package_name, # base/common package only
  $package_ensure   = $::bareos::params::package_ensure,
  $service_ensure   = $::bareos::params::service_ensure,
  $service_enable   = $::bareos::params::service_enable,

  $console_package_name  = $::bareos::params::console_package_name,
  $monitor_package_name  = $::bareos::params::monitor_package_name,
  $director_package_name = $::bareos::params::director_package_name,
  $director_service_name = $::bareos::params::director_service_name,
  $director_managed_dirs = $::bareos::params::director_managed_dirs,
  $client_package_name   = $::bareos::params::client_package_name,
  $client_service_name   = $::bareos::params::client_service_name,
  $storage_package_name  = $::bareos::params::storage_package_name,
  $storage_service_name  = $::bareos::params::storage_service_name,
) inherits ::bareos::params {

  if $manage_repo {
    class {'::bareos::repository':
      release => $repo_release,
    }
  }

  if $manage_package {
    package { $package_name:
      ensure => $package_ensure,
      tag    => ['bareos', 'bareos_core'],
    }
  }

  if $manage_user {
    group { $file_group:
      ensure     => present,
      forcelocal => true,
      system     => true,
      tag        => ['bareos', 'bareos_core'],
    }
    -> user { $file_owner:
      ensure     => present,
      forcelocal => true,
      comment    => 'Bareos system user',
      home       => '/var/lib/bareos',
      shell      => '/bin/false',
      groups     => ['disk', 'tape', $file_group] + $user_groups,
      system     => true,
      tag        => ['bareos', 'bareos_core'],
    }
  }

  file { $config_dir:
    ensure       => directory,
    purge        => true,
    recurse      => true,
    recurselimit => 1,
    mode         => $::bareos::file_dir_mode,
    owner        => $::bareos::file_owner,
    group        => $::bareos::file_group,
    tag          => ['bareos', 'bareos_core'],
  }
}
