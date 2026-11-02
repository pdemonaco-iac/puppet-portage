# @summary Manages repos.conf/DEFAULT.conf, the [DEFAULT] section, of a target.
#
# @param root
#   Config root of the owning target.
# @param main_repo
#   Main repository.
# @param eclass_overrides
#   Repositories every repository inherits eclasses from (generally not
#   recommended).
# @param force
#   Attributes egencache and emirrordist must respect.
# @param purge
#   Remove unmanaged files from repos.conf.
# @param purge_ignore
#   File name patterns exempt from purging.
define portage::repos_default (
  Portage::Targetroot $root,
  Optional[Pattern[/\A[A-Za-z0-9_][A-Za-z0-9_.+-]*\z/]] $main_repo = undef,
  Optional[Array[Pattern[/\A[A-Za-z0-9_][A-Za-z0-9_.+-]*\z/]]] $eclass_overrides = undef,
  Optional[Array[Enum['aliases', 'eclass-overrides', 'masters']]] $force = undef,
  Boolean $purge = true,
  Array[String[1]] $purge_ignore = [],
) {
  $prefix = $root ? {
    '/'     => '',
    default => $root,
  }
  $dir = "${prefix}/etc/portage/repos.conf"

  $attributes = {
    'main-repo'        => $main_repo,
    'eclass-overrides' => $eclass_overrides,
    'force'            => $force,
  }.filter |$key, $value| { $value =~ NotUndef }

  unless defined(Portage::Managed_dir[$dir]) {
    portage::managed_dir { $dir:
      purge        => $purge,
      purge_ignore => $purge_ignore,
    }
  }

  file { "${dir}/DEFAULT.conf":
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => epp('portage/repo.conf.epp', { 'section' => 'DEFAULT', 'attributes' => $attributes }),
    require => File[$dir],
  }
}
