# @summary Installs the binpkg signing key into each build target root.
#
# Each root gets a private GnuPG home at /etc/portage/binpkg-signing holding
# the signing key, imported once with `gpg --import`. Portage signs with it
# when the target's make.conf carries `$make_conf` (see below). The private
# key is a Sensitive value and is redacted from catalogs, reports and logs.
#
# `$make_conf` and `$public_key` are exposed for portage::buildhost, which
# merges `$make_conf` into every target's make.conf, and for distribution to
# consumers.
#
# The private key is never purged: the GnuPG home lives beside, not inside,
# any directory this module purges, and /etc/portage/gnupg (the getuto
# keyring used for verification) is untouched.
#
# @param private_key
#   ASCII-armored private signing key, supplied through eyaml.
# @param public_key
#   ASCII-armored public key matching `private_key`.
# @param key_id
#   Key ID or fingerprint Portage signs with (BINPKG_GPG_SIGNING_KEY); the
#   key must be usable without a passphrase.
# @param roots
#   Config roots to install the key into.
#
# @example Hiera data
#   portage::buildhost::signing::roots:
#     - /var/lib/portage-targets/stage3
#   portage::buildhost::signing::key_id: '0x40DCF18E97150795'
#   portage::buildhost::signing::public_key: |
#     -----BEGIN PGP PUBLIC KEY BLOCK-----
#     ...
#   portage::buildhost::signing::private_key: ENC[PKCS7,...]
class portage::buildhost::signing (
  Sensitive[Pattern[/\A-----BEGIN PGP PRIVATE KEY BLOCK-----[\s\S]+-----END PGP PRIVATE KEY BLOCK-----\s*\z/]] $private_key,
  Pattern[/\A-----BEGIN PGP PUBLIC KEY BLOCK-----[\s\S]+-----END PGP PUBLIC KEY BLOCK-----\s*\z/] $public_key,
  Pattern[/\A(0x)?[0-9A-Fa-f]{16,40}!?\z/] $key_id,
  Array[Portage::Targetroot, 1] $roots,
) {
  $gpg_home = '/etc/portage/binpkg-signing'

  $make_conf = {
    'FEATURES'                    => ['binpkg-signing'],
    'BINPKG_GPG_SIGNING_GPG_HOME' => $gpg_home,
    'BINPKG_GPG_SIGNING_KEY'      => $key_id,
  }

  $roots.each |$root| {
    $prefix = $root ? {
      '/'     => '',
      default => $root,
    }
    $home = "${prefix}${gpg_home}"

    file { $home:
      ensure => directory,
      owner  => 'root',
      group  => 'root',
      mode   => '0700',
    }

    file { "${home}/signing-key.asc":
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0600',
      content => $private_key,
      require => File[$home],
    }

    file { "${home}/signing-key.pub.asc":
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => $public_key,
      require => File[$home],
    }

    exec { "import binpkg signing key into ${root}":
      command   => "gpg --homedir ${home} --batch --import ${home}/signing-key.asc",
      unless    => "gpg --homedir ${home} --batch --list-secret-keys ${key_id}",
      path      => ['/usr/bin', '/bin'],
      logoutput => false,
      require   => File["${home}/signing-key.asc"],
    }
  }
}
