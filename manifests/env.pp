# @summary Manages one file in /etc/portage/env/ of a target.
#
# Env files use the make.conf variable syntax and are selected per package
# through portage::package_env.
#
# @param root
#   Config root of the owning target.
# @param config
#   make.conf variables; see Portage::Makeconfig for the type each accepts.
# @param filename
#   Env name; defaults to the title minus its `<target>/` prefix.
# @param purge
#   Remove unmanaged files from the env directory.
# @param purge_ignore
#   File name patterns exempt from purging.
define portage::env (
  Portage::Targetroot $root,
  Portage::Makeconfig $config = {},
  Optional[Pattern[/\A[A-Za-z0-9_][A-Za-z0-9_.+-]*\z/]] $filename = undef,
  Boolean $purge = true,
  Array[String[1]] $purge_ignore = [],
) {
  if $root != '/' {
    $config.each |$key, $value| {
      if [$value].flatten.join(' ') =~ /-march=native/ {
        fail("portage::env[${title}]: ${key} sets -march=native, which is only allowed for the host target")
      }
    }
  }

  $dir = $root ? {
    '/'     => '/etc/portage/env',
    default => "${root}/etc/portage/env",
  }

  $file = $filename ? {
    undef   => regsubst($title, '\A[^/]*/', ''),
    default => $filename,
  }

  unless defined(Portage::Managed_dir[$dir]) {
    portage::managed_dir { $dir:
      purge        => $purge,
      purge_ignore => $purge_ignore,
    }
  }

  file { "${dir}/${file}":
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => epp('portage/make.conf.epp', { 'config' => $config }),
    require => File[$dir],
  }
}
