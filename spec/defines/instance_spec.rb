require 'spec_helper'

describe 'inventory_md::instance' do
  let(:title) { 'testinv' }
  let(:params) do
    {
      datadir: '/var/www/inventory/testinv',
      api_port: 8765,
    }
  end

  # We need to include the parent class
  let(:pre_condition) { 'include inventory_md' }

  context 'with default parameters' do
    it { is_expected.to compile.with_all_deps }

    it {
      is_expected.to contain_group('inventory-testinv').with(
        gid: %r{^3\d+$},
      )
    }

    it {
      is_expected.to contain_user('inventory-testinv').with(
        gid: 'inventory-testinv',
        home: '/var/www/inventory/testinv',
        shell: '/bin/bash',
      )
    }

    it {
      is_expected.to contain_file('/var/www/inventory/testinv').with(
        ensure: 'directory',
        owner: 'inventory-testinv',
        group: 'inventory-testinv',
        mode: '2775',
      )
    }

    it {
      is_expected.to contain_file('/etc/inventory-system/testinv.conf').with(
        ensure: 'file',
        mode: '0640',
        owner: 'root',
        group: 'inventory-testinv',
      )
    }

    it {
      is_expected.to contain_file('/etc/inventory-system/testinv.conf')
        .with_content(%r{INVENTORY_PATH=/var/www/inventory/testinv})
        .with_content(%r{API_PORT=8765})
        .with_content(%r{API_HOST=127\.0\.0\.1})
    }

    it {
      is_expected.to contain_service('inventory-api@testinv').with(
        ensure: 'running',
        enable: true,
      )
    }
  end

  context 'with custom user and group' do
    let(:params) do
      super().merge(
        user: 'invuser',
        group: 'invgroup',
      )
    end

    it { is_expected.to compile.with_all_deps }
    it { is_expected.to contain_user('invuser') }
    it { is_expected.to contain_group('invgroup') }

    it {
      is_expected.to contain_file('/var/www/inventory/testinv').with(
        owner: 'invuser',
        group: 'invgroup',
      )
    }
  end

  context 'with custom api_host' do
    let(:params) do
      super().merge(api_host: '0.0.0.0')
    end

    it { is_expected.to compile.with_all_deps }

    it {
      is_expected.to contain_file('/etc/inventory-system/testinv.conf')
        .with_content(%r{API_HOST=0\.0\.0\.0})
    }
  end

  context 'with anthropic_api_key' do
    let(:params) do
      super().merge(anthropic_api_key: 'sk-ant-secret')
    end

    it { is_expected.to compile.with_all_deps }

    it {
      is_expected.to contain_file('/etc/inventory-system/testinv.conf')
        .with_content(%r{ANTHROPIC_API_KEY=sk-ant-secret})
    }
  end

  context 'without anthropic_api_key' do
    it { is_expected.to compile.with_all_deps }

    it {
      is_expected.to contain_file('/etc/inventory-system/testinv.conf')
        .without_content(%r{ANTHROPIC_API_KEY})
    }
  end

  context 'with additional_members' do
    let(:params) do
      super().merge(additional_members: ['alice', 'bob'])
    end

    it { is_expected.to compile.with_all_deps }

    it {
      is_expected.to contain_group('inventory-testinv').with(
        members: ['alice', 'bob'],
      )
    }
  end
end
