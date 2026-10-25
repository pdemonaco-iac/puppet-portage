# @summary Manages the host's Portage configuration as the `host` portage::target.
#
# Every parameter except `root` is passed to portage::target; see it for the
# details of each. Hash parameters deep-merge across Hiera layers, and an
# entry can be removed in a higher layer by prefixing its key with `--`.
#
# Managed directories purge unmanaged files by default, so run
# `puppet agent --test --noop` before the first apply on an existing node.
#
# @param make_conf
#   make.conf variables; make.conf is only managed when this is non-empty.
# @param repos_default
#   Parameters of portage::repos_default.
# @param repositories
#   portage::repository resources.
# @param profile
#   Parameters of portage::profile.
# @param binrepos_default
#   Parameters of portage::binrepos_default.
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
#   Default for every managed directory.
# @param purge_ignore
#   Default purge_ignore patterns per parameter name above.
#
# @example Hiera data
#   portage::make_conf:
#     MAKEOPTS: ['-j8']
#   portage::repositories:
#     gentoo:
#       sync_type: rsync
#       sync_uri: rsync://buildhost.example.org/gentoo
#   portage::profile:
#     path: default/linux/amd64/23.0/systemd
class portage (
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
  portage::target { 'host':
    root             => '/',
    make_conf        => $make_conf,
    repos_default    => $repos_default,
    repositories     => $repositories,
    profile          => $profile,
    binrepos_default => $binrepos_default,
    binrepos         => $binrepos,
    package_use      => $package_use,
    accept_keywords  => $accept_keywords,
    licenses         => $licenses,
    masks            => $masks,
    unmasks          => $unmasks,
    package_envs     => $package_envs,
    envs             => $envs,
    sets             => $sets,
    patches          => $patches,
    postsync         => $postsync,
    purge            => $purge,
    purge_ignore     => $purge_ignore,
  }
}
