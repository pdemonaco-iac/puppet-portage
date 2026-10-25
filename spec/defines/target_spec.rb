# frozen_string_literal: true

require 'spec_helper'

describe 'portage::target' do
  let(:title) { 'host' }
  let(:params) { { root: '/' } }

  it { is_expected.to compile.with_all_deps }

  it do
    is_expected.to contain_file('/etc/portage').with(ensure: 'directory', mode: '0755')
    is_expected.to contain_file('/etc/portage').without_recurse.without_purge
  end

  it { is_expected.not_to contain_file('/etc/portage/make.conf') }
  it { is_expected.not_to contain_file('/etc/portage/gnupg') }

  context 'with every resource kind' do
    let(:params) do
      {
        root: '/',
        make_conf: { 'MAKEOPTS' => ['-j8'] },
        repos_default: { 'main_repo' => 'gentoo' },
        repositories: { 'gentoo' => { 'sync_type' => 'rsync', 'sync_uri' => 'rsync://m.example/gentoo' } },
        profile: { 'path' => 'default/linux/amd64/23.0' },
        binrepos_default: { 'frozen' => false },
        binrepos: { 'buildhost' => { 'sync_uri' => 'https://binhost.example.org/amd64', 'priority' => 10 } },
        package_use: { 'use' => { 'entries' => { 'dev-lang/rust' => ['clippy'] } } },
        accept_keywords: { 'keywords' => { 'entries' => { 'dev-lang/rust' => ['~amd64'] } } },
        licenses: { 'licenses' => { 'entries' => { 'sys-kernel/linux-firmware' => ['linux-fw-redistributable'] } } },
        masks: { 'pins' => { 'atoms' => ['>=dev-lang/rust-2'] } },
        unmasks: { 'unpins' => { 'atoms' => ['=dev-lang/rust-1.80.0'] } },
        package_envs: { 'envs' => { 'entries' => { 'dev-qt/qtwebengine' => ['lowjobs'] } } },
        envs: { 'lowjobs' => { 'config' => { 'MAKEOPTS' => ['-j2'] } } },
        sets: { 'tools' => { 'atoms' => ['app-editors/vim'], 'world' => true } },
        patches: { 'vim-fix' => { 'package' => 'app-editors/vim', 'content' => "--- a\n+++ b\n", 'filename' => 'fix.patch' } },
        postsync: { '10-notify' => { 'content' => "#!/bin/sh\n" } },
      }
    end

    it { is_expected.to compile.with_all_deps }
    it { is_expected.to contain_portage__makeconf('host/make.conf').with_root('/') }
    it { is_expected.to contain_file('/etc/portage/make.conf') }
    it { is_expected.to contain_portage__repos_default('host/repos_default').with_root('/') }
    it { is_expected.to contain_portage__repository('host/gentoo').with(root: '/', purge: true, purge_ignore: []) }
    it { is_expected.to contain_portage__profile('host/profile').with_root('/') }
    it { is_expected.to contain_file('/etc/portage/make.profile').with_target('../../var/db/repos/gentoo/profiles/default/linux/amd64/23.0') }
    it { is_expected.to contain_portage__binrepos_default('host/binrepos_default') }
    it { is_expected.to contain_portage__binrepo('host/buildhost') }
    it { is_expected.to contain_portage__package_use('host/use') }
    it { is_expected.to contain_portage__accept_keywords('host/keywords') }
    it { is_expected.to contain_portage__license('host/licenses') }
    it { is_expected.to contain_portage__mask('host/pins').with_unmask(false) }
    it { is_expected.to contain_portage__mask('host/unmask/unpins').with(unmask: true, filename: 'unpins') }
    it { is_expected.to contain_portage__package_env('host/envs') }
    it { is_expected.to contain_portage__env('host/lowjobs') }
    it { is_expected.to contain_portage__set('host/tools') }
    it { is_expected.to contain_portage__patch('host/vim-fix') }
    it { is_expected.to contain_portage__postsync('host/10-notify') }
    it { is_expected.to contain_file('/etc/portage/package.unmask/unpins') }
    it { is_expected.to contain_file('/etc/portage/package.mask/pins') }
    it { is_expected.to contain_file('/etc/portage/binrepos.conf/DEFAULT.conf') }
    it { is_expected.to contain_file('/etc/portage/repos.conf/DEFAULT.conf') }
  end

  context 'with the same key in every package.* kind' do
    let(:params) do
      {
        root: '/',
        package_use: { 'local' => { 'entries' => { 'dev-lang/rust' => ['clippy'] } } },
        accept_keywords: { 'local' => { 'entries' => { 'dev-lang/rust' => ['~amd64'] } } },
        licenses: { 'local' => { 'entries' => { 'sys-kernel/linux-firmware' => ['linux-fw-redistributable'] } } },
        masks: { 'local' => { 'atoms' => ['>=dev-lang/rust-2'] } },
        unmasks: { 'local' => { 'atoms' => ['=dev-lang/rust-1.80.0'] } },
        envs: { 'lowjobs' => { 'config' => { 'MAKEOPTS' => ['-j2'] } } },
        package_envs: { 'local' => { 'entries' => { 'dev-qt/qtwebengine' => ['lowjobs'] } } },
      }
    end

    it { is_expected.to compile.with_all_deps }

    %w[package.use package.accept_keywords package.license package.mask package.unmask package.env].each do |kind|
      it { is_expected.to contain_file("/etc/portage/#{kind}/local") }
    end
  end

  context 'with purge disabled and purge_ignore' do
    let(:params) do
      {
        root: '/',
        purge: false,
        purge_ignore: { 'repositories' => ['local-*'] },
        repos_default: { 'main_repo' => 'gentoo' },
        repositories: { 'gentoo' => {}, 'guru' => { 'purge' => true } },
      }
    end

    it { is_expected.to contain_portage__repository('host/gentoo').with(purge: false, purge_ignore: ['local-*']) }
    it { is_expected.to contain_portage__repository('host/guru').with(purge: true, purge_ignore: ['local-*']) }
    it { is_expected.to contain_portage__repos_default('host/repos_default').with(purge: false, purge_ignore: ['local-*']) }
  end

  context 'with a root passed inside a resource hash' do
    let(:params) { { root: '/', postsync: { 'x' => { 'root' => '/var/lib/portage-targets/other', 'content' => '#!/bin/sh' } } } }

    it { is_expected.to contain_portage__postsync('host/x').with_root('/') }
  end

  context 'with a host and a chroot target in one catalog' do
    let(:pre_condition) do
      <<~PP
        portage::target { 'stage3':
          root         => '/var/lib/portage-targets/stage3',
          make_conf    => { 'MAKEOPTS' => ['-j4'] },
          repositories => { 'gentoo' => {} },
          package_use  => { 'use' => { 'entries' => { 'dev-lang/rust' => ['doc'] } } },
          envs         => { 'lowjobs' => { 'config' => { 'MAKEOPTS' => ['-j1'] } } },
          package_envs => { 'envs' => { 'entries' => { 'dev-qt/qtwebengine' => ['lowjobs'] } } },
        }
      PP
    end
    let(:params) do
      {
        root: '/',
        make_conf: { 'MAKEOPTS' => ['-j8'] },
        repositories: { 'gentoo' => {} },
        package_use: { 'use' => { 'entries' => { 'dev-lang/rust' => ['clippy'] } } },
        envs: { 'lowjobs' => { 'config' => { 'MAKEOPTS' => ['-j2'] } } },
        package_envs: { 'envs' => { 'entries' => { 'dev-qt/qtwebengine' => ['lowjobs'] } } },
      }
    end

    it { is_expected.to compile.with_all_deps }
    it { is_expected.to contain_portage__repository('host/gentoo').with_root('/') }
    it { is_expected.to contain_portage__repository('stage3/gentoo').with_root('/var/lib/portage-targets/stage3') }
    it { is_expected.to contain_file('/etc/portage/make.conf').with_content(%r{-j8}) }
    it { is_expected.to contain_file('/var/lib/portage-targets/stage3/etc/portage/make.conf').with_content(%r{-j4}) }
    it { is_expected.to contain_file('/etc/portage/package.use/use').with_content(%r{clippy}) }
    it { is_expected.to contain_file('/var/lib/portage-targets/stage3/etc/portage/package.use/use').with_content(%r{doc}) }
    it { is_expected.to contain_file('/var/lib/portage-targets/stage3/etc/portage').with(ensure: 'directory') }
    it { is_expected.to contain_file('/var/lib/portage-targets/stage3/etc/portage').without_recurse.without_purge }
    it { is_expected.not_to contain_file('/var/lib/portage-targets/stage3/etc/portage/gnupg') }
  end

  context 'with a package_env referencing an env missing from the target' do
    let(:params) { { root: '/', package_envs: { 'envs' => { 'entries' => { 'dev-qt/qtwebengine' => ['missing'] } } } } }

    it { is_expected.to compile.and_raise_error(%r{Portage::Env\[host/missing\]}) }
  end

  context 'with -march=native in a chroot' do
    let(:params) { { root: '/var/lib/portage-targets/stage3', make_conf: { 'CFLAGS' => ['-march=native'] } } }

    it { is_expected.to compile.and_raise_error(%r{march=native}) }
  end

  context 'with an invalid root' do
    let(:params) { { root: '/tmp/elsewhere' } }

    it { is_expected.to compile.and_raise_error(%r{root}) }
  end
end
