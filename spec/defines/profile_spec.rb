# frozen_string_literal: true

require 'spec_helper'

describe 'portage::profile' do
  let(:title) { 'host/profile' }
  let(:params) { { root: '/', path: 'default/linux/amd64/23.0/systemd' } }

  it do
    is_expected.to contain_file('/etc/portage/make.profile')
      .with(ensure: 'link', target: '../../var/db/repos/gentoo/profiles/default/linux/amd64/23.0/systemd')
  end

  context 'with a chroot root' do
    let(:params) { super().merge(root: '/var/lib/portage-targets/stage3') }

    it do
      is_expected.to contain_file('/var/lib/portage-targets/stage3/etc/portage/make.profile')
        .with(ensure: 'link', target: '../../var/db/repos/gentoo/profiles/default/linux/amd64/23.0/systemd')
    end
  end

  context 'with another repo' do
    let(:params) { super().merge(repo: 'guru') }

    it { is_expected.to contain_file('/etc/portage/make.profile').with_target('../../var/db/repos/guru/profiles/default/linux/amd64/23.0/systemd') }
  end

  ['../evil', '/abs/path', 'default/../x', 'a//b', ''].each do |bad|
    context "with invalid path #{bad.inspect}" do
      let(:params) { super().merge(path: bad) }

      it { is_expected.to compile.and_raise_error(%r{path}) }
    end
  end
end
