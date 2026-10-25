# frozen_string_literal: true

require 'spec_helper'

describe 'portage::binrepos_default' do
  let(:title) { 'host/default' }
  let(:params) { { root: '/', frozen: true } }

  it { is_expected.to contain_file('/etc/portage/binrepos.conf').with(ensure: 'directory', purge: true) }

  it do
    is_expected.to contain_file('/etc/portage/binrepos.conf/DEFAULT.conf').with(
      ensure: 'file', owner: 'root', group: 'root', mode: '0644',
    ).with_content(<<~CONF)
      # This file is managed by Puppet. Local changes will be overwritten.
      [DEFAULT]
      frozen = yes
    CONF
  end

  context 'with frozen off' do
    let(:params) { super().merge(frozen: false) }

    it { is_expected.to contain_file('/etc/portage/binrepos.conf/DEFAULT.conf').with_content(%r{^frozen = no$}) }
  end

  context 'with all attributes and a chroot root' do
    let(:params) do
      {
        root: '/var/lib/portage-targets/stage3',
        frozen: true,
        fetchcommand: 'wget -t 3 -T 60 "${URI}" -P "${DISTDIR}"',
        resumecommand: 'wget -c "${URI}" -P "${DISTDIR}"',
      }
    end

    it do
      is_expected.to contain_file('/var/lib/portage-targets/stage3/etc/portage/binrepos.conf/DEFAULT.conf')
        .with_content(%r{^fetchcommand = wget -t 3 -T 60 "\$\{URI\}" -P "\$\{DISTDIR\}"$})
        .with_content(%r{^resumecommand = wget -c "\$\{URI\}" -P "\$\{DISTDIR\}"$})
    end
  end

  context 'alongside a binrepo' do
    let(:pre_condition) { "portage::binrepo { 'host/buildhost': root => '/', sync_uri => 'https://binhost.example.org/amd64' }" }

    it { is_expected.to compile.with_all_deps }
    it { is_expected.to contain_file('/etc/portage/binrepos.conf/buildhost.conf') }
  end

  context 'with an empty fetchcommand' do
    let(:params) { super().merge(fetchcommand: '') }

    it { is_expected.to compile.and_raise_error(%r{fetchcommand}) }
  end
end
