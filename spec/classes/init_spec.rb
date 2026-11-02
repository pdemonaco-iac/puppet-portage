# frozen_string_literal: true

require 'spec_helper'

describe 'portage' do
  # FacterDB has no Gentoo fact sets, so on_supported_os would yield no examples.
  let(:facts) do
    {
      os: {
        name: 'Gentoo',
        family: 'Gentoo',
        architecture: 'amd64',
        hardware: 'x86_64',
        release: { full: 'rolling', major: 'rolling' },
      },
      kernel: 'Linux',
    }
  end

  it { is_expected.to compile.with_all_deps }
  it { is_expected.to contain_portage__target('host').with(root: '/', purge: true, purge_ignore: {}) }
  it { is_expected.to contain_file('/etc/portage').without_purge }
  it { is_expected.not_to contain_file('/etc/portage/gnupg') }

  context 'with parameters' do
    let(:params) do
      {
        make_conf: { 'MAKEOPTS' => ['-j8'] },
        repositories: { 'gentoo' => { 'sync_type' => 'rsync', 'sync_uri' => 'rsync://m.example/gentoo' } },
        profile: { 'path' => 'default/linux/amd64/23.0' },
        masks: { 'pins' => { 'atoms' => ['>=dev-lang/rust-2'] } },
        unmasks: { 'unpins' => { 'atoms' => ['=dev-lang/rust-1.80.0'] } },
        purge: false,
        purge_ignore: { 'repositories' => ['local-*'] },
      }
    end

    it { is_expected.to compile.with_all_deps }
    it { is_expected.to contain_portage__target('host').with(purge: false, purge_ignore: { 'repositories' => ['local-*'] }) }
    it { is_expected.to contain_portage__repository('host/gentoo').with(root: '/', purge: false, purge_ignore: ['local-*']) }
    it { is_expected.to contain_file('/etc/portage/make.conf').with_content(%r{MAKEOPTS="-j8"}) }
    it { is_expected.to contain_file('/etc/portage/make.profile').with_target('../../var/db/repos/gentoo/profiles/default/linux/amd64/23.0') }
    it { is_expected.to contain_file('/etc/portage/package.unmask/unpins') }
  end

  context 'with an invalid make_conf key' do
    let(:params) { { make_conf: { 'NOT_A_VAR' => ['x'] } } }

    it { is_expected.to compile.and_raise_error(%r{NOT_A_VAR}) }
  end
end
