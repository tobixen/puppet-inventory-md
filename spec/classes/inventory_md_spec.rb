require 'spec_helper'

describe 'inventory_md' do
  context 'with default parameters' do
    it { is_expected.to compile.with_all_deps }

    it { is_expected.to contain_package('python3-pip') }
    it { is_expected.to contain_package('python3-venv') }
    it { is_expected.to contain_package('git') }
    it { is_expected.to contain_package('make') }

    it {
      is_expected.to contain_vcsrepo('/opt/inventory-system').with(
        ensure: 'latest',
        provider: 'git',
        source: 'https://github.com/tobixen/inventory-system.git',
        revision: 'main',
      )
    }

    it { is_expected.to contain_file('/etc/inventory-system').with_ensure('directory') }

    it {
      is_expected.to contain_file('/etc/systemd/system/inventory-api@.service').with(
        ensure: 'link',
        target: '/opt/inventory-system/systemd/inventory-api@.service',
      )
    }

    it {
      is_expected.to contain_file('/etc/systemd/system/inventory-web@.service').with(
        ensure: 'link',
        target: '/opt/inventory-system/systemd/inventory-web@.service',
      )
    }

    it { is_expected.to contain_exec('systemd-daemon-reload').with_refreshonly(true) }
    it { is_expected.to contain_exec('install-inventory-system').with_refreshonly(true) }
    it { is_expected.to contain_exec('initial-install-inventory-system') }
  end

  context 'with custom install_dir' do
    let(:params) { { install_dir: '/srv/inventory' } }

    it { is_expected.to compile.with_all_deps }

    it {
      is_expected.to contain_vcsrepo('/srv/inventory').with(
        ensure: 'latest',
        provider: 'git',
      )
    }

    it {
      is_expected.to contain_file('/etc/systemd/system/inventory-api@.service').with(
        target: '/srv/inventory/systemd/inventory-api@.service',
      )
    }
  end

  context 'with an instance' do
    let(:params) do
      {
        instances: {
          'test' => {
            'datadir'  => '/var/www/inventory/test',
            'api_port' => 8800,
          },
        },
      }
    end

    it { is_expected.to compile.with_all_deps }
    it { is_expected.to contain_inventory_md__instance('test') }
  end

  context 'with anthropic_api_key' do
    let(:params) do
      {
        anthropic_api_key: 'sk-ant-test123',
        instances: {
          'myinv' => {
            'datadir' => '/data/myinv',
          },
        },
      }
    end

    it { is_expected.to compile.with_all_deps }

    it {
      is_expected.to contain_inventory_md__instance('myinv').with(
        anthropic_api_key: 'sk-ant-test123',
      )
    }
  end
end
