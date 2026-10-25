# @summary Imports a binhost's signing public key into the getuto keyring of a target.
#
# The keyring is /etc/portage/gnupg in the target's root. It is never managed
# as a file resource, so it is never purged: getuto initialises it once (only
# getuto may create it, or it skips adding the Gentoo release keys and its
# local trust key), then the key is imported and locally signed with getuto's
# trust key so Portage accepts packages signed by it. getuto's refresh only
# re-imports the Gentoo keys and refreshes existing ones from keyservers; it
# never removes other keys.
#
# @param root
#   Config root of the owning target.
# @param public_key
#   ASCII-armored public key, e.g. `$portage::buildhost::signing::public_key`
#   from the build host.
# @param fingerprint
#   Full fingerprint of the key (40 hex digits).
# @param filename
#   Name of the stored key in binhost-keys/; defaults to the title minus its
#   `<target>/` prefix.
# @param purge
#   Remove unmanaged files from binhost-keys/.
# @param purge_ignore
#   File name patterns exempt from purging.
define portage::binhost_key (
  Portage::Targetroot $root,
  Pattern[/\A-----BEGIN PGP PUBLIC KEY BLOCK-----[\s\S]+-----END PGP PUBLIC KEY BLOCK-----\s*\z/] $public_key,
  Pattern[/\A(0x)?[0-9A-Fa-f]{40}\z/] $fingerprint,
  Optional[Pattern[/\A[A-Za-z0-9_][A-Za-z0-9_.+-]*\z/]] $filename = undef,
  Boolean $purge = true,
  Array[String[1]] $purge_ignore = [],
) {
  $prefix = $root ? {
    '/'     => '',
    default => $root,
  }
  $home = "${prefix}/etc/portage/gnupg"
  $dir = "${prefix}/etc/portage/binhost-keys"
  $fpr = $fingerprint.regsubst('\A0x', '').upcase

  $entry = $filename ? {
    undef   => regsubst($title, '\A[^/]*/', ''),
    default => $filename,
  }
  $key = "${dir}/${entry}.asc"

  unless defined(Portage::Managed_dir[$dir]) {
    portage::managed_dir { $dir:
      purge        => $purge,
      purge_ignore => $purge_ignore,
    }
  }

  file { $key:
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => $public_key,
    require => File[$dir],
  }

  $getuto = "getuto ${root}"
  unless defined(Exec[$getuto]) {
    exec { $getuto:
      command     => 'getuto',
      environment => ["ROOT=${root}"],
      creates     => $home,
      path        => ['/usr/bin', '/usr/sbin', '/bin', '/sbin'],
    }
  }

  $gpg = "gpg --homedir ${home} --batch --no-tty"
  $import = [
    "${gpg} --import ${key}",
    "${gpg} --yes --passphrase-file=${home}/pass --pinentry-mode loopback --quick-lsign-key ${fpr}",
    "${gpg} --check-trustdb",
    "chmod ugo+r ${home}/trustdb.gpg",
  ]

  exec { "import binhost key ${fpr} into ${root}":
    command   => $import.join(' && '),
    unless    => "${gpg} --with-colons --list-keys ${fpr} | grep -q '^pub:[fu]:'",
    provider  => shell,
    path      => ['/usr/bin', '/usr/sbin', '/bin', '/sbin'],
    logoutput => on_failure,
    require   => [Exec[$getuto], File[$key]],
  }
}
