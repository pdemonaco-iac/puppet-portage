# frozen_string_literal: true

require 'spec_helper'

describe 'portage::env' do
  let(:title) { 'host/lowmem' }
  let(:params) { { root: '/', config: { 'MAKEOPTS' => ['-j1'], 'FEATURES' => ['-test'] } } }

  it do
    is_expected.to contain_file('/etc/portage/env').with(ensure: 'directory', recurse: true, purge: true, ignore: [])
  end

  it do
    is_expected.to contain_file('/etc/portage/env/lowmem').with(
      ensure: 'file', owner: 'root', group: 'root', mode: '0644',
    ).with_content(<<~CONF)
      # This file is managed by Puppet. Local changes will be overwritten.
      FEATURES="-test"
      MAKEOPTS="-j1"
    CONF
  end

  context 'with purge disabled and purge_ignore' do
    let(:params) { super().merge(purge: false, purge_ignore: ['keep-*']) }

    it { is_expected.to contain_file('/etc/portage/env').with(recurse: false, purge: false, ignore: ['keep-*']) }
  end

  context 'with a chroot root' do
    let(:params) { super().merge(root: '/var/lib/portage-targets/stage3') }

    it { is_expected.to contain_file('/var/lib/portage-targets/stage3/etc/portage/env/lowmem') }

    context 'with -march=native' do
      let(:params) { super().merge(config: { 'CFLAGS' => ['-march=native'] }) }

      it { is_expected.to compile.and_raise_error(%r{-march=native}) }
    end
  end

  context 'with an unsupported variable' do
    let(:params) { super().merge(config: { 'PORTDIR' => '/x' }) }

    it { is_expected.to compile.and_raise_error(%r{PORTDIR}) }
  end
end
