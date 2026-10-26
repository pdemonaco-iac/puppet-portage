# frozen_string_literal: true

require 'spec_helper'

describe 'portage::buildhost::signing' do
  let(:private_key) { "-----BEGIN PGP PRIVATE KEY BLOCK-----\n\nsecretsecret\n-----END PGP PRIVATE KEY BLOCK-----\n" }
  let(:public_key) { "-----BEGIN PGP PUBLIC KEY BLOCK-----\n\npublicpublic\n-----END PGP PUBLIC KEY BLOCK-----\n" }
  let(:chroot) { '/var/lib/portage-targets/stage3' }
  let(:params) do
    {
      private_key: sensitive(private_key),
      public_key: public_key,
      key_id: '0x40DCF18E97150795',
      roots: [chroot],
    }
  end

  it { is_expected.to compile.with_all_deps }

  it { is_expected.to contain_file("#{chroot}/etc/portage/binpkg-signing").with(ensure: 'directory', mode: '0700', owner: 'root') }

  it do
    is_expected.to contain_file("#{chroot}/etc/portage/binpkg-signing/signing-key.asc")
      .with(ensure: 'file', mode: '0600', owner: 'root', group: 'root', content: sensitive(private_key))
  end

  it do
    is_expected.to contain_file("#{chroot}/etc/portage/binpkg-signing/signing-key.pub.asc")
      .with(ensure: 'file', mode: '0644', content: public_key)
  end

  it do
    is_expected.to contain_exec("import binpkg signing key into #{chroot}").with(
      command: "gpg --homedir #{chroot}/etc/portage/binpkg-signing --batch --import #{chroot}/etc/portage/binpkg-signing/signing-key.asc",
      unless: "gpg --homedir #{chroot}/etc/portage/binpkg-signing --batch --list-secret-keys 0x40DCF18E97150795",
      logoutput: false,
    ).that_requires("File[#{chroot}/etc/portage/binpkg-signing/signing-key.asc]")
  end

  it { is_expected.not_to contain_file("#{chroot}/etc/portage/gnupg") }

  context 'when a profile reads the exposed variables' do
    let(:post_condition) do
      <<~PP
        $conf = $portage::buildhost::signing::make_conf
        notify { 'features': message => $conf['FEATURES'][0] }
        notify { 'home': message => $conf['BINPKG_GPG_SIGNING_GPG_HOME'] }
        notify { 'key': message => $conf['BINPKG_GPG_SIGNING_KEY'] }
        notify { 'public': message => $portage::buildhost::signing::public_key }
      PP
    end

    it { is_expected.to contain_notify('features').with_message('binpkg-signing') }
    it { is_expected.to contain_notify('home').with_message('/etc/portage/binpkg-signing') }
    it { is_expected.to contain_notify('key').with_message('0x40DCF18E97150795') }
    it { is_expected.to contain_notify('public').with_message(public_key) }
  end

  context 'with the host and two chroots' do
    let(:params) { super().merge(roots: ['/', chroot, '/var/lib/portage-targets/other']) }

    it { is_expected.to compile.with_all_deps }

    ['/etc/portage/binpkg-signing', '/var/lib/portage-targets/stage3/etc/portage/binpkg-signing', '/var/lib/portage-targets/other/etc/portage/binpkg-signing'].each do |home|
      it { is_expected.to contain_file(home).with_mode('0700') }
      it { is_expected.to contain_file("#{home}/signing-key.asc").with_content(sensitive(private_key)) }
      it { is_expected.to contain_file("#{home}/signing-key.pub.asc").with_content(public_key) }
    end

    it { is_expected.to contain_exec('import binpkg signing key into /').with_unless(%r{--homedir /etc/portage/binpkg-signing }) }
    it { is_expected.to contain_exec('import binpkg signing key into /var/lib/portage-targets/other') }
  end

  context 'with a host target in the same catalog' do
    let(:pre_condition) { "portage::target { 'host': root => '/', make_conf => { 'FEATURES' => ['binpkg-signing'], 'BINPKG_GPG_SIGNING_KEY' => '0x40DCF18E97150795' } }" }
    let(:params) { super().merge(roots: ['/']) }

    it { is_expected.to compile.with_all_deps }
    it { is_expected.to contain_file('/etc/portage').that_comes_before('File[/etc/portage/binpkg-signing]') }
  end

  context 'with a private key that is not a Sensitive value' do
    let(:params) { super().merge(private_key: private_key) }

    it { is_expected.to compile.and_raise_error(%r{private_key}) }
  end

  context 'with a public key given as the private key' do
    let(:params) { super().merge(private_key: sensitive(public_key)) }

    it { is_expected.to compile.and_raise_error(%r{private_key}) }
  end

  context 'with an invalid key_id' do
    let(:params) { super().merge(key_id: 'not a key') }

    it { is_expected.to compile.and_raise_error(%r{key_id}) }
  end

  context 'with no roots' do
    let(:params) { super().merge(roots: []) }

    it { is_expected.to compile.and_raise_error(%r{roots}) }
  end
end
