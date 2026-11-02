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
# @param extra
#   Further variables rendered verbatim after `config`, e.g. the APACHE2_*
#   values collected from the legacy portage::makeconf shim; a key may not
#   also be in `config`.
#
# @api private
define portage::makeconf_file (
  Portage::Targetroot $root,
  Portage::Makeconfig $config = {},
  Hash[Pattern[/\A[A-Z][A-Z0-9_]*\z/], String] $extra = {},
) {
  $config.keys.each |$key| {
    if $key in $extra {
      fail("portage::makeconf_file[${title}]: ${key} is set both in config and in extra")
    }
  }

  if $root != '/' {
    $config.each |$key, $value| {
      if [$value].flatten.join(' ') =~ /-march=native/ {
        fail("portage::makeconf_file[${title}]: ${key} sets -march=native, which is only allowed for the host target")
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
    content => epp('portage/make.conf.epp', { 'config' => $config, 'extra' => $extra }),
  }
}
