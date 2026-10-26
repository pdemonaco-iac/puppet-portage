# frozen_string_literal: true

require 'open3'
require 'spec_helper'

describe 'portage::buildhost::publish' do
  let(:params) { { targets: %w[desktop server], repos: %w[gentoo guru] } }
  let(:script) { catalogue.resource('File', '/usr/local/sbin/portage-publish')[:content] }
  let(:commands) { script.lines.reject { |line| line.start_with?('#') } }

  it { is_expected.to compile.with_all_deps }

  it { is_expected.to contain_file('/usr/local/sbin/portage-publish').with(ensure: 'file', mode: '0755', owner: 'root', group: 'root') }

  describe 'layout' do
    it { is_expected.to contain_file('/srv/portage-mirror').with(ensure: 'directory', mode: '0755') }
    it { is_expected.to contain_file('/srv/portage-mirror/gentoo').with_ensure('directory') }
    it { is_expected.to contain_file('/srv/portage-mirror/guru').with_ensure('directory') }
    it { is_expected.to contain_file('/srv/binhost').with(ensure: 'directory', mode: '0755') }
    it { is_expected.to contain_file('/srv/binhost/desktop').with_ensure('directory') }
    it { is_expected.to contain_file('/srv/binhost/server').with_ensure('directory') }
  end

  describe 'script' do
    it { expect(script).to start_with("#!/bin/bash\n") }
    it { expect(script).to include("targets=(desktop server)\n") }
    it { expect(script).to include("repos=(gentoo guru)\n") }
    it { expect(script).to include("emerge_args=(--update --deep --newuse @world)\n") }
    it { expect(script).to include("target_emerge=/usr/local/sbin/target-emerge\n") }
    it { expect(script).to include("mirror_dir=/srv/portage-mirror\n") }
    it { expect(script).to include("binhost_dir=/srv/binhost\n") }
    it { expect(script).to include('flock -n 9') }

    it 'syncs, builds every target, then publishes repositories, binpkgs and indexes, in that order' do
      positions = [
        'emaint sync --auto',
        '"$target_emerge" "$target" "${emerge_args[@]}"',
        'rsync --archive --delete --delay-updates "${repos_dir}/${repo}/" "${mirror_dir}/${repo}/"',
        'rsync --archive --delete --delay-updates "${pkgdir_root}/${target}/" "${binhost_dir}/${target}/"',
        'PKGDIR="${binhost_dir}/${target}" emaint binhost --fix',
      ].map { |text| script.index(text) }

      expect(positions).to all(be_an(Integer))
      expect(positions).to eq(positions.sort)
    end

    it 'stops before publishing when a build fails' do
      expect(script).to include('set -euo pipefail')
    end

    it 'never regenerates repository metadata' do
      expect(commands.join).not_to match(%r{egencache|metadata|--regen})
    end

    it 'runs the targets one after the other' do
      expect(commands.join).not_to match(%r{&\s*$|xargs|parallel})
    end

    it 'is valid bash' do
      _out, err, status = Open3.capture3('bash', '-n', stdin_data: script)
      expect(status).to be_success, err
    end
  end

  describe 'cron' do
    it { is_expected.to contain_cron('portage-publish').with(ensure: 'absent', user: 'root') }

    context 'with a schedule' do
      let(:params) { super().merge(cron_schedule: { 'minute' => '30', 'hour' => '3', 'weekday' => '0' }) }

      it do
        is_expected.to contain_cron('portage-publish').with(
          ensure: 'present',
          command: '/usr/local/sbin/portage-publish',
          user: 'root',
          minute: '30',
          hour: '3',
          monthday: '*',
          month: '*',
          weekday: '0',
          environment: ['SHELL=/bin/bash', 'PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'],
        ).that_requires('File[/usr/local/sbin/portage-publish]')
      end
    end

    context 'with a schedule and a user' do
      let(:params) { super().merge(cron_schedule: { 'minute' => '0', 'hour' => '*/6', 'user' => 'builder' }) }

      it { is_expected.to contain_cron('portage-publish').with(ensure: 'present', minute: '0', hour: '*/6', weekday: '*', user: 'builder') }
    end

    context 'with an invalid schedule' do
      let(:params) { super().merge(cron_schedule: { 'minute' => '0; rm -rf /', 'hour' => '3' }) }

      it { is_expected.to compile.and_raise_error(%r{minute}) }
    end
  end

  context 'with custom paths' do
    let(:params) { super().merge(mirror_dir: '/srv/mirror', binhost_dir: '/srv/packages', script_path: '/usr/local/bin/publish') }

    it { is_expected.to contain_file('/srv/mirror/gentoo') }
    it { is_expected.to contain_file('/srv/packages/desktop') }
    it { is_expected.to contain_file('/usr/local/bin/publish').with_content(%r{^binhost_dir=/srv/packages$}) }
    it { is_expected.to contain_cron('portage-publish').with_command('/usr/local/bin/publish') }
  end

  context 'with an invalid target name' do
    let(:params) { { targets: ['../etc'] } }

    it { is_expected.to compile.and_raise_error(%r{targets}) }
  end
end
