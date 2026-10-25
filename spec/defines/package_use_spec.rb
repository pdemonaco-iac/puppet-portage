# frozen_string_literal: true

require 'spec_helper'

describe 'portage::package_use' do
  let(:title) { 'host/web' }
  let(:params) { { root: '/', entries: { 'www-servers/nginx' => %w[ssl -debug] } } }

  it { is_expected.to contain_portage__atomfile('host/web').with(kind: 'package.use', root: '/') }
  it { is_expected.to contain_file('/etc/portage/package.use/web').with_content(%r{^www-servers/nginx ssl -debug$}) }

  context 'with a chroot root' do
    let(:params) { super().merge(root: '/var/lib/portage-targets/stage3') }

    it { is_expected.to contain_file('/var/lib/portage-targets/stage3/etc/portage/package.use/web') }
  end

  context 'with invalid entries' do
    let(:params) { { root: '/', entries: { 'www-servers/nginx' => ['bad flag'] } } }

    it { is_expected.to compile.and_raise_error(%r{entries}) }
  end
end
