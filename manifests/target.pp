# @summary Owns one complete Portage config root and composes its resources.
#
# Inner resources are titled `<target>/<key>`, so targets never collide. Each
# hash maps a key to the parameters of the matching defined type, minus `root`.
# The directories those types manage purge unmanaged files by default;
# /etc/portage itself is never purged, so /etc/portage/gnupg (the getuto
# keyring) survives in every root.
#
# @param root
#   Config root: `/` for the host, `/var/lib/portage-targets/<name>` for a chroot.
# @param make_conf
#   make.conf variables; make.conf is only managed when this is non-empty.
# @param repos_default
#   Parameters of portage::repos_default (the repos.conf [DEFAULT] section).
# @param repositories
#   portage::repository resources.
# @param profile
#   Parameters of portage::profile (`path` and optionally `repo`).
# @param binrepos_default
#   Parameters of portage::binrepos_default (the binrepos.conf [DEFAULT] section).
# @param binrepos
#   portage::binrepo resources.
# @param package_use
#   portage::package_use resources.
# @param accept_keywords
#   portage::accept_keywords resources.
# @param licenses
#   portage::license resources.
# @param masks
#   portage::mask resources.
# @param unmasks
#   portage::mask resources written to package.unmask.
# @param package_envs
#   portage::package_env resources.
# @param envs
#   portage::env resources.
# @param sets
#   portage::set resources.
# @param patches
#   portage::patch resources.
# @param postsync
#   portage::postsync resources.
# @param purge
#   Default for every managed directory; a resource's own `purge` wins.
# @param purge_ignore
#   Default purge_ignore patterns per parameter name above (`repositories`
#   and `repos_default` share repos.conf, `binrepos` and `binrepos_default`
#   share binrepos.conf); a resource's own `purge_ignore` wins.
define portage::target (
  Portage::Targetroot $root,
  Portage::Makeconfig $make_conf = {},
  Optional[Hash[String[1], Any]] $repos_default = undef,
  Portage::Resources $repositories = {},
  Optional[Hash[String[1], Any]] $profile = undef,
  Optional[Hash[String[1], Any]] $binrepos_default = undef,
  Portage::Resources $binrepos = {},
  Portage::Resources $package_use = {},
  Portage::Resources $accept_keywords = {},
  Portage::Resources $licenses = {},
  Portage::Resources $masks = {},
  Portage::Resources $unmasks = {},
  Portage::Resources $package_envs = {},
  Portage::Resources $envs = {},
  Portage::Resources $sets = {},
  Portage::Resources $patches = {},
  Portage::Resources $postsync = {},
  Boolean $purge = true,
  Hash[String[1], Array[String[1]]] $purge_ignore = {},
) {
  $prefix = $root ? {
    '/'     => '',
    default => $root,
  }

  file { "${prefix}/etc/portage":
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  unless $make_conf.empty {
    portage::makeconf { "${title}/make.conf":
      root   => $root,
      config => $make_conf,
    }
  }

  $singletons = {
    'repos_default'    => ['portage::repos_default', $repos_default, 'repositories'],
    'profile'          => ['portage::profile', $profile, undef],
    'binrepos_default' => ['portage::binrepos_default', $binrepos_default, 'binrepos'],
  }
  $singletons.each |$kind, $spec| {
    if $spec[1] =~ NotUndef {
      $defaults = $spec[2] ? {
        undef   => {},
        default => { 'purge' => $purge, 'purge_ignore' => $purge_ignore[$spec[2]] ? { undef => [], default => $purge_ignore[$spec[2]] } },
      }
      Resource[$spec[0]] { "${title}/${kind}":
        * => $defaults + $spec[1] + { 'root' => $root },
      }
    }
  }

  $collections = {
    'repositories'    => ['portage::repository', $repositories, {}],
    'binrepos'        => ['portage::binrepo', $binrepos, {}],
    'package_use'     => ['portage::package_use', $package_use, {}],
    'accept_keywords' => ['portage::accept_keywords', $accept_keywords, {}],
    'licenses'        => ['portage::license', $licenses, {}],
    'masks'           => ['portage::mask', $masks, {}],
    'unmasks'         => ['portage::mask', $unmasks, { 'unmask' => true }],
    'package_envs'    => ['portage::package_env', $package_envs, {}],
    'envs'            => ['portage::env', $envs, {}],
    'sets'            => ['portage::set', $sets, {}],
    'patches'         => ['portage::patch', $patches, {}],
    'postsync'        => ['portage::postsync', $postsync, {}],
  }
  $collections.each |$kind, $spec| {
    $defaults = { 'purge' => $purge, 'purge_ignore' => $purge_ignore[$kind] ? { undef => [], default => $purge_ignore[$kind] } } + $spec[2]
    $spec[1].each |$key, $params| {
      # masks and unmasks share a define, so unmask titles get their own namespace
      $unmask = $kind ? {
        'unmasks' => { 'filename' => $key },
        default   => {},
      }
      $name = $kind ? {
        'unmasks' => "${title}/unmask/${key}",
        default   => "${title}/${key}",
      }
      Resource[$spec[0]] { $name:
        * => $defaults + $unmask + $params + { 'root' => $root },
      }
    }
  }
}
