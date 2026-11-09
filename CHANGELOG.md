# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Added
- `cache_dir` instance parameter (default `/var/cache/inventory-md/<instance>`); the service gets `INVENTORY_MD_SKOS__CACHE_DIR=<cache_dir>/skos`, keeping the SKOS vocabulary cache out of the datadir

### Fixed
- With any `pip_extras` (the default is `['chat']`), the pip package was reinstalled on every agent run, since the pip provider never finds a name with extras in `pip freeze`; the extras are now installed by a separate exec that only runs when they are missing. With `package_ensure => latest`, only inventory-md itself is upgraded now, not the extras' dependencies (e.g. `anthropic`)

## [0.2.1] - 2026-02-12

### Fixed
- Spec test expected 'present' instead of 'latest' after default change, breaking CI and Forge publish

## [0.2.0] - 2026-01-29

### Changed
- Default `package_ensure` from 'present' to 'latest' for automatic updates

## [0.1.0] - 2026-01-13

### Added
- Initial release
- Main `inventory_md` class for installation
- `inventory_md::instance` defined type for managing instances
- Systemd service management
- Git workflow with bare repositories and post-receive hooks
- Optional Anthropic API key support
- Spec tests for main class and instance define
- GitHub Actions for CI/CD and Puppet Forge publishing
