# frozen_string_literal: true

require 'open3'
require 'spec_helper'

describe 'portage::buildhost' do
  let(:facts) do
    {
      os: { name: 'Gentoo', family: 'Gentoo', architecture: 'amd64', hardware: 'x86_64', release: { full: 'rolling', major: 'rolling' } },
      kernel: 'Linux',
      networking: { fqdn: 'buildhost.example.org', hostname: 'buildhost', domain: 'example.org', ip: '192.0.2.10' },
    }
  end
  let(:targets) do
    {
      'desktop' => { 'profile' => { 'path' => 'default/linux/amd64/23.0/desktop/systemd' }, 'make_conf' => { 'MAKEOPTS' => ['-j8'] } },
      'server' => { 'make_conf' => { 'FEATURES' => ['buildpkg'] }, 'binrepos' => { 'extra' => { 'sync_uri' => 'https://binhost.example.org/x' } } },
    }
  end
  let(:params) { { targets: targets, signing: false } }
  let(:wrapper) { catalogue.resource('File', '/usr/local/sbin/target-emerge')[:content] }

  context 'without targets' do
    let(:params) { {} }

    it { is_expected.to compile.with_all_deps }
    it { is_expected.to contain_file('/usr/local/sbin/target-emerge').with(ensure: 'file', mode: '0755', owner: 'root') }
    it { is_expected.not_to contain_class('portage::buildhost::signing') }
    it { is_expected.to contain_class('portage::buildhost::publish').with(targets: [], target_emerge: '/usr/local/sbin/target-emerge') }
  end

  context 'with a targets hash' do
    it { is_expected.to compile.with_all_deps }
    it { is_expected.to contain_portage__target('desktop').with_root('/var/lib/portage-targets/desktop') }
    it { is_expected.to contain_portage__target('server').with_root('/var/lib/portage-targets/server') }
    it { is_expected.to contain_portage__profile('desktop/profile').with_root('/var/lib/portage-targets/desktop') }
    it { is_expected.to contain_file('/var/lib/portage-targets/desktop/etc/portage/make.conf').with_content(%r{^FEATURES="getbinpkg buildpkg"$}).with_content(%r{^MAKEOPTS="-j8"$}) }
    it { is_expected.to contain_file('/var/lib/portage-targets/server/etc/portage/make.conf').with_content(%r{^FEATURES="buildpkg"$}) }

    it 'adds the upstream binrepo with signature verification to every target' do
      %w[desktop server].each do |name|
        is_expected.to contain_file("/var/lib/portage-targets/#{name}/etc/portage/binrepos.conf/upstream.conf")
          .with_content(%r{^sync-uri = https://distfiles.gentoo.org/releases/amd64/binpackages/23.0/x86-64-v3/$})
          .with_content(%r{^priority = 1$})
          .with_content(%r{^verify-signature = yes$})
      end
    end

    it { is_expected.to contain_file('/var/lib/portage-targets/server/etc/portage/binrepos.conf/extra.conf') }
    it { is_expected.not_to contain_file('/var/lib/portage-targets/desktop/etc/portage/binrepos.conf/extra.conf') }
    it { is_expected.to contain_file('/var/cache/portage-targets/desktop').with(ensure: 'directory') }
    it { is_expected.to contain_file('/var/cache/portage-targets/server').with(ensure: 'directory') }
    it { is_expected.to contain_class('portage::buildhost::publish').with_targets(%w[desktop server]) }
    it { is_expected.to contain_file('/usr/local/sbin/portage-publish').with_content(%r{^targets=\(desktop server\)$}) }
    it { is_expected.to contain_file('/srv/binhost/desktop') }
    it { is_expected.to contain_class('portage::buildhost::mirror').with(repos: ['gentoo'], mirror_dir: '/srv/portage-mirror') }
    it { is_expected.to contain_service('rsyncd').with(ensure: 'running', enable: true) }
    it { is_expected.to contain_class('portage::buildhost::binhost').with(binhost_dir: '/srv/binhost', pkgdir_root: '/var/cache/portage-targets') }
    it { is_expected.to contain_apache__vhost('portage-binhost-80').with_docroot('/srv/binhost') }
  end

  context 'without publish' do
    let(:params) { { targets: targets, signing: false, publish: false } }

    it { is_expected.to compile.with_all_deps }
    it { is_expected.not_to contain_class('portage::buildhost::publish') }
    it { is_expected.not_to contain_file('/usr/local/sbin/portage-publish') }
    it { is_expected.to contain_class('portage::buildhost::mirror').with_repos(['gentoo']) }
  end

  context 'without binhost' do
    let(:params) { { targets: targets, signing: false, binhost: false } }

    it { is_expected.to compile.with_all_deps }
    it { is_expected.not_to contain_class('portage::buildhost::binhost') }
    it { is_expected.not_to contain_class('apache') }
  end

  context 'without mirror' do
    let(:params) { { targets: targets, signing: false, mirror: false } }

    it { is_expected.to compile.with_all_deps }
    it { is_expected.not_to contain_class('portage::buildhost::mirror') }
    it { is_expected.not_to contain_service('rsyncd') }
  end

  context 'with a custom upstream_binrepo' do
    let(:params) { super().merge(upstream_binrepo: { 'sync_uri' => 'https://mirror.example.org/binpkgs', 'verify_signature' => false }) }

    it { is_expected.to contain_file('/var/lib/portage-targets/desktop/etc/portage/binrepos.conf/upstream.conf').with_content(%r{^verify-signature = no$}) }
  end

  context 'with signing' do
    let(:hiera_config) { 'spec/hiera_buildhost_signing.yaml' }
    let(:params) { { targets: targets } }

    it { is_expected.to compile.with_all_deps }
    it { is_expected.to contain_class('portage::buildhost::signing').with_roots(['/var/lib/portage-targets/desktop', '/var/lib/portage-targets/server']) }
    it { is_expected.to contain_file('/var/lib/portage-targets/desktop/etc/portage/binpkg-signing/signing-key.asc').with_mode('0600') }
    it { is_expected.to contain_file('/var/lib/portage-targets/server/etc/portage/binpkg-signing/signing-key.asc').with_mode('0600') }

    it 'adds the signing settings to every target' do
      %w[desktop server].each do |name|
        is_expected.to contain_file("/var/lib/portage-targets/#{name}/etc/portage/make.conf")
          .with_content(%r{^BINPKG_GPG_SIGNING_GPG_HOME="/etc/portage/binpkg-signing"$})
          .with_content(%r{^BINPKG_GPG_SIGNING_KEY="0x40DCF18E97150795"$})
      end
    end

    it { is_expected.to contain_file('/var/lib/portage-targets/desktop/etc/portage/make.conf').with_content(%r{^FEATURES="getbinpkg buildpkg binpkg-signing"$}) }
  end

  context 'with a target name that is not a valid chroot name' do
    let(:params) { { targets: { '../etc' => {} }, signing: false } }

    it { is_expected.to compile.and_raise_error(%r{targets}) }
  end

  describe 'target-emerge wrapper' do
    let(:params) { { targets: targets, signing: false, distfiles_dir: '/srv/distfiles', pkgdir_root: '/srv/pkgdirs' } }

    it { expect(wrapper).to start_with("#!/bin/bash\n") }
    it { expect(wrapper).to include("targets_dir=/var/lib/portage-targets\n") }
    it { expect(wrapper).to include("distfiles_dir=/srv/distfiles\n") }
    it { expect(wrapper).to include("pkgdir_root=/srv/pkgdirs\n") }
    it { expect(wrapper).to include('mount -t proc proc "${root}/proc"') }
    it { expect(wrapper).to include('bind /sys "${root}/sys"') }
    it { expect(wrapper).to include('bind /dev "${root}/dev"') }
    it { expect(wrapper).to include('bind "$repos_dir" "${root}${repos_dir}" ro') }
    it { expect(wrapper).to include('bind "$distfiles_dir" "${root}/var/cache/distfiles"') }
    it { expect(wrapper).to include('bind "$pkgdir" "${root}/var/cache/binpkgs"') }
    it { expect(wrapper).to include('mount -o remount,bind,ro "$dest"') }
    it { expect(wrapper).to include('trap cleanup EXIT') }
    it { expect(wrapper).to include('umount -R') }
    it { expect(wrapper).to include('chroot "$root" /usr/bin/emerge "$@"') }
    it { is_expected.not_to contain_mount('/var/lib/portage-targets/desktop/proc') }

    it 'is valid bash' do
      _out, err, status = Open3.capture3('bash', '-n', stdin_data: wrapper)
      expect(status).to be_success, err
    end
  end
end
