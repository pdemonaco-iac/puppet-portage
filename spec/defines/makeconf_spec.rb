# frozen_string_literal: true

require 'spec_helper'

describe 'portage::makeconf' do
  let(:facts) do
    { os: { family: 'Gentoo', name: 'Gentoo', architecture: 'amd64' }, kernel: 'Linux' }
  end
  let(:title) { 'host/make.conf' }
  let(:params) { { root: '/', config: config } }

  context 'with scalar, array, escaped and ${VAR} values' do
    let(:config) do
      {
        'CFLAGS' => ['-O2', '-pipe', '-march=native'],
        'MAKEOPTS' => ['-j8', '-l8'],
        'CXXFLAGS' => ['${CFLAGS}'],
        'GENTOO_MIRRORS' => ['rsync://mirror.example/gentoo', 'https://mirror2.example/gentoo'],
        'EMERGE_DEFAULT_OPTS' => ['--jobs=4', '--usepkg', '--exclude "sys-apps/foo"'],
        'USE' => ['ssl', '-gtk'],
        'FEATURES' => %w[buildpkg -sandbox],
        'USE_ORDER' => %w[env pkg conf],
        'PORTAGE_BINHOST_TTL' => 3600,
        'NOCOLOR' => true,
        'BINPKG_FORMAT' => 'gpkg',
      }
    end

    it do
      is_expected.to contain_file('/etc/portage/make.conf').with(
        ensure: 'file', owner: 'root', group: 'root', mode: '0644',
      ).with_content(<<~'CONF')
        # This file is managed by Puppet. Local changes will be overwritten.
        BINPKG_FORMAT="gpkg"
        CFLAGS="-O2 -pipe -march=native"
        CXXFLAGS="${CFLAGS}"
        EMERGE_DEFAULT_OPTS="--jobs=4 --usepkg --exclude \"sys-apps/foo\""
        FEATURES="buildpkg -sandbox"
        GENTOO_MIRRORS="rsync://mirror.example/gentoo https://mirror2.example/gentoo"
        MAKEOPTS="-j8 -l8"
        NOCOLOR="true"
        PORTAGE_BINHOST_TTL="3600"
        USE="ssl -gtk"
        USE_ORDER="env:pkg:conf"
      CONF
    end
  end

  context 'with a chroot root' do
    let(:params) { { root: '/var/lib/portage-targets/stage3', config: config } }

    context 'without -march=native' do
      let(:config) { { 'CFLAGS' => ['-O2', '-march=x86-64-v3'] } }

      it { is_expected.to contain_file('/var/lib/portage-targets/stage3/etc/portage/make.conf') }
    end

    context 'with -march=native in an array' do
      let(:config) { { 'CFLAGS' => ['-O2', '-march=native'] } }

      it { is_expected.to compile.and_raise_error(%r{-march=native}) }
    end

    context 'with -march=native in a string' do
      let(:config) { { 'CXXFLAGS' => ['-O2 -march=native'] } }

      it { is_expected.to compile.and_raise_error(%r{-march=native}) }
    end
  end

  context 'with an unsupported variable name' do
    let(:config) { { 'PORTDIR' => '/var/db/repos/gentoo' } }

    it { is_expected.to compile.and_raise_error(%r{PORTDIR}) }
  end

  context 'with stdlib-typed path and mode values' do
    let(:config) { { 'PKGDIR' => '/var/cache/binpkgs', 'PORTAGE_WORKDIR_MODE' => '0700' } }

    it { is_expected.to contain_file('/etc/portage/make.conf').with_content(%r{^PKGDIR="/var/cache/binpkgs"$}) }
  end

  context 'with a relative path' do
    let(:config) { { 'PKGDIR' => 'binpkgs' } }

    it { is_expected.to compile.and_raise_error(%r{PKGDIR}) }
  end

  context 'with a value of the wrong type' do
    let(:config) { { 'USE' => 'ssl -gtk' } }

    it { is_expected.to compile.and_raise_error(%r{USE}) }
  end
end
