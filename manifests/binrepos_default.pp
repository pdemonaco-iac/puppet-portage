# @summary Manages binrepos.conf/DEFAULT.conf, the [DEFAULT] section, of a target.
#
# @param root
#   Config root of the owning target.
# @param frozen
#   Use the most recently cached copy of the remote index and do not refresh
#   it; only meant to be set temporarily for reproducible dependency
#   calculations.
# @param fetchcommand
#   FETCHCOMMAND used to fetch files from binrepos, overriding make.conf.
# @param resumecommand
#   RESUMECOMMAND used to fetch files from binrepos, overriding make.conf.
# @param purge
#   Remove unmanaged files from binrepos.conf.
# @param purge_ignore
#   File name patterns exempt from purging.
define portage::binrepos_default (
  Portage::Targetroot $root,
  Optional[Boolean] $frozen = undef,
  Optional[String[1]] $fetchcommand = undef,
  Optional[String[1]] $resumecommand = undef,
  Boolean $purge = true,
  Array[String[1]] $purge_ignore = [],
) {
  $prefix = $root ? {
    '/'     => '',
    default => $root,
  }
  $dir = "${prefix}/etc/portage/binrepos.conf"

  $attributes = {
    'frozen'        => $frozen,
    'fetchcommand'  => $fetchcommand,
    'resumecommand' => $resumecommand,
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
