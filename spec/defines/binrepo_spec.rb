# frozen_string_literal: true

require 'spec_helper'

describe 'portage::binrepo' do
  let(:title) { 'host/buildhost' }
  let(:params) { { root: '/', sync_uri: 'https://binhost.example.org/amd64', priority: 10, verify_signature: true } }

  it { is_expected.to contain_file('/etc/portage/binrepos.conf').with(ensure: 'directory', recurse: true, purge: true) }

  it do
    is_expected.to contain_file('/etc/portage/binrepos.conf/buildhost.conf')
      .with(ensure: 'file', mode: '0644')
      .with_content("# This file is managed by Puppet. Local changes will be overwritten.\n[buildhost]\nsync-uri = https://binhost.example.org/amd64\npriority = 10\nverify-signature = yes\n")
  end

  context 'with signature verification off' do
    let(:params) { super().merge(verify_signature: false) }

    it { is_expected.to contain_file('/etc/portage/binrepos.conf/buildhost.conf').with_content(%r{^verify-signature = no$}) }
  end

  context 'with verify_signature unset' do
    let(:params) { { root: '/', sync_uri: 'https://binhost.example.org/amd64' } }

    it { is_expected.to contain_file('/etc/portage/binrepos.conf/buildhost.conf').without_content(%r{verify-signature|priority}) }
  end

  context 'with the optional attributes' do
    let(:params) do
      super().merge(location: '/var/cache/binhost/buildhost', openpgp_key_package: 'sec-keys/openpgp-keys-gentoo-release',
                    getbinpkg_exclude: ['sys-devel/gcc'], getbinpkg_include: ['dev-lang/rust:stable', 'app-editors/vim'])
    end

    it do
      is_expected.to contain_file('/etc/portage/binrepos.conf/buildhost.conf')
        .with_content(%r{^location = /var/cache/binhost/buildhost$})
        .with_content(%r{^openpgp-key-package = sec-keys/openpgp-keys-gentoo-release$})
        .with_content(%r{^getbinpkg-exclude = sys-devel/gcc$})
        .with_content(%r{^getbinpkg-include = dev-lang/rust:stable app-editors/vim$})
    end
  end

  context 'with a chroot root, purge disabled and purge_ignore' do
    let(:params) { super().merge(root: '/var/lib/portage-targets/stage3', purge: false, purge_ignore: ['local-*']) }

    it { is_expected.to contain_file('/var/lib/portage-targets/stage3/etc/portage/binrepos.conf').with(recurse: false, purge: false, ignore: ['local-*']) }
    it { is_expected.to contain_file('/var/lib/portage-targets/stage3/etc/portage/binrepos.conf/buildhost.conf') }
  end

  context 'with binrepo_name' do
    let(:params) { super().merge(binrepo_name: 'gentoobinhost') }

    it { is_expected.to contain_file('/etc/portage/binrepos.conf/gentoobinhost.conf').with_content(%r{^\[gentoobinhost\]$}) }
  end

  context 'with two binrepos in one target' do
    let(:pre_condition) do
      "portage::binrepo { 'host/upstream': root => '/', sync_uri => 'https://distfiles.gentoo.org/releases/amd64/binpackages/23.0/x86-64-v3/', priority => 1, verify_signature => true }"
    end

    it { is_expected.to compile.with_all_deps }
    it { is_expected.to contain_file('/etc/portage/binrepos.conf/upstream.conf').with_content(%r{^priority = 1$}) }
    it { is_expected.to contain_file('/etc/portage/binrepos.conf/buildhost.conf').with_content(%r{^priority = 10$}) }
  end

  context 'with the reserved name DEFAULT' do
    let(:title) { 'host/DEFAULT' }

    it { is_expected.to compile.and_raise_error(%r{binrepo_name|DEFAULT}) }
  end

  context 'with an invalid sync_uri' do
    let(:params) { super().merge(sync_uri: 'not a uri') }

    it { is_expected.to compile.and_raise_error(%r{sync_uri}) }
  end
end
