# @summary Manages one file in /etc/portage/package.env/ of a target.
#
# Every referenced env name must be declared as `portage::env` in the same
# target (`<target>/<name>`); otherwise catalog compilation fails.
#
# @param root
#   Config root of the owning target.
# @param entries
#   Atoms mapped to the env names applied to them.
# @param target
#   Target owning the env resources; defaults to the title's `<target>/` prefix.
# @param filename
#   File name; defaults to the title minus its `<target>/` prefix.
# @param purge
#   Remove unmanaged files from the directory.
# @param purge_ignore
#   File name patterns exempt from purging.
define portage::package_env (
  Portage::Targetroot $root,
  Hash[Portage::Atom, Array[Pattern[/\A[A-Za-z0-9_][A-Za-z0-9_.+-]*\z/]]] $entries,
  Optional[String[1]] $target = undef,
  Optional[String[1]] $filename = undef,
  Boolean $purge = true,
  Array[String[1]] $purge_ignore = [],
) {
  $owner = $target ? {
    undef   => regsubst($title, '\A([^/]*)/.*\z', '\1'),
    default => $target,
  }

  $envs = $entries.values.flatten.unique.map |$name| { Portage::Env["${owner}/${name}"] }

  $file = $filename ? {
    undef   => regsubst($title, '\A[^/]*/', ''),
    default => $filename,
  }

  portage::atomfile { "${title}:package.env":
    root         => $root,
    kind         => 'package.env',
    entries      => $entries,
    filename     => $file,
    purge        => $purge,
    purge_ignore => $purge_ignore,
    require      => $envs,
  }
}
