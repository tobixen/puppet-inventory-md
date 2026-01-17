# @summary Manages a single inventory-system instance
#
# Creates and configures an inventory-system instance including user, data
# directory, and systemd services.
#
# @param datadir
#   Directory containing inventory data (inventory.md, inventory.json).
#
# @param api_port
#   Port for the inventory API service.
#
# @param api_host
#   Host/IP for the API server to bind to. Default: 127.0.0.1
#
# @param user
#   System user to run the instance as.
#
# @param group
#   System group for the instance.
#
# @param uid_offset
#   Offset to add to base UID/GID (3000). Defaults to random value based on name.
#
# @param anthropic_api_key
#   Optional Anthropic API key for Claude chat functionality.
#
# @param additional_members
#   Users to add to the instance group for collaborative access.
#
# @param use_aur
#   Internal parameter set by main class. True if using AUR package on Arch Linux.
#
# @example Basic instance
#   inventory_md::instance { 'myinventory':
#     datadir  => '/var/www/inventory/myinventory',
#     api_port => 8765,
#   }
#
define inventory_md::instance (
  Stdlib::Absolutepath $datadir,
  Integer[1024, 65535] $api_port      = 8765,
  String $api_host                    = '127.0.0.1',
  String $user                        = "inventory-${name}",
  String $group                       = "inventory-${name}",
  Integer[0, 690] $uid_offset         = fqdn_rand(690, $name),
  Optional[String] $anthropic_api_key = undef,
  Array[String] $additional_members   = [],
  Boolean $use_aur                    = false,
) {
  # Create user and group for this instance
  if !defined(Group[$group]) {
    group { $group:
      gid     => 3000 + $uid_offset,
      members => $additional_members,
    }
  }

  if !defined(User[$user]) {
    user { $user:
      uid     => 3000 + $uid_offset,
      gid     => $group,
      comment => "Inventory system user for ${name}",
      home    => $datadir,
      shell   => '/bin/bash',
      require => Group[$group],
    }
  }

  # Ensure data directory exists and has correct permissions
  file { $datadir:
    ensure  => 'directory',
    owner   => $user,
    group   => $group,
    mode    => '2775',  # Setgid + group write for collaboration
    require => User[$user],
  }

  # Create configuration file
  file { "/etc/inventory-system/${name}.conf":
    ensure  => 'file',
    mode    => '0640',
    owner   => 'root',
    group   => $group,
    content => epp('inventory_md/instance.conf.epp', {
      'name'              => $name,
      'datadir'           => $datadir,
      'api_port'          => $api_port,
      'api_host'          => $api_host,
      'anthropic_api_key' => $anthropic_api_key,
    }),
    require => File['/etc/inventory-system'],
    notify  => Service["inventory-api@${name}"],
  }

  # Enable and start API service
  # Dependencies differ based on installation method
  if $use_aur {
    # AUR package includes systemd service files
    service { "inventory-api@${name}":
      ensure  => running,
      enable  => true,
      require => [
        Aur['inventory-md'],
        File["/etc/inventory-system/${name}.conf"],
        File[$datadir],
      ],
    }
  } else {
    # Pip installation - we manage the systemd service file
    service { "inventory-api@${name}":
      ensure  => running,
      enable  => true,
      require => [
        File['/etc/systemd/system/inventory-api@.service'],
        File["/etc/inventory-system/${name}.conf"],
        File[$datadir],
        Package['inventory-md'],
      ],
    }
  }
}
