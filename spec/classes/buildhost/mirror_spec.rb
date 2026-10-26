# frozen_string_literal: true

require 'spec_helper'

describe 'portage::buildhost::mirror' do
  let(:params) { { repos: %w[gentoo guru] } }
  let(:rsyncd_conf) { catalogue.resource('File', '/etc/rsyncd.conf')[:content] }

  it { is_expected.to compile.with_all_deps }
  it { is_expected.to contain_package('net-misc/rsync').with_ensure('installed').that_comes_before(['File[/etc/rsyncd.conf]', 'Service[rsyncd]']) }
  it { is_expected.to contain_file('/etc/rsyncd.conf').with(ensure: 'file', mode: '0644', owner: 'root').that_notifies('Service[rsyncd]') }
  it { is_expected.to contain_service('rsyncd').with(ensure: 'running', enable: true) }
  it { is_expected.not_to contain_file('/etc/rsync/rsyncd.motd') }

  it 'renders the global settings' do
    expect(rsyncd_conf).to include("pid file = /run/rsyncd.pid\n", "max connections = 5\n", "use chroot = yes\n",
                                   "uid = nobody\n", "gid = nobody\n", "read only = yes\n")
    expect(rsyncd_conf).not_to match(%r{motd file|hosts allow})
  end

  it 'renders one read-only module per repository under the mirror' do
    expect(rsyncd_conf).to include(<<~CONF)

      [gentoo]
      path = /srv/portage-mirror/gentoo
      comment = Published snapshot of the gentoo repository
      read only = yes
      exclude = .git/
    CONF
    expect(rsyncd_conf).to include("[guru]\npath = /srv/portage-mirror/guru\n")
    expect(rsyncd_conf.scan(%r{^\[.*\]$})).to eq(['[gentoo]', '[guru]'])
  end

  it 'never serves the live repositories' do
    expect(rsyncd_conf.scan(%r{^path = (.*)$}).flatten).to all(start_with('/srv/portage-mirror/'))
    expect(rsyncd_conf).not_to include('/var/db/repos')
  end

  context 'with a module alias, motd, hosts_allow and no excludes' do
    let(:params) do
      super().merge(module_aliases: { 'gentoo-portage' => 'gentoo' }, motd: "!! Gentoo Util Mirror !!\nInternal only\n",
                    hosts_allow: ['192.0.2.0/24', '2001:db8::/32'], exclude: [], max_connections: 10)
    end

    it { is_expected.to contain_file('/etc/rsync').with(ensure: 'directory', mode: '0755') }
    it { is_expected.to contain_file('/etc/rsync/rsyncd.motd').with_content("!! Gentoo Util Mirror !!\nInternal only\n").that_notifies('Service[rsyncd]') }

    it do
      expect(rsyncd_conf).to include("motd file = /etc/rsync/rsyncd.motd\n", "hosts allow = 192.0.2.0/24 2001:db8::/32\n",
                                     "hosts deny = *\n", "max connections = 10\n")
    end

    it { expect(rsyncd_conf).to include("[gentoo-portage]\npath = /srv/portage-mirror/gentoo\n") }
    it { expect(rsyncd_conf).not_to include('exclude') }
  end

  context 'with a custom mirror_dir and service' do
    let(:params) { super().merge(mirror_dir: '/srv/mirror', service_name: 'rsyncd-mirror', manage_package: false, use_chroot: false) }

    it { is_expected.to compile.with_all_deps }
    it { is_expected.not_to contain_package('net-misc/rsync') }
    it { is_expected.to contain_service('rsyncd-mirror').with(ensure: 'running', enable: true) }
    it { expect(rsyncd_conf).to include("path = /srv/mirror/guru\n", "use chroot = no\n") }
  end

  ['/var/db/repos', '/var/db/repos/', '/var/db/repos/published', '/var/db', '/'].each do |dir|
    context "with mirror_dir #{dir}" do
      let(:params) { super().merge(mirror_dir: dir) }

      it { is_expected.to compile.and_raise_error(%r{overlaps the live repositories}) }
    end
  end

  context 'with an alias to an unpublished repository' do
    let(:params) { super().merge(module_aliases: { 'old' => 'missing' }) }

    it { is_expected.to compile.and_raise_error(%r{not in repos}) }
  end

  context 'with an alias named like a repository' do
    let(:params) { super().merge(module_aliases: { 'guru' => 'gentoo' }) }

    it { is_expected.to compile.and_raise_error(%r{collides}) }
  end

  context 'with a repository name that would escape the mirror' do
    let(:params) { { repos: ['../../var/db/repos/gentoo'] } }

    it { is_expected.to compile.and_raise_error(%r{repos}) }
  end
end
