# frozen_string_literal: true

require 'spec_helper'

describe 'portage::conf_update_hook' do
  let(:title) { 'host/etckeeper' }
  let(:params) { { root: '/', content: "#!/bin/sh\netckeeper pre-install\n" } }

  it { is_expected.to compile.with_all_deps }
  it { is_expected.to contain_portage__managed_dir('/etc/portage/conf-update.d').with(purge: true, purge_ignore: []) }
  it { is_expected.to contain_file('/etc/portage/conf-update.d').with(ensure: 'directory', recurse: true, purge: true) }
  it { is_expected.to contain_file('/etc/portage/conf-update.d/etckeeper').with(ensure: 'file', owner: 'root', group: 'root', mode: '0755', content: "#!/bin/sh\netckeeper pre-install\n") }

  context 'with source and a filename' do
    let(:params) { { root: '/', source: 'puppet:///modules/profile/etckeeper-hook', filename: '50-etckeeper' } }

    it { is_expected.to contain_file('/etc/portage/conf-update.d/50-etckeeper').with(source: 'puppet:///modules/profile/etckeeper-hook', content: nil) }
    it { is_expected.not_to contain_file('/etc/portage/conf-update.d/etckeeper') }
  end

  context 'with a chroot root, purge disabled and purge_ignore' do
    let(:params) { super().merge(root: '/var/lib/portage-targets/stage3', purge: false, purge_ignore: ['local-*']) }

    it { is_expected.to contain_file('/var/lib/portage-targets/stage3/etc/portage/conf-update.d').with(recurse: false, purge: false, ignore: ['local-*']) }
    it { is_expected.to contain_file('/var/lib/portage-targets/stage3/etc/portage/conf-update.d/etckeeper') }
  end

  context 'with two hooks in one target' do
    let(:pre_condition) { "portage::conf_update_hook { 'host/other': root => '/', content => '#!/bin/sh' }" }

    it { is_expected.to compile.with_all_deps }
    it { is_expected.to contain_file('/etc/portage/conf-update.d/other').with_mode('0755') }
  end

  context 'with both content and source' do
    let(:params) { super().merge(source: 'puppet:///modules/profile/etckeeper-hook') }

    it { is_expected.to compile.and_raise_error(%r{exactly one of content and source}) }
  end

  context 'with neither content nor source' do
    let(:params) { { root: '/' } }

    it { is_expected.to compile.and_raise_error(%r{exactly one of content and source}) }
  end

  context 'with an invalid filename' do
    let(:params) { super().merge(filename: '../evil') }

    it { is_expected.to compile.and_raise_error(%r{filename}) }
  end
end
