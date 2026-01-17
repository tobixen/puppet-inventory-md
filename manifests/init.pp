# @summary Manages installation and configuration of inventory-system instances
#
# This class installs the inventory-system application and manages multiple
# instances for tracking home inventories.
#
# @param instances
#   Hash of inventory instances to create. Each key is the instance name,
#   and the value is a hash of parameters for inventory_md::instance.
#
# @param anthropic_api_key
#   Optional Anthropic API key for Claude chat functionality.
#
# @param package_ensure
#   Version or 'present'/'latest' for the pip package.
#
# @param pip_extras
#   Pip extras to install, e.g., ['chat', 'barcode']. Default: ['chat']
#   Only used when installing from PyPI (non-Arch systems).
#
# @example Basic usage
#   class { 'inventory_md':
#     anthropic_api_key => 'sk-ant-...',
#     instances         => {
#       'home' => {
#         datadir  => '/var/www/inventory/home',
#         api_port => 8765,
#       },
#     },
#   }
#
class inventory_md (
  Hash $instances                    = {},
  Optional[String] $anthropic_api_key = undef,
  String $package_ensure             = 'present',
  Array[String] $pip_extras          = ['chat'],
) {
  # Determine installation method based on OS and available modules
  # On Arch Linux with puppet-aur module available, use AUR package
  # Otherwise, install from PyPI using pip
  $os_name = $facts.dig('os', 'name')
  $use_aur = ($os_name == 'Archlinux') and defined('aur')

  if $use_aur {
    # Install from AUR - includes systemd services
    aur { 'inventory-md':
      ensure => $package_ensure,
    }
  } else {
    # Build package name with extras for pip
    $extras_str = $pip_extras.empty ? {
      true  => '',
      false => "[${pip_extras.join(',')}]",
    }
    $package_name = "inventory-md${extras_str}"

    # Install inventory-md from PyPI
    package { 'inventory-md':
      ensure   => $package_ensure,
      name     => $package_name,
      provider => pip3,
    }
  }

  # Create configuration directory
  file { '/etc/inventory-system':
    ensure => 'directory',
    mode   => '0755',
  }

  # For pip installations, we need to manage systemd template services
  # AUR package includes its own systemd files
  if !$use_aur {
    file {
      default:
        require => Package['inventory-md'],
        notify  => Exec['systemd-daemon-reload'];
      '/etc/systemd/system/inventory-api@.service':
        ensure  => 'file',
        mode    => '0644',
        content => epp('inventory_md/inventory-api@.service.epp');
      '/etc/systemd/system/inventory-web@.service':
        ensure  => 'file',
        mode    => '0644',
        content => epp('inventory_md/inventory-web@.service.epp');
    }

    # Reload systemd when unit files change
    exec { 'systemd-daemon-reload':
      command     => '/usr/bin/systemctl daemon-reload',
      refreshonly => true,
    }
  }

  # Create instances from parameters
  $instances.each |String $name, Hash $params| {
    inventory_md::instance { $name:
      anthropic_api_key => $anthropic_api_key,
      use_aur           => $use_aur,
      *                 => $params,
    }
  }
}
