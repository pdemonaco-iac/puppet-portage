# frozen_string_literal: true

require 'spec_helper'

describe 'portage::postsync' do
  let(:title) { 'host/10-notify' }
  let(:params) { { root: '/', content: "#!/bin/sh\necho synced\n" } }

  it { is_expected.to contain_file('/etc/portage/postsync.d').with(ensure: 'directory', recurse: true, purge: true) }
  it { is_expected.to contain_file('/etc/portage/postsync.d/10-notify').with(ensure: 'file', mode: '0755', content: "#!/bin/sh\necho synced\n") }

  context 'with per_repo' do
    let(:params) { super().merge(per_repo: true) }

    it { is_expected.to contain_file('/etc/portage/repo.postsync.d').with(ensure: 'directory', purge: true) }
    it { is_expected.to contain_file('/etc/portage/repo.postsync.d/10-notify').with_mode('0755') }
    it { is_expected.not_to contain_file('/etc/portage/postsync.d/10-notify') }
  end

  context 'with a chroot root, purge disabled and purge_ignore' do
    let(:params) { super().merge(root: '/var/lib/portage-targets/stage3', purge: false, purge_ignore: ['local-*']) }

    it { is_expected.to contain_file('/var/lib/portage-targets/stage3/etc/portage/postsync.d').with(recurse: false, purge: false, ignore: ['local-*']) }
    it { is_expected.to contain_file('/var/lib/portage-targets/stage3/etc/portage/postsync.d/10-notify') }
  end

  context 'with two hooks in one target' do
    let(:pre_condition) { "portage::postsync { 'host/20-other': root => '/', content => '#!/bin/sh' }" }

    it { is_expected.to compile.with_all_deps }
  end

  context 'with an invalid filename' do
    let(:params) { super().merge(filename: '../evil') }

    it { is_expected.to compile.and_raise_error(%r{filename}) }
  end
end
