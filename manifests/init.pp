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
# @param source_repo
#   Git repository URL to clone inventory-system from.
#
# @param source_revision
#   Git revision (branch/tag) to checkout.
#
# @param install_dir
#   Directory to install inventory-system to.
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
  Hash $instances                                        = {},
  Optional[String] $anthropic_api_key                    = undef,
  String $source_repo                                    = 'https://github.com/tobixen/inventory-system.git',
  String $source_revision                                = 'main',
  Stdlib::Absolutepath $install_dir                      = '/opt/inventory-md',
) {
  # Ensure required packages
  stdlib::ensure_packages(['python3-pip', 'python3-venv', 'git', 'make'])

  # Install inventory-system from git repository
  vcsrepo { $install_dir:
    ensure   => latest,
    provider => git,
    source   => $source_repo,
    revision => $source_revision,
  }

  # Create Python virtual environment and install inventory-system
  exec { 'install-inventory-system':
    command     => "/usr/bin/make -C ${install_dir} install",
    refreshonly => true,
    subscribe   => Vcsrepo[$install_dir],
    require     => [Package['python3-venv'], Package['make']],
  }

  # Initial installation (runs only once)
  exec { 'initial-install-inventory-system':
    command => "/usr/bin/make -C ${install_dir} install",
    creates => "${install_dir}/venv/bin/inventory-md",
    require => [Package['python3-venv'], Package['make'], Vcsrepo[$install_dir]],
  }

  # Create base directories
  file { '/etc/inventory-system':
    ensure => 'directory',
    mode   => '0755',
  }

  # Install systemd template services via symlinks
  file {
    default:
      require => Vcsrepo[$install_dir],
      notify  => Exec['systemd-daemon-reload'];
    '/etc/systemd/system/inventory-api@.service':
      ensure => 'link',
      target => "${install_dir}/systemd/inventory-api@.service";
    '/etc/systemd/system/inventory-web@.service':
      ensure => 'link',
      target => "${install_dir}/systemd/inventory-web@.service";
  }

  # Reload systemd when unit files change
  exec { 'systemd-daemon-reload':
    command     => '/usr/bin/systemctl daemon-reload',
    refreshonly => true,
  }

  # Create instances from parameters, passing down anthropic_api_key
  $instances.each |String $name, Hash $params| {
    inventory_md::instance { $name:
      anthropic_api_key => $anthropic_api_key,
      install_dir       => $install_dir,
      *                 => $params,
    }
  }
}
