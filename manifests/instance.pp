# @summary Manages a single inventory-system instance
#
# Creates and configures an inventory-system instance including user, data
# directory, git workflow, and systemd services.
#
# @param datadir
#   Directory containing inventory data (inventory.md, inventory.json).
#
# @param api_port
#   Port for the inventory API service.
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
# @param git_bare_repo
#   Path to the bare git repository for the git push workflow.
#
# @param install_dir
#   Directory where inventory-system is installed.
#
# @example Basic instance
#   inventory_md::instance { 'myinventory':
#     datadir  => '/var/www/inventory/myinventory',
#     api_port => 8765,
#   }
#
define inventory_md::instance (
  Stdlib::Absolutepath $datadir,
  Integer[1024, 65535] $api_port                         = 8765,
  String $user                                           = "inventory-${name}",
  String $group                                          = "inventory-${name}",
  Integer[0, 690] $uid_offset                            = fqdn_rand(690, $name),
  Optional[String] $anthropic_api_key                    = undef,
  Array[String] $additional_members                      = [],
  Stdlib::Absolutepath $git_bare_repo                    = "/var/lib/inventory-system/${name}.git",
  Stdlib::Absolutepath $install_dir                      = '/opt/inventory-system',
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
      'anthropic_api_key' => $anthropic_api_key,
    }),
    require => File['/etc/inventory-system'],
  }

  # Enable and start API service
  service { "inventory-api@${name}":
    ensure    => running,
    enable    => true,
    require   => [
      File['/etc/systemd/system/inventory-api@.service'],
      File["/etc/inventory-system/${name}.conf"],
      File[$datadir],
    ],
    subscribe => Vcsrepo[$install_dir],
  }

  # Git workflow setup
  # Create parent directory for bare repos
  if !defined(File['/var/lib/inventory-system']) {
    file { '/var/lib/inventory-system':
      ensure => directory,
      mode   => '0755',
    }
  }

  # Create bare repository
  exec { "git-init-bare-${name}":
    command => "/usr/bin/git init --bare --shared=group ${git_bare_repo}",
    creates => "${git_bare_repo}/config",
    require => File['/var/lib/inventory-system'],
  }

  # Set ownership of bare repo
  exec { "git-bare-chown-${name}":
    command => "/usr/bin/chgrp -R ${group} ${git_bare_repo} && /usr/bin/chmod -R g+w ${git_bare_repo}",
    unless  => "/usr/bin/test -d ${git_bare_repo} && /usr/bin/test \"\$(stat -c %G ${git_bare_repo})\" = \"${group}\"",
    require => [Exec["git-init-bare-${name}"], Group[$group]],
  }

  # Install post-receive hook
  file { "${git_bare_repo}/hooks/post-receive":
    ensure  => file,
    content => epp('inventory_md/post-receive.epp', {
      'name'        => $name,
      'datadir'     => $datadir,
      'install_dir' => $install_dir,
    }),
    mode    => '0755',
    require => Exec["git-init-bare-${name}"],
  }

  # Initialize git in production directory
  exec { "git-init-prod-${name}":
    command => '/usr/bin/git init',
    cwd     => $datadir,
    creates => "${datadir}/.git/config",
    user    => $user,
    require => File[$datadir],
  }

  # Add remote to production directory
  exec { "git-add-remote-${name}":
    command => "/usr/bin/git remote add origin ${git_bare_repo} || /usr/bin/git remote set-url origin ${git_bare_repo}",
    cwd     => $datadir,
    unless  => "/usr/bin/git -C ${datadir} remote get-url origin 2>/dev/null | /usr/bin/grep -q ${git_bare_repo}",
    user    => $user,
    require => [Exec["git-init-prod-${name}"], Exec["git-init-bare-${name}"]],
  }
}
