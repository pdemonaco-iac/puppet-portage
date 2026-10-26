# frozen_string_literal: true

require 'spec_helper'

describe 'portage::patch' do
  let(:title) { 'host/fix-build.patch' }
  let(:params) { { root: '/', package: 'sys-apps/sed-4.8-r1:0', content: "--- a\n+++ b\n" } }

  it { is_expected.to contain_file('/etc/portage/patches').with(ensure: 'directory', recurse: true, purge: true) }
  it { is_expected.to contain_file('/etc/portage/patches/sys-apps').with(ensure: 'directory') }
  it { is_expected.to contain_file('/etc/portage/patches/sys-apps/sed-4.8-r1:0').with(ensure: 'directory') }

  it do
    is_expected.to contain_file('/etc/portage/patches/sys-apps/sed-4.8-r1:0/fix-build.patch').with(
      ensure: 'file', mode: '0644', content: "--- a\n+++ b\n",
    )
  end

  it { is_expected.not_to contain_exec('rebuild') }

  context 'with source and a .diff filename' do
    let(:params) { { root: '/', package: 'sys-apps/sed', source: 'puppet:///modules/profile/sed.diff', filename: 'sed.diff' } }

    it { is_expected.to contain_file('/etc/portage/patches/sys-apps/sed/sed.diff').with_source('puppet:///modules/profile/sed.diff') }
  end

  context 'with a chroot root' do
    let(:params) { super().merge(root: '/var/lib/portage-targets/stage3') }

    it { is_expected.to contain_file('/var/lib/portage-targets/stage3/etc/portage/patches/sys-apps/sed-4.8-r1:0/fix-build.patch') }
  end

  context 'with two patches for one package and one for the same category' do
    let(:pre_condition) do
      <<~PP
        portage::patch { 'host/b.patch': root => '/', package => 'sys-apps/sed-4.8-r1:0', content => 'x' }
        portage::patch { 'host/c.patch': root => '/', package => 'sys-apps/grep', content => 'x' }
      PP
    end

    it { is_expected.to compile.with_all_deps }
  end

  context 'with neither content nor source' do
    let(:params) { { root: '/', package: 'sys-apps/sed' } }

    it { is_expected.to compile.and_raise_error(%r{exactly one of content and source}) }
  end

  context 'with both content and source' do
    let(:params) { super().merge(source: 'puppet:///modules/profile/sed.diff') }

    it { is_expected.to compile.and_raise_error(%r{exactly one of content and source}) }
  end

  context 'with an invalid package directory' do
    let(:params) { super().merge(package: '../etc') }

    it { is_expected.to compile.and_raise_error(%r{package}) }
  end

  context 'with a filename lacking a patch extension' do
    let(:params) { super().merge(filename: 'fix.txt') }

    it { is_expected.to compile.and_raise_error(%r{filename}) }
  end
end
