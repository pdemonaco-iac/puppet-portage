# frozen_string_literal: true

require 'spec_helper'

describe 'portage::package_env' do
  let(:title) { 'host/heavy' }
  let(:params) { { root: '/', entries: { 'www-client/firefox' => ['lowmem'] } } }

  context 'with a matching portage::env in the same target' do
    let(:pre_condition) { "portage::env { 'host/lowmem': root => '/', config => { 'MAKEOPTS' => ['-j1'] } }" }

    it { is_expected.to compile.with_all_deps }
    it { is_expected.to contain_portage__atomfile('host/heavy').with(kind: 'package.env').that_requires('Portage::Env[host/lowmem]') }

    it do
      is_expected.to contain_file('/etc/portage/package.env/heavy').with_content(<<~CONF)
        # This file is managed by Puppet. Local changes will be overwritten.
        www-client/firefox lowmem
      CONF
    end
  end

  context 'with no matching portage::env' do
    it { is_expected.to compile.and_raise_error(%r{Portage::Env\[host/lowmem\]}) }
  end

  context 'with an env declared in another target' do
    let(:pre_condition) { "portage::env { 'other/lowmem': root => '/var/lib/portage-targets/other' }" }

    it { is_expected.to compile.and_raise_error(%r{Portage::Env\[host/lowmem\]}) }
  end

  context 'with an invalid atom' do
    let(:params) { super().merge(entries: { 'nope' => ['lowmem'] }) }

    it { is_expected.to compile.and_raise_error(%r{entries}) }
  end
end
