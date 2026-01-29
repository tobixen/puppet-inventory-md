# Changelog

All notable changes to this project will be documented in this file.

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
