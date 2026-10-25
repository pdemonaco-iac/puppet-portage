# frozen_string_literal: true

require 'spec_helper'

describe 'portage::binhost_key' do
  let(:title) { 'host/buildhost' }
  let(:fpr) { '0123456789ABCDEF0123456789ABCDEF01234567' }
  let(:public_key) { "-----BEGIN PGP PUBLIC KEY BLOCK-----\n\npublicpublic\n-----END PGP PUBLIC KEY BLOCK-----\n" }
  let(:params) { { root: '/', public_key: public_key, fingerprint: fpr } }

  it { is_expected.to compile.with_all_deps }

  it { is_expected.to contain_file('/etc/portage/binhost-keys').with(ensure: 'directory', purge: true) }
  it { is_expected.to contain_file('/etc/portage/binhost-keys/buildhost.asc').with(ensure: 'file', mode: '0644', content: public_key) }

  it 'never manages, and so never purges, the getuto keyring' do
    is_expected.not_to contain_file('/etc/portage/gnupg')
    is_expected.not_to contain_portage__managed_dir('/etc/portage/gnupg')
  end

  it { is_expected.to contain_exec('getuto /').with(command: 'getuto', environment: ['ROOT=/'], creates: '/etc/portage/gnupg') }

  it do
    gpg = 'gpg --homedir /etc/portage/gnupg --batch --no-tty'
    is_expected.to contain_exec("import binhost key #{fpr} into /").with(
      command: [
        "#{gpg} --import /etc/portage/binhost-keys/buildhost.asc",
        "#{gpg} --yes --passphrase-file=/etc/portage/gnupg/pass --pinentry-mode loopback --quick-lsign-key #{fpr}",
        "#{gpg} --check-trustdb",
        'chmod ugo+r /etc/portage/gnupg/trustdb.gpg',
      ].join(' && '),
      unless: "#{gpg} --with-colons --list-keys #{fpr} | grep -q '^pub:[fu]:'",
      provider: 'shell',
    ).that_requires(['Exec[getuto /]', 'File[/etc/portage/binhost-keys/buildhost.asc]'])
  end

  it { is_expected.not_to contain_exec("import binhost key #{fpr} into /").with_refreshonly(true) }

  context 'with a 0x-prefixed lowercase fingerprint and a filename' do
    let(:params) { super().merge(fingerprint: "0x#{fpr.downcase}", filename: 'lan') }

    it { is_expected.to contain_exec("import binhost key #{fpr} into /") }
    it { is_expected.to contain_file('/etc/portage/binhost-keys/lan.asc') }
  end

  context 'with a chroot root' do
    let(:params) { super().merge(root: '/var/lib/portage-targets/stage3') }

    it { is_expected.to contain_exec('getuto /var/lib/portage-targets/stage3').with(environment: ['ROOT=/var/lib/portage-targets/stage3'], creates: '/var/lib/portage-targets/stage3/etc/portage/gnupg') }
    it { is_expected.to contain_exec("import binhost key #{fpr} into /var/lib/portage-targets/stage3").with_unless(%r{\Agpg --homedir /var/lib/portage-targets/stage3/etc/portage/gnupg }) }
    it { is_expected.to contain_file('/var/lib/portage-targets/stage3/etc/portage/binhost-keys/buildhost.asc') }
  end

  context 'with two keys in one root' do
    let(:pre_condition) do
      "portage::binhost_key { 'host/other': root => '/', fingerprint => '89ABCDEF0123456789ABCDEF0123456789ABCDEF', public_key => \"-----BEGIN PGP PUBLIC KEY BLOCK-----\\nx\\n-----END PGP PUBLIC KEY BLOCK-----\\n\" }"
    end

    it { is_expected.to compile.with_all_deps }
    it { is_expected.to contain_exec('import binhost key 89ABCDEF0123456789ABCDEF0123456789ABCDEF into /').that_requires('Exec[getuto /]') }
  end

  context 'with a short key id' do
    let(:params) { super().merge(fingerprint: '0x40DCF18E97150795') }

    it { is_expected.to compile.and_raise_error(%r{fingerprint}) }
  end

  context 'with a private key' do
    let(:params) { super().merge(public_key: "-----BEGIN PGP PRIVATE KEY BLOCK-----\nx\n-----END PGP PRIVATE KEY BLOCK-----\n") }

    it { is_expected.to compile.and_raise_error(%r{public_key}) }
  end
end
