# @summary Manages a single inventory-system instance
#
# Creates and configures an inventory-system instance including user, data
# directory, systemd services, and optional git repository for version control.
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
# @param manage_git
#   Whether to set up git repository for the inventory data. Default: true
#
# @param git_bare_repo
#   Path to the bare git repository used for pushing changes.
#   Default: /var/lib/inventory-system/${name}.git
#
# @param git_remote
#   Optional remote URL to configure for syncing between hosts.
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
# @example Instance with remote sync
#   inventory_md::instance { 'myinventory':
#     datadir    => '/var/www/inventory/myinventory',
#     api_port   => 8765,
#     git_remote => 'git@github.com:user/inventory-data.git',
#   }
#
define inventory_md::instance (
  Stdlib::Absolutepath $datadir,
  Integer[1024, 65535] $api_port               = 8765,
  String $api_host                             = '127.0.0.1',
  String $user                                 = "inventory-${name}",
  String $group                                = "inventory-${name}",
  Integer[0, 690] $uid_offset                  = fqdn_rand(690, $name),
  Optional[String] $anthropic_api_key          = undef,
  Array[String] $additional_members            = [],
  Boolean $manage_git                          = true,
  Stdlib::Absolutepath $git_bare_repo          = "/var/lib/inventory-system/${name}.git",
  Optional[String] $git_remote                 = undef,
  Boolean $use_aur                             = false,
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

  # Git repository management
  if $manage_git {
    # Ensure parent directory for bare repos exists
    if !defined(File['/var/lib/inventory-system']) {
      file { '/var/lib/inventory-system':
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
      }
    }

    # Get parent directory of bare repo for custom paths
    $git_bare_repo_parent = dirname($git_bare_repo)
    if $git_bare_repo_parent != '/var/lib/inventory-system' and !defined(File[$git_bare_repo_parent]) {
      file { $git_bare_repo_parent:
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        before => Exec["git-init-bare-${name}"],
      }
    }

    # Create bare git repository for receiving pushes
    exec { "git-init-bare-${name}":
      command => "/usr/bin/git init --bare ${git_bare_repo}",
      creates => "${git_bare_repo}/config",
      require => File['/var/lib/inventory-system'],
    }

    # Set ownership of bare repo
    exec { "chown-bare-repo-${name}":
      command     => "/usr/bin/chown -R ${user}:${group} ${git_bare_repo}",
      refreshonly => true,
      subscribe   => Exec["git-init-bare-${name}"],
    }

    # Post-receive hook to update working directory after push
    file { "${git_bare_repo}/hooks/post-receive":
      ensure  => 'file',
      owner   => $user,
      group   => $group,
      mode    => '0755',
      content => epp('inventory_md/post-receive.epp', {
        'datadir' => $datadir,
        'user'    => $user,
      }),
      require => Exec["git-init-bare-${name}"],
    }

    # Initialize git in the data directory
    exec { "git-init-datadir-${name}":
      command => "/usr/bin/git init",
      cwd     => $datadir,
      creates => "${datadir}/.git",
      user    => $user,
      require => File[$datadir],
    }

    # Configure git user for commits
    exec { "git-config-user-${name}":
      command => "/usr/bin/git config user.name 'Inventory System' && /usr/bin/git config user.email 'inventory@localhost'",
      cwd     => $datadir,
      unless  => "/usr/bin/git config user.name",
      user    => $user,
      require => Exec["git-init-datadir-${name}"],
    }

    # Add bare repo as remote 'local' for pushing
    exec { "git-add-local-remote-${name}":
      command => "/usr/bin/git remote add local ${git_bare_repo}",
      cwd     => $datadir,
      unless  => "/usr/bin/git remote | /usr/bin/grep -q '^local$'",
      user    => $user,
      require => [Exec["git-init-datadir-${name}"], Exec["git-init-bare-${name}"]],
    }

    # Optionally configure external remote for syncing
    if $git_remote {
      exec { "git-add-origin-remote-${name}":
        command => "/usr/bin/git remote add origin ${git_remote}",
        cwd     => $datadir,
        unless  => "/usr/bin/git remote | /usr/bin/grep -q '^origin$'",
        user    => $user,
        require => Exec["git-init-datadir-${name}"],
      }
    }
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
