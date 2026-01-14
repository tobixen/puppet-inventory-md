# inventory_md

A Puppet module for deploying [inventory-system](https://github.com/tobixen/inventory-md) instances for tracking home inventories.

## Description

This module installs and configures the inventory-system application, a Python-based tool for maintaining home inventories with an API server for web access and optional Claude AI chat integration.

Features:
- Installs inventory-system from git with Python virtual environment
- Creates systemd services for API endpoints
- Supports multiple inventory instances on the same host
- Git-based workflow with bare repositories and auto-deploy hooks
- Optional Anthropic API key integration for AI-powered chat

## Requirements

- Puppet 7.0 or later
- Ubuntu 20.04/22.04/24.04 or Debian 11/12
- Python 3 with venv support
- Git

## Dependencies

- [puppetlabs/stdlib](https://forge.puppet.com/modules/puppetlabs/stdlib) >= 8.0.0
- [puppetlabs/vcsrepo](https://forge.puppet.com/modules/puppetlabs/vcsrepo) >= 5.0.0

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

### Hiera example

```yaml
inventory_md::anthropic_api_key: ENC[PKCS7,...]
inventory_md::instances:
  home:
    datadir: /var/www/inventory/home
    api_port: 8765
    additional_members:
      - alice
      - bob
  cabin:
    datadir: /var/www/inventory/cabin
    api_port: 8766
```

### Instance parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `datadir` | Stdlib::Absolutepath | *required* | Directory for inventory data |
| `api_port` | Integer[1024,65535] | 8765 | Port for API server |
| `api_host` | String | `127.0.0.1` | Host to bind API server (use `0.0.0.0` for LAN) |
| `user` | String | `inventory-$name` | System user |
| `group` | String | `inventory-$name` | System group |
| `additional_members` | Array[String] | [] | Users to add to instance group |
| `git_bare_repo` | Stdlib::Absolutepath | `/var/lib/inventory-system/$name.git` | Bare repo for git workflow |

## Git workflow

Each instance sets up a git workflow:
1. A bare repository at `git_bare_repo`
2. A working directory at `datadir`
3. A post-receive hook that auto-deploys on push

Push changes from your laptop:
```bash
git remote add server user@server:/var/lib/inventory-system/home.git
git push server main
```

## What this module does NOT handle

- Web server configuration (nginx/Apache) - set up separately
- SSL/TLS certificates
- Authentication (basic auth, OAuth, etc.)
- The actual inventory data (inventory.md)
- Photo storage and synchronization
- DNS configuration
- Firewall rules

## Web server proxy configuration

The API server listens on `127.0.0.1` (localhost) by default. To bind to all interfaces
for LAN access, set `api_host => '0.0.0.0'` in the instance configuration.

For production deployments, it's recommended to keep the default localhost binding and
use a reverse proxy (nginx/Apache) with SSL and authentication.

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
[inventory-system installation guide](https://github.com/tobixen/inventory-md/blob/main/docs/INSTALLATION.md).

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
