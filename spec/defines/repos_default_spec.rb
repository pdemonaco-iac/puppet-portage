# frozen_string_literal: true

require 'spec_helper'

describe 'portage::repos_default' do
  let(:title) { 'host/default' }
  let(:params) { { root: '/', main_repo: 'gentoo' } }

  it { is_expected.to contain_file('/etc/portage/repos.conf').with(ensure: 'directory', purge: true) }

  it do
    is_expected.to contain_file('/etc/portage/repos.conf/DEFAULT.conf').with(
      ensure: 'file', owner: 'root', group: 'root', mode: '0644',
    ).with_content(<<~CONF)
      # This file is managed by Puppet. Local changes will be overwritten.
      [DEFAULT]
      main-repo = gentoo
    CONF
  end

  it { is_expected.not_to contain_exec('emaint sync -r DEFAULT') }

  context 'with all attributes and a chroot root' do
    let(:params) { { root: '/var/lib/portage-targets/stage3', main_repo: 'gentoo', eclass_overrides: ['local'], force: ['masters'] } }

    it do
      is_expected.to contain_file('/var/lib/portage-targets/stage3/etc/portage/repos.conf/DEFAULT.conf')
        .with_content(%r{^eclass-overrides = local$})
        .with_content(%r{^force = masters$})
    end
  end

  context 'alongside a repository' do
    let(:pre_condition) { "portage::repository { 'host/gentoo': root => '/', sync_type => 'rsync', sync_uri => 'rsync://m.example/g' }" }

    it { is_expected.to compile.with_all_deps }
  end

  context 'with an invalid force value' do
    let(:params) { super().merge(force: ['bogus']) }

    it { is_expected.to compile.and_raise_error(%r{force}) }
  end
end
