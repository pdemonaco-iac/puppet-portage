# frozen_string_literal: true

require 'spec_helper'

describe 'portage::package_use' do
  let(:title) { 'host/web' }
  let(:params) { { root: '/', entries: { 'www-servers/nginx' => %w[ssl -debug] } } }

  it { is_expected.to contain_portage__atomfile('host/web:package.use').with(kind: 'package.use', root: '/') }
  it { is_expected.to contain_file('/etc/portage/package.use/web').with_content(%r{^www-servers/nginx ssl -debug$}) }

  context 'with a chroot root' do
    let(:params) { super().merge(root: '/var/lib/portage-targets/stage3') }

    it { is_expected.to contain_portage__managed_dir('/var/lib/portage-targets/stage3/etc/portage/package.use') }
    it { is_expected.to contain_file('/var/lib/portage-targets/stage3/etc/portage/package.use/web') }
  end

  context 'with wildcard atoms and USE_EXPAND groups' do
    let(:params) do
      {
        root: '/',
        entries: {
          '*/*' => ['PYTHON_TARGETS:', '-*', 'python3_13', 'python3_14'],
          '=sys-libs/libselinux-3.8.1-r1' => ['PYTHON_TARGETS:', '-python3_14'],
        },
      }
    end

    it { is_expected.to contain_file('/etc/portage/package.use/web').with_content(%r{^\*/\* PYTHON_TARGETS: -\* python3_13 python3_14$}) }
    it { is_expected.to contain_file('/etc/portage/package.use/web').with_content(%r{^=sys-libs/libselinux-3\.8\.1-r1 PYTHON_TARGETS: -python3_14$}) }
  end

  context 'with a lower-case group marker' do
    let(:params) { { root: '/', entries: { '*/*' => ['python_targets:'] } } }

    it { is_expected.to compile.and_raise_error(%r{entries}) }
  end

  context 'with invalid entries' do
    let(:params) { { root: '/', entries: { 'www-servers/nginx' => ['bad flag'] } } }

    it { is_expected.to compile.and_raise_error(%r{entries}) }
  end
end
