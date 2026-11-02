# @summary Private: one file of atoms in a managed /etc/portage/<kind>/ directory.
#
# The kind directory is declared (once per root) by the first atomfile of that
# kind and purged by default, so unmanaged files are removed.
#
# @param root
#   Config root of the owning target.
# @param kind
#   Directory under /etc/portage holding the file.
# @param entries
#   Atoms mapped to the items that follow them on the line (may be empty).
# @param filename
#   File name within the kind directory; defaults to the title minus its
#   `<target>/` prefix.
# @param purge
#   Remove unmanaged files from the kind directory.
# @param purge_ignore
#   File name patterns exempt from purging.
#
# @api private
define portage::atomfile (
  Portage::Targetroot $root,
  Enum['package.use', 'package.accept_keywords', 'package.license', 'package.mask', 'package.unmask', 'package.env'] $kind,
  Hash[Portage::Atom, Array[String[1]]] $entries = {},
  Optional[Pattern[/\A[A-Za-z0-9_][A-Za-z0-9_.+-]*\z/]] $filename = undef,
  Boolean $purge = true,
  Array[String[1]] $purge_ignore = [],
) {
  $dir = $root ? {
    '/'     => "/etc/portage/${kind}",
    default => "${root}/etc/portage/${kind}",
  }

  $file = $filename ? {
    undef   => regsubst($title, '\A[^/]*/', ''),
    default => $filename,
  }

  unless defined(Portage::Managed_dir[$dir]) {
    portage::managed_dir { $dir:
      purge        => $purge,
      purge_ignore => $purge_ignore,
    }
  }

  file { "${dir}/${file}":
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => epp('portage/atomfile.epp', { 'entries' => $entries }),
    require => File[$dir],
  }
}
