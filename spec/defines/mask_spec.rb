# frozen_string_literal: true

require 'spec_helper'

describe 'portage::mask' do
  let(:title) { 'host/pins' }
  let(:params) { { root: '/', atoms: ['>=dev-lang/ruby-3.4', 'app-misc/foo'] } }

  it { is_expected.to contain_portage__atomfile('host/pins').with(kind: 'package.mask') }

  it do
    is_expected.to contain_file('/etc/portage/package.mask/pins').with_content(<<~CONF)
      # This file is managed by Puppet. Local changes will be overwritten.
      >=dev-lang/ruby-3.4
      app-misc/foo
    CONF
  end

  context 'with unmask' do
    let(:params) { super().merge(unmask: true) }

    it { is_expected.to contain_file('/etc/portage/package.unmask').with(ensure: 'directory', purge: true) }
    it { is_expected.to contain_file('/etc/portage/package.unmask/pins') }
    it { is_expected.not_to contain_file('/etc/portage/package.mask/pins') }
  end

  context 'with an invalid atom' do
    let(:params) { { root: '/', atoms: ['nope'] } }

    it { is_expected.to compile.and_raise_error(%r{atoms}) }
  end
end
