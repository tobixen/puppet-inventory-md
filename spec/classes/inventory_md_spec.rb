require 'spec_helper'

describe 'inventory_md' do
  context 'with default parameters' do
    it { is_expected.to compile.with_all_deps }

    it {
      is_expected.to contain_package('inventory-md').with(
        ensure: 'present',
        name: 'inventory-md[chat]',
        provider: 'pip3',
      )
    }

    it { is_expected.to contain_file('/etc/inventory-system').with_ensure('directory') }

    it {
      is_expected.to contain_file('/etc/systemd/system/inventory-api@.service').with(
        ensure: 'file',
        mode: '0644',
      )
    }

    it {
      is_expected.to contain_file('/etc/systemd/system/inventory-web@.service').with(
        ensure: 'file',
        mode: '0644',
      )
    }

    it { is_expected.to contain_exec('systemd-daemon-reload').with_refreshonly(true) }
  end

  context 'with custom pip_extras' do
    let(:params) { { pip_extras: ['chat', 'barcode'] } }

    it { is_expected.to compile.with_all_deps }

    it {
      is_expected.to contain_package('inventory-md').with(
        name: 'inventory-md[chat,barcode]',
      )
    }
  end

  context 'with empty pip_extras' do
    let(:params) { { pip_extras: [] } }

    it { is_expected.to compile.with_all_deps }

    it {
      is_expected.to contain_package('inventory-md').with(
        name: 'inventory-md',
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
