# @summary Manages one binrepos.conf/<name>.conf of a target.
#
# @param root
#   Config root of the owning target.
# @param sync_uri
#   URI of the binary package repository used by `emerge --getbinpkg`.
# @param binrepo_name
#   Binrepo name (the section name); defaults to the title minus its
#   `<target>/` prefix.
# @param priority
#   Priority of the binrepo; when a package exists in several, the higher
#   priority is preferred.
# @param verify_signature
#   Verify the OpenPGP signatures of binary packages from this binrepo.
# @param location
#   Local cache of the remote repository; unique per binrepo. Portage defaults
#   to /var/cache/binhost/<name>.
# @param openpgp_key_package
#   Package providing the keyring; Portage notifies when it has an update.
# @param getbinpkg_exclude
#   Package names or slot atoms whose binary packages emerge does not fetch.
# @param getbinpkg_include
#   Package names or slot atoms whose binary packages emerge may fetch; others
#   are not fetched.
# @param purge
#   Remove unmanaged files from binrepos.conf.
# @param purge_ignore
#   File name patterns exempt from purging.
define portage::binrepo (
  Portage::Targetroot $root,
  Portage::Uri $sync_uri,
  Optional[Pattern[/\A(?!DEFAULT\z)[A-Za-z0-9_][A-Za-z0-9_.+-]*\z/]] $binrepo_name = undef,
  Optional[Integer] $priority = undef,
  Optional[Boolean] $verify_signature = undef,
  Optional[Stdlib::Unixpath] $location = undef,
  Optional[String[1]] $openpgp_key_package = undef,
  Optional[Array[String[1]]] $getbinpkg_exclude = undef,
  Optional[Array[String[1]]] $getbinpkg_include = undef,
  Boolean $purge = true,
  Array[String[1]] $purge_ignore = [],
) {
  $binrepo = $binrepo_name ? {
    undef   => regsubst($title, '\A[^/]*/', ''),
    default => $binrepo_name,
  }

  if $binrepo =~ /\ADEFAULT\z/ {
    fail("portage::binrepo[${title}]: DEFAULT is reserved")
  }

  $prefix = $root ? {
    '/'     => '',
    default => $root,
  }
  $dir = "${prefix}/etc/portage/binrepos.conf"

  $attributes = {
    'sync-uri'            => $sync_uri,
    'priority'            => $priority,
    'verify-signature'    => $verify_signature,
    'location'            => $location,
    'openpgp-key-package' => $openpgp_key_package,
    'getbinpkg-exclude'   => $getbinpkg_exclude,
    'getbinpkg-include'   => $getbinpkg_include,
  }.filter |$key, $value| { $value =~ NotUndef }

  unless defined(Portage::Managed_dir[$dir]) {
    portage::managed_dir { $dir:
      purge        => $purge,
      purge_ignore => $purge_ignore,
    }
  }

  file { "${dir}/${binrepo}.conf":
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => epp('portage/repo.conf.epp', { 'section' => $binrepo, 'attributes' => $attributes }),
    require => File[$dir],
  }
}
