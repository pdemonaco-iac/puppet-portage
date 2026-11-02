# @summary Manages one file in /etc/portage/package.accept_keywords/ of a target.
#
# @param root
#   Config root of the owning target.
# @param entries
#   Atoms mapped to the keywords that follow them on the line.
# @param filename
#   File name; defaults to the title minus its `<target>/` prefix.
# @param purge
#   Remove unmanaged files from the directory.
# @param purge_ignore
#   File name patterns exempt from purging.
define portage::accept_keywords (
  Portage::Targetroot $root,
  Hash[Portage::Atom, Array[Portage::Keyword]] $entries,
  Optional[String[1]] $filename = undef,
  Boolean $purge = true,
  Array[String[1]] $purge_ignore = [],
) {
  $file = $filename ? {
    undef   => regsubst($title, '\A[^/]*/', ''),
    default => $filename,
  }

  portage::atomfile { "${title}:package.accept_keywords":
    root         => $root,
    kind         => 'package.accept_keywords',
    entries      => $entries,
    filename     => $file,
    purge        => $purge,
    purge_ignore => $purge_ignore,
  }
}
