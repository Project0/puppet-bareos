# == Class: bareos::repository
#
# @summary
#   This class manages the bareos repository
#   Parameters should be configured in the upper class `::bareos`.
#
#   This class will be automatically included when a resource is defined.
#   It is not intended to be used directly by external resources like node definitions or other modules.
#
# @param release
#   The major bareos release version which should be used
# @param gpg_key_fingerprint
#   The GPG fingerprint of the repos key
# @param subscription
#   Activate the (paid) subscription repo. Otherwise the opensource repos will be selected
# @param username
#   The major bareos release version which should be used
# @param password
#   The major bareos release version which should be used
# @param https
#   Wether or not https should be used in repo URL
#
class bareos::repository (
  String              $release             = 'latest',
  Optional[String[1]] $gpg_key_fingerprint = undef,
  Boolean             $subscription        = false,
  Optional[String]    $username            = undef,
  Optional[String]    $password            = undef,
  Boolean             $https               = true,
) {
  if $https {
    $scheme = 'https://'
  } else {
    $scheme = 'http://'
  }
  if $subscription {
    if empty($username) or empty($password) {
      fail('For Bareos subscription repos both username and password are required.')
    }
    # note the .com
    $address = "download.bareos.com/bareos/release/${release}/"
  } else {
    $address = "download.bareos.org/bareos/release/${release}/"
  }

  $os = $facts['os']['name']
  $osrelease = $facts['os']['release']['full']
  $osmajrelease = $facts['os']['release']['major']

  if $gpg_key_fingerprint {
    $_gpg_key_fingerprint = $gpg_key_fingerprint
  } elsif $release == 'latest' or versioncmp($release, '18.2') >= 0 {
    # >= bareos-18.2
    if $subscription {
      $_gpg_key_fingerprint = '641A 1497 F1B1 1BEA 945F 840F E5D8 82B2 8657 AE28'
    } else {
      $_gpg_key_fingerprint = 'A0CF E15F 71F7 9857 4AB3 63DD 1182 83D9 A786 2CEE'
    }
  } else {
    # >= bareos-15.2
    $_gpg_key_fingerprint = '0143 857D 9CE8 C2D1 82FE 2631 F93C 028C 093B FBA2'
  }

  $yum_username = $username ? {
    undef   => 'absent',
    default => $username,
  }
  $yum_password = $password ? {
    undef   => 'absent',
    default => $password,
  }

  case $os {
    /(?i:redhat|centos|fedora|virtuozzolinux|amazon)/: {
      $url = "${scheme}${address}"
      case $os {
        'RedHat', 'VirtuozzoLinux': {
          $location = "${url}RHEL_${osmajrelease}"
        }
        'Centos': {
          $location = "${url}CentOS_${osmajrelease}"
        }
        'Fedora': {
          $location = "${url}Fedora_${osmajrelease}"
        }
        'Amazon': {
          case $osmajrelease {
            '2': {
              $location = "${url}RHEL_7"
            }
            default: {
              fail('Operatingsystem is not supported by this module')
            }
          }
        }
        default: {
          fail('Operatingsystem is not supported by this module')
        }
      }
      yumrepo { 'bareos':
        name     => 'bareos',
        descr    => 'Bareos Repository',
        username => $yum_username,
        password => $yum_password,
        baseurl  => $location,
        gpgcheck => '1',
        gpgkey   => "${location}/repodata/repomd.xml.key",
        priority => '1',
      }
    }
    /(?i:debian|ubuntu)/: {
      if $subscription {
        $url = "${scheme}${username}:${password}@${address}"
      } else {
        $url = "${scheme}${address}"
      }
      if $os  == 'Ubuntu' {
        unless $osrelease in ['12.04', '14.04', '16.04', '18.04'] {
          fail('Only Ubunutu LTS Versions are supported')
        }
        $location = "${url}xUbuntu_${osrelease}"
      } else {
        if $osmajrelease == '10' {
          $location = "${url}Debian_${osmajrelease}"
        } else {
          $location = "${url}Debian_${osmajrelease}.0"
        }
      }
      if $subscription {
        # release key file is not avaiable without login and
        # apt-key cannot handle username and password in URI
        $key = {
          id => regsubst($_gpg_key_fingerprint, ' ', '', 'G'),
        }
      } else {
        $key = {
          id     => regsubst($_gpg_key_fingerprint, ' ', '', 'G'),
          source => "${location}/Release.key",
        }
      }

      include apt
      ::apt::source { 'bareos':
        location => $location,
        release  => '/',
        repos    => '',
        key      => $key,
      }
      Apt::Source['bareos'] -> Package<|tag == 'bareos'|>
      Class['Apt::Update']  -> Package<|tag == 'bareos'|>
    }
    default: {
      fail('Operatingsystem is not supported by this module')
    }
  }
}
