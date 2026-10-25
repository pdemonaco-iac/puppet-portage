# frozen_string_literal: true

require 'spec_helper'

describe 'portage::accept_keywords' do
  let(:title) { 'host/web' }
  let(:params) { { root: '/', entries: { '=dev-lang/ruby-3.3*' => ['~amd64'] } } }

  it { is_expected.to contain_portage__atomfile('host/web').with(kind: 'package.accept_keywords', root: '/') }
  it { is_expected.to contain_file('/etc/portage/package.accept_keywords/web').with_content(%r{^=dev-lang/ruby-3\.3\* ~amd64$}) }

  context 'with a chroot root' do
    let(:params) { super().merge(root: '/var/lib/portage-targets/stage3') }

    it { is_expected.to contain_file('/var/lib/portage-targets/stage3/etc/portage/package.accept_keywords/web') }
  end

  context 'with invalid entries' do
    let(:params) { { root: '/', entries: { 'www-servers/nginx' => ['AMD64'] } } }

    it { is_expected.to compile.and_raise_error(%r{entries}) }
  end
end
