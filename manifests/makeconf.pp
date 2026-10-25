# @summary Private: renders a target's make.conf from a single hash.
#
# Arrays are space-joined, double quotes are escaped and `${VAR}` references
# are passed through literally for Portage to expand.
#
# @param root
#   Config root of the owning target.
# @param config
#   make.conf variables from make.conf(5); see Portage::Makeconfig for
#   the type each accepts.
#
# @api private
define portage::makeconf (
  Portage::Targetroot $root,
  Portage::Makeconfig $config = {},
) {
  if $root != '/' {
    $config.each |$key, $value| {
      if [$value].flatten.join(' ') =~ /-march=native/ {
        fail("portage::makeconf[${title}]: ${key} sets -march=native, which is only allowed for the host target")
      }
    }
  }

  $path = $root ? {
    '/'     => '/etc/portage/make.conf',
    default => "${root}/etc/portage/make.conf",
  }

  file { $path:
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => epp('portage/make.conf.epp', { 'config' => $config }),
  }
}
