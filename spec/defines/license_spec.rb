# frozen_string_literal: true

require 'spec_helper'

describe 'portage::license' do
  let(:title) { 'host/web' }
  let(:params) { { root: '/', entries: { 'sys-kernel/linux-firmware' => ['linux-fw-redistributable', '@BINARY-REDISTRIBUTABLE'] } } }

  it { is_expected.to contain_portage__atomfile('host/web:package.license').with(kind: 'package.license', root: '/') }
  it { is_expected.to contain_file('/etc/portage/package.license/web').with_content(%r{^sys-kernel/linux-firmware linux-fw-redistributable @BINARY-REDISTRIBUTABLE$}) }

  context 'with a chroot root' do
    let(:params) { super().merge(root: '/var/lib/portage-targets/stage3') }

    it { is_expected.to contain_file('/var/lib/portage-targets/stage3/etc/portage/package.license/web') }
  end

  context 'with invalid entries' do
    let(:params) { { root: '/', entries: { 'www-servers/nginx' => ['bad license'] } } }

    it { is_expected.to compile.and_raise_error(%r{entries}) }
  end
end
