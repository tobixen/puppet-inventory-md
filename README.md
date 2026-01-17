# inventory_md

A Puppet module for deploying [inventory-md](https://github.com/tobixen/inventory-md) instances for tracking home inventories.

## Description

This module installs and configures the inventory-md application, a Python-based tool for maintaining home inventories with an API server for web access and optional Claude AI chat integration.

Features:
- Installs inventory-md from PyPI using pip
- Creates systemd services for API endpoints
- Supports multiple inventory instances on the same host
- Optional Anthropic API key integration for AI-powered chat

## Requirements

- Puppet 7.0 or later
- Supported operating systems:
  - Ubuntu 20.04/22.04/24.04
  - Debian 11/12
  - RHEL/CentOS/Rocky/Alma 8/9
  - Fedora
  - Arch Linux
- Python 3 with pip (for non-Arch systems)

## Dependencies

- [puppetlabs/stdlib](https://forge.puppet.com/modules/puppetlabs/stdlib) >= 8.0.0
- [puppet-aur](https://forge.puppet.com/modules/lfaucheux/aur) (optional, for Arch Linux AUR support)

On Arch Linux, if the puppet-aur module is available, the module automatically installs from AUR instead of PyPI.

## Usage

### Basic usage

```puppet
class { 'inventory_md':
  instances => {
    'home' => {
      datadir  => '/var/www/inventory/home',
      api_port => 8765,
    },
  },
}
```

### With Anthropic API key for Claude chat

```puppet
class { 'inventory_md':
  anthropic_api_key => lookup('inventory_md::anthropic_api_key'),
  instances         => {
    'home' => {
      datadir  => '/var/www/inventory/home',
      api_port => 8765,
    },
    'cabin' => {
      datadir  => '/var/www/inventory/cabin',
      api_port => 8766,
    },
  },
}
```

### Exposing to LAN

```puppet
class { 'inventory_md':
  instances => {
    'home' => {
      datadir  => '/var/www/inventory/home',
      api_port => 8765,
      api_host => '0.0.0.0',  # Listen on all interfaces
    },
  },
}
```

### Hiera example

```yaml
inventory_md::anthropic_api_key: ENC[PKCS7,...]
inventory_md::instances:
  home:
    datadir: /var/www/inventory/home
    api_port: 8765
    api_host: '127.0.0.1'
    additional_members:
      - alice
      - bob
  cabin:
    datadir: /var/www/inventory/cabin
    api_port: 8766
```

### Class parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `instances` | Hash | {} | Hash of instances to create |
| `anthropic_api_key` | Optional[String] | undef | API key for Claude chat |
| `package_ensure` | String | 'present' | Version or present/latest |
| `pip_extras` | Array[String] | ['chat'] | Pip extras to install |

### Instance parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `datadir` | Stdlib::Absolutepath | *required* | Directory for inventory data |
| `api_port` | Integer[1024,65535] | 8765 | Port for API server |
| `api_host` | String | '127.0.0.1' | Host/IP to bind to |
| `user` | String | `inventory-$name` | System user |
| `group` | String | `inventory-$name` | System group |
| `additional_members` | Array[String] | [] | Users to add to instance group |

## Web server proxy configuration

The API server listens on localhost by default. To make it accessible from the web, configure
your web server (nginx/Apache) to proxy requests. This module does **not** manage
web server configuration because:
- SSL certificate paths vary (Let's Encrypt, manual certs, etc.)
- Authentication requirements differ per deployment
- Web server configs often have site-specific customizations

### nginx example

```nginx
server {
    listen 443 ssl;
    server_name inventory.example.com;

    # SSL (configure separately, e.g., with certbot)
    ssl_certificate /etc/letsencrypt/live/inventory.example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/inventory.example.com/privkey.pem;

    # Static files from datadir
    root /var/www/inventory/home;
    index search.html;

    # Proxy API requests to inventory-api service
    location /api/ {
        proxy_pass http://127.0.0.1:8765/api/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    location /chat {
        proxy_pass http://127.0.0.1:8765/chat;
        proxy_read_timeout 120s;
    }

    location /health {
        proxy_pass http://127.0.0.1:8765/health;
    }

    # Authentication (recommended)
    auth_basic "Inventory";
    auth_basic_user_file /etc/nginx/.htpasswd;
}
```

### Apache example

```apache
<VirtualHost *:443>
    ServerName inventory.example.com
    DocumentRoot /var/www/inventory/home

    # Proxy to API
    ProxyPass /api/ http://127.0.0.1:8765/api/
    ProxyPassReverse /api/ http://127.0.0.1:8765/api/
    ProxyPass /chat http://127.0.0.1:8765/chat
    ProxyPassReverse /chat http://127.0.0.1:8765/chat
    ProxyPass /health http://127.0.0.1:8765/health
    ProxyPassReverse /health http://127.0.0.1:8765/health
</VirtualHost>
```

For detailed configuration including SSL setup and authentication, see the
[inventory-md installation guide](https://github.com/tobixen/inventory-md/blob/main/docs/INSTALLATION.md).

## Development

Run tests:
```bash
bundle install
bundle exec rake spec
bundle exec rake lint
```

## License

Apache-2.0

## Author

Tobias Brox (tobixen)
