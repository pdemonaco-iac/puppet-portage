# frozen_string_literal: true

require 'spec_helper'

describe 'portage::set' do
  let(:title) { 'host/tools' }
  let(:params) { { root: '/', atoms: ['app-editors/vim', '=dev-lang/ruby-3.3*', '@base-tools'] } }

  it { is_expected.to contain_file('/etc/portage/sets').with(ensure: 'directory', recurse: true, purge: true, ignore: []) }

  it do
    is_expected.to contain_file('/etc/portage/sets/tools').with(ensure: 'file', mode: '0644').with_content(<<~CONF)
      # This file is managed by Puppet. Local changes will be overwritten.
      app-editors/vim
      =dev-lang/ruby-3.3*
      @base-tools
    CONF
  end

  it { is_expected.not_to contain_file_line('host/tools in world_sets') }

  context 'with world' do
    let(:params) { super().merge(world: true) }

    it { is_expected.to contain_file_line('host/tools in world_sets').with(path: '/var/lib/portage/world_sets', line: '@tools') }
  end

  context 'with a chroot root and world' do
    let(:params) { super().merge(root: '/var/lib/portage-targets/stage3', world: true) }

    it { is_expected.to contain_file('/var/lib/portage-targets/stage3/etc/portage/sets/tools') }
    it { is_expected.to contain_file_line('host/tools in world_sets').with_path('/var/lib/portage-targets/stage3/var/lib/portage/world_sets') }
  end

  context 'with purge disabled and purge_ignore' do
    let(:params) { super().merge(purge: false, purge_ignore: ['keep-*']) }

    it { is_expected.to contain_file('/etc/portage/sets').with(recurse: false, purge: false, ignore: ['keep-*']) }
  end

  context 'with two sets in one target' do
    let(:pre_condition) { "portage::set { 'host/other': root => '/', atoms => ['app-misc/foo'] }" }

    it { is_expected.to compile.with_all_deps }
  end

  context 'with an invalid atom' do
    let(:params) { super().merge(atoms: ['garbage']) }

    it { is_expected.to compile.and_raise_error(%r{atoms}) }
  end
end
