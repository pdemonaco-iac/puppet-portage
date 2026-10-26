# frozen_string_literal: true

require 'spec_helper'

describe 'portage::repository' do
  let(:title) { 'host/gentoo' }
  let(:params) { { root: '/', sync_type: 'rsync', sync_uri: 'rsync://mirror.example/gentoo-portage' } }

  it { is_expected.to contain_file('/etc/portage/repos.conf').with(ensure: 'directory', recurse: true, purge: true, ignore: []) }

  it do
    is_expected.to contain_file('/etc/portage/repos.conf/gentoo.conf').with(
      ensure: 'file', owner: 'root', group: 'root', mode: '0644',
    ).with_content(<<~CONF)
      # This file is managed by Puppet. Local changes will be overwritten.
      [gentoo]
      location = /var/db/repos/gentoo
      sync-type = rsync
      sync-uri = rsync://mirror.example/gentoo-portage
      sync-rsync-verify-metamanifest = yes
    CONF
  end

  it do
    is_expected.to contain_exec('emaint sync -r gentoo')
      .with(refreshonly: true)
      .that_subscribes_to('File[/etc/portage/repos.conf/gentoo.conf]')
  end

  context 'with metamanifest verification explicitly disabled' do
    let(:params) { super().merge(sync_rsync_verify_metamanifest: false, sync_rsync_verify_jobs: 2, sync_rsync_extra_opts: ['--bwlimit=1000']) }

    it do
      is_expected.to contain_file('/etc/portage/repos.conf/gentoo.conf')
        .with_content(%r{^sync-rsync-verify-metamanifest = no$})
        .with_content(%r{^sync-rsync-verify-jobs = 2$})
        .with_content(%r{^sync-rsync-extra-opts = --bwlimit=1000$})
    end
  end

  context 'with a git overlay' do
    let(:title) { 'host/guru' }
    let(:params) do
      {
        root: '/', sync_type: 'git', sync_uri: 'https://github.com/gentoo-mirror/guru.git',
        priority: 50, auto_sync: true, masters: ['gentoo'], sync_depth: 1,
        sync_git_verify_commit_signature: false,
      }
    end

    it do
      is_expected.to contain_file('/etc/portage/repos.conf/guru.conf').with_content(<<~CONF)
        # This file is managed by Puppet. Local changes will be overwritten.
        [guru]
        location = /var/db/repos/guru
        masters = gentoo
        priority = 50
        auto-sync = yes
        sync-type = git
        sync-uri = https://github.com/gentoo-mirror/guru.git
        sync-depth = 1
        sync-git-verify-commit-signature = no
      CONF
    end

    it { is_expected.not_to contain_file('/etc/portage/repos.conf/guru.conf').with_content(%r{metamanifest}) }
    it { is_expected.to contain_exec('emaint sync -r guru') }
  end

  context 'with the remaining rsync attributes' do
    let(:params) do
      super().merge(
        aliases: ['foo', '-baz'], force: ['masters'], volatile: false,
        strict_misc_digests: true, usepkg_exclude: ['sys-devel/gcc'], usepkg_include: ['dev-libs/foo:1'],
        sync_user: 'portage:portage', sync_umask: '022', sync_allow_hardlinks: false,
        sync_hooks_only_on_change: true, sync_rcu: true, sync_rcu_store_dir: '/var/cache/rcu/gentoo',
        sync_rcu_spare_snapshots: 1, sync_rcu_ttl_days: 7, sync_rsync_vcs_ignore: true,
        sync_openpgp_key_package: 'sec-keys/openpgp-keys-gentoo-release', sync_openpgp_key_refresh: 'wkd',
        sync_openpgp_key_refresh_retry_count: 40, sync_openpgp_key_refresh_retry_delay_exp_base: 2,
        sync_openpgp_key_refresh_retry_delay_max: 60, sync_openpgp_key_refresh_retry_delay_mult: 4,
        sync_openpgp_key_refresh_retry_overall_timeout: 1200, sync_openpgp_keyserver: 'hkps://keys.gentoo.org'
      )
    end

    it do
      is_expected.to contain_file('/etc/portage/repos.conf/gentoo.conf').with_content(<<~CONF)
        # This file is managed by Puppet. Local changes will be overwritten.
        [gentoo]
        location = /var/db/repos/gentoo
        aliases = foo -baz
        force = masters
        volatile = no
        strict-misc-digests = yes
        usepkg-exclude = sys-devel/gcc
        usepkg-include = dev-libs/foo:1
        sync-type = rsync
        sync-uri = rsync://mirror.example/gentoo-portage
        sync-user = portage:portage
        sync-umask = 022
        sync-allow-hardlinks = no
        sync-hooks-only-on-change = yes
        sync-rcu = yes
        sync-rcu-store-dir = /var/cache/rcu/gentoo
        sync-rcu-spare-snapshots = 1
        sync-rcu-ttl-days = 7
        sync-rsync-verify-metamanifest = yes
        sync-rsync-vcs-ignore = yes
        sync-openpgp-key-package = sec-keys/openpgp-keys-gentoo-release
        sync-openpgp-key-refresh = wkd
        sync-openpgp-key-refresh-retry-count = 40
        sync-openpgp-key-refresh-retry-delay-exp-base = 2
        sync-openpgp-key-refresh-retry-delay-max = 60
        sync-openpgp-key-refresh-retry-delay-mult = 4
        sync-openpgp-key-refresh-retry-overall-timeout = 1200
        sync-openpgp-keyserver = hkps://keys.gentoo.org
      CONF
    end
  end

  context 'with an empty eclass_overrides array' do
    let(:params) { super().merge(eclass_overrides: []) }

    it { is_expected.to contain_file('/etc/portage/repos.conf/gentoo.conf').with_content(%r{^eclass-overrides = $}) }
  end

  context 'with a boolean openpgp key refresh' do
    let(:params) { super().merge(sync_openpgp_key_refresh: false) }

    it { is_expected.to contain_file('/etc/portage/repos.conf/gentoo.conf').with_content(%r{^sync-openpgp-key-refresh = no$}) }
  end

  context 'with git attributes' do
    let(:params) do
      {
        root: '/', sync_type: 'git', sync_uri: 'git+ssh://git@example.org/x.git', clone_depth: 0,
        sync_git_clone_env: ['"VAR1=word1 word2"', 'VAR2=word3'], sync_git_clone_extra_opts: ['--single-branch'],
        sync_git_env: ['A=b'], sync_git_pull_env: ['C=d'], sync_git_pull_extra_opts: ['--ff-only'],
        sync_git_verify_max_age_days: 14,
      }
    end

    it do
      is_expected.to contain_file('/etc/portage/repos.conf/gentoo.conf')
        .with_content(%r{^clone-depth = 0$})
        .with_content(%r{^sync-git-verify-max-age-days = 14$})
        .with_content(%r{^sync-git-clone-env = "VAR1=word1 word2" VAR2=word3$})
        .with_content(%r{^sync-git-clone-extra-opts = --single-branch$})
        .with_content(%r{^sync-git-env = A=b$})
        .with_content(%r{^sync-git-pull-env = C=d$})
        .with_content(%r{^sync-git-pull-extra-opts = --ff-only$})
    end
  end

  context 'with mercurial attributes' do
    let(:params) do
      {
        root: '/', sync_type: 'mercurial', sync_uri: 'https://example.org/x',
        sync_mercurial_clone_env: ['A=b'], sync_mercurial_clone_extra_opts: ['--pull'],
        sync_mercurial_env: ['C=d'], sync_mercurial_pull_env: ['E=f'], sync_mercurial_pull_extra_opts: ['-u'],
      }
    end

    it do
      is_expected.to contain_file('/etc/portage/repos.conf/gentoo.conf')
        .with_content(%r{^sync-mercurial-clone-env = A=b$})
        .with_content(%r{^sync-mercurial-clone-extra-opts = --pull$})
        .with_content(%r{^sync-mercurial-env = C=d$})
        .with_content(%r{^sync-mercurial-pull-env = E=f$})
        .with_content(%r{^sync-mercurial-pull-extra-opts = -u$})
    end
  end

  context 'with a cvs repository' do
    let(:params) { { root: '/', sync_type: 'cvs', sync_uri: 'cvs://:pserver:anon@example.org:/cvs', sync_cvs_repo: 'gentoo' } }

    it { is_expected.to contain_file('/etc/portage/repos.conf/gentoo.conf').with_content(%r{^sync-cvs-repo = gentoo$}) }
  end

  context 'with a webrsync repository' do
    let(:params) do
      {
        root: '/', sync_type: 'webrsync', sync_uri: 'https://example.org/snapshots',
        sync_webrsync_delta: true, sync_webrsync_keep_snapshots: false, sync_webrsync_verify_signature: true,
      }
    end

    it do
      is_expected.to contain_file('/etc/portage/repos.conf/gentoo.conf')
        .with_content(%r{^sync-webrsync-delta = yes$})
        .with_content(%r{^sync-webrsync-keep-snapshots = no$})
        .with_content(%r{^sync-webrsync-verify-signature = yes$})
    end
  end

  {
    'git' => ['rsync', { sync_git_env: ['A=b'] }],
    'mercurial' => ['rsync', { sync_mercurial_env: ['A=b'] }],
    'cvs' => ['rsync', { sync_cvs_repo: 'gentoo' }],
    'webrsync' => ['rsync', { sync_webrsync_delta: true }],
    'rsync' => ['git', { sync_rcu: true }],
  }.each do |type, (other, extra)|
    context "with #{type}-only parameters on a #{other} repository" do
      let(:params) { { root: '/', sync_type: other, sync_uri: 'https://example.org/x' }.merge(extra) }

      it { is_expected.to compile.and_raise_error(%r{require sync_type #{type}}) }
    end
  end

  context 'with an invalid sync_umask' do
    let(:params) { super().merge(sync_umask: '999') }

    it { is_expected.to compile.and_raise_error(%r{sync_umask}) }
  end

  context 'with sync disabled' do
    let(:params) { super().merge(sync: false) }

    it { is_expected.not_to contain_exec('emaint sync -r gentoo') }
  end

  context 'without a sync_type' do
    let(:params) { { root: '/', location: '/srv/local' } }

    it { is_expected.to contain_file('/etc/portage/repos.conf/gentoo.conf').with_content(%r{^location = /srv/local$}) }
    it { is_expected.not_to contain_file('/etc/portage/repos.conf/gentoo.conf').with_content(%r{sync-type}) }
    it { is_expected.not_to contain_exec('emaint sync -r gentoo') }
  end

  context 'with a chroot root' do
    let(:params) { super().merge(root: '/var/lib/portage-targets/stage3') }

    it { is_expected.to contain_file('/var/lib/portage-targets/stage3/etc/portage/repos.conf/gentoo.conf') }
    it { is_expected.not_to contain_exec('emaint sync -r gentoo') }
  end

  context 'with purge disabled and purge_ignore' do
    let(:params) { super().merge(purge: false, purge_ignore: ['keep-*']) }

    it { is_expected.to contain_file('/etc/portage/repos.conf').with(recurse: false, purge: false, ignore: ['keep-*']) }
  end

  context 'with two repositories in one target' do
    let(:pre_condition) { "portage::repository { 'host/guru': root => '/', sync_type => 'git', sync_uri => 'https://example.org/guru.git' }" }

    it { is_expected.to compile.with_all_deps }
  end

  context 'with sync_type but no sync_uri' do
    let(:params) { { root: '/', sync_type: 'rsync' } }

    it { is_expected.to compile.and_raise_error(%r{sync_uri is required}) }
  end

  context 'with rsync options on a git repository' do
    let(:params) { { root: '/', sync_type: 'git', sync_uri: 'https://example.org/x.git', sync_rsync_verify_jobs: 2 } }

    it { is_expected.to compile.and_raise_error(%r{require sync_type rsync}) }
  end

  context 'with the reserved name DEFAULT' do
    let(:title) { 'host/DEFAULT' }

    it { is_expected.to compile.and_raise_error(%r{DEFAULT}) }
  end

  context 'with an invalid sync_uri' do
    let(:params) { super().merge(sync_uri: 'not a uri') }

    it { is_expected.to compile.and_raise_error(%r{sync_uri}) }
  end
end
