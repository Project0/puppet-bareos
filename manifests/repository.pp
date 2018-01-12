# == Class: bareos::repository
# This class manages the bareos repository
# Parameters should be configured in the upper class `::bareos`.
#
# This class will be automatically included when a resource is defined.
# It is not intended to be used directly by external resources like node definitions or other modules.
class bareos::repository(
  $release = 'latest',
  $repo_avail_release = undef,
  $manage_repo_release = undef,
) {

  $url = "http://download.bareos.org/bareos/release/${release}/"

  $os = $::operatingsystem
  $osrelease = $::operatingsystemrelease
  if defined('$::operatingsystemmajrelease') {
    $osmajrelease = $::operatingsystemmajrelease
  } else {
    $osmajrelease = split($osrelease, '.')
  }

  # Internal repositories, no other checks
  if ( $os == 'Gentoo' ) {
    # bareos is not yet stable, we need to keyword it
    # latest version available is 16.2
    $internal_repository = true

    if ($release == 'latest' or $release > '16.2' ) {
      $gentoorelease = '16.2'
    } else {
      $gentoorelease = '15.2'
    }

    portage::package {'app-backup/bareos':
      ensure           => present,
      target           => 'puppet-bareos',
      keywords         => ['~amd64', '~x86'],
      keywords_version => "=${gentoorelease}*",
    }
  }

  # Bareos repositories
  # bareos name convention make use of major version for most distribution, while make use of full version for Ubuntu. Checking both.
  if ( $internal_repository != true ) and ( $os != undef and $osrelease != undef and $osmajrelease != undef ) and
    ( $release in $repo_avail_release[$os][$osmajrelease] or $release in $repo_avail_release[$os][$osrelease] ) and
    ( ( $manage_repo_release == undef ) or ( 'all' in $manage_repo_release[$os] or $osmajrelease in $manage_repo_release[$os] or $osrelease in $manage_repo_release[$os] ) ) {
    case $os {
        /(?i:redhat|centos|fedora)/: {
          case $os {
            'RedHat': {
              $location = "${url}RHEL_${osmajrelease}"
            }
            'Centos': {
              $location = "${url}CentOS_${osmajrelease}"
            }
            'Fedora': {
              $location = "${url}Fedora_${osmajrelease}"
            }
            default: {
              fail('Operatingsystem is not supported by this module')
            }
          }
          yumrepo { 'bareos':
            name     => 'bareos',
            baseurl  => $location,
            gpgcheck => '1',
            gpgkey   => "${location}repodata/repomd.xml.key",
            priority => '1',
          }
      }
      /(?i:debian|ubuntu)/: {
        if $os  == 'Ubuntu' {
          $location = "${url}xUbuntu_${osrelease}"
        } else {
          $location = "${url}Debian_${osmajrelease}.0"
        }
        include ::apt
        ::apt::source { 'bareos':
          location => $location,
          release  => '/',
          repos    => '',
          key      => {
            id     => '0143857D9CE8C2D182FE2631F93C028C093BFBA2',
            source => "${location}/Release.key",
          },
        }
        Apt::Source['bareos'] -> Package<|tag == 'bareos'|>
        Class['Apt::Update']  -> Package<|tag == 'bareos'|>
      }
      default: {
        fail('Operatingsystem is not supported by this module')
      }
    }
  }
}
