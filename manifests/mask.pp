# @summary Manages one file in /etc/portage/package.mask/ or package.unmask/ of a target.
#
# @param root
#   Config root of the owning target.
# @param atoms
#   Atoms to mask (or unmask).
# @param unmask
#   Write to package.unmask instead of package.mask.
# @param filename
#   File name; defaults to the title minus its `<target>/` prefix.
# @param purge
#   Remove unmanaged files from the directory.
# @param purge_ignore
#   File name patterns exempt from purging.
define portage::mask (
  Portage::Targetroot $root,
  Array[Portage::Atom] $atoms,
  Boolean $unmask = false,
  Optional[String[1]] $filename = undef,
  Boolean $purge = true,
  Array[String[1]] $purge_ignore = [],
) {
  $kind = $unmask ? {
    true    => 'package.unmask',
    default => 'package.mask',
  }

  portage::atomfile { $title:
    root         => $root,
    kind         => $kind,
    entries      => $atoms.reduce({}) |$memo, $atom| { $memo + { $atom => [] } },
    filename     => $filename,
    purge        => $purge,
    purge_ignore => $purge_ignore,
  }
}
