# @summary Manages one package set file in /etc/portage/sets/ of a target.
#
# @param root
#   Config root of the owning target.
# @param atoms
#   Package atoms and nested sets (`@name`) in the set.
# @param world
#   Also list the set (`@name`) in /var/lib/portage/world_sets so that
#   `@world` includes it.
# @param filename
#   Set name; defaults to the title minus its `<target>/` prefix.
# @param purge
#   Remove unmanaged files from the sets directory.
# @param purge_ignore
#   File name patterns exempt from purging.
define portage::set (
  Portage::Targetroot $root,
  Array[Variant[Portage::Atom, Pattern[/\A@[A-Za-z0-9_][A-Za-z0-9_.+-]*\z/]]] $atoms,
  Boolean $world = false,
  Optional[Pattern[/\A[A-Za-z0-9_][A-Za-z0-9_.+-]*\z/]] $filename = undef,
  Boolean $purge = true,
  Array[String[1]] $purge_ignore = [],
) {
  $prefix = $root ? {
    '/'     => '',
    default => $root,
  }
  $dir = "${prefix}/etc/portage/sets"

  $entry = $filename ? {
    undef   => regsubst($title, '\A[^/]*/', ''),
    default => $filename,
  }

  unless defined(Portage::Managed_dir[$dir]) {
    portage::managed_dir { $dir:
      purge        => $purge,
      purge_ignore => $purge_ignore,
    }
  }

  file { "${dir}/${entry}":
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => "# This file is managed by Puppet. Local changes will be overwritten.\n${join($atoms, "\n")}\n",
    require => File[$dir],
  }

  if $world {
    file_line { "${title} in world_sets":
      path => "${prefix}/var/lib/portage/world_sets",
      line => "@${entry}",
    }
  }
}
