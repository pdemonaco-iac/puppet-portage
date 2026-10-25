# @summary Manages one file in /etc/portage/package.license/ of a target.
#
# @param root
#   Config root of the owning target.
# @param entries
#   Atoms mapped to the licenses that follow them on the line.
# @param filename
#   File name; defaults to the title minus its `<target>/` prefix.
# @param purge
#   Remove unmanaged files from the directory.
# @param purge_ignore
#   File name patterns exempt from purging.
define portage::license (
  Portage::Targetroot $root,
  Hash[Portage::Atom, Array[Portage::Licensetoken]] $entries,
  Optional[String[1]] $filename = undef,
  Boolean $purge = true,
  Array[String[1]] $purge_ignore = [],
) {
  portage::atomfile { $title:
    root         => $root,
    kind         => 'package.license',
    entries      => $entries,
    filename     => $filename,
    purge        => $purge,
    purge_ignore => $purge_ignore,
  }
}
