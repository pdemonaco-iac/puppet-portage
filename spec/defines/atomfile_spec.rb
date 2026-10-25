# frozen_string_literal: true

require 'spec_helper'

describe 'portage::atomfile' do
  let(:title) { 'host/web' }
  let(:params) { { root: '/', kind: 'package.use', entries: { 'www-servers/nginx' => %w[ssl http2], 'app-misc/foo' => [] } } }

  it do
    is_expected.to contain_file('/etc/portage/package.use').with(
      ensure: 'directory', recurse: true, purge: true, ignore: [],
    )
  end

  it do
    is_expected.to contain_file('/etc/portage/package.use/web').with(
      ensure: 'file', owner: 'root', group: 'root', mode: '0644',
    ).with_content(<<~CONF)
      # This file is managed by Puppet. Local changes will be overwritten.
      app-misc/foo
      www-servers/nginx ssl http2
    CONF
  end

  context 'with purge disabled and purge_ignore' do
    let(:params) { super().merge(purge: false, purge_ignore: ['local-*']) }

    it { is_expected.to contain_file('/etc/portage/package.use').with(recurse: false, purge: false, ignore: ['local-*']) }
  end

  context 'with an explicit filename and a chroot root' do
    let(:params) { super().merge(root: '/var/lib/portage-targets/stage3', filename: 'custom') }

    it { is_expected.to contain_file('/var/lib/portage-targets/stage3/etc/portage/package.use/custom') }
    it { is_expected.to contain_file('/var/lib/portage-targets/stage3/etc/portage/package.use').that_comes_before('File[/var/lib/portage-targets/stage3/etc/portage/package.use/custom]') }
  end

  context 'with two files of the same kind' do
    let(:pre_condition) { "portage::atomfile { 'host/other': root => '/', kind => 'package.use' }" }

    it { is_expected.to compile.with_all_deps }
    it { is_expected.to contain_file('/etc/portage/package.use/other') }
  end

  context 'with an invalid atom' do
    let(:params) { super().merge(entries: { 'garbage' => ['ssl'] }) }

    it { is_expected.to compile.and_raise_error(%r{garbage|entries}) }
  end

  context 'with an invalid kind' do
    let(:params) { super().merge(kind: 'package.env') }

    it { is_expected.to compile.and_raise_error(%r{kind}) }
  end
end
