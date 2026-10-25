# @summary Manages one file in /etc/portage/package.use/ of a target.
#
# @param root
#   Config root of the owning target.
# @param entries
#   Atoms mapped to the USE flags that follow them on the line.
# @param filename
#   File name; defaults to the title minus its `<target>/` prefix.
# @param purge
#   Remove unmanaged files from the directory.
# @param purge_ignore
#   File name patterns exempt from purging.
define portage::package_use (
  Portage::Targetroot $root,
  Hash[Portage::Atom, Array[Portage::Useflag]] $entries,
  Optional[String[1]] $filename = undef,
  Boolean $purge = true,
  Array[String[1]] $purge_ignore = [],
) {
  $file = $filename ? {
    undef   => regsubst($title, '\A[^/]*/', ''),
    default => $filename,
  }

  portage::atomfile { "${title}:package.use":
    root         => $root,
    kind         => 'package.use',
    entries      => $entries,
    filename     => $file,
    purge        => $purge,
    purge_ignore => $purge_ignore,
  }
}
